ad_library {

    library of procedures for building reports
    @creation-date 11 December 2013
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
    # 13-14 laugh
    # 15 within 10% of limit, anxious
    # 16 overlimit, error, alarm, (alarm notification: shock), error (surprise).

    # rock theme names and icons inspired from:
    # "Making Comics: Storytelling secrets of comics, manga and graphic novels by Scott McCloud"
    # http://www.scottmccloud.com/2-print/3-mc/
    # satisfaction , amusement, joy , laugh
    # concern, anxious, fear, terror
    # dejection, melancholy, sad, grief
    # alert, wonder, surprise, shock

    # make sure $health is in range 0 to 16
    set health [expr { [f::min 16 [f::max 0 round($health_score) ]] } ]

    # set filename first. It might be needed for image dimensions.
    set health_name_list [list "inactive" "active" "alert" "amusement" "joy" "joy" "joy" "joy" "joy" "joy" "joy" "joy" "joy" "laugh" "anxious" "surprise"]
    set icon_name [lindex $health_name_list $health_score]
    set url_dir "/resources/hosting-farm/icons"
    set work_dir [file join [acs_root_dir] www $url_dir]
    switch -exact $theme {
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
                ns_log Notice "mi_image_atts: icon_pathname '$icon_pathname' dir_work '$dir_work' icon_name '$icon_name' extension '$extension'"
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
        set ratio_w [expr { $width_limit / $width } ]
        if { $height_limit ne "" && $height_limit < $height } {
            set ratio_h [expr { $height_limit / $height } ]
        } 
    }
    set ratio [f::min $ratio_h $ratio_w]
    set width_new [expr { $width * $ratio } ]
    set height_new [expr { $height * $ratio } ]

    set health_html "<img src=\"[file join $url_dir $icon_name]\""
    append health_html " width=\"${width_new}\" height=\"${height_new}\""
    append health_html " alt=\"#accounts-ledger.${health_score}#\" title=\"\"#accounts-ledger.${health_score}#\"\">"
    return $health_html
}

