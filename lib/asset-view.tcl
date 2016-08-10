# hosting-farm/lib/asset-view.tcl
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
if { ![info exists asset_type] } {
    set asset_type [hf_constructor_a $asset_arr]
}
if { ![info exists separator] } {
    set separator ": "
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
    ns_log Warning "hosting-farm/lib/asset-view.tcl: asset_type_id is null or does not exist."
    set asset_type_id ""
}


# output
set content_list [list ]
foreach key [hf_asset_keys] {
    if { ( $detail_p || $tech_p ) || ![hf_key_hidden_q $key] } {
        set element ""
        append element $key $separator $asset_arr(${key})
        lappend content_list $element
    } 
}


if { [string match "*attr*" $asset_type] } {
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
        ns_log Warning "hosting-farm/lib/asset-view.tcl: sub_type_id is null or does not exist."
        set sub_type_id ""
    }

    if { $sub_type_id ne "" } {
        foreach key [hf_${sub_type_id}_keys] {
            if { ( $tech_p ) || ![hf_key_hidden_q $key] } {
                set element ""
                append element $key $separator $asset_arr(${key})
                lappend content_list $element
            } 
        }
    }

}


foreach element $content_list {
    append content "<li>"
    append content $element
    append content "</li>"
}

set form_id [qf_form action $base_url method post id 20160809 hash_check 1]
qf_input type "hidden" name "mode" value "p"
qf_input type submit value "#accounts-ledger.edit#" name "zev${asset_id}" class button
qf_append html "<br>"
if { $write_p && [exists_and_not_null asset_arr(trashed_p) ] } {
    if { [qf_is_true $asset_arr(trashed_p) ] } {
        qf_input type submit value "#accounts-finance.untrash#" name "zuv${asset_id}" class button
    } else {
        qf_input type submit value "#accounts-finance.trash#" name "ztl${asset_id}" class button
    }
    qf_append html "<br>"
}
#ns_log Notice "asset-view.tcl pub_p '${pub_p}' admin_p '${admin_p}'"
if { ( $pub_p || $admin_p ) && [exists_and_not_null asset_arr(publish_p) ] } {
    if { [qf_is_true $asset_arr(publish_p) ] } {
        qf_input type submit value "#hosting-farm.Unpublish#" name "zpv${asset_id}" class button
    } else {
        qf_input type submit value "#hosting-farm.Publish#" name "zwv${asset_id}" class button
    }
    qf_append html "<br>"
}
qf_close form_id $form_id
append content [qf_read form_id $form_id]
