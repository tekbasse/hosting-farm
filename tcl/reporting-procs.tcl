ad_library {

    library for making reports in Hosting Farm
    @creation-date 11 December 2013
    @Copyright (c) 2014 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl-2.0.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com
}


ad_proc -public hf_convert_to_iec_bytes {
    number
    unit
    {pretty_p "0"}
} { 
    Converts bytes with large numbers to whole bytes. Returns a pretty string if pretty_p is 1.

    @param number   A decimal number.
    @param unit     One of  B KiB MiB GiB TiB PiB EiB ZiB YiB
    @param pretty_p If 1, appends ' B' to returned number.

    @return Returns number in bytes.
} {
    set abbrev_list [list B KiB MiB GiB TiB PiB EiB ZiB YiB]
    # convert to units of one
    set unit_index [lsearch -exact $abbrev_list $unit]
    set number [expr { wide( $number ) } ]
    if { $unit_index > 0 } {
        set number [expr { $number * pow(1000,$unit_index) } ]
        set unit "B"
    }
    if { $pretty_p } {
        append number " ${unit}"
    }
    return $number
}

ad_proc -public hf_convert_to_dec_bytes {
    number
    unit
    {pretty_p "0"}
} { 
    Converts bytes with large numbers to whole bytes. Returns a pretty string if pretty_p is 1.

    @param number   A decimal number.
    @param unit     One of  B kB MB GB TB PB EB ZB YB
    @param pretty_p If 1, appends ' B' to returned number.

    @return Returns number in bytes.
} {
    set abbrev_list [list B kB MB GB TB PB EB ZB YB]
    # convert to units of one
    set unit_index [lsearch -exact $abbrev_list $unit]
    set number [expr { wide( $number ) } ]
    if { $unit_index > 0 } {
        set number [expr { $number * pow(1000,$unit_index) } ]
        set unit "B"
    }
    if { $pretty_p } {
        append number " ${unit}"
    }
    return $number
}

ad_proc -public hf_convert_to_unit_metric {
    number
    unit
    {pretty_p "0"}
} { 
    Converts bytes with large numbers to whole bytes. Returns a pretty string if pretty_p is 1.

    @param number   A decimal number.
    @param unit     One of B K M G T P E Z Y
    @param pretty_p If 1, appends ' B' to returned number.

    @return Returns number in bytes.
} {
    set abbrev_list [list B K M G T P E Z Y]
    # convert to units of one
    set unit_index [lsearch -exact $abbrev_list $unit]
    set number [expr { wide( $number ) } ]
    if { $unit_index > 0 } {
        set number [expr { $number * pow(1000,$unit_index) } ]
        set unit "B"
    }
    if { $pretty_p } {
        append number " ${unit}"
    }
    return $number
}

