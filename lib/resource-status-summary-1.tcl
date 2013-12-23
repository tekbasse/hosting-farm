# hosting-farm/lib/resource-status-summary-1.tcl
# Returns summary list of assets with status, highest scores first
# This version requires the entire table to be loaded for processing.
# TODO: make another version that uses pg's select limit and offset.. to scale well.

# REQUIRED:
# @param item_count          number of items
# @param items_per_page      number of items per page
# @param this_start_row      start row (item number) for this page


# OPTIONAL:
# @param base_url             url for building page links
# @param separator            html used between page numbers, defaults to &nbsp;
# @param list_limit           limits the list to that many items.
# @param list_offset          offset the list to start at some point other than the first item.
# @param columns              splits the list into $columns number of columns.
# @param before_columns_html  inserts html that goes between each column
# @param after_columns_html   ditto

# General process flow:
# 1. Get table as list_of_lists
# 2. Sort unformatted columns by row values
# 3. Pagination_bar -- calcs including list_limit and list_offset, build UI
# 4. Sort UI -- build
#     columns, column_order, and cell data vary between compact_p vs. default, keep in mind with sort UI
# 5. Format output -- compact_p vs. regular
set nav_html ""
set page_html ""

# ================================================
# 1. Get table as list_of_lists
# ================================================
# don't process list_offset or list_limit here.
set asset_stts_smmry_lists [hf_asset_summary_status "" $interval_remaining]
### for demo, setting item_count here
set item_count [llength $asset_stts_smmry_lists]
set items_per_page 12
if { ![info exists base_url] } {
    set base_url [ad_conn url]
}
#if { ![info exists base_url] } {
#    set base_url [ns_conn url]
#}
#if { ![info exists base_url] } {
#    set base_url [ad_conn path_url]
#}

set this_start_row_exists_p [info exists this_start_row]
set s_exists_p [info exists s]
set p_exists_p [info exists p]
if { !$this_start_row_exists_p || ( $this_start_row_exists_p && ![qf_is_natural_number $this_start_row] ) } {
    set this_start_row 1
}
if { ![info exists separator] } {
    set separator "&nbsp;"
}

# columns:
# as_label as_name as_type metric latest_sample percent_quota projected_eop score score_message


# ================================================
# 2. Sort unformatted columns by row values
# ================================================
# Sort Table Columns
# arguments
#     s sort_order_list (via form)
#     p primary_sort_col_new (via form)
#     table_lists (table represented as a list of lists
# ================================================
set table_lists $asset_stts_smmry_lists
set table_cols_count [llength [lindex $table_lists 0]]
set table_index_last [expr { $table_cols_count - 1 } ]
#set table_titles_list [list "Item&nbsp;ID" "Title" "Status" "Description" "Due&nbsp;Date" "Creation&nbsp;Date"]
set table_titles_list [list "Label" "Name" "Type" "Metric" "Reading" "Quota" "Projected" "Health Score" "Message"]
# as_label as_name as_type metric latest_sample percent_quota projected_eop score score_message
#ns_log Notice "resource-status-summary-1(45): table_cols_count $table_cols_count table_index_last $table_index_last "

# defaults and inputs
set sort_type_list [list "-ascii" "-dictionary" "-ascii" "-ascii" "-real" "-real" "-real" "-integer" "-ascii"]
#set sort_stack_list \[lrange \[list 0 1 2 3 4 5 6 7 8 9 10\] 0 $table_index_last \]
set i 0
set sort_stack_list [list ]
while { $i < $table_cols_count } {
    lappend sort_stack_list $i
    incr i
}
set sort_order_list [list ]
set sort_rev_order_list [list ]
set table_sorted_lists $table_lists

# Sort table?
if { $s_exists_p && $s ne "" } {
    # Sort table
    # A sort order has been requested
    # $s is in the form of a string of integers delimited by the letter a. 
    # Each integer is a column number.
    # A positive integer sorts column increasing.
    # A negative integer sorts column decreasing.
    # Primary sort column is listed first, followed by secondary sort etc.

    # Validate sort order, because it is user input via web
    # $s' first check and change to sort_order_scalar
    regsub -all -- {[^\-0-9a]} $s {} sort_order_scalar
    # ns_log Notice "resource-status-summary-1.tcl(73): sort_order_scalar $sort_order_scalar"
    # Converting sort_order_scalar to a list
    set sort_order_list [split $sort_order_scalar a]
    set sort_order_list [lrange $sort_order_list 0 $table_index_last]
    
}

