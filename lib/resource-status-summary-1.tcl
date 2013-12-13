# hosting-farm/lib/resource-status-summary-1.tcl
# Returns summary list of status, highest scores first

set asset_stts_smmry_lists [hf_asset_summary_status "" interval_remaining 5]

foreach report_list $asset_stts_smmry_lists {
    set status_list [lrange $report_list 0 3] 
    lappend status_list "[lindex $report_list 4] [lindex $report_list 5]"
    lappend status_list [lrange $report_list 6 7]
    lappend status_list [hf_health_html [lindex $report_list 8] [lindex $report_list 9] rock 36]
    lappend asset_report_lists $status_list
}

set asset_table_titles [list "label" "name" "type" "metric" "sample" "quota%" "projected" "status"]

if { [info exists columns ] } {
    set arl_length [llength $asset_report_lists]
    set items_per_list [expr { int( $arl_length / $columns ) + 1 } ]
    set new_report_lists [list ]
    set items_per_list_m_1 [expr { $items_per_list - 1 } ]
    for {set i 0} {$i < $items_per_list} {incr } {

        lappend new_report_lists $asset_table_titles
        lappend new_report_lists [lrange $asset_report_lists $i [expr { $i +$items_per_list } ] ]
        # between_columns_html  if exists, inserts html that goes between each column

    }

} else {

    set asset_report_lists [linsert $asset_report_lists 0 $asset_table_titles]
    set summary_html [qss_list_of_lists_to_html $asset_db_lists table_att_list td_att_list]
}