ad_proc -private hf_health_html { 
    health_score
    {message ""}
    {theme "rock"}
    {width_limit ""}
    {height_limit ""}
} {
   Returns html of icon etc representing health status.
} {
    # health score is 0 to 16, interprets statistics
    # 0 = inactive 
    # 1 active,
    # 2 not enough monitoring data. alert face 
    # 3 = amusement
    # 4 to 12 = normal range, joy
    # 13-14 laughter
    # 15 within 10% of limit, anxious
    # 16 overlimit, error, alarm, (alarm notification: shock), error (surprise).

    # rock theme names and icons inspired from:
    # "Making Comics: Storytelling secrets of comics, manga and graphic novels by Scott McCloud"
    # http://www.scottmccloud.com/2-print/3-mc/
    # satisfaction , amusement, joy , laughter
    # concern, anxious, fear, terror
    # dejection, melancholy, sad, grief
    # alert, wonder, surprise, shock

    # make sure $health is in range 0 to 16
    set health [expr { [f::min 16 [f::max 0 round($health_score) ]] } ]

    # set filename first. It might be needed for image dimensions.
    set health_name_list [list "inactive" "active" "alert" "amusement" "joy" "joy" "joy" "joy" "joy" "joy" "joy" "joy" "joy" "laughter" "anxiety" "surprise"]
    set icon_name [lindex $health_name_list $health_score]
    set url_dir "/resources/hosting-farm/icons"
    set work_dir [file join [acs_root_dir] www $url_dir]
    switch -exact -- $theme {
        rock {
            set extension ".png"
            set icon_name "rock-${icon_name}${extension}"
            set width 326 
            set height 326
        }
        default {
            set extension_list [list png jpg gif]
            set icon_name_glob $icon_name
            append icon_name_glob {*.{[jJ][pp][gG],[pP][nN][gG],[gG][iI][fF]}}
            set image_names_list [glob -nocomplain -tails -directory $work_dir -- $icon_name_glob ]
            # assume only one, or just pick the first in the list anyway..
            set icon_pathname [lindex $image_names_list 0]
            set extension [file extension $icon_pathname]
            set icon_name [file tail $icon_pathname]
            if { [regexp -nocase -- ".jpg" $extension match] } {
                set wh_list [ns_jpegsize $icon_name]
            } elseif { [regexp -nocase -- ".gif" $extension match] } {
                set wh_list [ns_gifsize $icon_name]
            } elseif { [string length $extension] > 0 } {
                # imagemagic \[exec identify -format "%[fx:w]x%[fx:h]" image.jpg\]
                ns_log Notice "hf_health_html: icon_pathname '$icon_pathname' dir_work '$dir_work' icon_name '$icon_name' extension '$extension'"
                #            set response [exec -- /usr/local/bin/gm -identify format $imagepath_name]
                catch {exec -- /usr/local/bin/gm -identify format $imagepath_name} response
                # response:
                #zbf.jpg JPEG 289x289+0+0 DirectClass 8-bit 6.4k 0.008u 0:01
                regexp {[^\ ]+[\ ][^\ ]+[\ ]([0-9]+)x([0-9]+)[^0-9].*} $response b width height
            }
        }
    }

    # fit within limits
    set ratio_w 1
    set ratio_h 1
    if { $width_limit ne "" && $width_limit < $width } {
        set ratio_w [expr { $width_limit / ( $width * 1.) } ]
        if { $height_limit ne "" && $height_limit < $height } {
            set ratio_h [expr { $height_limit / ( $height * 1.) } ]
        } 
    }
    set ratio [f::min $ratio_h $ratio_w]
    set width_new [expr { round( $width * $ratio ) } ]
    set height_new [expr { round( $height * $ratio ) } ]

    set health_html "<img src=\"[file join $url_dir $icon_name]\""
    append health_html " width=\"${width_new}\" height=\"${height_new}\""
    append health_html " alt=\"#accounts-ledger.${health_score}#\" title=\"#accounts-ledger.${health_score}#: $message\">"
    return $health_html
}


