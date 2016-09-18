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
if { [exists_and_not_null perms_arr(create_p)] } {
    set create_p $perms_arr(create_p)
} else {
    set create_p 0
}
if { [exists_and_not_null perms_arr(read_p)] } {
    set read_p $perms_arr(read_p)
} else {
    set read_p 0
}
if { [exists_and_not_null perms_arr(write_p)] } {
    set write_p $perms_arr(write_p)
} else {
    set write_p 0
}
if { [exists_and_not_null perms_arr(admin_p)] } {
    set admin_p $perms_arr(admin_p)
} else {
    set admin_p 0
}
if { [exists_and_not_null perms_arr(pkg_admin_p)] } {
    set pkg_admin_p $perms_arr(pkg_admin_p)
} else {
    set pkg_admin_p 0
}
if { [exists_and_not_null perms_arr(publish_p) ] } {
    set pub_p [qf_is_true $perms_arr(publish_p) ]
} else {
    set pub_p 0
}
if { ![info exists separator] } {
    set separator ":&nbsp;"
}

set attrs_lists [db_list_of_lists hf_attributes_set "select [hf_sub_asset_map_keys ","] from hf_sub_asset_map where instance_id=:instance_id and attribute_p!='0' and sub_f_id in ([template::util::tcl_to_sql_list $attrs_list])"]

if { [llength $attrs_lists ] > 0 } {
    set attrs_sorted_lists [lsort -integer -index 5 -increasing $attrs_lists]
    set attrs_sorted2_lists [lsort -ascii -index 4 -increasing $attrs_sorted_lists]
    set content ""
    
    set form_id [qf_form action $base_url method post id 20160916 hash_check 1]
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
            set button_label "${sub_label} (${sub_type_id})"
            qf_input type submit value $button_label name "Zvl${sub_f_id}" class button
            qf_append html "<br>"
        }
    }

    # Anything else?
    if { $admin_p } {
        set asset_types_lists [hf_asset_types]
        if { $pkg_admin_p } {
            set at_limited_lists $asset_types_lists
        } else {
            set id_list [hfl_attributes_allowed_by_user]
            # at is abbrev for asset_type
            set at_limited_lists [list ]
            foreach at_list $asset_types_lists {
                if { [lindex $at_list 0] in $id_list } {
                    lappend at_limited_lists $at_list
                }
            }
        }
        if { [llength $at_limited_lists] > 0 } {
            set at_sorted_lists [lsort -index 2 -dictionary $at_limited_lists]
            qf_append html "<br><br>#hosting-farm.Attribute# #acs-subsite.create#${separator}"
            qf_input type "hidden" name "asset_type" value "attr_only"
            set choices_list [list ]
            set selected 1
            foreach at_list $at_sorted_lists {
                set at_id [lindex $at_list 0]
                set at_title [lindex $at_list 2]
                set row_list [list label]
                lappend row_list " ${at_title} " value $at_id selected $selected
                lappend choices_list $row_list
                set selected 0
            }
            qf_choice type radio name sub_type_id value $choices_list
            qf_input type submit value "#acs-subsite.create#" name "Zal${asset_id}" class button
        }
    }

    qf_close form_id $form_id
    append content [qf_read form_id $form_id]
} else {
    append content "#acs-subsite.none#"
}