ad_proc -private hf_asset_summary_status {
    {customer_ids_list ""}
    {interval_remaining_ts ""}
    {list_limit ""}
    {now_ts ""}
    {interval_length_ts ""}
} {
    Returns summary list of status, highest scores first. Ordered lists are: asset_label asset_name asset_type metric latest_sample unit percent_quota projected_eop score score_message
} {
    # interval_remaining_ts  timestamp in seconds
    # # following two options might be alternatives to interval_remaining_ts
    # now_ts                in timestamp seconds
    # interval_length_ts    in timestamp seconds
    if { [llength $customer_ids_list] == 0 } {
        set customer_ids_list [list ]
    } 
    # list_limit            limits the number of items returned.

    # This is configured as a demo.
    # A release version would require user_id, customer_ids_list..
    
    if { $now_ts eq "" } {
        set now_ts [clock seconds]
    }

    # EOT = end of term
    # classic
    # asset_type attribute quota current_sample projected_EOT
    
    # compact view: percent of alloted resources
    # asset_type attribute pct_of_quota projected_EOT_pct
    

    # from ams example
    # HW Traffic 102400000000 136.69 GB 146.67 GB
    # HW Storage 10.00 TB 2.37 TB 3.25 TB
    # HW Memory 768.00 GB 537.00 GB 580.00 GB
    # VM Traffic 1024 GB 136.69 MB 146.67 MB
    # VM Storage 10.00 GB 2.37 GB 3.25 GB
    # VM Memory 768.00 MB 537.00 MB 580.00 MB
    # SS Traffic 1024 MB 136.69 KB 146.67 KB
    # SS Storage 10.00 MB 2.37 MB 3.25 MB
    # SS Memory 768.00 KB 537.00 KB 580.00 KB
    
    # following from hipsteripsum.me
    set random_names [list Umami gastropub authentic keytar Church-key Brooklyn four loko yr VHS craft beer hoodie Shoreditch gluten-free food truck squid seitan disrupt synth you probably havent heard of them Hoodie beard polaroid single-origin coffee skateboard organic irony plaid XOXO ethical IPhone squid photo booth irony street art lomo gastropub bitters literally kogi Bicycle rights PBR small batch deep ab.v post-ironic Vice photo booth Mustache Portland selvage Vice yr YOLO Banksy slow-carb Odd Future cred Shabby chic Blue Bottle pop-up XOXO cray locavore sartorial deep v butcher readymade gluten-free]
    set names_count [llength $random_names]
    set random_names_list [list ]
    set random_suffix_list [list net com me info ca us pa es co.uk tv no dk de fr jp cn in org cc biz nu ws bz org.uk tm ms pro mx tw jobs ac io sh eu at nl la fm it co ag pl sc hn mn tk vc pe au ch ru se fi if os so be do hi ho is jo ro un]
    set suffix_count [llength $random_suffix_list ]
    foreach name $random_names {
        lappend random_names_list "$name.[lindex ${random_suffix_list} [expr { int( rand() * $suffix_count + .5 ) } ]]"
    }
    
    set as_root_lists [list [list DC traffic power other] \
                           [list HW traffic storage] \
                           [list VM traffic storage memory] \
                           [list VH storage] \
                           [list SS traffic storage memory]]
    foreach asr_list $as_root_lists {
        set i [lindex $asr_list 0]
        set asr_arr($i) [lreplace $asr_list 0 0]
#        ns_log Notice "hf_asset_summary_status: asr_arr($i) '$asr_arr($i)'"
    }
    set as_type_list [list DC HW VM VH SS]
    set as_type_count [llength $as_type_list]
    
    set quota_lists [list \
                         [list DC traffic 102400000000000] \
                         [list DC power 10000000000000] \
                         [list DC other 10000000000000] \
                         [list HW traffic 102400000000] \
                         [list HW storage 10000000000000] \
                         [list VM traffic 1024000000000] \
                         [list VM storage 10000000000] \
                         [list VM memory 768000000] \
                         [list VH storage 10000000] \
                         [list SS traffic 1024000000] \
                         [list SS storage 10000000] \
                         [list SS memory 768000]]
    foreach q_list $quota_lists {
        set i "[lindex $q_list 0],[lindex $q_list 1]"
        set quota_arr($i) [lindex $q_list 2]

    }
    
    
    # asset db
    # attribute = meter_type = metric
    # as_label as_name as_type 
    set asset_db_lists [list ]
    set as_count [expr { int( rand() * 50 ) + 1 } ]
    for { set i 1} {$i < $as_count} {incr i} {
        set as_label [lindex $random_names_list $i]
        set as_name $as_label
        set as_type [lindex $as_type_list [expr { int( rand() * $as_type_count - .01 ) } ]]
#ns_log Notice "hf_asset_summary_status: as_type '$as_type' "
        # as_label as_name as_type
        set as_list [list $as_label $as_name $as_type]
        lappend asset_db_lists $as_list
    }
    
    
    
    
    # for the demo,  manually build a fake list instead of calling a procedure
    # as_label as_name as_type metric latest_sample unit percent_quota projected_eop score score_message
    foreach asset_list $asset_db_lists {
        # asset_list is a list of asset attributes: label, name, type
        set as_type [lindex $asset_list 2]
        # start rolling dice..
        set active_p [expr { int( rand() * 16 ) > 1 } ] 
        
        set as_reports_list $asset_list
        
        if { $active_p } {
            # sometimes an account is new, so not enough info exists
            # role dice..
            set history_exists_p [expr { int( rand() * 16.99 ) } ]
            
            # metric1 metric2 metric..
            foreach as_at $asr_arr($as_type) {
                # quota_arr(as_type,metric) = quota amount
                set iq "${as_type},${as_at}"
                set quota $quota_arr($iq)
                # 16 health scores, lets randomly try to get all cases for demo and testing
                # only 1/8 are stressfull , 1/8 = 0.125
                set sample [expr { int( rand() * $quota * 1.125 ) } ]
                set unit "B"
                set pct_quota [expr { 100. * $sample / ( $quota * 1.) } ]
                if { $history_exists_p } {
                    set weeks_rate [expr { int( rand() * $sample / 3. ) } ]  
                    # convert rate to interval_length
                    # 1 week = 604800 seconds
                    # interval_rate = units_per_week / secs_per_week * secs_per_interval_remaining
                    set interval_rate [expr { $weeks_rate * $interval_remaining_ts / 604800. } ]
                    set projected_eop [expr { $sample + $interval_rate } ]
                    set projected_eop_html $projected_eop
                    if { $as_at eq "traffic" } {
                        set sample_html [qal_pretty_bytes_iec $sample]
                        set projected_eop_html [qal_pretty_bytes_iec $projected_eop]
                    } else {
                        set sample_html [qal_pretty_bytes_dec $sample]
                        set projected_eop_html [qal_pretty_bytes_dec $projected_eop]
                    }
                    set pct_quota_html [format "%d%%"]
                } else {
                    # not enough history to calculate
                    set projected_eop 0
                    set projected_eop_html "#accounts-ledger.N_A#"
                }
                
                # calc health score value
                # initial health is based on background performance..
                set health_score [expr { int( rand() * 11 ) + 1 } ]
                set hs_message "#accounts-ledger.${health_score}#"
                if { $projected_eop > [expr { $quota * 0.9 } ] || $pct_quota > 0.8 } {
                    set health_score 13
                    set hs_message "Near quota limit."
                }
                if { $projected_eop > $quota } {
                    set health_score 14
                    set hs_message "May be over quota before end of term."
                }
                if { $pct_quota > 1 } {
                    set health_score 15
                    set hs_message "Over quota."
                }
                # $as_at is metric
                lappend as_reports_list $as_at
                lappend as_reports_list $sample_html $unit $pct_quota_html $projected_eop_html $health_score $hs_message
                # as_label as_name as_type metric latest_sample unit percent_quota projected_eop score score_message
                lappend asset_db_lists $as_reports_list
            }
        } else {
            # asset not active
            set health_score 0
            set hs_message ""
            lappend as_reports_list "#accounts-ledger.N_A#" "" "" "" "" $health_score "inactive"
            lappend asset_db_lists $as_reports_list
        }
    }
    
    # report db built from hf_monitor_config_n_control, monitor_log, hf_monitor_status
    # reportdb asset_label as_type as_attribute monitor_label portions_count health report_id
    # for quota monitoring, portions_count is count per last two weeks.
    set asset_db_sorted_lists [lsort -index 8 -decreasing $asset_db_lists]
    if { $list_limit ne "" } {
        incr list_limit -1
        set asset_db_sorted_lists [lrange $asset_db_sorted_lists 0 $list_limit]
    }
    return $asset_db_sorted_lists
}
