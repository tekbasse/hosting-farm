ad_library {

    misc date-time procedures..
    @creation-date 4 December 2013
    see: http://wiki.tcl.tk/39012 for interval_*ymdhs procs discussion
}

ad_proc -public hf_clock_scan_interval { 
    seconds 
    delta 
    units
} {
   clock_scan_interval formats $seconds to a string for processing by clock scan, 
    then returns a new timestamp in seconds.
} {
   
    set stamp [clock format $seconds -format "%Y%m%dT%H%M%S"]
    if { $delta < 0 } {
	append stamp " - " [expr { abs( $delta ) } ] " " $units
    } else {
	append stamp " + " $delta " " $units
    }
    return [clock scan $stamp]
}

ad_proc -public hf_interval_ymdhs { 
    s1 
    s2
} {
    interval_ymdhs calculates the interval of time between
    the earliest date and the last date
    by starting to count at the earliest date.

    This proc has audit features. It will automatically
    attempt to correct and report any discrepancies it finds.
} {
    # if s1 and s2 aren't in seconds, convert to seconds.
    if { ![string is integer -strict $s1] } {
	set s1 [clock scan $s1]
    }
    if { ![string is integer -strict $s2] } {
	set s2 [clock scan $s2]
    }
    # postgreSQL intervals determine month length based on earliest date in interval calculations.

    # set s1 to s2 in chronological sequence
    set sn_list [lsort -integer [list $s1 $s2]]
    set s1 [lindex $sn_list 0]
    set s2 [lindex $sn_list 1]
    
    # Arithmetic is done from most significant to least significant
    # The interval is spanned in largest units first.
    # A new position s1_pN is calculated for the Nth move along the interval.
    # s1 is s1_p0

    # Calculate years from s1_p0 to s2
    set y_count 0
    set s1_p0 $s1
    set s2_y_check $s1_p0
    while { $s2_y_check <= $s2  } {
	set s1_p1 $s2_y_check
	set y $y_count
	incr y_count
	set s2_y_check [clock_scan_interval $s1_p0 $y_count years]
    }
    # interval s1_p0 to s1_p1 counted in y years

    # is the base offset incremented one too much?
    set s2_y_check [clock_scan_interval $s1 $y years]
    if { $s2_y_check > $s2 } {
	set y [expr { $y - 1 } ]
	set s2_y_check [clock_scan_interval $s1 $y years]
    }
    # increment s1 (s1_p0) forward y years to s1_p1
    if { $y == 0 } {
	set s1_p1 $s1
    } else {
	set s1_p1 [clock_scan_interval $s1 $y years]
    }
    # interval s1 to s1_p1 counted in y years

    # Calculate months from s1_p1 to s2
    set m_count 0
    set s2_m_check $s1_p1
    while { $s2_m_check <= $s2  } {
	set s1_p2 $s2_m_check
	set m $m_count
	incr m_count
	set s2_m_check [clock_scan_interval $s1_p1 $m_count months]
    }
    # interval s1_p1 to s1_p2 counted in m months

    # Calculate interval s1_p2 to s2 in days
    # day_in_sec [expr { 60 * 60 * 24 } ]
    # 86400
    # Since length of month is not relative, use math.
    # Clip any fractional part.
    set d [expr { int( ( $s2 - $s1_p2 ) / 86400. ) } ]
    # Ideally, this should always be true, but daylight savings..
    # so, go backward one day and make hourly steps for last day.
    if { $d > 0 } {
	incr d -1
    }

    # Move interval from s1_p2 to s1_p3
    set s1_p3 [clock_scan_interval $s1_p2 $d days]
    # s1_p3 is less than a day from s2


    # Calculate interval s1_p3 to s2 in hours
    # hour_in_sec [expr { 60 * 60 } ]
    # 3600
    set h [expr { int( ( $s2 - $s1_p3 ) / 3600. ) } ]
    # Move interval from s1_p3 to s1_p4
    set s1_p4 [clock_scan_interval $s1_p3 $h hours]
    # s1_p4 is less than an hour from s2


    # Sometimes h = 24, yet is already included as a day!
    # For example, this case:
    # interval_ymdhs 20010410T000000 19570613T000000
    # from Age() example in PostgreSQL documentation:
    # http://www.postgresql.org/docs/9.1/static/functions-datetime.html
    # psql test=# select age(timestamp '2001-04-10', timestamp '1957-06-13');
    #       age           
    # -------------------------
    # 43 years 9 mons 27 days
    # (1 row)
    # According to LibreCalc, the difference is 16007 days
    #puts "s2=s1+16007days? [clock format [clock_scan_interval $s1 16007 days] -format %Y%m%dT%H%M%S]"
    # ^ this calc is consistent with 16007 days 
    # So, let's ignore the Postgresql irregularity for now.
    # Here's more background:
    # http://www.postgresql.org/message-id/5A86CA18-593F-4517-BB83-995115A6A402@morth.org
    # http://www.postgresql.org/message-id/200707060844.l668i89w097496@wwwmaster.postgresql.org
    # So, Postgres had a bug..

    # Sanity check: if over 24 or 48 hours, push it up to a day unit
    set h_in_days [expr { int( $h / 24. ) } ]
    if { $h >= 1 } {
	# adjust hours to less than a day
	set h [expr { $h - ( 24 * $h_in_days ) } ]
	incr d $h_in_days
	set h_correction_p 1
    } else {
	set h_correction_p 0
    }

    # Calculate interval s1_p4 to s2 in minutes
    # minute_in_sec [expr { 60 } ]
    # 60
    set mm [expr { int( ( $s2 - $s1_p4 ) / 60. ) } ]
    # Move interval from s1_p4 to s1_p5
    set s1_p5 [clock_scan_interval $s1_p4 $mm minutes]

    # Sanity check: if 60 minutes, push it up to an hour unit
    if { $mm >= 60 } {
	# adjust 60 minutes to 1 hour
	# puts "interval_ymdhs: debug info mm - 60, h + 1"
	set mm [expr { $mm - 60 } ]
	incr h
	set mm_correction_p 1
    } else {
	set mm_correction_p 0
    }

    # Calculate interval s1_p5 to s2 in seconds
    set s [expr { int( $s2 - $s1_p5 ) } ]

    # Sanity check: if 60 seconds, push it up to one minute unit
    if { $s >= 60 } {
	# adjust 60 minutes to 1 hour
	set s [expr { $s - 60 } ]
	incr mm
	set s_correction_p 1
    } else {
	set s_correction_p 0
    }

    set return_list [list $y $m $d $h $mm $s]

    # test results by adding difference to s1 to get s2:
    set i 0
    set s1_test [clock format $s1 -format "%Y%m%dT%H%M%S"]
    set signs_inconsistent_p 0
    foreach unit {years months days hours minutes seconds} {
	set t_term [lindex $return_list $i]
	if { $t_term != 0 } {
	    if { $t_term > 0 } {
		append s1_test " + $t_term $unit"
	    } else {
		append s1_test " - [expr { abs( $t_term ) } ] $unit"
		set signs_inconsistent_p 1
	    }
	}
	incr i
    }
    
    set s2_test [clock scan $s1_test]
#  puts "test s2 '$s2_test' from: '$s1_test'"
   set counter 0
    while { $s2 ne $s2_test && $counter < 30 } {
	set s2_diff [expr { $s2_test - $s2 } ]
	ns_log Notice "\ninterval_ymdhs: debug s1 $s1 s2 $s2 y $y m $m d $d h $h s $s s2_diff $s2_diff"
	if { [expr { abs($s2_diff) } ] > 86399 } {
	    if { $s2_diff > 0 } {
		incr d -1
		ns_log Notice "interval_ymdhs: debug, audit adjustment. decreasing 1 day to $d"
	    } else {
		incr d
		ns_log Notice "interval_ymdhs: debug, audit adjustment. increasing 1 day to $d"
	    }
	} elseif { [expr { abs($s2_diff) } ] > 3599 } {
	    if { $s2_diff > 0 } {
		incr h -1
		ns_log Notice "interval_ymdhs: debug, audit adjustment. decreasing 1 hour to $h"
	    } else {
		incr h
		ns_log Notice "interval_ymdhs: debug, audit adjustment. increasing 1 hour to $h"
	    }
	} elseif { [expr { abs($s2_diff) } ] > 59 } {
	    if { $s2_diff > 0 } {
		incr mm -1
		ns_log Notice "interval_ymdhs: debug, audit adjustment. decreasing 1 minute to $mm"
	    } else {
		incr mm
		ns_log Notice "interval_ymdhs: debug, audit adjustment. increasing 1 minute to $mm"
	    }
	} elseif { [expr { abs($s2_diff) } ] > 0 } {
	    if { $s2_diff > 0 } {
		incr s -1
		ns_log Notice "interval_ymdhs: debug, audit adjustment. decreasing 1 second to $s"
	    } else {
		incr s
		ns_log Notice "interval_ymdhs: debug, audit adjustment. increasing 1 second to $s"
	    }
	}
	
	set return_list [list $y $m $d $h $mm $s]
	#    set return_list [list [expr { abs($y) } ] [expr { abs($m) } ] [expr { abs($d) } ] [expr { abs($h) } ] [expr { abs($mm) } ] [expr { abs($s) } ]]
	
	# test results by adding difference to s1 to get s2:
	set i 0
	set s1_test [clock format $s1 -format "%Y%m%dT%H%M%S"]
	foreach unit {years months days hours minutes seconds} {
	    set t_term [lindex $return_list $i]
	    if { $t_term != 0 } {
		if { $t_term > 0 } {
		    append s1_test " + $t_term $unit"
		} else {
		    append s1_test " - [expr { abs( $t_term ) } ] $unit"
		}
	    }
	    incr i
	}
	set s2_test [clock scan $s1_test]
	incr counter
    }
    if { ( $counter > 0 || $signs_inconsistent_p ) && ( $h_correction_p || $mm_correction_p || $s_correction_p ) } {
#	ns_log Notice "interval_ymdhs: Corrections in the main calculation were applied: h ${h_correction_p}, mm ${mm_correction_p}, s ${s_correction_p}" 
    }
    if { $signs_inconsistent_p } {
	ns_log Notice "\ninterval_ymdhs: signs inconsistent y $y m $m d $d h $h mm $mm s $s"
    }
    if { $s2 eq $s2_test } {
	return $return_list
    } else {
	set s2_diff [expr { $s2_test - $s2 } ]
	ns_log Notice "debug s1 $s1 s1_p1 $s1_p1 s1_p2 $s1_p2 s1_p3 $s1_p3 s1_p4 $s1_p4"
	ns_log Notice "debug y $y m $m d $d h $h mm $mm s $s"
	ns_log Notice "interval_ymdhs error: s2 is '$s2' but s2_test is '$s2_test' a difference of ${s2_diff} from s1 '$s1_test'."
#	error "result audit fails" "error: s2 is $s2 but s2_test is '$s2_test' a difference of ${s2_diff} from: '$s1_test'."
    }
}

