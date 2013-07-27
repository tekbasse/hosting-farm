ad_library {

    permissions API for hosting-farm
    @creation-date 5 June 2013

    use hf_permission_p to check for permissions in place of permission::permission_p
    #  hf_permission_p instance_id user_id customer_id property_label privilege

}

# when checking permissions here, if user is not admin, user is checked against role_id for the specific property_label.
# This allows: 
#     admins to assign custom permissions administration to non-admins
#     role-based assigning, permissions admin of customer assets and adding assets (without adding new roles, property types etc)

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
    set user_id [ad_conn user_id]
    set read_p [hf_permission_p $instance_id $user_id $customer_id customer_assets read]
    set asset_ids_list [list ]
    if { $read_p } {
        set asset_ids_list [db_list asset_ids_for_customer_get "select id from hf_assets where instance_id = :instance_id and qal_customer_id = :customer_id and time_stop > current_timestamp and not (trashed_p = '1') and id in ( select asset_id from hf_asset_label_map where instance_id = :instance_id ) order by last_modified desc"]
    }
    return $asset_ids_list
}

ad_proc -private hf_property_id {
    {instance_id ""} 
    {customer_id ""}
    asset_type_id
} {
    Returns property id or -1 if doesn't exist.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    # check permissions
    set this_user_id [ad_conn user_id]
    set read_p [hf_permission_p $instance_id $this_user_id $customer_id permissions_properties read]
    set exists_p 0
    if { $read_p } {
        set exists_p [db_0or1row hf_property_id_read "select id from hf_property where instance_id = :instance_id and asset_type_id = :asset_type_id"]
    }
    return $exists_p
}

ad_proc -private hf_property_create  {
    {instance_id ""} 
    {customer_id ""}
    asset_type_id 
    title
} {
    Creates a property_label. Returns 1 if successful, otherwise returns 0.
    asset_type_id is either asset_type or a hard-coded type defined via hf_property_create, for example: contact_record , or qal_customer_id coded. If referencing qal_customer_id prepend "customer_id-" to the id number.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    # check permissions
    set this_user_id [ad_conn user_id]
    set create_p [hf_permission_p $instance_id $this_user_id $customer_id permissions_properties create]
    set return_val 0
    if { $create_p } {
        # vet input data
        if { [string length [string trim $title]] > 0 && [string length $asset_type_id] > 0 } {
            set exists_p [expr { [hf_property_id $instance_id $asset_type_id] > -1 } ]
            if { !$exists_p } {
                # create property
                db_dml hf_property_create {insert into hf_property
                    (instance_id, asset_type_id, title)
                    values (:instance_id, :asset_type_id, :title) }
                set return_val 1
            }
        }
    } 
    return $return_val
}

ad_proc -private hf_property_delete {
    property_id
    {customer_id ""}
} {
    Deletes a property.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    # check permissions
    set this_user_id [ad_conn user_id]
    set delete_p [hf_permission_p $instance_id $this_user_id $customer_id permissions_properties delete]
    set return_val 0
    if { $delete_p } {
        set exists_p [expr { [hf_property_id $instance_id $asset_type_id] > -1 } ]
        if { $exists_p } {
            # delete property
            db_dml hf_property_delete "delete from hf_property where instance_id = :instance_id and id = :property_id"
            set return_val 1
        } 
    } 
    return $return_val
}

ad_proc -private hf_property_write {
    {instance_id ""} 
    {customer_id ""}
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
    # check permissions
    set this_user_id [ad_conn user_id]
    set write_p [hf_permission_p $instance_id $this_user_id $customer_id permissions_properties write]
    set return_val 0
    if { $write_p } {
        # vet input data
        if { [string length [string trim $title]] > 0 && [string length $asset_type_id] > 0 } {
            set exists_p [db_0or1row hf_property_ck2 "select id from hf_property where instance_id = :instance_id and id = :property_id"]
            if { $exists_p } {
                # update property
                db_dml hf_property_update {update hf_property 
                    set title = :title, asset_type_id = :asset_type_id 
                    where instance_id = :instance_id and property_id = :property_id}
            } else {
                # create property
                db_dml hf_property_create {insert into hf_property
                    (instance_id, asset_type_id, title)
                    values (:instance_id, :asset_type_id, :title) }
            }
            set return_val 1
        }
    } 
    return $return_val
}

ad_proc -private hf_property_read {
    {instance_id ""} 
    {customer_id ""}
    asset_type_id
} {
    Returns property info as a list in the order id, title; or an empty list if property doesn't exist for asset_type_id.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    # check permissions
    set this_user_id [ad_conn user_id]
    set read_p [hf_permission_p $instance_id $this_user_id $customer_id permissions_properties read]
    set return_list [list ]
    if { $read_p } {
        # use db_list_of_lists to get info, then pop the record out of the list of lists .. to a list.
        set hf_properties_lists [db_list_of_lists "hf_property_set_read" "select id, title from hf_property where instance_id = :instance_id and asset_type_id = :asset_type_id "]
        set return_list [lindex $hf_properties_lists 0]
    }
    return $return_list
}


