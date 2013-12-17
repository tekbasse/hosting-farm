# hosting-farm/lib/resource-status-summary-1.tcl
# Returns summary list of assets with status, highest scores first
# This version requires the entire table to be loaded for processing.
# TODO: make another version that uses pg's select limit and offset.. to scale well.

# Include 'list_limit' to limit the list to that many items.

# If 'columns' exists, splits the list into $columns number of columns.
# before_columns_html and after_columns_html  if exists, inserts html that goes between each column

if { ![info exists compact_p] } {
    set compact_p 1
}

# General flow:
# get table as list_of_lists
# sort
# paginate
# process list_limit
# show_sort UI
#     columns, column_order, and cell data vary between compact_p vs. default, keep in mind with sort UI

# show_pagination UI
# output.. compact_p vs. regular, according to row_count, columns, column_order and cell data


# query the data. For now, 

if { [info exists list_limit] && $list_limit > 0 && [info exists list_start] && $list_offset > 0 } {
    set asset_stts_smmry_lists [hf_asset_summary_status "" $interval_remaining $list_limit "" "" $list_offset]
} else {
    set asset_stts_smmry_lists [hf_asset_summary_status "" $interval_remaining]
}
# as_label as_name as_type metric latest_sample percent_quota projected_eop score score_message



### following from table-sort


# this is rough in code that sorts a table of info by column, and adds more functions to each row.
# This code will be used to generate more useful page sort UI for tables using qss_* functions

#set table_lists [list [list a b c d e f] [list b c a d e f a] [list a b c a b c a] [list a b c a c d b ] [list a b c f e d g]]
set table_lists $asset_stts_smmry_lists

# ================================================
# Sort Table Columns
# arguments
#     s sort_order_list (via form)
#     p primary_sort_col_new (via form)
#     table_lists (table represented as a list of lists
# ================================================
set table_cols_count [llength [lindex $table_lists 0]]
set table_index_last [expr { $table_cols_count - 1 } ]
#set table_titles_list [list "Item&nbsp;ID" "Title" "Status" "Description" "Due&nbsp;Date" "Creation&nbsp;Date"]
set table_titles_list [list "Label" "Name" "Type" "Metric" "Reading" "Quota" "Projected" "Health Score" "Message"]
# as_label as_name as_type metric latest_sample percent_quota projected_eop score score_message
ns_log Notice "resource-status-summary-1(12): table_cols_count $table_cols_count table_index_last $table_index_last "

# defaults and inputs
#set sort_type_list [list "-integer" "-ascii" "-ascii" "-ascii" "-ascii" "-ascii" "-ascii"]
set sort_type_list [list "-ascii" "-dictionary" "-ascii" "-ascii" "-real" "-real" "-real" "-integer" "-ascii"]
set sort_stack_list [lrange [list 0 1 2 3 4 5 6 7 8 9 10] 0 $table_index_last ]
set sort_order_list [list ]
set sort_rev_order_list [list ]
set table_sorted_lists $table_lists
set form_posted [qf_get_inputs_as_array input_array]
ns_log Notice "hf_table_sort.tcl(26): form_posted $form_posted"

