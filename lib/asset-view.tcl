# hosting-farm/lib/asset-view.tcl
# show an hf asset record
# for editing, see asset-input.tcl

# requires:
# @param array with elements of hf_asset_keys
# optional:
#  detail_p      If detail_p is 1, flags to show record detail
#  tech_p        If is 1, flags to show technical info (for admins)


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

    qf_lists_to_vars $asset_type_list [hf_asset_type_keys]
} else {
    set asset_type_id ""
}


##code hf_key_hidden_q
# hf_peek_pop_stack
