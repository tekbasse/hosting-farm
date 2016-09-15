# hosting-farm/lib/asset-view.tcl

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
    ns_log Warning "hosting-farm/lib/asset-edit.tcl.55: asset_type not defined"
    # lets guess it instead of fail
    set asset_type [hf_constructor_a asset_arr]
}

# Make sure any asset_arr(asset_type) does not overwrite asset_type
array unset asset_arr asset_type

template::util::array_to_vars asset_arr

if { ![exists_and_not_null sub_type_id] } {
    set sub_type_id ""
}
if { ![exists_and_not_null asset_type_id] } {
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
if { ![exists_and_not_null base_url] } {
    set base_url [ad_conn url]
}

if { ![info exists tech_p] } {
    set tech_p 0
    set user_id [ad_conn user_id]
    set instance_id [ad_conn package_id]
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
    ns_log Warning "hosting-farm/lib/asset-edit.tcl: theme '${theme}'."
    set theme_label ""
    set theme_title ""
    set theme_description ""
}


# output
set content_list [list ]
if { [string match "*asset*" $asset_type] } {
    foreach key [hf_key_order_for_display [hf_asset_keys]] {
        if { ( $detail_p || $tech_p ) || ![hf_key_hidden_q $key] } {
            set element ""
            append element "#hosting-farm.${key}#" $separator $asset_arr(${key})
            lappend content_list $element
        } 
    }
}


if { [string match "*attr*" $asset_type] } {
    if { $sub_type_id in [hf_asset_type_id_list] } {
        if { $sub_type_id ne "" } {
            set keys_list [concat [hf_${sub_type_id}_keys] [hf_sub_asset_map_keys]]
            foreach key [hf_key_order_for_display $keys_list] {
                if { ( $tech_p ) || ![hf_key_hidden_q $key] } {
                    set element ""
                    append element "#hosting-farm.${key}#" $separator $asset_arr(${key})
                    lappend content_list $element
                } 
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

if { $asset_type eq "attr_only" } {
    set mapped_f_id $f_id
    set mapped_asset_id $asset_id
    set ref_id $sub_f_id
    set z "Z"
} else {
    set z "z"
    set ref_id $asset_id
    set mapped_asset_id ""
    set mapped_f_id ""
}
set form_id [qf_form action $base_url method post id 20160809 hash_check 1]
qf_bypass name mode value "p"
qf_bypass name asset_type value $asset_type
qf_bypass name mapped_asset_id value $mapped_asset_id
qf_bypass name mapped_f_id value $mapped_f_id
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
qf_close form_id $form_id
append content [qf_read form_id $form_id]
