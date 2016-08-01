ad_library {

    permissions API for Hosting Farm
    @creation-date 5 June 2013
    @Copyright (c) 2014 Benjamin Brink
    @license GNU General Public License 3, see project home or http://www.gnu.org/licenses/gpl-3.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com

    use hf_permission_p to check for permissions in place of permission::permission_p
    #  hf_permission_p user_id customer_id property_label privilege instance_id

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

    @param user_id     Checks for user_id if not blank, otherwise checks for user_id from connection.
    @param instance_id Checks for user_id in context of instance_id if not blank, otherwise from connection.

    @return Returns qal_customer_id numbers in a list.

} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    #qal_customer_id defined by qal_customer.id accounts-ledger/sql/postgresql/entities-channels-create.sql
    set qal_customer_ids_list [db_list qal_customer_ids_get "select qal_customer_id from hf_user_roles_map where instance_id=:instance_id and user_id=:user_id"]
    return $qal_customer_ids_list
}


ad_proc -public hf_active_asset_ids_of_customer {
    customer_id
    {top_level_p "0"}
} {
    Returns a list of active asset_ids (contracts) for customer_id

    @param customer_id Checks for this customer.
    @top_level_p

    @return Returns asset_id numbers in a list.

} {
    upvar instance_id instance_id
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    set read_p [hf_permission_p $user_id $customer_id assets read $instance_id]
    set asset_ids_list [list ]
    if { $read_p } {
        set f_id_list [db_list f_ids_for_customer_get { select f_id from hf_assets 
            where instance_id=:instance_id 
            and qal_customer_id=:customer_id
            and trashed_p!='1'} ]
        if { [qf_is_true $top_level_p] } {
            # This is trickier than for sys admins, because top level may
            # very well be dependent on a system asset or asset
            # of another customer
            set asset_tla_list [db_list asset_ids_for_customer_get_tla_f_id "
                select f_id from hf_sub_asset_map
                where instance_id=:instance_id
                and trashed_p!='1'
                and f_id in ( [template::util::tcl_to_sql_list $f_id_list] )
                and f_id not in ( select sub_f_id from hf_sub_asset_map
                                  where sub_f_id in [template::util::tcl_to_sql_list $f_id_list] ) " ]
            set asset_ids_list [db_list asset_ids_for_customer_get_tla_id "select asset_id
                from hf_asset_rev_map
                where instance_id=:instance_id
                and trashed_p!='1'
                and f_id in ( [template::util::tcl_to_sql_list $asset_tla_list] )" ]
        } else {
            set asset_ids_list [db_list asset_ids_for_customer_get "select asset_id from hf_asset_rev_map where instance_id=:instance_id and trashed_p!='1' and f_id in ( [template::util::tcl_to_sql_list $f_id_list] )"]
        }
    }
    return $asset_ids_list
}

ad_proc -private hf_property_id {
    asset_type_id
    {instance_id ""} 
} {
    Returns the property_id of an asset_type_id.
    By default, asset_type_id is either a standard asset_type_id, or 
    one of the additional ones hard coded in the hosting-farm API:
    main_contact_record
    admin_contact_record
    tech_contact_record
    permissions_properties
    permissions_roles
    permissions_privileges
    non_assets
    published
    assets
 
    @param asset_type_id

    @return property_id or -1 if doesn't exist.
} {
    set id ""
    db_0or1row hf_property_id_read "select id from hf_property where instance_id=:instance_id and asset_type_id=:asset_type_id"
    return $id
}

ad_proc -private hf_property_create {
    asset_type_id
    title
    {customer_id ""}
    {instance_id ""}
} {
    Creates a property_label. Returns 1 if successful, otherwise returns 0.
    asset_type_id is either asset_type or a hard-coded type defined via hf_property_create, for example: contact_record , or qal_customer_id coded. If referencing qal_customer_id prepend "customer_id-" to the id number.
} {
    set return_val 0
    if { $asset_type_id ne "" && $title ne "" } {
        if { $instance_id eq "" } {
            # set instance_id package_id
            set instance_id [ad_conn package_id]
        }
        # check permissions
        set this_user_id [ad_conn user_id]
        set create_p [hf_permission_p $this_user_id $customer_id permissions_properties create $instance_id]
        
        if { $create_p } {
            # vet input data
            if { [string length [string trim $title]] > 0 && [string length $asset_type_id] > 0 } {
                set exists_p [expr { [hf_property_id $asset_type_id $instance_id] > -1 } ]
                if { !$exists_p } {
                    # create property
                    db_dml hf_property_create {insert into hf_property
                        (instance_id, asset_type_id, title)
                        values (:instance_id, :asset_type_id, :title) }
                    set return_val 1
                }
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
    set delete_p [hf_permission_p $this_user_id $customer_id permissions_properties delete $instance_id]
    set return_val 0
    if { $delete_p } {
        set exists_p [expr { [hf_property_id $asset_type_id $instance_id] > -1 } ]
        if { $exists_p } {
            # delete property
            db_dml hf_property_delete "delete from hf_property where instance_id=:instance_id and id=:property_id"
            set return_val 1
        } 
    } 
    return $return_val
}

ad_proc -private hf_property_write {
    property_id
    asset_type_id
    title
    {customer_id ""}
    {instance_id ""} 
} {
    Revises a property. Returns 1 if successful, otherwise returns 0.
} {
    set return_val 0
    if { $property_id ne "" && asset_type_id ne "" } {
        if { $instance_id eq "" } {
            # set instance_id package_id
            set instance_id [ad_conn package_id]
        }
        # check permissions
        set this_user_id [ad_conn user_id]
        set write_p [hf_permission_p $this_user_id $customer_id permissions_properties write $instance_id]
        if { $write_p } {
            # vet input data
            if { [string length [string trim $title]] > 0 && [string length $asset_type_id] > 0 } {
                set exists_p [db_0or1row hf_property_ck2 "select id from hf_property where instance_id=:instance_id and id=:property_id"]
                if { $exists_p } {
                    # update property
                    db_dml hf_property_update {update hf_property 
                        set title=:title, asset_type_id=:asset_type_id 
                        where instance_id=:instance_id and property_id=:property_id}
                } else {
                    # create property
                    db_dml hf_property_create {insert into hf_property
                        (instance_id, asset_type_id, title)
                        values (:instance_id, :asset_type_id, :title) }
                }
                set return_val 1
            }
        } 
    }
    return $return_val
}

ad_proc -private hf_property_read {
    asset_type_id
    {customer_id ""}
    {instance_id ""} 
} {
    Returns property info as a list in the order id, title; or an empty list if property doesn't exist for asset_type_id.
} {
    set return_list [list ]
    if { $asset_type_id ne "" } {
        if { $instance_id eq "" } {
            # set instance_id package_id
            set instance_id [ad_conn package_id]
        }
        # check permissions
        set this_user_id [ad_conn user_id]
        set read_p [hf_permission_p $this_user_id $customer_id permissions_properties read $instance_id]
        
        if { $read_p } {
            # use db_list_of_lists to get info, then pop the record out of the list of lists .. to a list.
            set hf_properties_lists [db_list_of_lists "hf_property_set_read" "select id, title from hf_property where instance_id=:instance_id and asset_type_id=:asset_type_id "]
            set return_list [lindex $hf_properties_lists 0]
        }
    }
    return $return_list
}


ad_proc -private hf_customer_roles_of_user {
    {customer_id ""}
    {instance_id ""}
} {
    Lists roles assigned to user for customer_id
} {
    set assigned_roles_list [list ]
    if { $customer_id ne "" } {
        if { $instance_id eq "" } {
            # set instance_id package_id
            set instance_id [ad_conn package_id]
        }
        set user_id [ad_conn user_id]
        set read_p [hf_permission_p $user_id $customer_id permissions_privileges read $instance_id]
        set assigned_roles_list [list ]
        if { $read_p } {
            set assigned_roles_list [db_list hf_user_roles_customer_read "select hf_role_id from hf_user_roles_map where instance_id=:instance_id and qal_customer_id=:customer_id and user_id=:user_id"]
        }
    }
    return $assigned_roles_list
}

ad_proc -private hf_users_roles_of_customer {
    {customer_id ""}
    {instance_id ""}
} {
    Lists customer roles assigned, as a list of user_id, role_id pairs.
} {
    set assigned_roles_list [list ]
    if { $customer_id ne "" } {
        if { $instance_id eq "" } {
            # set instance_id package_id
            set instance_id [ad_conn package_id]
        }
        set this_user_id [ad_conn user_id]
        set read_p [hf_permission_p $this_user_id $customer_id permissions_privileges read $instance_id]
        if { $admin_p } {
            set assigned_roles_list [db_list_of_lists hf_roles_customer_read "select user_id, hf_role_id from hf_user_roles_map where instance_id=:instance_id and qal_customer_id=:customer_id"]
        }
    }
    return $assigned_roles_list
}

ad_proc -private hf_user_role_exists_q {
    user_id
    role_id
    {customer_id ""}
    {instance_id ""}
} {
    If privilege exists, returns 1, else returns 0.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set this_user_id [ad_conn user_id]
    set read_p [hf_permission_p $this_user_id $customer_id perimssions_roles read $instance_id]
    set exists_p 0
    if { $read_p } {
        set exists_p [db_0or1row hf_user_role_exists_q "select hf_role_id from hf_user_roles_map where instance_id=:instance_id and qal_customer_id=:customer_id and hf_role_id=:role_id and user_id=:user_id"]
    }
    return $exists_p
}


ad_proc -private hf_roles_of_user {
    user_id
    {customer_id ""}
} {
    Returns list of roles of user. Empty list if none found.
} {
    upvar 1 instance_id instance_id
    if { ![info exists instance_id] } {
        set instance_id [ad_conn package_id]
    }
    if { ![qf_is_natural_number $user_id] } {
        set user_id [ad_conn user_id]
    }
    if { $customer_id eq "" } {
        set roles_list [db_list hf_roles_of_user "select distinct on (label) label from hf_role where instance_id=:instance_id and id in (select hf_role_id from hf_user_roles_map where instance_id=:instance_id and user_id=:user_id)"] 
    } elseif { [qf_is_natural_number $customer_id] } {
        set roles_list [db_list hf_roles_of_user "select distinct on (label) label from hf_role where instance_id=:instance_id and id in (select hf_role_id from hf_user_roles_map where instance_id=:instance_id and user_id=:user_id and customer_id=:customer_id)"]
    } 
    return $roles_list
}


ad_proc -private hf_user_role_add {
    customer_id
    user_id
    role_id
    {instance_id ""}
} {
    Create a privilege ie assign a customer's role to a user. Returns 1 if succeeds.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set this_user_id [ad_conn user_id]
    # does this user have permission to assign?
    set create_p [hf_permission_p $this_user_id $customer_id permissions_privileges create $instance_id]
    
    if { $create_p } {
        # does permission already exist?
        set exists_p [hf_user_role_exists_q $user_id $role_id $customer_id $instance_id]
        if { $exists_p } {
            # db update is redundant
        } else {
            db_dml hf_privilege_create { insert into hf_user_roles_map 
                (instance_id, qal_customer_id, hf_role_id, user_id)
                values (:instance_id, :customer_id, :role_id, :user_id) }
        }
    }
    return $create_p
}

ad_proc -private hf_user_role_delete {
    customer_id
    user_id
    role_id
    {instance_id ""}
} {
    Deletes a privilege ie deletes's a customer's role to a user. Returns 1 if succeeds.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set this_user_id [ad_conn user_id]
    # does this user have permission?
    set delete_p [hf_permission_p $this_user_id $customer_id permissions_privileges delete $instance_id]
    if { $delete_p } {
        db_dml hf_privilege_delete { delete from hf_user_roles_map where instance_id=:instance_id and qal_customer_id=:customer_id and user_id=:user_id and hf_role_id=:role_id }
    }
    return $delete_p
}



ad_proc -private hf_role_create {
    customer_id
    label 
    title 
    {description ""}
    {instance_id ""} 
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
    set create_p [hf_permission_p $this_user_id $customer_id permissions_roles create $instance_id]
    set return_val 0
    if { $create_p } {
        # vet input data
        if { [string length [string trim $title]] > 0 && [string length $label] > 0 } {
            set exists_p [hf_role_id_exists_q $label $instance_id]
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
    role_id
    {customer_id ""}
    {instance_id ""} 
} {
    Deletes a role. Returns 1 if successful, otherwise returns 0.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    # check permissions
    set this_user_id [ad_conn user_id]
    set delete_p [hf_permission_p $this_user_id $customer_id permissions_roles delete $instance_id]
    set return_val 0
    if { $delete_p } {
        set exists_p [hf_role_id_exists_q $role_id $instance_id]
        if { $exists_p } {
            db_dml hf_role_delete {delete from hf_role where instance_id=:instance_id and id=:role_id}
            set return_val 1
        } 
    }
    return $return_val
}

ad_proc -private hf_role_write {
    role_id 
    label 
    title 
    description
    {customer_id ""}
    {instance_id ""} 
} {
    Writes a revision for a role. Returns 1 if successful, otherwise returns 0.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    # check permissions
    set this_user_id [ad_conn user_id]
    set write_p [hf_permission_p $this_user_id $customer_id permissions_roles write $instance_id]
    set return_val 0
    if { $write_p } {
        # vet input data
        if { [string length [string trim $title]] > 0 && [string length $label] > 0 } {
            set exists_p [hf_role_id_exists_q $label $instance_id]
            if { $exists_p } {
                # update role
                db_dml hf_role_update {update hf_role
                    set label=:label, title=:title, description=:description where instance_id=:instance_id and id=:role_id}
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


ad_proc -private hf_role_id_of_label {
    label
    {instance_id ""} 
} {
    Returns role_id from label or empty string if role doesn't exist.
} {
    set id ""
    db_0or1row hf_role_id_get "select id from hf_role where instance_id=:instance_id and label=:label"
    return $id
}

ad_proc -private hf_role_id_exists_q {
    role_id
    {instance_id ""} 
} {
    Returns 1 if role_id exists, or 0 if role doesn't exist.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    # check permissions  Not necessary, because disclosure is extremely limited compared to speed.
#    set this_user_id [ad_conn user_id]
#    set read_p [hf_permission_p $this_user_id $role_id permissions_roles read $instance_id]
    set exists_p 0
    set exists_p [db_0or1row hf_role_id_exists_q "select label from hf_role where instance_id=:instance_id and id=:role_id"]
    return $exists_p
}

ad_proc -private hf_role_read {
    role_id
    {customer_id ""}
    {instance_id ""} 
} {
    Returns role's label, title, and description as a list, or an empty list if role_id doesn't exist.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    # check permissions
    set this_user_id [ad_conn user_id]
    set read_p [hf_permission_p $this_user_id $customer_id permissions_roles read $instance_id]
    set role_list [list ]
    if { $read_p } {
        set role_list [db_list_of_lists hf_role_read "select label,title,description from hf_role where instance_id=:instance_id and id=:id"]
        set role_list [lindex $role_list 0]
    }
    return $role_list
}

ad_proc -private hf_roles {
    {instance_id ""} 
} {
    Returns roles as a list, with each list item consisting of label, title, and description as a list, or an empty list if no roles exist.
} {
    set role_list [db_list_of_lists hf_roles_read "select label,title,description from hf_role where instance_id=:instance_id"]
    return $role_list
}

ad_proc -private hf_permission_p {
    user_id 
    customer_id
    property_label 
    privilege
    {instance_id ""} 
} {
    Checks for permission  in place of permission::permission_p within hosting-farm package.

    Permissions works like this: 
 
    Each asset is associated with an id (asset_id). 
    Each asset_id is associated with a customer (customer_id).
    A privilege is the same as in permission::permission_p (read/write/create/admin).
    Default property_labels consist of:
      assets, 
      permissions_roles, 
      permissions_privileges, 
      permissions_properties, and
      published.
    Each role is assigned privileges on property_labels. Default privilege is none.
    Default roles consist of:
      technical_contact,
      technical_staff,
      billing_contact,
      billing_staff,
      primary_contact,
      primary_staff, and
      site_developer.
    Each asset is associated with a customer, and each user assigned roles.
    This proc confirms that one of roles assigned to user_id can do privilege on customer's property_label.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    # first, verify that the user has adequate system permission.
    # This needs to work at least for admins, in order to set up hf_permissions.
    #set allowed_p [permission::permission_p -party_id $user_id -object_id $instance_id -privilege $privilege]
    set allowed_p [permission::permission_p -party_id $user_id -object_id $instance_id -privilege read]
    set admin_p [permission::permission_p -party_id $user_id -object_id $instance_id -privilege admin]
    if { $admin_p } {
        # user is set to go. No need to check further.
    } elseif { $allowed_p && $privilege eq "read" && $property_label eq "published" } {
        
        # A generic case is privilege read, property_level published.
        # customer_id is not relevant.
        # User is set to go. No need to check further.

    } elseif { $allowed_p && $customer_id ne "" } {
        # this privilege passed first hurdle, but is still not allowed.
        set allowed_p 0
        # unless any of the roles assigned to the user allow this PRIVILEGE for this PROPERTY_LABEL
        # checking.. 

        # Verify user is a member of the customer_id users and
        # determine assigned customer_id roles for user_id

        # insert a call to a customer_id-to-customer_id map that can return multiple customer_ids, to handle a hierarcy of customer_ids
        # for cases where a large organization has multiple departments.  Right now, treating them as separate customers is adequate.

        # select role_id list of user for this customer
        set role_ids_list [db_list hf_user_roles_for_customer_get "select hf_role_id from hf_user_roles_map where instance_id=:instance_id and qal_customer_id=:customer_id and user_id=:user_id"]
        #    ns_log Notice "hf_permission_p.575: user_id '${user_id}' customer_id '${customer_id}' role_ids_list '${role_ids_list}'"
        if { [llength $role_ids_list] > 0 } {
            #    ns_log Notice "hf_permission_p.587: user_id ${user_id} customer_id ${customer_id} property_label ${property_label} role_ids_list '${role_ids_list}'"
            # get the property_id
            set property_id_exists_p [db_0or1row hf_property_id_exist_p "select id as property_id from hf_property where instance_id=:instance_id and asset_type_id=:property_label"]
            if { $property_id_exists_p } {
                # ns_log Notice "hf_permission_p.591: user_id ${user_id} customer_id ${customer_id} property_id '${property_id}' privilege '${privilege}' instance_id '${instance_id}'"
                # conform at least one of the roles has privilege on property_id
                set allowed_p [db_0or1row hf_property_role_privilege_ck "select privilege from hf_property_role_privilege_map where instance_id=:instance_id and property_id=:property_id and privilege=:privilege and role_id in ([template::util::tcl_to_sql_list $role_ids_list]) limit 1"]
            }
        } 
    } else {
        # customer_id eq ""
        set allowed_p 0
    }
    return $allowed_p
}

ad_proc -private hf_pkg_admin_required  {
} {
    Requires user to have package admin permission, or redirects to register page.
} {
    set user_id [ad_conn user_id]
    set package_id [ad_conn package_id]
    set admin_p [permission::permission_p -party_id $user_id -object_id $package_id -privilege admin]
    if { !$admin_p } {
        ad_redirect_for_registration
        ad_script_abort
    }
    return $admin_p
}
