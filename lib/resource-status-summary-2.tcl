# hosting-farm/lib/resource-status-summary-1.tcl
# Returns summary list of status, highest scores first

if { ![info exists compact_p] } {
    set compact_p 1
}

# This is a compact version of resource-stat-summary-1

# Include 'list_limit' to limit the list to that many items.

# If 'columns' exists, splits the list into $columns number of columns.
# before_columns_html and after_columns_html  if exists, inserts html that goes between each column


if { [info exists list_limit] && $list_limit > 0 } {
    set asset_stts_smmry_lists [hf_asset_summary_status "" $interval_remaining $list_limit]
} else {
    set asset_stts_smmry_lists [hf_asset_summary_status "" $interval_remaining]
}
# as_label as_name as_type metric latest_sample percent_quota projected_eop score score_message

set asset_report_lists [list ]
foreach report_list $asset_stts_smmry_lists {
    set status_list [list ]
    lappend status_list "<a href=\"[string tolower [lindex $report_list 2]]?label=[lindex $report_list 1]\">[lindex $report_list 0]</a>"
#    lappend status_list [lindex $report_list 1]
    lappend status_list [lindex $report_list 2]
    set metric [lindex $report_list 3]
    lappend status_list $metric
    set sample [lindex $report_list 4]
    set projected_eop [lindex $report_list 6]
    if { $metric eq "traffic" } {
        set sample [qal_pretty_bytes_iec $sample]
        set projected_eop [qal_pretty_bytes_iec $projected_eop]
    } else {
        set sample [qal_pretty_bytes_dec $sample]
        set projected_eop [qal_pretty_bytes_dec $projected_eop]
    }
    lappend status_list $sample
    lappend status_list [format "%d%%" [lindex $report_list 5]]
    lappend status_list $projected_eop

    lappend status_list [hf_health_html [lindex $report_list 7] [lindex $report_list 8] rock 35]
    lappend asset_report_lists $status_list
}

set asset_table_titles [list "name" "type" "metric" "sample" "quota" "projected" "status"]
set table_att_list [list ]
set td_att_list [list ]
if { [info exists columns ] } {
    set before_columns_html  {<div class="l-grid-quarter m-grid-half s-grid-whole padded">
  <div class="content-box">
 <div>&nbsp;</div>
    }
    set after_columns_html { <div>&nbsp;</div>
  </div>
</div>
    }
    set arl_length [llength $asset_report_lists]
    set items_per_list [expr { int( $arl_length / $columns ) + 1 } ]

    set items_per_list_m_1 [expr { $items_per_list - 1 } ]
    set summary_html ""
    for {set i 0} {$i < $items_per_list} {incr i} {
        if { [info exists before_columns_html] } {
            append summary_html $before_columns_html
        }
        set new_report_lists [list ]
        lappend new_report_lists $asset_table_titles
        set column_lists [lrange $asset_report_lists $i [expr { $i + $items_per_list } ] ]
        foreach row_list $column_lists {
            lappend new_report_lists $row_list
        }
        # between_columns_html  if exists, inserts html that goes between each column
        append summary_html [qss_list_of_lists_to_html_table $new_report_lists $table_att_list $td_att_list]
        if { [info exists after_columns_html] } {
            append summary_html $after_columns_html
        }
    }

} else {

    if { $compact_p } {
        
        # was:  "name" "type" "metric" "sample" "quota" "projected" "status"
        # dropping sample, projected
        set asset_report_new_lists [list ]
        set max_quota 100
        foreach report_list $asset_report_lists {
            set max_quota [f::max [regsub -all { %} [lindex $report_list 4] ] $max_quota]
        }
        foreach report_list $asset_report_lists {
            set report_new_list [list]
            set name [lindex $report_list 0]
            set type [lindex $report_list 1]
            lappend report_new_list [hf_as_type_html $type $name hf 35]
            # metric
            lappend report_new_list [lindex $report_list 2]
            # quota
            set quota_html [lindex $report_list 4]
            set quota [regsub { %} $quota_html {} quota]
            lappend report_new_list [hf_meter_percent_html $quota "$quota %" "" 120 35 $max_quota]
            # status
            lappend report_new_list [lindex $report_list 6]
            lappend asset_report_new_lists $report_new_list
        }
        set td_att_compact_list [list [lindex $td_att_list 0] [lindex $td_att_list 2] [lindex $td_att_list 4] [lindex $td_att_list 6]]
        #following is not compact enough.
#        set summary_html [qss_list_of_lists_to_html_table $asset_report_new_lists $table_att_list $td_att_compact_list]
        set summary_html ""
        foreach item $asset_report_new_lists {
            append summary_html "[lindex $item 0]<br>"
            append summary_html "<div class=\"grid-third\">[lindex $item 1]</div>"
            append summary_html "<div class=\"grid-third\" style=\"text-align: right;\">[lindex $item 2]</div>"
            append summary_html "<div class=\"grid-third\">[lindex $item 3]</div>"
        }
    } else {
        set asset_report_lists [linsert $asset_report_lists 0 $asset_table_titles]
        set summary_html [qss_list_of_lists_to_html_table $asset_report_lists $table_att_list $td_att_list]
    }


}