# Sort table?
if { [info exists input_array(s)] } {
    # Sort table
    ns_log Notice "hf_table_sort.tcl(29): input_array(s) $input_array(s)"
    # A sort order has been requested
    # Validate sort order, because it is user input via web
    regsub -all -- {[^\-0-9a]} $input_array(s) {} sort_order_scalar
    ns_log Notice "hf_table_sort.tcl(30): sort_order_scalar $sort_order_scalar"
    set sort_order_list [split $sort_order_scalar a]
    set sort_order_list [lrange $sort_order_list 0 $table_index_last]
    # Has a sort order change been requested?
    if { [info exists input_array(p)] } {
        ns_log Notice "hf_table_sort.tcl(32): sort_order_list '$sort_order_list' input_array(p) $input_array(p)"
        # new primary sort requested
        # validate user input, fail silently
        regsub -all -- {[^\-0-9]+} $input_array(p) {} primary_sort_col_new
        set primary_sort_col_pos [expr { abs( $primary_sort_col_new ) } ]
        ns_log Notice "hf_table_sort.tcl(35): primary_sort_col_new $primary_sort_col_new"
        if { $primary_sort_col_new ne "" && $primary_sort_col_pos < $table_cols_count } {
            ns_log Notice "hf_table_sort.tcl(44): primary_sort_col_new $primary_sort_col_new primary_sort_col_pos $primary_sort_col_pos"
            # modify sort_order_list
            set sort_order_new_list [list $primary_sort_col_new]
            foreach ii $sort_order_list {
                if { [expr { abs($ii) } ] ne $primary_sort_col_pos } {
                    lappend sort_order_new_list $ii
                    ns_log Notice "hf_table_sort.tcl(46): ii '$ii' sort_order_new_list '$sort_order_new_list'"
                }
            }
            set sort_order_list $sort_order_new_list
            ns_log Notice "hf_table_sort.tcl(48): end if primary_sort_col_new.. "
        }
        ns_log Notice "hf_table_sort.tcl(49): end if input_array(p).. "
    }

    ns_log Notice "hf_table_sort.tcl(52): sort_order_scalar '$sort_order_scalar' sort_order_list '$sort_order_list'"
    # Create a reverse index list for index countdown
    set sort_rev_order_list [lsort -integer -decreasing [lrange $sort_stack_list 0 [expr { [llength $sort_order_list] - 1 } ] ] ]
    ns_log Notice "hf_table_sort.tcl(53): sort_rev_order_list '$sort_rev_order_list' "
    foreach ii $sort_rev_order_list {
        set col2sort [lindex $sort_order_list $ii]
        ns_log Notice "hf_table_sort.tcl(54): ii $ii col2sort '$col2sort' llength col2sort [llength $col2sort] sort_rev_order_list '$sort_rev_order_list' sort_order_list '$sort_order_list'"
        if { [string range $col2sort 0 0] eq "-" } {
            set col2sort_wo_sign [string range $col2sort 1 end]
            set sort_order "-decreasing"
        } else { 
            set col2sort_wo_sign $col2sort
            set sort_order "-increasing"
        }
        set sort_type [lindex $sort_type_list $col2sort_wo_sign]
        # Putting following lsort in a catch statement so that if the sort errors, default to -ascii sort.
        # Sort table_lists by column number $col2sort_wo_sign, where 0 is left most column
        if {[catch { set table_sorted_lists [lsort $sort_type $sort_order -index $col2sort_wo_sign $table_sorted_lists] } result]} {
            # lsort errored, probably due to bad sort_type. Fall back to -ascii sort_type, or fail..
            set table_sorted_lists [lsort -ascii $sort_order -index $col2sort_wo_sign $table_sorted_lists]
            ns_log Notice "hf_table_sort(83): lsort fell back to sort_type -ascii due to error: $result"
        }
        ns_log Notice "hf_table_sort.tcl(66): lsort $sort_type $sort_order -index $col2sort_wo_sign table_sorted_lists"
        
    }
} 

# UI for Table Sort

# Add the sort links to the titles.
set url [ad_conn url]
# urlcode sort_order_list
set s_urlcoded ""
foreach sort_i $sort_order_list {
    append s_urlcoded $sort_i
    append s_urlcoded a
}
set s_urlcoded [string range $s_urlcoded 0 end-1]
set text_asc "^"
set text_desc "v"
set title_asc "ascending"
set title_desc "descending"
set table_titles_w_links_list [list ]
set column_count 0
set primary_sort_col [lindex $sort_order_list 0]
foreach title $table_titles_list {
    # For now, just inactivate the left most sort link that was most recently pressed (if it has been)
    set title_new $title
    if { $primary_sort_col eq "" || ( $primary_sort_col ne "" && $column_count ne [expr { abs($primary_sort_col) } ] ) } {
        ns_log Notice "hf_table_sort.tcl(104): column_count $column_count s_urlcoded '$s_urlcoded'"
        append title_new " (<a href=\"$url?s=${s_urlcoded}&p=${column_count}\" title=\"${title_asc}\">${text_asc}</a>:<a href=\"$url?s=${s_urlcoded}&p=-${column_count}\" title=\"${title_desc}\">${text_desc}</a>)"
    } else {
        if { [string range $s_urlcoded 0 0] eq "-" } {
            ns_log Notice "hf_table_sort.tcl(105): column_count $column_count title $title s_urlcoded '$s_urlcoded'"
            # decreasing primary sort chosen last, no need to make the link active
            append title_new " (<a href=\"$url?s=${s_urlcoded}&p=${column_count}\" title=\"${title_asc}\">${text_asc}</a>:${text_desc})"
        } else {
            ns_log Notice "hf_table_sort.tcl(106): column_count $column_count title $title s_urlcoded '$s_urlcoded'"
            # increasing primary sort chosen last, no need to make the link active
            append title_new " (${text_asc}:<a href=\"$url?s=${s_urlcoded}&p=-${column_count}\" title=\"${title_desc}\">${text_desc}</a>)"
        }
    }
    lappend table_titles_w_links_list $title_new
    incr column_count
}
set table_titles_list $table_titles_w_links_list

