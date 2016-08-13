# hosting-farm/lib/attrs.tcl
# show a list of hf asset attributes
#

# to pass array via include, see: /doc/acs-templating/tagref/include
# ie: &local_arr_name="calling_page_arr_name"
# or: &local_lists_name=calling_page_lists_nam

##
# Array expects
# up to one key per asset_type_id
# each key's value consists of a list of lists.
# Each primary list element represents a row of values
# consistent with the order provided by
# the proc hf_{asset_type_id}_keys for the asset_type_id

# This allows sql in calling page to easily scope and limit list
# using pagination-bar

# @see hosting-farm/lib/pagination-bar.tcl for lists pagination menu
# @param base_url is url for page (required)
# @param item_count (required)
# @param items_per_page (required)
# @param this_start_row (required) the start row for this page
# @param separator is html used between page numbers, defaults to &nbsp;
if { ![info exists instance_id] } {
    set instance_id [ad_conn package_id]
}

set attrs_lists [db_list_of_lists hf_attributes_set "select [hf_sub_asset_map_keys ","] from hf_sub_asset_map where instance_id=:instance_id and attribute_p!='0' and sub_f_id in ([template::util::tcl_to_sql_list $attrs_list])"]

if { [llength $attrs_lists ] > 0 } {
    set attrs_sorted_lists [lsort -integer 5 -increasing $attrs_lists]
    set attrs_sorted2_lists [lsort -ascii 4 -increasing $attrs_sorted_lists]
    set content ""
    
    set form_id [qf_form action $base_url method post id 20160802 hash_check 1]
    qf_input type "hidden" name "mode" value "p"
    
    set i 0
    set sam_keys [hf_sub_asset_map_keys]
    set found_primary_attr_p 0
    foreach attr_list $attrs_sorted2_lists {
        qf_lists_to_vars $attr_list $sam_keys
        if { !$found_primary_attr_p && $sub_type_id eq $type_id } {
            set found_primary_attr_p 1
            # ignore this attribute
        } else {
            incr i
            if { $sub_label eq "" } {
                set sub_label $i
            }
            qf_input type submit value $sub_label name "Zvl${sub_f_id}" class button
            qf_append html "<br>"
        }
    }
    qf_close form_id $form_id
    append content [qf_read form_id $form_id]
} else {
    append content "#acs-subsite.none#"
}
