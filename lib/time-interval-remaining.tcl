# hosting-farm/lib/time-interval-remaining.tcl
# requires time1, time2 in tcl seconds
set images_html ""
if { [info exists time1] && [info exists time2] } {
    set ymdhms_ref_list [list 5 4 3 2 1 0]
    set ymdhms_unit_list [list "year" "month" "day" "hour" "minute" "second"]
    # link units to switch branch
    foreach unit $ymdhms_unit_list {
        set switch_arr($unit) $unit
    }
    set switch_arr(second) "default" 
    set switch_arr(minute) "default"
# test case:
#set time1 "1386610479"
#set time2 "1469384818"

    set units_list [hf_interval_remains_ymdhms $time1 $time2]
    set units_string [hf_interval_remains_ymdhms_w_units $time1 $time2]
    append images_html "<div class=\"hf_interval_remains\" title=\"${units_string}\">"
    

    # image widths ymd(hms): 54 15 2 (2)
    set m_width 15
    set mdhms_px_width [expr { abs( [lindex $units_list 1] * 15. ) + abs( [lindex $units_list 2] * 2. ) + 2. } ]
    set y_px_width [expr { abs( [lindex $units_list 0] * 54. ) } ]
    set div_px_width [expr { $y_px_width + $mdhms_px_width } ]
    # 4 column max width approx 189 px
#    set reduce_factor [expr { ( 244. - $mdhms_px_width ) / ( $y_px_width ) } ]
    set reduce_factor [expr { 189. / ( $mdhms_px_width + $y_px_width ) } ]
    if { $reduce_factor > 1 } {
        set reduce_factor 1.
    }
    if { [expr { $reduce_factor * $y_px_width + $mdhms_px_width } ] > 187 } {
        set m_width [expr { int( 15 * $reduce_factor ) } ]
    }
    set y_width [expr { int( 54 * $reduce_factor ) } ]

    foreach unit_ref $ymdhms_ref_list {
        set unit_val [lindex $units_list $unit_ref]
        set unit [lindex $ymdhms_unit_list $unit_ref]
        if { $unit_val != 0 } {
            set image_html ""
            set unit_val_abs [expr { abs( $unit_val) } ]
            switch -exact -- $switch_arr($unit) {
                year {
ns_log Notice "hosting-farm/lib/time-interval-remaining.tcl y_width $y_width m_width $m_width mdhms_px_width $mdhms_px_width y_px_width $y_px_width"
                    for {set i 0} { $i < $unit_val_abs } { incr i } {
                        append image_html "<img src=\"/resources/hosting-farm/icons/1-year.png\" style=\"vertical-align: bottom;\" width=\"${y_width}\" height=\"42\" alt=\"\">"
                    }
                }
                month { 
                    for {set i 0} { $i < $unit_val_abs } { incr i } {
                        append image_html "<img src=\"/resources/hosting-farm/icons/1-month.png\" style=\"vertical-align: bottom;\" width=\"${m_width}\" height=\"34\" alt=\"\">"
                    }
                }
                day {   
                    for {set i 0} { $i < $unit_val_abs } { incr i } {
                        append image_html "<img src=\"/resources/hosting-farm/icons/1-day.png\" style=\"vertical-align: bottom;\" width=\"2\" height=\"12\" alt=\"\">"
                    }
                }
                hour {
                    # hour image is in 2 hour segments, round off to nearest segment unit
                    set height [expr { round( $unit_val_abs / 2. ) } ]
                    if { $height > 0 } {
                        append image_html "<img src=\"/resources/hosting-farm/icons/2-hours.png\" style=\"vertical-align: bottom;\" width=\"2\" height=\"${height}\" alt=\"\">"
                    }
                }
                default { 
                    # ignore 
                }
            }
            if { [string length $image_html] > 0 } {
                append images_html $image_html
            }
        }
    }
    append images_html "</div>\n"
}