ad_proc -public hf_interval_ymdhs_w_units { 
    t1 
    t2 
} {
    interval_ymdhs_w_units
    returns interval_ymdhs values with units
} {
    set v_list [interval_ymdhs $t2 $t1]
    set i 0
    set a ""
    foreach f {years months days hours minutes seconds} {
	append a "[lindex $v_list $i] $f \n"
	incr i
    }
    return $a
}


ad_proc -public hf_interval_remains_ymdhs { 
    s1 
    s2 
} {
    interval_remains_ymdhs calculates the interval of time between
    the earliest date and the last date
    by starting to count at the last date and work backwards in time.

    This proc has audit features. It will automatically
    attempt to correct and report any discrepancies it finds.
} {
    # if s1 and s2 aren't in seconds, convert to seconds.
    if { ![string is integer -strict $s1] } {
	set s1 [clock scan $s1]
    }
    if { ![string is integer -strict $s2] } {
	set s2 [clock scan $s2]
    }
    # set s1 to s2 in reverse chronological sequence
    set sn_list [lsort -decreasing -integer [list $s1 $s2]]
    set s1 [lindex $sn_list 0]
    set s2 [lindex $sn_list 1]
    
    # Arithmetic is done from most significant to least significant
    # The interval is spanned in largest units first.
    # A new position s1_pN is calculated for the Nth move along the interval.
    # s1 is s1_p0

    # Calculate years from s1_p0 to s2
    set y_count 0
    set s1_p0 $s1
    set s2_y_check $s1_p0
    while { $s2_y_check > $s2  } {
	set s1_p1 $s2_y_check
	set y $y_count
	incr y_count -1
	set s2_y_check [clock_scan_interval $s1_p0 $y_count years]
    }
    # interval s1_p0 to s1_p1 counted in y years


    # Calculate months from s1_p1 to s2
    set m_count 0
    set s2_m_check $s1_p1
    while { $s2_m_check > $s2  } {
	set s1_p2 $s2_m_check
	set m $m_count
	incr m_count -1
	set s2_m_check [clock_scan_interval $s1_p1 $m_count months]
    }
    # interval s1_p1 to s1_p2 counted in m months

    # Calculate interval s1_p2 to s2 in days
    # day_in_sec [expr { 60 * 60 * 24 } ]
    # 86400
    # Since length of month is not relative, use math.
    # Clip any fractional part.
    set d [expr { int( ceil( ( $s2 - $s1_p2 ) / 86400. ) ) } ]
    # Ideally, this should always be true, but daylight savings..
    # so, go backward one day and make hourly steps for last day.
    if { $d < 0 } {
	incr d
    }

    # Move interval from s1_p2 to s1_p3
    set s1_p3 [clock_scan_interval $s1_p2 $d days]
    # s1_p3 is less than a day from s2


    # Calculate interval s1_p3 to s2 in hours
    # hour_in_sec [expr { 60 * 60 } ]
    # 3600
    set h [expr { int( ceil( ( $s2 - $s1_p3 ) / 3600. ) ) } ]
    # Move interval from s1_p3 to s1_p4
    set s1_p4 [clock_scan_interval $s1_p3 $h hours]
    # s1_p4 is less than an hour from s2

    # Sanity check: if over 24 or 48 hours, push it up to a day unit
    set h_in_days [expr { int( ceil( $h / 24. ) )  } ]
    if { $h_in_days <= -1 } {
	# adjust hours to less than a day
	set h [expr { $h - ( 24 * $h_in_days ) } ]
	incr d $h_in_days
	set h_correction_p 1
    } else {
	set h_correction_p 0
    }

    # Calculate interval s1_p4 to s2 in minutes
    # minute_in_sec [expr { 60 } ]
    # 60
    set mm [expr { int( ceil( ( $s2 - $s1_p4 ) / 60. ) ) } ]
    # Move interval from s1_p4 to s1_p5
    set s1_p5 [clock_scan_interval $s1_p4 $mm minutes]

    # Sanity check: if 60 minutes, push it up to an hour unit
    if { $mm <= -60 } {
	# adjust 60 minutes to 1 hour
	# ns_log Notice "interval_remains_ymdhs: debug info mm + 60, h - 1"
	set mm [expr { $mm + 60 } ]
	incr h -1
	set mm_correction_p 1
    } else {
	set mm_correction_p 0
    }

    # Calculate interval s1_p5 to s2 in seconds
    set s [expr { $s2 - $s1_p5 } ]

    # Sanity check: if 60 seconds, push it up to one minute unit
    if { $s <= -60 } {
	# adjust 60 minutes to 1 hour
	set s [expr { $s + 60 } ]
	incr mm -1
	set s_correction_p 1
    } else {
	set s_correction_p 0
    }

    set return_list [list $y $m $d $h $mm $s]
    #    set return_list [list [expr { abs($y) } ] [expr { abs($m) } ] [expr { abs($d) } ] [expr { abs($h) } ] [expr { abs($mm) } ] [expr { abs($s) } ]]

    # test results by adding difference to s1 to get s2:
    set i 0
    set s1_test [clock format $s1 -format "%Y%m%dT%H%M%S"]
    set signs_inconsistent_p 0
    foreach unit {years months days hours minutes seconds} {
	set t_term [lindex $return_list $i]
	if { $t_term != 0 } {
	    if { $t_term > 0 } {
		append s1_test " + $t_term $unit"
		set signs_inconsistent_p 1
	    } else {
		append s1_test " - [expr { abs( $t_term ) } ] $unit"
	    }
	}
	incr i
    }
    set s2_test [clock scan $s1_test]

    set counter 0
    while { $s2 ne $s2_test && $counter < 3 } {
	set s2_diff [expr { $s2_test - $s2 } ]
	ns_log Notice "\ninterval_remains_ymdhs: debug s1 $s1 s2 $s2 y $y m $m d $d h $h s $s s2_diff $s2_diff"
	if { [expr { abs($s2_diff) } ] >= 86399 } {
	    if { $s2_diff > 0 } {
		incr d -1
		ns_log Notice "interval_remains_ymdhs: debug, audit adjustment. increasing 1 day to $d"
	    } else {
		incr d
		ns_log Notice "interval_remains_ymdhs: debug, audit adjustment. decreasing 1 day to $d"
	    }
	} elseif { [expr { abs($s2_diff) } ] > 3599 } {
	    if { $s2_diff > 0 } {
		incr h -1
		ns_log Notice "interval_remains_ymdhs: debug, audit adjustment. increasing 1 hour to $h"
	    } else {
		incr h
		ns_log Notice "interval_remains_ymdhs: debug, audit adjustment. decreasing 1 hour to $h"
	    }
	} elseif { [expr { abs($s2_diff) } ] > 59 } {
	    if { $s2_diff > 0 } {
		incr mm -1
		ns_log Notice "interval_remains_ymdhs: debug, audit adjustment. increasing 1 minute to $mm"
	    } else {
		incr mm
		ns_log Notice "interval_remains_ymdhs: debug, audit adjustment. decreasing 1 minute to $mm"
	    }
	} elseif { [expr { abs($s2_diff) } ] > 0 } {
	    if { $s2_diff > 0 } {
		incr s -1
		ns_log Notice "interval_remains_ymdhs: debug, audit adjustment. increasing 1 second to $s"
	    } else {
		incr s
		ns_log Notice "interval_remains_ymdhs: debug, audit adjustment. decreasing 1 second to $s"
	    }
	}
	
	set return_list [list $y $m $d $h $mm $s]
	#    set return_list [list [expr { abs($y) } ] [expr { abs($m) } ] [expr { abs($d) } ] [expr { abs($h) } ] [expr { abs($mm) } ] [expr { abs($s) } ]]
	
	# test results by adding difference to s1 to get s2:
	set i 0
	set s1_test [clock format $s1 -format "%Y%m%dT%H%M%S"]
	foreach unit {years months days hours minutes seconds} {
	    set t_term [lindex $return_list $i]
	    if { $t_term != 0 } {
		if { $t_term > 0 } {
		    append s1_test " + $t_term $unit"
		} else {
		    append s1_test " - [expr { abs( $t_term ) } ] $unit"
		}
	    }
	    incr i
	}
	set s2_test [clock scan $s1_test]
	incr counter
    }
    if { ( $counter > 0 || $signs_inconsistent_p ) && ( $h_correction_p || $mm_correction_p || $s_correction_p ) } {
#	ns_log Notice "interval_remains_ymdhs: Corrections in the main calculation were applied: h ${h_correction_p}, mm ${mm_correction_p}, s ${s_correction_p}" 
    }
    if { $signs_inconsistent_p } {
	ns_log Notice "\ninterval_remains_ymdhs: signs inconsistent y $y m $m d $d h $h mm $mm s $s"
    }
    if { $s2 eq $s2_test } {
	return $return_list
    } else {
	set s2_diff [expr { $s2_test - $s2 } ]
	ns_log Notice "debug s1 $s1 s1_p1 $s1_p1 s1_p2 $s1_p2 s1_p3 $s1_p3 s1_p4 $s1_p4"
	ns_log Notice "debug y $y m $m d $d h $h mm $mm s $s"
	ns_log Notice "interval_remains_ymdhs error: s2 is '$s2' but s2_test is '$s2_test' a difference of ${s2_diff} from s1 '$s1_test'."
#	error "result audit fails" "error: s2 is $s2 but s2_test is '$s2_test' a difference of ${s2_diff} from: '$s1_test'."
    }

}

ad_proc -public hf_interval_remains_ymdhs_w_units { 
    t1 
    t2
} {
    interval_remains_ymdhs_w_units
    returns interval_remains_ymdhs values with units
} {
    set v_list [interval_ymdhs $t2 $t1]
    set i 0
    set a ""
    foreach f {years months days hours minutes seconds} {
	append a "[lindex $v_list $i] $f \n"
	incr i
    }
    return $a
}