# Add Row of Titles to Table
set table_sorted_lists [linsert $table_sorted_lists 0 [lrange $table_titles_list 0 $table_index_last]]

# Result: table_sorted_lists
# Number of sorted columns:
set sort_cols_count [llength $sort_order_list]



# ================================================
# Change the order of columns
# so that the primary sort col is left, secondary is 2nd from left etc.
# parameters: table_sorted_lists
set table_col_sorted_lists [list ]
# Rebuild the table, one row at a time, adding the primary, secondary etc. columns in order
foreach table_row_list $table_sorted_lists {
    set table_row_new [list ]
    # Track the rows that aren't sorted
    set unsorted_list $sort_stack_list
    foreach ii $sort_order_list {
        set ii_pos [expr { abs( $ii ) } ]
        lappend table_row_new [lindex $table_row_list $ii_pos]
        # Blank the reference instead of removing it, or the $ii reference won't work. lsearch is slower
        set unsorted_list [lreplace $unsorted_list $ii_pos $ii_pos ""]
    }
    # Now that the sorted columns are added to the row, add the remaining columns
    foreach ui $unsorted_list {
        if { $ui ne "" } {
            # Add unsorted column to row
            lappend table_row_new [lindex $table_row_list $ui]
        }
    }
    # Confirm that all columns have been accounted for.
    set table_row_new_cols [llength $table_row_new]
    if { $table_row_new_cols != $table_cols_count } {
        ns_log Notice "hf_table_sort.tcl(71): table_row_new has ${table_row_new_cols} instead of ${table_cols_count} columns."
    }
    # Append new row to new table
    lappend table_col_sorted_lists $table_row_new
}

# ================================================
# Add UI Options column to table

set table2_lists [list ]
set row_count 0
foreach row_list $table_col_sorted_lists {
    set new_row_list $row_list
    if { $row_count > 0 } {
        set new_row_list $row_list
        set item_id [string trim [lindex $row_list 0]]
        set view   "<a href=\"viewa?item_id=$item_id\">view</a>"
        set edit   "<a href=\"edita?item_id=$item_id\">edit</a>"
        set delete "<a href=\"deletea?item_id=$item_id\">delete</a>"
        set options_col "$view $edit $delete"
    } else {
        # First row is a title row. Add title
        set options_col "Options"
    }
    lappend new_row_list $options_col

    # Add the revised row to the new table
    lappend table2_lists $new_row_list
    incr row_count
}


# ================================================
# Formatting code
# Add attributes to the TABLE tag
set table2_atts_list [list border 1 cellspacing 0 cellpadding 2]

# Add cell formatting to TD tags
set cell_formating_list [list ]
# Let's try to get fancy, have the rows alternate color after the first row, 
# and have the sorted columns slightly lighter in color to highlight them
# base alternating row colors:
set color_even_row "#cccccc"
set color_odd_row "#ccffcc"
# sorted column colors
set color_even_scol "#dddddd"
set color_odd_scol "#ddffdd"

