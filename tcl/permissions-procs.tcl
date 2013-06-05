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

ad_proc -public hf_active_contract_ids_for_user {
    user_id
    {instance_id ""}
} {
    Returns a list of active contract_ids for user_id
} {

}