ad_proc -private hf_as_type_html { 
    as_type
    {title ""}
    {theme "hf"}
    {width_limit ""}
    {height_limit ""}
} {
   Returns html of icon etc representing asset type.
} {
    set as_type_abbrev_list [list DC HW VM VH SS]
    # make sure $as_type is in range 
    set as_type_i [lsearch -nocase $as_type_abbrev_list $as_type]
    set as_type_html ""
    if { $as_type_i > -1 } {
        set as_type [lindex $as_type_abbrev_list $as_type_i]
        # set filename first. It might be needed for image dimensions.
        set as_type_name_list [list "Data Center" "Hardware" "Virtual Machine" "Virtual Host" "Software as Service"]
        # short circuiting.. by using as_type_abbrev_list instead
        set icon_name $as_type
        set url_dir "/resources/hosting-farm/icons"
        set work_dir [file join [acs_root_dir] www $url_dir]
        switch -exact -- $theme {
            hf {
                set extension ".png"
                set icon_name "[string tolower ${as_type}]${extension}"
                set width 326 
                set height 326
            }
            default {
                set extension_list [list png jpg gif]
                set icon_name_glob $icon_name
                append icon_name_glob {*.{[jJ][pp][gG],[pP][nN][gG],[gG][iI][fF]}}
                set image_names_list [glob -nocomplain -tails -directory $work_dir -- $icon_name_glob ]
                # assume only one, or just pick the first in the list anyway..
                set icon_pathname [lindex $image_names_list 0]
                set extension [file extension $icon_pathname]
                set icon_name [file tail $icon_pathname]
                if { [regexp -nocase -- ".jpg" $extension match] } {
                    set wh_list [ns_jpegsize $icon_name]
                } elseif { [regexp -nocase -- ".gif" $extension match] } {
                    set wh_list [ns_gifsize $icon_name]
                } elseif { [string length $extension] > 0 } {
                    # imagemagic \[exec identify -format "%[fx:w]x%[fx:h]" image.jpg\]
                    ns_log Notice "hf_as_type_html: icon_pathname '$icon_pathname' dir_work '$dir_work' icon_name '$icon_name' extension '$extension'"
                    #            set response [exec -- /usr/local/bin/gm -identify format $imagepath_name]
                    catch {exec -- /usr/local/bin/gm -identify format $imagepath_name} response
                    # response:
                    #zbf.jpg JPEG 289x289+0+0 DirectClass 8-bit 6.4k 0.008u 0:01
                    regexp {[^\ ]+[\ ][^\ ]+[\ ]([0-9]+)x([0-9]+)[^0-9].*} $response b width height
                }
            }
        }
        
        # fit within limits
        set ratio_w 1
        set ratio_h 1
        if { $width_limit ne "" && $width_limit < $width } {
            set ratio_w [expr { $width_limit / ( $width * 1.) } ]
            if { $height_limit ne "" && $height_limit < $height } {
                set ratio_h [expr { $height_limit / ( $height * 1.) } ]
            } 
        }
        set ratio [f::min $ratio_h $ratio_w]
        set width_new [expr { round( $width * $ratio ) } ]
        set height_new [expr { round( $height * $ratio ) } ]

        set as_type_html ""
        set title_is_html_p 0
        # if title contains an A tag, let's expand it around the image.
        if { [regexp -nocase {<a href=[\"]?([^\"]+)[\"]?>([^\<]+)</a>} $title title_html url title ] } {
            set title_is_html_p 1
            append as_type_html "<a href=\"$url\" title=\"$title\">"
        }

       
        append as_type_html "<img src=\"[file join $url_dir $icon_name]\""
        append as_type_html " width=\"${width_new}\" height=\"${height_new}\""
        append as_type_html " title=\"${title}\">"
        if { $title_is_html_p } {
            append as_type_html "</a>"
        }
    }
    return $as_type_html
}

ad_proc -private hf_meter_percent_html { 
    meter_percent
    {title ""}
    {fill_color ""}
    {width "392"}
    {height "392"}
    {max_percent "100"}
} {
   Returns html of icon etc representing a metered percentage. 
    Expects 0 to 100 percent. 100 = 100%. The default color 
    starts as a bluish-gray and becomes more yellow as it approaches 1.
    If max_percent is provided, then width represents the point of max value. This is useful for
    aligning multiple meters with the same meter box size.
} {
    set meter_percent_html ""
    # make sure meter_percent is a number greater than 0
#    ns_log Notice "hf_meter_percent_html(438): max_percent '$max_percent' meter_percent '$meter_percent' fill_color '$fill_color'"
    if { $meter_percent >= 0 } {
        if { $fill_color eq "" } {
            set hexi_nbr [list 0 1 2 3 4 5 6 7 8 9 a b c d e f]
            # convert meter to number
            # base of 666699 to ffffcc
            set bar_list [list r g b]
            set min_color_list [list 6 6 9]
            set max_color_list [list 15 15 12]
            set i 0
            foreach bar $bar_list {
                set min_c [lindex $min_color_list $i]
                set max_c [lindex $max_color_list $i]
#                ns_log Notice "hf_meter_percent_html: bar $bar min_c $min_c max_c $max_c meter_percent $meter_percent"
                set color [f::min [expr { int( ( $max_c - $min_c ) * $meter_percent / 100. ) + $min_c } ] 15]
                set color_h [lindex $hexi_nbr $color]
                append fill_color $color_h $color_h
                incr i
            }
        }
        if { $max_percent ne "100" } {
#            ns_log Notice "hf_meter_percent_html(458): max_percent '$max_percent' meter_percent '$meter_percent' fill_color '$fill_color'"
            set ratio [expr { 100. / ( $max_percent * 1. ) } ]
        } else {
            set ratio 1.
        }
        set width_box [expr { int( $width * $ratio ) } ]
        set width_bar [expr { round( $meter_percent * $width / $max_percent ) } ]
 #          ns_log Notice "hf_meter_percent_html(466): max_percent '$max_percent' meter_percent '$meter_percent' width '$width' width_box '$width_box' width_bar '$width_bar'"
        # box without borders
        append meter_percent_html "\n<div style=\"z-index: 5; width: ${width}px; height: ${height}px;\" title=\"$title\">"

        # bar
        append meter_percent_html "<div style=\"z-index: 7; background-color: #${fill_color}; width: ${width_bar}px; height: ${height}px;\">"
        # bordered box
        set height_box [expr { $height - 4 } ]
        append meter_percent_html "<div style=\"overflow-x: visible; z-index: 9; border: 2px solid; width: ${width_box}px; height: ${height_box}px;\">"

        # close box divs
        append meter_percent_html "</div></div></div>"
    }
    return $meter_percent_html
}

ad_proc -private hf_pagination_by_items {
    item_count
    items_per_page
    first_item_displayed
} {
    returns a list of 3 pagination components, the first is a list of page_number and start_row pairs for pages before the current page, the second contains page_number and start_row for the current page, and the third is the same value pair for pages after the current page.  See hosting-farm/lib/paginiation-bar for an implementation example. 
} {
    # based on ecds_pagination_by_items
    if { $items_per_page > 0 && $item_count > 0 && $first_item_displayed > 0 && $first_item_displayed <= $item_count } {
        set bar_list [list]
        set end_page [expr { ( $item_count + $items_per_page - 1 ) / $items_per_page } ]

        set current_page [expr { ( $first_item_displayed + $items_per_page - 1 ) / $items_per_page } ]

        # first row of current page \[expr { (( $current_page - 1)  * $items_per_page ) + 1 } \]

        # create bar_list with no pages beyond end_page

        if { $item_count > [expr { $items_per_page * 81 } ] } {
            # use exponential page referencing
            set relative_step 0
            set next_bar_list [list]
            set prev_bar_list [list]
            # 0.69314718056 = log(2)  
            set max_search_points [expr { int( ( log( $end_page ) / 0.69314718056 ) + 1 ) } ]
            for {set exponent 0} { $exponent <= $max_search_points } { incr exponent 1 } {
                # exponent refers to a page, relative_step refers to a relative row
                set relative_step_row [expr { int( pow( 2, $exponent ) ) } ]
                set relative_step_page $relative_step_row
                lappend next_bar_list $relative_step_page
                set prev_bar_list [linsert $prev_bar_list 0 [expr { -1 * $relative_step_page } ]]
            }

            # template_bar_list and relative_bar_list contain page numbers
            set template_bar_list [concat $prev_bar_list 0 $next_bar_list]
            set relative_bar_list [lsort -unique -increasing -integer $template_bar_list]
            
            # translalte bar_list relative values to absolute rows
            foreach {relative_page} $relative_bar_list {
                set new_page [expr { int ( $relative_page + $current_page ) } ]
                if { $new_page < $end_page } {
                    lappend bar_list $new_page 
                }
            }

        } elseif {  $item_count > [expr { $items_per_page * 10 } ] } {
            # use linear, stepped page referencing

            set next_bar_list [list 1 2 3 4 5]
            set prev_bar_list [list -5 -4 -3 -2 -1]
            set template_bar_list [concat $prev_bar_list 0 $next_bar_list]
            set relative_bar_list [lsort -unique -increasing -integer $template_bar_list]
            # translalte bar_list relative values to absolute rows
            foreach {relative_page} $relative_bar_list {
                set new_page [expr { int ( $relative_page + $current_page ) } ]
                if { $new_page < $end_page } {
                    lappend bar_list $new_page 
                }
            }
            # add absolute page references
            for {set page_number 10} { $page_number <= $end_page } { incr page_number 10 } {
                lappend bar_list $page_number
                set bar_list [linsert $bar_list 0 [expr { -1 * $page_number } ] ]
            }

        } else {
            # use complete page reference list
            for {set page_number 1} { $page_number <= $end_page } { incr page_number 1 } {
                lappend bar_list $page_number
            }
        }

        # add absolute reference for first page, last page
        lappend bar_list $end_page
        set bar_list [linsert $bar_list 0 1]

        # clean up list
        # now we need to sort and remove any remaining nonpositive integers and duplicates
        set filtered_bar_list [lsort -unique -increasing -integer [lsearch -all -glob -inline $bar_list {[0-9]*} ]]
        # delete any cases of page zero
        set zero_index [lsearch $filtered_bar_list 0]
        set bar_list [lreplace $filtered_bar_list $zero_index $zero_index]

        # generate list of lists for code in ecommerce/lib
        set prev_bar_list_pair [list]
        set current_bar_list_pair [list]
        set next_bar_list_pair [list]
        foreach page $bar_list {
            set start_item [expr { ( ( $page - 1 ) * $items_per_page ) + 1 } ]
            if { $page < $current_page } {
                lappend prev_bar_list_pair $page $start_item
            } elseif { $page eq $current_page } {
                lappend current_bar_list_pair $page $start_item
            } elseif { $page > $current_page } {
                lappend next_bar_list_pair $page $start_item
            }
        }
        set bar_list_set [list $prev_bar_list_pair $current_bar_list_pair $next_bar_list_pair]
    } else {
        ns_log Warning "hf_pagination_by_items: parameter value(s) out of bounds for $item_count $items_per_page $first_item_displayed"
    }

    return $bar_list_set
}

