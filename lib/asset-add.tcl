# hosting-farm/lib/asset-add.tcl
ns_log Notice "hosting-farm/lib/asset-add.tcl start"
# requires:
#   asset_arr array of asset/attribute key values
#   asset_type
#   asset_id (or mapped_asset_id if attr_only)


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
    ns_log Warning "hosting-farm/lib/asset-add.tcl.55: asset_type not defined"
    # lets guess it instead of fail
    set asset_type [hf_constructor_a asset_arr]
}

if { ![array exists asset_arr] } {
    ns_log Error "hosting-farm/lib/asset-add.tcl.28: asset_arr not defined"
}

# Make sure any asset_arr(asset_type) does not overwrite asset_type
array unset asset_arr asset_type

template::util::array_to_vars asset_arr

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
if { ![info exists base_url] } {
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
    ns_log Warning "hosting-farm/lib/asset-add.tcl: theme '${theme}'."
    set theme_label ""
    set theme_title ""
    set theme_description ""
}


# output

set cancel_link_html "<a href=\"${base_url}\">#acs-kernel.common_Cancel#</a>"
#set conn_package_url \[ad_conn package_url\]
#set base_url \[file join $conn_package_url $url\]



qf_form action $base_url method post id 20160811 hash_check 1
qf_bypass_nv_list [list mode c mode_next v asset_type $asset_type]

set key_list [list ]
set asset_key_list [list ]
if { [string match "*asset*" $asset_type ] } {
    set key_list [hf_key_sort_for_display [hf_asset_keys]]
    set asset_key_list $key_list
    
}
set attr_key_list [list ]
if { [string match "*attr*" $asset_type ] } {
    if { $sub_type_id in [hf_asset_type_id_list] } {
        set attr_key_list [concat [hf_${sub_type_id}_keys] [hf_sub_asset_map_keys] ]
        # remove duplicates
        set attr_key_list [lsort -unique $attr_key_list]
        set attr_key_list [hf_key_sort_for_display $attr_key_list]
        set key_list [concat $key_list $attr_key_list ]
    } else {
        ns_log Warning "hosting-farm/lib/asset-add.tcl.164: asset_type '${asset_type}' sub_type_id '${sub_type_id}' not valid"
    }
}

set edit_asset_p 0
if { $asset_type eq "asset_primary_attr" || $asset_type eq "asset_only" } {
    set edit_asset_p 1
}

set edit_attr_p 0
if { [string match "*attr*" $asset_type] } {
    set edit_attr_p 1
}

foreach key $key_list {
    set val $asset_arr(${key})
    if { ( $edit_asset_p && $key in $asset_key_list ) || ( $edit_attr_p && $key in $attr_key_list ) } {
        set edit_key_p 1
    } else {
        set edit_key_p 0
    }
    if { ![hf_key_hidden_q $key] && [privilege_on_key_allowed_q write $key] && $edit_key_p } {
        qf_append html "<br>"
        if { $key eq "details" || $key eq "description" } {
            qf_textarea value $val name $key label "#hosting-farm.${key}#${separator}" cols 40 rows 3
        } elseif { [string match "*_p" $key] } {
            if { [qf_is_true $val] } {
                set 1_selected_p 1
                set 0_selected_p 0
            } else {
                set 1_selected_p 0
                set 0_selected_p 1
            }
            if { $key ne "trashed_p" } {
                qf_append html "#hosting-farm.${key}#${separator}"
                set choices_list [list \
                                      [list label "#acs-kernel.common_yes#" value 1 selected $1_selected_p ] \
                                      [list label "#acs-kernel.common_no#" value 0 selected $0_selected_p ] ]
                qf_choice type radio name $key value $choices_list
            } else {

                qf_append html "<span>#hosting-farm.${key}#${separator}${val}</span>"
                qf_input type hidden name $key value $val
            }
        } else {
            qf_input type text value $val name $key label "#hosting-farm.${key}#${separator}" size 40 maxlength 80
        }
    } elseif { $detail_p || $tech_p } {
        qf_append html "<br>"
        qf_append html "<span>#hosting-farm.${key}#${separator}${val}</span>"
        qf_input type hidden name $key value $val
    } else {
        qf_input type hidden name $key value $val
    }
}


qf_input type submit value "#acs-kernel.common_Save#"
qf_append html " &nbsp; &nbsp; &nbsp; ${cancel_link_html}"
qf_close
append content [qf_read]


