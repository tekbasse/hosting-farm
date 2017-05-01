# hosting-farm/lib/asset-view.tcl
 ns_log Notice "hosting-farm/lib/asset-view.tcl start"
# requires:
#   asset_arr array of asset/attribute key values
#   asset_type
#   asset_id (or mapped_asset_id if attr_only)
#   sub_f_id (if asset_type includes attribute)

# optional:
#  detail_p      If detail_p is 1, flags to show record detail
#  tech_p        If is 1, flags to show technical info (for admins)
#  separator     Used to separate key from value in list.
#  base_url      Where to post form to.

# if admin assets, show edit asset button and  show all detail
# if write published  show button to change state of publish_p
# if write assets, show:, button to change state of monitor_p, trashed_p

# 
# to pass array via include, see: /doc/acs-templating/tagref/include
# ie: &asset_arr="calling_page_arr_name"
#


if { ![info exists detail_p] } {
    set detail_p 0
}
if { ![exists_and_not_null asset_type ] } {
    ns_log Warning "hosting-farm/lib/asset-view.tcl.55: asset_type not defined"
    # lets guess it instead of fail
    set asset_type [hf_constructor_a asset_arr]
}

# Make sure any asset_arr(asset_type) does not overwrite asset_type
array unset asset_arr asset_type

template::util::array_to_vars asset_arr

set include_view_attrs_p 0
set include_view_sub_assets_p 0

if { ![info exists f_id] } {
    set f_id ""
}
if { ![info exists sub_f_id] } {
    set sub_f_id ""
}
if { ![info exists sub_type_id] } {
    set sub_type_id ""
}
if { ![info exists asset_type_id] } {
    set asset_type_id $sub_type_id
}

