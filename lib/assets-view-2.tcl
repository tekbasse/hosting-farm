# hosting-farm/lib/assets-view-2.tcl
# show a list of hf assets as form submit buttons.
#
# requires:
# assets_lists  As if from a db_lists_of_lists query hf_assets
#               where elements are returned in order of hf_asset_keys
# 


# to pass array (or lists) via include: /doc/acs-templating/tagref/include
# ie: &local_arr_name=calling_page_arr_name
# or: &local_lists_name=calling_page_lists_name
#


# all_types combined in the element "all"


# This allows sql in calling page to easily scope and limit list
# using pagination-bar

# @see hosting-farm/lib/pagination-bar.tcl for lists pagination menu
# @param base_url is url for page (required)
# @param item_count (required)
# @param items_per_page (required)
# @param this_start_row (required) the start row for this page
# @param separator is html used between page numbers, defaults to &nbsp;



# assets_lists \[hf_asset_ids_for_user $user_id\]
# output is page_html 
# nav_bar:  prev_bar current_bar next_bar

# following from:
# hosting-farm/lib/assets-view-2.tcl
# Returns summary list of assets with status, highest scores first
# This version requires the entire table to be loaded for processing.
# TODO: make another version that uses pg's select limit and offset.. to scale well.

# REQUIRED:
# @param this_start_row      start row (item number) for this page


# OPTIONAL:
# @param items_per_page      number of items per page
# @param base_url             url for building page links
# @param separator            html used between page numbers, defaults to &nbsp;
# @param list_limit           limits the list to that many items.
# @param list_offset          offset the list to start at some point other than the first item.
# @param columns              splits the list into $columns number of columns.
# @param before_columns_html  inserts html that goes between each column
# @param after_columns_html   ditto
# @param show_page_num_p           Answers Q: Use the page number in pagniation bar?
#                             If not, uses the first value of the left-most (primary sort) column
# @param show_titles_p        (defaults to 1)


# General process flow:
# 1. Get table as list_of_lists
# 2. Sort unformatted columns by row values
# 3. Pagination_bar -- calcs including list_limit and list_offset, build UI
# 4. Sort UI -- build
#     columns, column_order, and cell data vary between compact_p vs. default, keep in mind with sort UI
# 5. Format output -- compact_p vs. regular

set page_html ""


# ================================================
# 1. Get table as list_of_lists
# ================================================
# don't process list_offset or list_limit here.
#set asset_stts_smmry_lists $assets_lists
set asset_stts_smmry_lists [list ]
foreach row_list $assets_lists {
    set row_new_list [list ]
    lappend row_new_list [lindex $row_list 1]
    lappend row_new_list [lindex $row_list 0]
    lappend asset_stts_smmry_lists $row_new_list
}
set col2sort_wo_sign 0
set table_sorted_lists [lsort -dictionary -index $col2sort_wo_sign -increasing $asset_stts_smmry_lists]

