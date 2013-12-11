# hosting-farm/lib/resource-status-summary-1.tcl
# requires:
# 
# optional: 
# list_limit
         
# This is configured as a demo.
# A release version would require user_id, customer_ids_list..

# check for compact style
if { ![info exists compact_p ] } {
    set compact_p 0
}

# use percent measurements and faces for compact style

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
    lappend random_names_list "$name.[lindex [expr { int( rand() * $suffix_count + .5 ) } ]"
}

set as_root_lists [list [list DC traffic power other] \
                       [list HW traffic storage] \
                       [list VM traffic storage memory] \
                       [list VH storage] \
                       [list SS traffic storage memory]]
foreach asr_list $as_root_lists {
    set asr_arr([lindex $asr_list 0]) [lreplace $asr_list 0 0]
}
set as_type_list [list DC HW VM VH SS]
set as_type_count [llength $as_type_lists]

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
    set quota_arr("[lindex $q_list 0],[lindex $q_list 1]") [lindex $q_list 2]
}


# asset db
# attribute = meter_type = metric
# as_label as_name as_type metric lastest_sample unit
set as_count [expr { int( rand() * 50 ) + 1 } ]
for { set i 1} {$i < $as_count} {incr i} {
    set as_label [lindex $random_names_list $i]
    set as_name $as_label
    set as_type [lindex $as_type_list [expr { int( rand() * $as_type_count + .99 ) } ]]
    foreach as_at $asr_arr($as_type) {
        set as_list [list ]############
                     lappend asset_db_lists $as_list
                 }
}
# report db built from hf_monitor_config_n_control, monitor_log, hf_monitor_status
# reportdb asset_label as_type as_attribute monitor_label portions_count health report_id
# for quota monitoring, portions_count is count per last two weeks.


# health score is 0 to 16, interprets statistics
# see icons
#satisfaction , amusement, joy , laugh
#concern, anxious, fear, terror
#dejection, melancholy, sad, grief
#alert, wonder, surprise, shock

# 0 = inactive 
# 1 active,
# 2 not enough monitoring data. alert face 
# 3 = amusement
# 4 to 12 = normal range, joy
# 13-14 laugh
# 15 within 10% of limit, anxious
# 16 overlimit, error, alarm, (alarm notification: shock), error (surprise).
set theme "rock"
set icon_name_list [list "inactive" "active" "alert" "amusement" "joy" "joy" "joy" "joy" "joy" "joy" "joy" "joy" "joy" "laugh" "anxious" "surprise"]

# as_label as_name as_type metric latest_sample unit percent_quota projected_eop score score_message