# Has a sort order change been requested?
if { $p_exists_p && $p ne "" } {
    # new primary sort requested
    # This is a similar reference to $s, but only one integer.
    # Since this is the first time used as a primary, additional validation and processing is required.
    # validate user input, fail silently
    regsub -all -- {[^\-0-9]+} $p {} primary_sort_col_new
    # primary_sort_col_pos = primary sort column's position
    # primary_sort_col_new = a negative or positive column position. 
    set primary_sort_col_pos [expr { abs( $primary_sort_col_new ) } ]
    # ns_log Notice "resource-status-summary-1.tcl(85): primary_sort_col_new $primary_sort_col_new"
    if { $primary_sort_col_new ne "" && $primary_sort_col_pos < $table_cols_count } {
        # ns_log Notice "resource-status-summary-1.tcl(87): primary_sort_col_new $primary_sort_col_new primary_sort_col_pos $primary_sort_col_pos"
        # modify sort_order_list
        set sort_order_new_list [list $primary_sort_col_new]
        foreach ii $sort_order_list {
            if { [expr { abs($ii) } ] ne $primary_sort_col_pos } {
                lappend sort_order_new_list $ii
                # ns_log Notice "resource-status-summary-1.tcl(93): ii '$ii' sort_order_new_list '$sort_order_new_list'"
            }
        }
        set sort_order_list $sort_order_new_list
        # ns_log Notice "resource-status-summary-1.tcl(97): end if primary_sort_col_new.. "
    }
}

if { ( $s_exists_p && $s ne "" ) || ( $p_exists_p && $p ne "" ) } {
    # ns_log Notice "resource-status-summary-1.tcl(101): sort_order_scalar '$sort_order_scalar' sort_order_list '$sort_order_list'"
    # Create a reverse index list for index countdown, because primary sort is last, secondary sort is second to last..
    # sort_stack_list 0 1 2 3..
    set sort_rev_order_list [lsort -integer -decreasing [lrange $sort_stack_list 0 [expr { [llength $sort_order_list] - 1 } ] ] ]
    # sort_rev_order_list ..3 2 1 0
    #ns_log Notice "resource-status-summary-1.tcl(104): sort_rev_order_list '$sort_rev_order_list' "
    foreach ii $sort_rev_order_list {
        set col2sort [lindex $sort_order_list $ii]
        # ns_log Notice "resource-status-summary-1.tcl(107): ii $ii col2sort '$col2sort' llength col2sort [llength $col2sort] sort_rev_order_list '$sort_rev_order_list' sort_order_list '$sort_order_list'"
        if { [string range $col2sort 0 0] eq "-" } {
            set col2sort_wo_sign [string range $col2sort 1 end]
            set sort_order "-decreasing"
        } else { 
            set col2sort_wo_sign $col2sort
            set sort_order "-increasing"
        }
        set sort_type [lindex $sort_type_list $col2sort_wo_sign]
        # Following lsort is in a catch statement so that if the sort errors, it defaults to ascii sort.
        # Sort table_lists by column number $col2sort_wo_sign, where 0 is left most column
        
        if {[catch { set table_sorted_lists [lsort $sort_type $sort_order -index $col2sort_wo_sign $table_sorted_lists] } result]} {
            # lsort errored, probably due to bad sort_type. Fall back to -ascii sort_type, or fail..
            set table_sorted_lists [lsort -ascii $sort_order -index $col2sort_wo_sign $table_sorted_lists]
            ns_log Notice "resource-status-summary-1(121): lsort fell back to sort_type -ascii due to error: $result"
        }
        #ns_log Notice "resource-status-summary-1.tcl(123): lsort $sort_type $sort_order -index $col2sort_wo_sign table_sorted_lists"
    }
}

# ================================================
# 3. Pagination_bar -- calcs including list_limit and list_offset, build UI
# ================================================
# if $s exists, addid to to pagination urls.

# Add the sort links to the titles.

# urlcode sort_order_list
set s_urlcoded ""
foreach sort_i $sort_order_list {
    append s_urlcoded $sort_i
    append s_urlcoded a
}
set s_urlcoded [string range $s_urlcoded 0 end-1]
set s_url_add "&s=${s_urlcoded}"

# Sanity check 
if { $this_start_row > $item_count } {
    set this_start_row $item_count
}

set bar_list_set [hf_pagination_by_items $item_count $items_per_page $this_start_row]
set prev_bar [list]
set next_bar [list]