set item_count [llength $asset_stts_smmry_lists]
if { $item_count > 0 } {


    if { ![info exists base_url] } {
        set base_url [ad_conn url]
    }
    #if { !\[info exists base_url\] } {
    #    set base_url \[ns_conn url\]
    #}
    #if { !\[info exists base_url\] } {
    #    set base_url \[ad_conn path_url\]
    #}
    if { ![info exists show_page_num_p ] } {
        set show_page_num_p 0
    }
    if { ![info exists show_titles_p ] } {
        set show_titles_p 1
    }

    set this_start_row_exists_p [info exists this_start_row]
    if { !$this_start_row_exists_p || ( $this_start_row_exists_p && ![qf_is_natural_number $this_start_row] ) } {
        set this_start_row 1
    }
    if { ![info exists separator] } {
        set separator "&nbsp;"
    }


    # ================================================
    # Pagination_bar -- calcs including list_limit and list_offset, build UI
    # ================================================
    # if $s exists, add it to to pagination urls.
    ns_log Notice "assets-view.tcl.210"
    # setup

    if { ![info exists items_per_page] } {
        set items_per_page 12
    }
    set prev_bar ""
    set next_bar ""
    set current_bar ""

    # Calc a pagination bar?
    if { $item_count > $items_per_page } {
        
        # Sanity check 
        if { $this_start_row > $item_count } {
            set this_start_row $item_count
        }
        if { $this_start_row < 1 } {
            set this_start_row 1
        }
        set form_id [qf_form action $base_url method post id 20160802 hash_check 1]
        qf_input type hidden name mode value p

        set bar_list_set [hf_pagination_by_items $item_count $items_per_page $this_start_row]
        set prev_bar_list [list]
        set next_bar_list [list]
        
        set prev_bar_pg_sr_list [lindex $bar_list_set 0]
        foreach {page_num start_row} $prev_bar_pg_sr_list {
            if { $show_page_num_p } {
                set page_ref $page_num
            } else {
                set item_index [expr { ( $start_row - 1 ) } ]
                set primary_sort_field_val [lindex [lindex $table_sorted_lists $item_index] $col2sort_wo_sign]
                set page_ref [qf_abbreviate [lang::util::localize $primary_sort_field_val] 5]
                if { $page_ref eq "" } {
                    set page_ref "#hosting-farm.page_number# ${page_num}"
                }
            }
            #lappend prev_bar_list " <a href=\"${base_url}?this_start_row=${start_row}${s_url_add}\">${page_ref}</a> "
            # from accounts-finance: input type="submit" value="Sort by Y ascending" name="zy" class="btn"
            qf_input type submit value $page_ref name="zsr${start_row}" class btn
        } 
        #set prev_bar \[join $prev_bar_list $separator\]
        
        set current_bar_list [lindex $bar_list_set 1]
        set page_num [lindex $current_bar_list 0]
        set start_row [lindex $current_bar_list 1]
        if { $show_page_num_p } {
            set page_ref $page_num
        } else {
            set item_index [expr { ( $start_row - 1 ) } ]
            set primary_sort_field_val [lindex [lindex $table_sorted_lists $item_index] $col2sort_wo_sign]
            set page_ref [qf_abbreviate [lang::util::localize $primary_sort_field_val] 5]
            if { $page_ref eq "" } {
                set page_ref "#hosting-farm.page_number# ${page_num}"
            }
        }
        
        #set current_bar "[lindex $current_bar_list 0]"
        set current_bar $page_ref
        

        # ================================================
        # Paginated table here
        # ================================================
        # not implemented in this version. code removed.

        # Begin building the paginated table here. Table rows have been sorted.
        ns_log Notice "assets-view.tcl.424"
        set table_paged_sorted_lists [list ]
        set lindex_start [expr { $this_start_row - 1 } ]
        set lindex_last [expr { $item_count - 1 } ]
        set last_row [expr { $lindex_start + $items_per_page - 1 } ]
        if { $lindex_last < $last_row } {
            set last_row $lindex_last
        }
        for { set row_num $lindex_start } { $row_num <= $last_row } {incr row_num} {
            set row_list [lindex $table_sorted_lists $row_num]
            lappend table_paged_sorted_lists $row_list
            set asset_name [lindex $row_list 0]
            set asset_id [lindex $row_list 1]
            qf_input type submit value $asset_name name "zaid${asset_id}" class btn
        }
        # Result: table_page_sorted_lists



        # ========
        # next bar
        set next_bar_pg_sr_list [lindex $bar_list_set 2]
        foreach {page_num start_row} $next_bar_pg_sr_list {
            if { $show_page_num_p } {
                set page_ref $page_num
            } else {
                #        set item_index \[expr { ( $page_num - 1 ) * $items_per_page + 1 } \]
                set item_index [expr { ( $page_num - 1 ) * $items_per_page  } ]
                set primary_sort_field_val [lindex [lindex $table_sorted_lists $item_index] $col2sort_wo_sign]
                set page_ref [qf_abbreviate [lang::util::localize $primary_sort_field_val] 5]
                if { $page_ref eq "" } {
                    set page_ref "#hosting-farm.page_number# ${page_num}"
                }
            }
            #lappend next_bar_list " <a href=\"${base_url}?this_start_row=${start_row}${s_url_add}\">${page_ref}</a> "
            qf_input type submit value $page_ref name="zsr${start_row}" class btn
        }
        #set next_bar \[join $next_bar_list $separator\]
    }

    # add start_row to sort_urls.
    if { $this_start_row_exists_p } {
        set page_url_add "&amp;this_start_row=${this_start_row}"
    } else {
        set page_url_add ""
    }


    qf_close fom_id $form_id
    append page_html [qf_read form_id $form_id]
} else {
    append page_html "#acs-subsite.none#"
}