ad_proc -private hf_customer_privileges_this_user {
    {instance_id ""}
    customer_id
} {
    Lists customer roles assigned to user for customer_id
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    set read_p [hf_permission_p $instance_id $user_id $customer_id permissions_privileges read]
    set assigned_roles_list [list ]
    if { $read_p } {
        set assigned_roles_list [db_list hf_user_roles_customer_read "select hf_role_id from hf_user_roles_map where instance_id = :instance_id and qal_customer_id = :customer_id and user_id = :user_id"]
    }
    return $assigned_roles_list
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
    set this_user_id [ad_conn user_id]
    set read_p [hf_permission_p $instance_id $this_user_id $customer_id permissions_privileges read]
    set assigned_roles_list [list ]
    if { $admin_p } {
        set assigned_roles_list [db_list_of_lists hf_roles_customer_read "select user_id, hf_role_id from hf_user_roles_map where instance_id = :instance_id and qal_customer_id = :customer_id"]
    }
    return $assigned_roles_list
}

ad_proc -private hf_privilege_exists {
    {instance_id ""}
    customer_id
    user_id
    role_id
} {
    If privilege exists, returns 1, else returns 0.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set this_user_id [ad_conn user_id]
    set read_p [hf_permission_p $instance_id $this_user_id $customer_id perimssions_roles read]
    set exists_p 0
    if { $read_p } {
        set exists_p [db_0or1row hf_privilege_exists_p "select hf_role_id from hf_user_roles_map where instance_id = :instance_id and qal_customer_id = :customer_id and hf_role_id = :role_id and user_id = :user_id"]
    }
    return $exists_p
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
    set this_user_id [ad_conn user_id]
    # does this user have permission to assign?
    set create_p [hf_permission_p $instance_id $this_user_id $customer_id permissions_privileges create]
    
    if { $create_p } {
        # does permission already exist?
        set exists_p [hf_privilege_exists_p $instance_id $customer_id $user_id $role_id]
        if { $exists_p } {
            # db update is redundant
        } else {
            db_dml hf_privilege_create { insert into hf_user_roles_map 
                (instance_id, customer_id, hf_role_id, user_id)
                values (:instance_id, :customer_id, :role_id, :user_id) }
        }
    }
    return $create_p
}

ad_proc -private hf_privilege_delete {
    {instance_id ""}
    customer_id
    user_id
    role_id
} {
    Deletes a priviledge ie deletes's a customer's role to a user. Returns 1 if succeeds.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set this_user_id [ad_conn user_id]
    # does this user have permission?
    set delete_p [hf_permission_p $instance_id $this_user_id $customer_id permissions_privileges delete]
    if { $delete_p } {
        db_dml hf_privilege_delete { delete from hf_user_roles_map where instance_id = :instance_id and customer_id = :customer_id and user_id = :user_id and role_id = :role_id }
    }
    return $delete_p
}

ad_proc -private hf_role_create {
    {instance_id ""} 
    customer_id
    label 
    title 
    {description ""}
} {
    Creates a role. Returns role_id, or 0 if unsuccessful.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }

    # table hf_role has instance_id, id (seq nextval), label, title, description, where label includes technical_contact, technical_staff, billing_*, primary_*, site_developer etc roles
    # check permissions
    set this_user_id [ad_conn user_id]
    set create_p [hf_permission_p $instance_id $this_user_id $customer_id permissions_roles create]
    set return_val 0
    if { $create_p } {
        # vet input data
        if { [string length [string trim $title]] > 0 && [string length $label] > 0 } {
            set exists_p [hf_role_id_exists $instance_id $label]
            if { !$exists_p } {
                # create role
                db_dml hf_role_create {insert into hf_role
                    (instance_id, label, title, description)
                    values (:instance_id, :label, :title, :description) }
                set return_val 1
            }
        }
    } 
    return $return_val
}

ad_proc -private hf_role_delete {
    {instance_id ""} 
    {customer_id ""}
    role_id
} {
    Deletes a role. Returns 1 if successful, otherwise returns 0.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    # check permissions
    set this_user_id [ad_conn user_id]
    set delete_p [hf_permission_p $instance_id $this_user_id $customer_id permissions_roles delete]
    set return_val 0
    if { $delete_p } {
        set exists_p [hf_role_id_exists $instance_id $role_id]
        if { $exists_p } {
            db_dml hf_role_delete {delete from hf_role where instance_id = :instance_id and id = :role_id}
            set return_val 1
        } 
    }
    return $return_val
}

