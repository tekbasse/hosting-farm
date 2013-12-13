# hosting-farm/lib/resource-status-summary-1.tcl
# Returns summary list of status, highest scores first

# if $columns exists, splits the list into $columns number of columns
# before_columns_html and after_columns_html  if exists, inserts html that goes between each column


set asset_stts_smmry_lists [hf_asset_summary_status "" $interval_remaining 5]

set asset_report_lists [list ]
foreach report_list $asset_stts_smmry_lists {
    set status_list [list ]
    lappend status_list "<a href=\"[string tolower [lindex $report_list 2]]?label=[lindex $report_list 1]\">[lindex $report_list 0]</a>"
#    lappend status_list [lindex $report_list 1]
    lappend status_list [lindex $report_list 2]
    lappend status_list [lindex $report_list 3]
    lappend status_list [lindex $report_list 4]
    lappend status_list [lindex $report_list 5]
    lappend status_list [lindex $report_list 6]
    lappend status_list [hf_health_html [lindex $report_list 7] [lindex $report_list 8] rock 36]
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

    set asset_report_lists [linsert $asset_report_lists 0 $asset_table_titles]
    set summary_html [qss_list_of_lists_to_html_table $asset_report_lists $table_att_list $td_att_list]
}