if { ![info exists separator] } {
    set separator ": "
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
    p    set write_p 0
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
if { ![info exists base_url] } {
    set base_url [ad_conn url]
}

if { ![info exists tech_p] } {
    set tech_p 0
    set user_id [ad_conn user_id]
    set instance_id [qc_set_instance_id]
    if { [info exists asset_arr(asset_id) ] } {
        set asset_id $asset_arr(asset_id)
    } else {
        set asset_id ""
    }
    if { ![info exists qal_customer_id] } {
        set qal_customer_id [hf_customer_id_of_asset_id $asset_id]
    }
    if { $qal_customer_id ne "" } {
        set user_roles [hf_roles_of_user $user_id $qal_customer_id]
        set tech_p [string match "*technical_*" $user_roles]
    } 
}


set theme $sub_type_id
set has_icon_p 0
set has_bg_image_p 0
if { $theme eq "" } {
    set theme $asset_type_id
}

if { $theme ne "" } {
    #    asset_label asset_title asset_description
    set asset_type_list [lindex [hf_asset_type_read $asset_type_id $instance_id] 0]
    if { [llength $asset_type_list ] > 0 } {
        qf_lists_to_vars $asset_type_list [hf_asset_type_keys]
    } else {
        set asset_label ""
        set asset_title ""
        set asset_description ""
    }
    set icon_url [file join resources icons $theme]
    set bg_image_url $icon_url
    append icon_url ".png"
    append bg_image_url "-background.png"
    set acs_root [acs_root_dir]
    set has_icon_p [file exists [file join $acs_root packages hosting-farm www $icon_url]]
    set has_bg_image_p [file exists [file join $acs_root packages hosting-farm www $bg_image_url]]

    # get sub_type_id info
    #    asset_label asset_title asset_description
    set theme_type_list [lindex [hf_asset_type_read $theme $instance_id] 0]
    if { [llength $theme_type_list ] > 0 } {
        set theme_label [lindex $theme_type_list 0]
        set theme_title [lindex $theme_type_list 1]
        set theme_description [lindex $theme_type_list 2]
    }
} else {
    ns_log Warning "hosting-farm/lib/asset-view.tcl: theme '${theme}'."
    set theme_label ""
    set theme_title ""
    set theme_description ""
}


# output
set content_list [list ]
if { [string match "*asset*" $asset_type] } {
    foreach key [hf_key_sort_for_display [hf_asset_keys]] {
        if { ( $detail_p || $tech_p ) || ![hf_key_hidden_q $key] } {
            set element ""
            append element "#hosting-farm.${key}#" $separator $asset_arr(${key})
            lappend content_list $element
        } 
    }
}


if { [string match "*attr*" $asset_type] } {
    if { $sub_type_id in [hf_asset_type_id_list] } {
        set keys_list [concat [hf_${sub_type_id}_keys] [hf_sub_asset_map_keys]]
        foreach key [hf_key_sort_for_display $keys_list] {
            if { ( $tech_p ) || ![hf_key_hidden_q $key] } {
                set element ""
                append element "#hosting-farm.${key}#" $separator $asset_arr(${key})
                lappend content_list $element
            } 
        }


        # get sub_type_id info
        #    asset_label asset_title asset_description
        # changed to sub_asset_label sub_asset_title sub_asset_description
        set sub_asset_type_list [lindex [hf_asset_type_read $sub_type_id $instance_id] 0]
        if { [llength $sub_asset_type_list ] > 0 } {
            set sub_asset_label [lindex $sub_asset_type_list 0]
            set sub_asset_title [lindex $sub_asset_type_list 1]
            set sub_asset_description [lindex $sub_asset_type_list 2]
        } else {
            set sub_asset_label ""
            set sub_asset_title ""
            set sub_asset_description ""
        }
    } else {
        ns_log Warning "hosting-farm/lib/asset-view.tcl: sub_type_id '${sub_type_id}' is not valid"
    }
}


foreach element $content_list {
    append content "<li>"
    append content $element
    append content "</li>"
}

set mapped_asset_id $asset_id
set mapped_f_id $f_id
if { $asset_type eq "attr_only" } {
    set ref_id $sub_f_id
    set z "Z"
} else {
    set z "z"
    set ref_id $asset_id
}
set form_id [qf_form action $base_url method post id 20160918 hash_check 1]
qf_input type hidden name mode value "p"
qf_input type hidden name asset_type value $asset_type
qf_input type hidden name mapped_asset_id value $mapped_asset_id
qf_input type hidden name mapped_f_id value $mapped_f_id

qf_input type submit value "#accounts-ledger.edit#" name "${z}ev${sub_f_id}" class button
qf_append html "<br>"
if { $write_p && [exists_and_not_null asset_arr(trashed_p) ] } {
    if { [qf_is_true $asset_arr(trashed_p) ] } {
        qf_input type submit value "#accounts-finance.untrash#" name "${z}Tvo${ref_id}" class button
    } else {
        qf_input type submit value "#accounts-finance.trash#" name "${z}tl${ref_id}" class button
    }
    qf_append html "<br>"
}
#ns_log Notice "asset-view.tcl pub_p '${pub_p}' admin_p '${admin_p}'"
if { ( $pub_p || $admin_p ) && [exists_and_not_null asset_arr(publish_p) ] } {
    if { [qf_is_true $asset_arr(publish_p) ] } {
        qf_input type submit value "#hosting-farm.Unpublish#" name "${z}sv${ref_id}" class button
    } else {
        qf_input type submit value "#hosting-farm.Publish#" name "${z}Sv${ref_id}" class button
    }
    qf_append html "<br>"
}
# anything else?
if { $asset_type eq "attr_only" } {
    set ref_id $sub_f_id
} else {
    set ref_id $f_id
}
if { $ref_id ne "" } {
    set attrs_list [hf_asset_attributes $ref_id]
    if { [llength $attrs_list ] > 0 } {
        #set include_view_attrs_p 1
        set attrs_lists [db_list_of_lists hf_attributes_set "select [hf_sub_asset_map_keys ","] from hf_sub_asset_map where instance_id=:instance_id and attribute_p!='0' and sub_f_id in ([template::util::tcl_to_sql_list $attrs_list])"]

        if { [llength $attrs_lists ] > 0 } {
            set attrs_sorted_lists [lsort -integer -index 5 -increasing $attrs_lists]
            set attrs_sorted2_lists [lsort -ascii -index 4 -increasing $attrs_sorted_lists]
            qf_append html "<div class=\"attributes\"><br><br>"
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
            qf_append html "</div>"
        }
        # Anything else?
        if { $create_p || $admin_p || $pkg_admin_p } {

            # hf_asset_type_id_list
            # hf_types_allowed_by 
            # hfl_assets_allowed_by_user 
            # hfl_attributes_allowed_by_user

            set asset_types_lists [hf_asset_types]
            set pre_id_list [hf_types_allowed_by [qal_first_nonempty_in_list [list $sub_type_id $type_id $asset_type_id]]]
            if { $admin_p || $pkg_admin_p } {
                set id_list $pre_id_list
            } else {
                set id_list [set_intersection [hfl_attributes_allowed_by_user] $pre_id_list]
            }
            # at is abbrev for asset_type
            set at_limited_lists [list ]
            foreach at_list $asset_types_lists {
                if { [lindex $at_list 0] in $id_list } {
                    lappend at_limited_lists $at_list
                }
            }
            if { [llength $at_limited_lists] > 0 } {
                set at_sorted_lists [lsort -index 2 -dictionary $at_limited_lists]
                qf_append html "<br><br>#hosting-farm.Attribute# #acs-subsite.create#${separator}"
                qf_input type "hidden" name "state" value "attr_only"
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

    }
    
    set asset_ids_list [hf_asset_subassets $ref_id]
    if { [llength $asset_ids_list ] > 0 } {
        set assets_lists [hf_assets_read $asset_ids_list]
        #set include_view_sub_assets_p 1
    }
}

qf_close form_id $form_id
append content [qf_read form_id $form_id]