set prev_bar_list [lindex $bar_list_set 0]
foreach {page_num start_row} $prev_bar_list {
    if { $s eq "" } {
        set page_ref $page_num
    } else {
        set item_index [expr { ( $start_row - 1 ) } ]
        set primary_sort_field_val [lindex [lindex $table_sorted_lists $item_index] $col2sort_wo_sign]
        set page_ref [qf_abbreviate $primary_sort_field_val 4]
    }
    lappend prev_bar " <a href=\"${base_url}?this_start_row=${start_row}${s_url_add}\">${page_ref}</a> "    
} 
set prev_bar [join $prev_bar $separator]

set current_bar_list [lindex $bar_list_set 1]
set page_num [lindex $current_bar_list 0]
set start_row [lindex $current_bar_list 1]
if { $s eq "" } {
    set page_ref $page_num
} else {
    set item_index [expr { ( $start_row - 1 ) } ]
    set primary_sort_field_val [lindex [lindex $table_sorted_lists $item_index] $col2sort_wo_sign]
    set page_ref [qf_abbreviate $primary_sort_field_val 4]
}

#set current_bar "[lindex $current_bar_list 0]"
set current_bar $page_ref

set next_bar_list [lindex $bar_list_set 2]
foreach {page_num start_row} $next_bar_list {
    if { $s eq "" } {
        set page_ref $page_num
    } else {
        set item_index [expr { ( $page_num - 1 ) * $items_per_page + 1 } ]
        set primary_sort_field_val [lindex [lindex $table_sorted_lists $item_index] $col2sort_wo_sign]
        set page_ref [qf_abbreviate $primary_sort_field_val 4]
    }
    lappend next_bar " <a href=\"${base_url}?this_start_row=${start_row}${s_url_add}\">${page_ref}</a> "
}
set next_bar [join $next_bar $separator]


# add start_row to sort_urls.
if { $this_start_row_exists_p } {
    set page_url_add "&this_start_row=${this_start_row}"
} else {
    set page_url_add ""
}

# ================================================
# 4. Sort UI -- build
# ================================================


# Sort's abbreviated title should be context sensitive, changing depending on sort type.
# sort_type_list is indexed by sort_column nbr (0...)

set text_asc "A"
set text_desc "Z"
set nbr_asc "1"
set nbr_desc "9"
set title_asc "increasing"
set title_desc "decreasing"

set table_titles_w_links_list [list ]
set column_count 0
set primary_sort_col [lindex $sort_order_list $column_count]

foreach title $table_titles_list {
    # figure out column data type for sort button (text or nbr) (column order not changed yet)
    set column_type [string range [lindex $sort_type_list $column_count] 1 end]
    if { $column_type eq "integer" || $column_type eq "real" } {
        set abbrev_asc $nbr_asc
        set abbrev_desc $nbr_desc
    } else {
        set abbrev_asc $text_asc
        set abbrev_desc $text_desc
    }
    # For now, just inactivate the left most sort link that was most recently pressed (if it has been)
    set title_new $title
    if { $primary_sort_col eq "" || ( $primary_sort_col ne "" && $column_count ne [expr { abs($primary_sort_col) } ] ) } {
        # ns_log Notice "resource-status-summary-1.tcl(150): column_count $column_count s_urlcoded '$s_urlcoded'"
        append title_new " (<a href=\"$base_url?s=${s_urlcoded}&p=${column_count}${page_url_add}\" title=\"${title_asc}\">${abbrev_asc}</a>:<a href=\"$base_url?s=${s_urlcoded}&p=-${column_count}${page_url_add}\" title=\"${title_desc}\">${abbrev_desc}</a>)"
    } else {
        if { [string range $s_urlcoded 0 0] eq "-" } {
            # ns_log Notice "resource-status-summary-1.tcl(154): column_count $column_count title $title s_urlcoded '$s_urlcoded'"
            # decreasing primary sort chosen last, no need to make the link active
            append title_new " (<a href=\"$base_url?s=${s_urlcoded}&p=${column_count}${page_url_add}\" title=\"${title_asc}\">${abbrev_asc}</a>:${abbrev_desc})"
        } else {
            # ns_log Notice "resource-status-summary-1.tcl(158): column_count $column_count title $title s_urlcoded '$s_urlcoded'"
            # increasing primary sort chosen last, no need to make the link active
            append title_new " (${abbrev_asc}:<a href=\"$base_url?s=${s_urlcoded}&p=-${column_count}${page_url_add}\" title=\"${title_desc}\">${abbrev_desc}</a>)"
        }
    }
    lappend table_titles_w_links_list $title_new
    incr column_count
}
set table_titles_list $table_titles_w_links_list

