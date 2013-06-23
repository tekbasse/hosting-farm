ad_library {

    permissions API for hosting-farm
    @creation-date 5 June 2013

    use hf_permission_p to check for permissions in place of permission::permission_p
}

ad_proc -public hf_customer_ids_for_user { 
    {user_id ""}
    {instance_id ""}
} {
    Returns a list of qal_customer_ids for user_id
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    #qal_customer_id defined by qal_customer.id accounts-ledger/sql/postgresql/entities-channels-create.sql
    set qal_customer_ids_list [db_list qal_customer_ids_get "select qal_customer_id from hf_user_customer_map where instance_id = :instance_id and user_id =:user_id"]
    return $qal_customer_ids_list
}


ad_proc -public hf_active_asset_ids_for_customer {
    customer_id
    {instance_id ""}
} {
    Returns a list of active asset_ids (contracts) for customer_id
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set asset_ids_list [db_list asset_ids_for_customer_get "select id from hf_assets where instance_id = :instance_id and qal_customer_id = :customer_id and time_stop > current_timestamp and not (trashed_p = '1')"]
    return $asset_ids_list
}

ad_proc -private hf_customer_privileges {
    {instance_id ""}
    customer_id
} {
    Lists customer roles assigned, as a list of user_id, role_id pairs.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    set property_label customer_roles
    set read_p [hf_permission_p $instance_id $user_id $property_label $role_id read]
    set assigned_roles_list [db_list_of_lists hf_user_roles_customer_read "select user_id, hf_role_id from hf_user_roles_map where instance_id = :instance_id and qal_customer_id = :customer_id"]
    return $assigned_roles_list
    
}

ad_proc -private hf_privilege_create {
    {instance_id ""}
    customer_id
    user_id
    role_id
} {
    Create a priviledge ie assign a customer's role to a user. Returns 1 if succeeds.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    # does this user have permission to assign?
    set write_p [hf_permission_p $instance_id $user_id $property_id $role_id $privilege]
    
    # If privilege already exists, skip.

    
}

ad_proc -private hf_privilege_delete {
    {instance_id ""}
    customer_id
    user_id
    role_id
} {
    Deletes a priviledge. Returns 1 if succeeds.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }

}

ad_proc -private hf_role_create {
    {instance_id ""} 
    label 
    title 
    description 
} {
    Creates a role. Returns role_id, or 0 if unsuccessful.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }

}

ad_proc -private hf_role_delete {
    {instance_id ""} 
    role_id
} {
    Deletes a role. Returns 1 if successful, otherwise returns 0.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }

}

ad_proc -private hf_role_write {
    {instance_id ""} 
    role_id 
    label 
    title 
    description
} {
    Writes a revision for a role. Returns 1 if successful, otherwise returns 0.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }

}

ad_proc -private hf_role_read {
    {instance_id ""} 
    label
} {
    Returns data about a role as a list, or an empty list if label doesn't exist as a role.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }

}

ad_proc -private hf_property_create  {
    {instance_id ""} 
    asset_type_id 
    title
} {
    Creates a property_label. Returns value of property_id if successful, otherwise returns 0.
    asset_type_id is either asset_type or a hard-coded type defined via hf_property_create, for example: contact_record 
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }

}

ad_proc -private hf_property_delete {
    property_id
} {
    Deletes a property.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }

}

ad_proc -private hf_property_write {
    {instance_id ""} 
    property_id 
    asset_type_id 
    title
} {
    Revises a property. Returns 1 if successful, otherwise returns 0.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }

}

ad_proc -private hf_property_read {
    {instance_id ""} 
    asset_type_id
} {
    Returns property info as a list, or an empty list if property doesn't exist for asset_type_id.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }

}

ad_proc -private hf_permission_create {
    {instance_id ""} 
    property_id
    role_id 
    privilege
} {
    Creates a permission, where privilege is create, read, write, delete, or admin. Returns 1 if successful, otherwise returns 0.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }

}

ad_proc -private hf_permission_delete {
    {instance_id ""} 
    property_id 
    role_id 
    privilege 
} {
    Deletes a permission. Returns 1 if successful, otherwise returns 0.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }

}

ad_proc -private hf_permission_p {
    {instance_id ""} 
    user_id 
    customer_id
    property_label 
    privilege
} {
    Checks for permission  in place of permission::permission_p within hosting-farm package.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set allowed_p 0
    # first, verify that the user has adequate system permission.
    # This needs to work at least for admins, in order to set up hf_permissions.
    set allowed_p [permission::permission_p -party_id $user_id -object_id $instance_id -privilege $privilege]
    if { $allowed_p && $privilege eq "admin" } {
	# user is set to go. No need to check further.
    } elseif { $allowed_p } {
	# this privilege is not allowed.
	set allowed_p 0
	# unless any of the roles assigned to the user allow this PRIVILEGE for this PROPERTY_LABEL
	# checking.. 
	# Verify user is a member of the customer_id users and
	# determine assigned customer_id roles for user_id
	set role_ids_list db_list hf_user_roles_for_customer_get "select hf_role_id from hf_user_roles_map where instance_id = :instance_id and qal_customer_id = :customer_id and user_id = :user_id"
	if { [llength $roles_id_list] > 0 } {
	    set property_id_exists_p [db_0or1row hf_property_id_exist_p "select id from hf_property where instance_id = :instance_id and asset_type_id = :property_label"]
	    if { $property_id_exists_p } {
		set allowed_p [db_0or1row hf_property_role_privilege_ck "select privilege from hf_property_role_privilege_map where instance_id = :instance_id and property_id = :property_id and privilege = :privilege and role_id in ([template::util::tcl_to_sql_list $roles_id_list])"]
	    }
	}
    }    
    return $allowed_p
}
