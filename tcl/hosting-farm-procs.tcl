ad_library {

    misc API for hosting-farm
    @creation-date 5 June 2013
}

# following defined in permissions-procs.tcl
# hf_customer_ids_for_user
# hf_active_asset_ids_for_customer 

ad_proc -private hf_asset_ids_for_user { 
    {instance_id ""}
    {user_id ""}
} {
    Returns asset_ids available to user_id as list of lists (each list represents ids by  one customer)
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    set customer_ids_list [hf_customer_ids_for_user $user_id]
    # get asset_ids assigned to customer_ids
    set asset_ids_list [list ]
    foreach customer_id $customer_ids_list {
        set assets_list [hf_asset_ids_for_customer_id $instance_id $customer_id]
        if { [llength $assets_list > 0 ] } {
            lappend asset_ids_list $assets_list
        }
    }
    return $asset_ids_list
}

ad_proc -private hf_asset_ids_for_customer_id {
    {instance_id ""}
    customer_id
} {
    Returns asset_ids for customer_id as a list
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    ## make sure that user_id has permission to access customer_id info
    # check permissions
    set user_id [ad_conn user_id]
    set read_p [hf_permission_p $instance_id $user_id $customer_id "customer_id-${customer_id}" read]



}


# hf_asset_create_from_asset_template instance_id asset_id args
# hf_asset_create_from_asset_label instance_id asset_label args

# hf_asset_templates_active instance_id label_match
# hf_asset_templates_all instance_id 
