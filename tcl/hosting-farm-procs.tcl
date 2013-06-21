ad_library {

    misc API for hosting-farm
    @creation-date 5 June 2013
}

ad_proc -public hf_asset_ids_for_user { 
    user_id
    {instance_id ""}
} {
    Returns asset_ids for user_id
} {

}
# hf_asset_ids_for_customer_id instance_id customer_id

# hf_asset_create_from_asset_template instance_id asset_id args
# hf_asset_create_from_asset_label instance_id asset_label args

# hf_asset_templates_active instance_id label_match
# hf_asset_templates_all instance_id 