# Begin building the paginated table here. Table rows have been sorted.
# Add Row of Titles to Table
#set table_sorted_lists [linsert $table_sorted_lists 0 [lrange $table_titles_list 0 $table_index_last]]
set table_paged_sorted_lists [list ]
lappend table_paged_sorted_lists [lrange $table_titles_list 0 $table_index_last]
set lindex_start [expr { $this_start_row - 1 } ]
set lindex_last [expr { $item_count - 1 } ]
set last_row [expr { $lindex_start + $items_per_page - 1 } ]
if { $lindex_last < $last_row } {
    set last_row $lindex_last
}
for { set row_num $lindex_start } { $row_num <= $last_row } {incr row_num} {
    lappend table_paged_sorted_lists [lindex $table_sorted_lists $row_num]
}
set table_sorted_lists $table_paged_sorted_lists
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
        ns_log Notice "resource-status-summary-1.tcl(203): Warning: table_row_new has ${table_row_new_cols} instead of ${table_cols_count} columns."
    }
    # Append new row to new table
    lappend table_col_sorted_lists $table_row_new
}

# ================================================
# Add UI Options column to table?
# Not at this time. Keep here in case a variant needs the code at some point.
if { 0 } {
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
} else {
    set table2_lists $table_col_sorted_lists
}

# ================================================
# 5. Format output -- compact_p vs. regular etc.
# Add attributes to the TABLE tag
set table2_atts_list [list border 1 cellspacing 0 cellpadding 2]

# Add cell formatting to TD tags
set cell_formating_list [list ]
# Let's try to get fancy, have the rows alternate color after the first row, 
# and have the sorted columns slightly lighter in color to highlight them
# base alternating row colors:
set color_even_row "#ccc"
set color_odd_row "#cfc"
# sorted column colors
set color_even_scol "#ddd"
set color_odd_scol "#dfd"

# Set the default title row and column TD formats before columns sorted:

set title_td_attrs_list [list ]
set column_nbr 0
foreach title $table_titles_list {
    set column_type [string range [lindex $sort_type_list $column_nbr] 1 end]
    # Title row TD formats in title_td_attrs_list
    # even row TD attributes in even_row_list
    # odd row TD attributes in odd_row_list
    if { $column_type eq "integer" ||$column_type eq "real" } {
        lappend title_td_attrs_list [list valign top align right]
        # Value is a number, so right justify
        lappend even_row_list [list valign top align right]
        lappend odd_row_list [list valign top align right]
    } else {
        lappend title_td_attrs_list [list valign top]
        lappend even_row_list [list valign top]
        lappend odd_row_list [list valign top]
    }
    incr column_nbr
}
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
append page_html $table2_html


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
# ignore columns option for now
if { 0 } {
    if { [info exists columns] && $columns > 1 } {
        set before_columns_html  {<div class="l-grid-half m-grid-whole s-grid-whole padded">
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
        
        for {set i 0} {$i < $columns} {incr i} {
            if { [info exists before_columns_html] } {
                append page_html $before_columns_html
            }
            set new_report_lists [list ]
            lappend new_report_lists $asset_table_titles
            set column_lists [lrange $asset_report_lists [expr { $i * $items_per_list } ] [expr { $i * $items_per_list + $items_per_list_m_1 } ] ]
            foreach row_list $column_lists {
                lappend new_report_lists $row_list
            }
            # between_columns_html  if exists, inserts html that goes between each column
            append page_html [qss_list_of_lists_to_html_table $new_report_lists $table_att_list $td_att_list]
            if { [info exists after_columns_html] } {
                append page_html $after_columns_html
            }
        }
        
    }
} else {


if { [info exists compact_p] && $compact_p } {
        
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
#        set page_html [qss_list_of_lists_to_html_table $asset_report_new_lists $table_att_list $td_att_compact_list]
        set page_html "<table>"
        foreach item $asset_report_new_lists {
            append page_html "<tr>"
            append page_html "<td>[lindex $item 0]</td>"
            append page_html "<td>[lindex $item 1]</td>"
            append page_html "<td>[lindex $item 2]</td>"
            append page_html "<td>[lindex $item 3]</td>"
            append page_html "</tr>"
        }
        append page_html "</table>"
    } else {
        set asset_report_lists [linsert $asset_report_lists 0 $asset_table_titles]
#        set page_html [qss_list_of_lists_to_html_table $asset_report_lists $table_att_list $td_att_list]
    }


}

