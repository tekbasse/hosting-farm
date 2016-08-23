# hosting-farm/lib/asset-add.tcl
# show an hf asset record
# for editing, see asset-input.tcl

# requires:
# @param array with elements of hf_asset_keys
# optional:
#  detail_p      If detail_p is 1, flags to show record detail
#  tech_p        If is 1, flags to show technical info (for admins)
# asset_type     as determined by hf_constructor_a
# separator      Used to separate key from value in list.

# if admin assets, show edit asset button and  show all detail
# if write published  show button to change state of publish_p
# if write assets, show:, button to change state of monitor_p, trashed_p


# provides variables of each element:
# from hf_asset_keys:
#  asset_id
#  label
#  name
#  asset_type_id
#  trashed_p
#  trashed_by
#  template_p
#  templated_p
#  publish_p
#  monitor_p
#  popularity
#  triage_priority
#  op_status
#  qal_product_id
#  qal_customer_id
#  instance_id
#  user_id
#  last_modified
#  created
#  flags
#  template_id
#  f_id


#   and related:
#    asset_label asset_title asset_description

# to pass array via include, see: /doc/acs-templating/tagref/include
# ie: &asset_arr="calling_page_arr_name"
#

if { ![info exists detail_p] } {
    set detail_p 0
}
if { ![exists_and_not_null asset_type ] } {
    ns_log Warning "hosting-farm/lib/asset-add.tcl.55: asset_type not defined"
    set asset_type [hf_constructor_a $asset_arr]
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
ns_log Notice "hosting-farm/lib/asset-add.tcl.97: asset_type '${asset_type}'"
if { [array exists asset_arr] } {
    template::util::array_to_vars asset_arr
}

if { [exists_and_not_null asset_type_id] } {
    # get asset_type_id info
    #    asset_label asset_title asset_description
    set asset_type_list [lindex [hf_asset_type_read $asset_type_id $instance_id] 0]
    if { [llength $asset_type_list ] > 0 } {
        qf_lists_to_vars $asset_type_list [hf_asset_type_keys]
    } else {
        set asset_label ""
        set asset_title ""
        set asset_description ""
    }
} else {
    ns_log Warning "hosting-farm/lib/asset-add.tcl: asset_type_id is null or does not exist."
    set asset_type_id ""
}


# output
foreach key [array names asset_arr] {
    set asset_arr(${key}) [qf_unquote $asset_arr(${key}) ]
}

set cancel_link_html "<a href=\"${base_url}\">#acs-kernel.common_Cancel#</a>"

#set conn_package_url \[ad_conn package_url\]
#set base_url \[file join $conn_package_url $url\]



qf_form action $base_url method post id 20160819 hash_check 1
qf_input type hidden value a name mode
qf_input type hidden value v name mode_next
qf_input type hidden value $asset_type name asset_type

#qf_append html "<div style=\"width: 70%; text-align: right;\">"

if { [string match "*asset*" $asset_type ] } {
    foreach key [hf_key_order_for_display [array names asset_arr]] {
        set val $asset_arr(${key})
        # was  ( $detail_p || $tech_p ) || !\[hf_key_hidden_q $key\] && \[privilege_on_key_allowed_q write $key\]
        if { ![hf_key_hidden_q $key] && [privilege_on_key_allowed_q write $key] } {
            qf_append html "<br>"
            set val_unquoted [qf_unquote $val]
            if { [string match "*_p" $key] } {
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
                }
            } else {
                qf_input type text value $val_unquoted name $key label "#hosting-farm.${key}#${separator}" size 40 maxlength 80
            }
        } elseif { $detail_p || $tech_p } {
            qf_append html "<br>"
            qf_append html "<span>#hosting-farm.${key}#${separator}${val}</span>"
            qf_input type hidden value $val name $key
        } else {
            qf_input type hidden value $val name $key
        }
    }
}
#qf_append html "</div>"
qf_append html "<br>"
qf_input type submit value "#acs-kernel.common_Save#"
qf_append html " &nbsp; &nbsp; &nbsp; ${cancel_link_html}"
qf_close
append content [qf_read]


if { [string match "*attr*" $asset_type ] } {
    if { [exists_and_not_null sub_type_id] } {
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
        ns_log Warning "hosting-farm/lib/asset-add.tcl: sub_type_id is null or does not exist."
        set sub_type_id ""
    }
}