ad_proc -private hf_role_write {
    {instance_id ""} 
    {customer_id ""}
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
    # check permissions
    set this_user_id [ad_conn user_id]
    set write_p [hf_permission_p $instance_id $this_user_id $customer_id permissions_roles write]
    set return_val 0
    if { $write_p } {
        # vet input data
        if { [string length [string trim $title]] > 0 && [string length $label] > 0 } {
            set exists_p [hf_role_id_exists $instance_id $label]
            if { $exists_p } {
                # update role
                db_dml hf_role_update {update hf_role
                    set label = :label and title = :title and description =:description where instance_id = :instance_id and id = :role_id}
                set return_val 1
            } else {
                # create role
                db_dml hf_role_create {insert into hf_role
                    (instance_id, label, title, description)
                    values (:instance_id, :label, :title, :description) }
                set return_val 1
            }
        }
    } 
    return $return_val
}


ad_proc -private hf_role_id {
    {instance_id ""} 
    {customer_id ""}
    label
} {
    Returns role_id from label or -1 if role doesn't exist.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    # check permissions
    set this_user_id [ad_conn user_id]
    set read_p [hf_permission_p $instance_id $this_user_id $customer_id permissions_roles read]
    set id -1
    if { $read_p } {
        db_0or1row hf_role_id_get "select id from hf_role where instance_id = :instance_id and label = :label"
    }
    return $id
}

ad_proc -private hf_role_id_exists {
    {instance_id ""} 
    label
} {
    Returns role_id from label or -1 if role doesn't exist.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    # check permissions  Not necessary, because disclosure is extremely limited compared to speed.
#    set this_user_id [ad_conn user_id]
#    set read_p [hf_permission_p $instance_id $this_user_id $role_id permissions_roles read]
    set exists_p 0
    if { $read_p } {
        set exists_p [db_0or1row hf_role_id_exists "select id from hf_role where instance_id = :instance_id and label = :label"]
    }
    return $exists_p
}

ad_proc -private hf_role_read {
    {instance_id ""} 
    {customer_id ""}
    role_id
} {
    Returns role's label, title, and description as a list, or an empty list if role_id doesn't exist.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    # check permissions
    set this_user_id [ad_conn user_id]
    set read_p [hf_permission_p $instance_id $this_user_id $customer_id permissions_roles read]
    set role_list [list ]
    if { $read_p } {
        set role_list [db_list_of_lists hf_role_read "select label,title,description from hf_role where instance_id = :instance_id and id = :id"]
        set role_list [lindex $role_list 0]
    }
    return $role_list
}

ad_proc -private hf_roles {
    {instance_id ""} 
    {customer_id ""}
} {
    Returns roles as a list, with each list item consisting of label, title, and description as a list, or an empty list if no roles exist.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    # check permissions
    set this_user_id [ad_conn user_id]
    set read_p [hf_permission_p $instance_id $this_user_id $customer_id permissions_roles read]
    set role_list [list ]
    if { $read_p } {
        set role_list [db_list_of_lists hf_roles_read "select label,title,description from hf_role where instance_id = :instance_id"]
    }
    return $role_list
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
    # first, verify that the user has adequate system permission.
    # This needs to work at least for admins, in order to set up hf_permissions.
    set allowed_p [permission::permission_p -party_id $user_id -object_id $instance_id -privilege $privilege]
    if { $allowed_p && $privilege eq "admin" } {
        # user is set to go. No need to check further.
    } elseif { $allowed_p && $customer_id ne "" } {
        # this privilege passed first hurdle, but is still not allowed.
        set allowed_p 0
        # unless any of the roles assigned to the user allow this PRIVILEGE for this PROPERTY_LABEL
        # checking.. 
        # Verify user is a member of the customer_id users and
        # determine assigned customer_id roles for user_id

        # insert a call to a customer_id-to-customer_id map that can return multiple customer_ids, to handle a hierarcy of customer_ids
        # for cases where a large organization has multiple departments.  Right now, treating them as separate customers is adequate.

        set role_ids_list db_list hf_user_roles_for_customer_get "select hf_role_id from hf_user_roles_map where instance_id = :instance_id and qal_customer_id = :customer_id and user_id = :user_id"
        if { [llength $roles_id_list] > 0 } {
            set property_id_exists_p [db_0or1row hf_property_id_exist_p "select id as property_id from hf_property where instance_id = :instance_id and asset_type_id = :property_label"]
            if { $property_id_exists_p } {
                set allowed_p [db_0or1row hf_property_role_privilege_ck "select privilege from hf_property_role_privilege_map where instance_id = :instance_id and property_id = :property_id and privilege = :privilege and role_id in ([template::util::tcl_to_sql_list $roles_id_list])"]
            }
        }
    }    
    return $allowed_p
}