# Set the default title row TD formats before columns sorted:
# Title row TD formats
set title_td_attrs_list [list [list valign top align right bgcolor #ffffff]\
         [list valign top bgcolor #ffffff]\
         [list valign top bgcolor #ffffff]\
         [list valign top bgcolor #ffffff]\
         [list valign top bgcolor #ffffff]\
         [list valign top bgcolor #ffffff]\
         [list valign top bgcolor #ffffff]]
# The first column is an index number, so right justify the values
set even_row_list [list [list valign top align right] [list valign top] [list valign top] [list valign top] [list valign top] [list valign top] [list valign top]]
set odd_row_list [list [list valign top align right] [list valign top] [list valign top] [list valign top] [list valign top] [list valign top] [list valign top]]
set cell_table_lists [list $title_td_attrs_list $odd_row_list $even_row_list]

# Rebuild the even/odd rows adding the colors
# If the column order changes, then formatting of the TD tags may change, too.
# So, re-order the formatting columns, inserting the appropriate color at each cell.
# Use the same looping logic from when the table columns changed order to avoid inconsistencies

# Rebuild the cell format table, one row at a time, adding the primary, secondary etc. columns in order
set row_count 0
set cell_table_sorted_lists [list ]
foreach td_row_list $cell_table_lists {
    set td_row_new [list ]
    # Track the rows that aren't sorted
    set unsorted_list $sort_stack_list
    foreach ii $sort_order_list {
        set ii_pos [expr { abs( $ii ) } ]
        set cell_format_list [lindex $td_row_list $ii_pos]
        if { $row_count > 0 } {
            # add the appropriate background color
            if { [f::even_p $row_count] } {
                lappend cell_format_list bgcolor $color_even_scol
            } else {
                lappend cell_format_list bgcolor $color_odd_scol
            }
        }
        lappend td_row_new $cell_format_list
        # Blank the reference instead of removing it, or the $ii reference won't work. lsearch is slower
        set unsorted_list [lreplace $unsorted_list $ii_pos $ii_pos ""]
    }
    # Now that the sorted columns are added to the row, add the remaining columns
    foreach ui $unsorted_list {
        if { $ui ne "" } {
            set cell_format_list [lindex $td_row_list $ui]
            if { $row_count > 0 } {
                # add the appropriate background color
                if { [f::even_p $row_count] } {
                    lappend cell_format_list bgcolor $color_even_row
                } else {
                    lappend cell_format_list bgcolor $color_odd_row
                }
            }
            # Add unsorted column to row
            lappend td_row_new $cell_format_list
        }
    }
    # Append new row to new table
    lappend cell_table_sorted_lists $td_row_new
    incr row_count
}

set table_row_count [llength $table2_lists]
set row_odd_format [lindex $cell_table_sorted_lists 1]
set row_even_format [lindex $cell_table_sorted_lists 2]
if { $table_row_count > 3 } { 
    # Repeat the odd/even rows for the length of the table (table2_lists)
    for {set row_i 3} {$row_i < $table_row_count} { incr row_i } {
        if { [f::even_p $row_i ] } {
            lappend cell_table_sorted_lists $row_even_format
        } else {
            lappend cell_table_sorted_lists $row_odd_format
        }
    }

}
# ================================================


# this builds the html table and assigns it to table2_html
set table2_html [qss_list_of_lists_to_html_table $table2_lists $table2_atts_list $cell_table_sorted_lists]
# add table2_html to adp output
append summary_html $table2_html


## following from resource-status-summary-2.tcl


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
    lappend status_list "([lindex $report_list 7]) [lindex $report_list 8]"
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
            regsub -all -- {[ %]} [lindex $report_list 4] {} quota_test
            set max_quota [f::max $quota_test $max_quota]
        }
        foreach report_list $asset_report_lists {
            set report_new_list [list]
            set name [lindex $report_list 0]
            set type [lindex $report_list 1]
            lappend report_new_list [hf_as_type_html $type $name hf 35]
            # metric
            set metric [lindex $report_list 2]
            lappend report_new_list "<img src=\"/hosting-farm/resources/icons/hf-${metric}.png\" width=\"35\" height=\"35\" title=\"$metric\">"
            # quota
            set quota_html [lindex $report_list 4]
            regsub -all -- {[ %]} $quota_html {} quota
            # status
            set status [lindex $report_list 6]
            set score_message [lindex $report_list 7]
            lappend report_new_list [hf_meter_percent_html $quota "$quota %" "" 80 35 $max_quota]
            lappend report_new_list $status
            lappend asset_report_new_lists $report_new_list
        }
        set td_att_compact_list [list [lindex $td_att_list 0] [lindex $td_att_list 2] [lindex $td_att_list 4] [lindex $td_att_list 6]]
        #following is not compact enough.
#        set summary_html [qss_list_of_lists_to_html_table $asset_report_new_lists $table_att_list $td_att_compact_list]
        set summary_html "<table>"
        foreach item $asset_report_new_lists {
            append summary_html "<tr>"
            append summary_html "<td>[lindex $item 0]</td>"
            append summary_html "<td>[lindex $item 1]</td>"
            append summary_html "<td>[lindex $item 2]</td>"
            append summary_html "<td>[lindex $item 3]</td>"
            append summary_html "</tr>"
        }
        append summary_html "</table>"
    } else {
        set asset_report_lists [linsert $asset_report_lists 0 $asset_table_titles]
        set summary_html [qss_list_of_lists_to_html_table $asset_report_lists $table_att_list $td_att_list]
    }


}

