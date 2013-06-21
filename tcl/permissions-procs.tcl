ad_library {

    permissions API for hosting-farm
    @creation-date 5 June 2013

    use hf_permission_p to check for permissions in place of permission::permission_p
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

}

ad_proc -private  hf_privilege_create {
    instance_id
    customer_id
    user_id
    role_id
} {
    Create a priviledge for passed condition. Returns 1 if succeeds.
} {

}

ad_proc -private  hf_privilege_delete {
    instance_id
    customer_id
    user_id
    role_id
} {
    Deletes a priviledge. Returns 1 if succeeds.
} {

}

ad_proc -private  hf_role_create {
    instance_id 
    label 
    title 
    description 
} {
    Creates a role. Returns role_id, or 0 if unsuccessful.
} {

}

ad_proc -private  hf_role_delete {
    instance_id 
    role_id
} {
    Deletes a role. Returns 1 if successful, otherwise returns 0.
} {

}

ad_proc -private  hf_role_write {
    instance_id 
    role_id 
    label 
    title 
    description
} {
    Writes a revision for a role. Returns 1 if successful, otherwise returns 0.
} {

}

ad_proc -private  hf_role_read {
    instance_id 
    label
} {
    Returns data about a role as a list, or an empty list if label doesn't exist as a role.
} {

}

ad_proc -private  hf_property_create  {
    instance_id 
    asset_type_id 
    title
} {
    Creates a property. Returns value of property_id if successful, otherwise returns 0.
    asset_type_id is either asset_type or a hard-coded type defined via hf_property_create, for example: contact_record 
} {

}

ad_proc -private  hf_property_delete {
    property_id
} {
    Deletes a property.
} {

}

ad_proc -private  hf_property_write {
    instance_id 
    property_id 
    asset_type_id 
    title
} {
    Revises a property. Returns 1 if successful, otherwise returns 0.
} {

}

ad_proc -private  hf_property_read {
    instance_id 
    asset_type_id
} {
    Returns property info as a list, or an empty list if property doesn't exist for asset_type_id.
} {

}

ad_proc -private  hf_permission_create {
    instance_id 
    property_id
    role_id 
    privilege
} {
    Creates a permission, where privilege is create, read, write, delete, or admin. Returns 1 if successful, otherwise returns 0.
} {

}

ad_proc -private  hf_permission_delete {
    instance_id 
    property_id 
    role_id 
    privilege 
} {
    Deletes a permission. Returns 1 if successful, otherwise returns 0.
} {

}

ad_proc -private  hf_permission_p {
    instance_id 
    user_id 
    property_id 
    role_id 
    privilege
} {
    Checks for permission  in place of permission::permission_p within hosting-farm package.
} {

}
