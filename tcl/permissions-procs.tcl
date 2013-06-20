ad_library {

    permissions API for hosting-farm
    @creation-date 5 June 2013
}

ad_proc -public hf_customer_ids_for_user { 
    user_id
    {instance_id ""}
} {
    Returns a list of qal_customer_ids for user_id
} {

}


ad_proc -public hf_active_contract_ids_for_customer {
    customer_id
    {instance_id ""}
} {
    Returns a list of active contract_ids for user_id
} {

}

# hf_privilege_create instance_id customer_id user_id role_id
# hf_privilege_delete instance_id customer_id user_id role_id

# hf_role_create instance_id label description
# hf_role_delete instance_id role_id
# hf_role_write instance_id role_id label title description
# hf_role_read instance_id label
