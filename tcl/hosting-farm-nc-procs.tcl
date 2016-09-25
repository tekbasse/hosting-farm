# hosting-farm/tcl/hosting-farm-nc-procs.tcl
ad_library {

    library for no-connection admin of Hosting Farm
    a repository file for scheduled procs and developer convenience allowing apm to reload most of api during testing
    @creation-date 2015-12-30
    @Copyright (c) 2015 Benjamin Brink
    @license GNU General Public License 3, see project home or http://www.gnu.org/licenses/gpl-3.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com

}

# using standard namespace to avoid caching of data that can happen in separate namespaces
ad_proc -private hf_nc_go_ahead {
    {asset_id_varnam "asset_id"}
    {property "assets"}
} {
    Confirms process is not run via connection, or is run by an admin. 
} {
    if { $asset_id_varnam eq "" } {
        set asset_id_varnam "asset_id"
    }
    upvar 1 $asset_id_varnam asset_id
    if { [ns_conn isconnected] } {
        set user_id [ad_conn user_id]
        set instance_id [ad_conn package_id]
        #set go_ahead \[permission::permission_p -party_id $user_id -object_id $instance_id -privilege admin\]
        set customer_id [hf_customer_id_of_asset_id $asset_id]
        # Make sure asset_id is consistent to asset_type_id
        set asset_type_id [hf_nc_asset_type_id $asset_id]
        if { $property eq "" || $property eq "assets" } {
            set property $asset_type_id
        }
        set go_ahead [hf_permission_p $user_id $customer_id $property admin $instance_id]
        if { !$go_ahead } {
            ns_log Warning "hf_nc_go_head failed. Called by user_id '${user_id}' args: asset_id_varnam '${asset_id_varnam}' instance_id '${instance_id}' asset_id '${asset_id}' asset_type_id '${asset_type_id}' property '${property}'"
        }
    } else {
                #if { ![string match {hf_*} $argv0 ] && ![string match {hfl_*} $argv0 ] } {
        #    set go_ahead 0
        #    ns_log Warning "hf_nc_go_head.42: failed. Called by proc '${argv0}' args: asset_id_varnam '${asset_id_varnam}' asset_id '${asset_id}' asset_type_id '${asset_type_id}'"
        #} else {
        set go_ahead [hf_nc_proc_in_context_q ]
        #ns_log Notice "hf_nc_go_ahead: ns_thread name [ns_thread name] ns_thread id [ns_thread id] ns_info threads [ns_info threads] ns_info scheduled [ns_info scheduled]"
        #}
    }
    if { !$go_ahead } {
        ns_log Warning "hf_nc_go_ahead: permission denied."
        ad_script_abort
    }

    return $go_ahead
}

ad_proc -private hf_nc_users_of_asset_id {
    asset_id
    instance_id
    {privilege ""}
    {role ""}
} {
    Returns a list of user_ids, or empty string if there are none. 
    If privilege is included, users are filtered to the ones allowed to perform privilege on the asset. Privilege is the kind provided by hf_permissions system, ie read, write, admin.
    If role is included, users are filtered to the ones assigned the role. If role and privilege are specified, users are only filtered by role, since role is the most specific.  For example, if privilege were "write", admin and manager roles allowed to work with asset_type would qualify. Whereas specifying a single manager or admin role will result in fewer users with same privilege.
} {
    #  If asset_type_id is included, returns users with roles assigned to asset_id's type.
    #  If role_id and asset_type_id is included, returns users with assigned role for asset_id.

    set success_p [hf_nc_go_ahead ]
    set user_ids_list [list ]
    set role_ids_list [list ]
    if { $success_p } {
        if { $privilege ne "" && $role eq "" } {
            # filter by privilege ie get a filtered role_ids_list 
            
            # Get asset_type_id
            set asset_type_id [hf_nc_asset_type_id $asset_id]
            set property_id_exists_p [db_0or1row hf_assets_type_users_r "select property_id from hf_property where asset_type_id=:asset_type_id"]

            if { $property_id_exists_p } {
                # property_id_exists_p should be true. It is looked up in a table.
                
                set role_ids_list [qc_roles_of_prop_priv $property_id $privilege]

            } 

            if { [llength $role_ids_list] == 0 } {
                # Either :
                # property_id_exists_p is false
                # Or, no role exists for property_id and privilege.
                set success_p 0
            }

        } elseif { $role ne "" } {

            set role_exists_p [db_0or1row hf_role_id_of_label_r "select id from hf_role where label=:role"]
            if { $role_exists_p } {
                set role_ids_list [list $id]
            } else {
                # role not found.
                set success_p 0
            }

        } else {
            # privilege and role not specified
            set role_ids_list [qc_roles_of_prop_priv $property_id]

        }

        if { $success_p && [llength $role_ids_list] > 0 } {
            set customer_id [hf_customer_id_of_asset_id $asset_id]
            # get user_ids limited by hf_role_id in one query
            set user_ids_list [db_list hf_user_role_of_customer_id_r "select user_id from hf_user_roles_map where instance_id = :instance_id and qal_customer_id=:customer_id and role_id in ([template::util::tcl_to_sql_list $role_ids_list)"]
            
        }
    }
    
    return $user_ids_list
}



ad_proc -private hf_nc_asset_type_id {
    asset_id
} {
    Returns asset_type_id
} {
    # avoid infinite loop. do not call a permission proc from here.
    upvar 1 instance_id instance_id
    set asset_type_id ""
    db_0or1row hf_assets_asset_type_id_r "select asset_type_id from hf_assets where instance_id=:instance_id and asset_id=:asset_id"
    return $asset_type_id
}

ad_proc -private hf_nc_ip_read {
    asset_id
    instance_id
    arr_name
} {
    Adds elements to an array. Creates array if it doesn't exist.
} {
    upvar 1 $arr_name obj_arr
    set success_p [hf_nc_go_ahead ]
    if { $success_p } {
        # element list
        set ip_var_list [list ipv4_addr ipv4_status ipv6_addr ipv6_status]
        # Multiple ip_ids could have been specified in hf_nc_dc etc, but there is would be no check on
        # a query at this point. By collecting additional mapped ip_id here, only values related to same
        # asset are returned.
        set ip_id_list [db_list hf_asset_ip_map_read_star "select ip_id from hf_asset_ip_map where asset_id=:asset_id and instance_id=:instance_id"]
        # Check for case of hf_asset_id.ip_id carried over from hf_nc_asset_read
        if { [info exists obj_arr(ip_id)] } {
            if { $obj_arr(ip_id) ne "" } {
                if { [lsearch -exact $ip_id_list $obj_arr(ip_id)] == -1 } {
                    # obj_arr(ip_id) is unique
                    lappend ip_id_list $obj_arr(ip_id)
                }
            }
        }
        # check for case of hf_virtual_machines.ip_id
        set vm_ip_id_p [db_0or1row hf_vm_ip_id_read "select ip_id from hf_virtual_machines where vm_id=:asset_id"]
        if { $vm_ip_id_p } {
            if { [lsearch -exact $ip_id_list $ip_id] == -1 } {
                # ip_id is unique
                lappend ip_id_list $ip_id
            }
        }

        set ip_lists [db_list_of_lists hf_ip_address_prop_get1 "select ipv4_addr, ipv4_status, ipv6_addr, ipv6_status, ip_id from hf_ip_addresses where instance_id=:instance_id and ip_id in ([template::util::tcl_to_sql_list $ip_id_list])"]
        set ip_lists_len [llength $ip_lists]
        if { $ip_lists_len > 1 } {
            set new_ip_id_list [list ]
            for {set j 0} {$j < $ip_lists_len} {incr j} {
                set ip1_list [lindex $ip_lists $j]
                set ip_id [lindex $ip1_list 4]
                lappend new_ip_id_list $ip_id
                foreach ip_var $ip_var_list {
                    # Adding ip_id to field_name to prevent name collison in returnning array.
                    set obj_arr(${ip_var}_${ip_id}) [lindex $ip1_list $i]
                    incr i
                }
            }
            # Just add the ip_ids that were found.
            set obj_arr(ip_ids_list) $new_ip_id_list
        } else {
            set ip1_list [lindex $ip_lists 0]
            set obj_arr(ip_id) [lindex $ip1_list 4]
            template::util::list_to_array [lrange $ip1_list 0 end-1] obj_arr $ip1_list
            set i 0
            foreach ip_var $ip_var_list {
                set obj_arr(${ip_var}) [lindex $ip1_list $i]
                incr i
            }
        }
    }
    return $success_p
}

ad_proc -private hf_nc_asset_read {
    asset_id
    instance_id
    arr_name
} {
    Adds elements to an array. Creates array if it doesn't exist.
} {
    upvar 1 $arr_name obj_arr
    set success_p [hf_nc_go_ahead ]
    if { $success_p } {
        # element list
        set as_var_list [list asset_type_id label templated_p template_p flags ns_id ua_id op_status]
        set as_lists [db_list_of_lists hf_as_prop_get1 "select asset_type_id, label, templated_p, template_p, flags, ns_id, ua_id, op_status from hf_assets where instance_id=:instance_id and asset_id=:asset_id"] 
        set as_lists_len [llength $as_var_list]
        if { $as_lists_len > 1 } {
            ns_log Warning "hf_nc_asset_read: multiple assets found with same asset_id '${asset_id}'. This should not happen."
            set success_p 0
        } else {
            set as1_list [lindex $as_lists 0]
            template::util::list_to_array $as1_list obj_arr $as_var_list
        }
    }
    return $success_p
}


ad_proc -private hf_nc_dc_read {
    asset_id
    instance_id
    arr_name
} {
    Adds elements to an array. Creates array if it doesn't exist.
} {
    upvar 1 $arr_name obj_arr
    set success_p [hf_nc_go_ahead ]
    if { $success_p } {
        # element list
        set dc_var_list [list affix description]
        set dc_lists [db_list_of_lists hf_data_center_prop_get1 "select affix, description from hf_data_centers where instance_id=:instance_id and dc_id=:asset_id)"]
        set dc_lists_len [llength $dc_lists_len]
        if { $dc_lists_len > 1 } {
            ns_log Warning "hf_nc_dc_read: multiple assets found with same asset_id '${asset_id}'. This should not happen."
            set success_p 0
        } else {
            set dc1_list [lindex $dc_lists 0]
            template::util::list_to_array $dc1_list obj_arr $dc_var_list
        }
    }
    return $success_p
}


ad_proc -private hf_nc_hw_read {
    asset_id
    instance_id
    arr_name
} {
    Adds elements to an array. Creates array if it doesn't exist.
} {
    upvar 1 $arr_name obj_arr
    set success_p [hf_nc_go_ahead ]
    if { $success_p } {
        # element list
        set hw_var_list [list system_name backup_sys os_id ni_id]
        set hw_lists [db_list_of_lists hf_hardware_prop_get1 "select system_name, backup_sys, os_id, ns_id from hf_hardware where instance_id=:instance_id and hw_id=:asset_id)"]
        set hw_lists_len [llength $hw_var_list]
        if { $hw_lists_len > 1 } {
            ns_log Warning "hf_nc_hw_read: multiple assets found with same asset_id '${asset_id}'. This should not happen."
            set success_p 0
        } else {
            set hw1_list [lindex $hw_lists 0]
            temmplate::util::list_to_array $hw1_list obj_arr $hw_var_list
        }
    }
    return $success_p
}

ad_proc -private hf_nc_ni_read {
    asset_id
    instance_id
    arr_name
} {
    Adds elements to an array. Creates array if it doesn't exist.
} {
    upvar 1 $arr_name obj_arr
    set success_p [hf_nc_go_ahead ]
    if { $success_p } {
        set ni_id_list [list ]
        # element list
        set ni_var_list [list os_dev_ref bia_mac_address ul_mac_address ipv4_addr_range ipv6_addr_range ]
        if { ![info exists obj_arr(asset_type_id)] } {
            set obj_arr(asset_type_id) [hf_nc_asset_type_id $asset_id]
        }
        if { [info exists obj_arr(asset_type_id) ] && $obj_arr(asset_type_id) ne "" } {
            switch -exact -- $obj_arr(asset_type_id) {
                dc {
                    set ni_id_list [db_lists hf_dc_ni_map_nc_read "select ni_id from hf_dc_ni_map where instance_id=:instance_id and dc_id=:asset_id"] 
                    
                }
                hw {
                    set ni_id_list [db_lists hf_hw_ni_map_nc_read "select ni_id from hf_hw_ni_map where instance_id=:instance_id and hw_id=:asset_id"] 
                }
            }
        }
        set ni_lists [db_list_of_lists hf_network_interfaces_prop_get1 "select os_dev_ref, bia_mac_address, ul_mac_address, ipv4_addr_range, ipv6_addr_range, ni_id from hf_network_interfaces where instance_id=:instance_id and ni_id in ([template::util::tcl_to_sql_list $ni_id_list])"]
        set ni_lists_len [llength $ni_lists]
        if { $ni_lists_len > 1 } {
            set new_ni_id_list [list ]
            for {set j 0} {$j < $ni_lists_len} {incr j} {
                set ni1_list [lindex $ni_lists $j]
                lappend new_ni_id_list [lindex $ni1_list 5]
                foreach ni_var $ni_var_list {
                    # Adding ni_id to field_name to prevent name collison in returnning array.
                    set obj_arr(${ni_var}_${ni_id}) [lindex $ni1_list $i]
                    incr i
                }
            }
            set obj_arr(ni_ids_list) $new_ni_id_list
        } else {
            set ni1_list [lindex $ni_lists 0]
            set obj_arr(ni_id) [lindex $ni1_list 5]
            template::util::list_to_array [lrange $ni1_list 0 end-1] ob_arr $ni_var_list
        }
    }
    return $success_p
}

ad_proc -private hf_nc_os_read {
    os_id
    instance_id
    arr_name
} {
    Adds elements to an array. Creates array if it doesn't exist.
} {
    upvar 1 $arr_name obj_arr
    set success_p [hf_nc_go_ahead ]
    if { $success_p } {
        # element list
        set os_var_list [list os_label os_brand os_version os_kernel os_orphaned_p os_requires_upgrade_p]
        set os_lists [db_list_of_lists hf_operating_systems_prop_get1 "select label, brand, version, kernel, orphaned_p, requires_upgrade_p from hf_operating_systems where instance_id=:instance_id and os_id=:os_id"]
        set os1_list [lindex $os_lists 0]
        tempate::util::list_to_array $os1_list obj_arr $os_var_list
    }
    return $success_p
}

ad_proc -private hf_nc_vm_read {
    asset_id
    instance_id
    arr_name
} {
    Adds elements to an array. Creates array if it doesn't exist.
} {
    upvar 1 $arr_name obj_arr
    set success_p [hf_nc_go_ahead ]
    if { $success_p } {
        # element list
        set vm_var_list [list domain_name type_id resource_path mount_union ip_id ni_id os_id]
        set vm_lists [db_list_of_lists hf_virtual_machines_prop_get1 "select domain_name, type_id, resource_path, mount_union, ip_id, ni_id, ns_id, os_id from hf_virtual_machines where instance_id=:instance_id and vm_id=:vm_id"]
        set vm_lists_len [llength $vm_lists]
        if { $vm_lists_len > 1 } {
            ns_log Warning "hf_nc_vm_read: multiple assets found with same asset_id '${asset_id}'. This should not happen."
            set success_p 0
        } else {
            set vm1_list [lindex $vm_lists 0]
            template::util::list_to_array $mv1_list obj_arr $vm_var_list
        }
    }
    return $success_p
}


ad_proc -private hf_nc_vh_read {
    asset_id
    instance_id
    arr_name
} {
    Adds elements to an array. Creates array if it doesn't exist.
} {
    upvar 1 $arr_name obj_arr
    set success_p [hf_nc_go_ahead ]
    if { $success_p } {
        # element list
        set vh_var_list [list ua_id ns_id domain_name ]
        set vh_lists [db_list_of_lists hf_vh_prop_get1 "select ua_id, ns_id, domain_name from hf_vhosts where instance_id=:instance_id and vh_id=:asset_id"]
        set vh_lists_len [llength $vh_list]
        if { $vh_lists_len > 1 } {
            ns_log Warning "hf_nc_vh_read: multiple assets found with same asset_id '${asset_id}'. This should not happen."
            set success_p 0
        } else {
            set vh1_list [lindex $vh_lists 0]
            template::util::list_to_array $vh1_list obj_arr $vh_var_list
            if { ![info exists obj_arr(vm_id)] } {
                set has_vm_p [db_0or1row hf_vm_vh_map_nc_read "select vm_id from hf_vm_vh_map where vh_id=:asset_id and instance_id=:instance_id"]
                if { $has_vm_p } {
                    set obj_arr(vm_id) $vm_id
                }
            }
        }
    }
    return $success_p
}


ad_proc -private hf_nc_ns_read {
    ns_id
    instance_id
    arr_name
} {
    Adds elements to an array. Creates array if it doesn't exist.
} {
    upvar 1 $arr_name obj_arr
    set success_p [hf_nc_go_ahead ]
    if { $success_p } {
        # element list
        set ns_var_list [list active_p name_record ]
        set ns_lists [db_list_of_lists hf_ns_prop_get1 "select active_p name_record from hf_ns_records where instance_id=:instance_id and id=:ns_id"]
        set ns_lists_len [llength $ns_lists]
        if { $ns_var_len > 1 } {
            ns_log Warning "hf_nc_ns_read: multiple assets found with same asset_id '${asset_id}'. This should not happen."
            set success_p 0
        } else {
            set ns1_list [lindex $ns_lists 0]
            template::util::list_to_array $ns1_list obj_arr $ns_var_list
        }
    }
    return $success_p
}


ad_proc -private hf_nc_ss_read {
    asset_id
    instance_id
    arr_name
} {
    Adds elements to an array. Creates array if it doesn't exist.
} {
    upvar 1 $arr_name obj_arr
    set success_p [hf_nc_go_ahead ]
    if { $success_p } {
        # element list
        set ss_var_list [list server_name service_name daemon_ref protocol port ua_id ss_type ss_subtype ss_undersubtype ss_ultrasubtype config_uri memory_bytes ]
        set ss_lists [db_list_of_lists hf_ss_prop_get1 "select server_name, service_name, daemon_ref, protocol, port, ua_id, ss_type, ss_subtype, ss_undersubtype, ss_ultrasubtype, config_uri, memory_bytes, ss_id from hf_services where instance_id=:instance_id and ( ss_id=:asset_id or ss_id in (select ss_id from hf_ss_map where instance_id=:instance_id and hf_id=:asset_id)"]
        set ss_lists_len [llength $ss_lists]
        if { $ss_lists_len > 1 } {
            set new_ss_id_list [list ]
            for {set j 0} {$j < $ss_lists_len} {incr j} {
                set ss1_list [lindex $ss_lists $j]
                lappend new_ss_id_list [lindex $ss1_list 12]
                foreach ss_var $ss_var_list {
                    # Adding ss_id to field_name to prevent name collison in returnning array.
                    set obj_arr(${ss_var}_${ss_id}) [lindex $ss1_list $i]
                    incr i
                }
            }
            set obj_arr(ss_ids_list) $new_ss_id_list
        } else {
            set ss1_list [lindex $ss_lists 0]
            set obj_arr(ss_id) [lindex $ss1_list 12]
            template::util::list_to_array [lrange $ss1_list 0 end-1] obj_arr $ss_var_list
        }
    }
    return $success_p
}

ad_proc -private hf_nc_ns_read {
    asset_id
    instance_id
    arr_name
} {
    Adds elements to an array. Creates array if it doesn't exist.
} {
    upvar 1 $arr_name obj_arr
    set success_p [hf_nc_go_ahead ]
    if { $success_p } {
        # element list
        set ns_var_list [list active_p name_record ]
        set ns_lists [db_list_of_lists hf_ns_prop_get1 "select active_p name_record from hf_ns_records where instance_id=:instance_id and id=:asset_id"]
        set ns_lists_len [llength $ns_lists]
        if { $ns_lists_len > 1 } 
        ns_log Warning "hf_nc_ns_read: multiple records found with same asset_id '${asset_id}'. This should not happen."
        set success_p 0
    } else {
        set ns1_lists [lindex $ns_lists 0]
        template::util::list_to_array $ns1_list obj_arr $ns_var_list
    }
    return $success_p
}


ad_proc -private hf_asset_properties {
    asset_id
    array_name
    {instance_id ""}
    {user_id ""}
} {
    Passes properties of an asset into array_name; creates array_name if it doesn't exist. Returns 1 if asset is returned, otherwise returns 0.
} {
    upvar $array_name named_arr
    set success_p [hf_nc_go_ahead ]
    if { $success_p } {

        set asset_type_id [hf_nc_asset_type_id $asset_id]
        if { $asset_type_id eq "" } {
            set success_p 0
        }
        if { $success_p } {
            # Don't use hf_* API here. Create queries specific to system call requirements.
            switch -exact -- $asset_type_id {
                dc {
                    # Subtle difference between dc and hw.
                    # A dc can have 1 property exposed without
                    # necessitating a specific hw asset.
                    #set asset_prop_list hf_dcs $instance_id "" $asset_id
                    hf_nc_asset_read $asset_id $instance_id named_arr
                    hf_nc_hw_read $asset_id $instance_id named_arr
                    set named_arr(ns_id) ""
                    set named_arr(os_id) ""
                    hf_nc_ni_read $asset_id $instance_id named_arr
                    hf_nc_ip_read $asset_id $instance_id named_arr
                    hf_nc_os_read $named_arr(os_id) $instance_id named_arr
                }
                hw {
                    #set asset_prop_list [hf_hws $instance_id "" $asset_id]
                    hf_nc_asset_read $asset_id $instance_id named_arr
                    if { [hf_nc_hw_read $asset_id $instance_id named_arr ] } {
                        set named_arr(ns_id) ""
                        set named_arr(os_id) ""
                        hf_nc_ni_read $asset_id $instance_id named_arr
                        hf_nc_ip_read $asset_id $instance_id named_arr
                        hf_nc_os_read $named_arr(os_id) $instance_id named_arr
                    }
                }
                vm {
                    #set asset_prop_list [hf_vms $instance_id "" $asset_id]
                    # split query into separate tables to handle more dynamics
                    # h_assets  hf_asset_ip_map hf_ip_addresses hf_virutal_machines hf_ua hf_up 
                    hf_nc_asset_read $asset_id $instance_id named_arr
                    if { [hf_nc_vm_read $asset_id $instance_id named_arr] } {
                        hf_nc_ip_read $vm_id $instance_id named_arr
                        hf_nc_os_read $named_arr(os_id) $instance_id named_arr
                        hf_nc_ns_read $asset_id $instance_id named_arr
                        hf_ua_read $named_arr(ua_id) "" "" $instance_id 1 named_arr
                    }
                }
                vh {
                    #set asset_prop_list [hf_vhs $instance_id "" $asset_id]
                    set named_arr(os_id) ""
                    hf_nc_asset_read $vm_id $instance_id named_arr
                    if { [hf_nc_vh_read $vm_id $instance_id named_arr] } {
                        hf_nc_ip_read $vm_id $instance_id named_arr
                        hf_nc_os_read $named_arr(os_id) $instance_id named_arr
                        hf_nc_vm_read $asset_id $instance_id named_arr
                        hf_nc_ns_read $asset_id $instance_id named_arr
                        hf_ua_read $named_arr(ua_id) "" "" $instance_id 1 named_arr
                    }
                }
                hs,ss {
                    # see ss, hs hosting service is saas: ss
                    # hf_ss_map ss_id, hf_id, hf_services,
                    # maybe ua_id hf_up
                    hf_nc_asset_read $vm_id $instance_id named_arr
                    if { [hf_nc_ss_read $asset_id $instance_id named_arr] } {
                        if { [info exists named_arr(vm_id) ] } {
                            set vm_id $named_arr(vm_id)
                            hf_nc_vm_read $vm_id $instance_id named_arr
                            hf_nc_ip_read $vm_id $instance_id named_arr
                            hf_nc_os_read $named_arr(os_id) $instance_id named_arr

                            hf_nc_ns_read $asset_id $instance_id named_arr
                            hf_ua_read $named_arr(ua_id) "" "" $instance_id 1 named_arr
                        }
                    }
                    ns {
                        # ns , custom domain name service records
                        hf_nc_ns_read $asset_id $instance_id named_arr
                    }
                    ot { 
                        # other, nothing specific. Supply generic info.
                        hf_nc_asset_read $asset_id $instance_id named_arr
                    }
                    
                    default {
                        ns_log Warning "hf_asset_properties: missing useful asset_type_id in switch options. asset_type_id '${asset_type_id}'"
                    }
             
                }
            }
        } else {
            ns_log Warning "hf_asset_properties: no asset_id '${asset_id}' found. instance_id '${instance_id}' user_id '${user_id}' array_name '${array_name}'"
        }
    }
    return $success_p
}

ad_proc -private hf_ua_read {
    {ua_id ""}
    {ua ""}
    {connection_type ""}
    {instance_id ""}
    {r_up_p "0"}
    {arr_nam "hf_ua_arr"}
} {
    Reads ua by ua_id or ua
    See hf_ua_ck for access credential checking. hf_ua_read is for admin only.
    Returns 1 if successful, otherwise 0.
    Values returned to calling environment in array hf_ua_arr.
    if r_up_p true, includes password.
} {
    upvar 1 $arr_nam hu_arr
    set success_p [hf_nc_go_ahead ]
    if { $success_p } {
        # validation and limits
        if { ![qf_is_natural_number $instance_id] } {
            # set instance_id package_id
            # fail if it is not provided.
            set instance_id 0
        }
        if { ![qf_is_natural_number $ua_id] } {
            set ua_id ""
        }
        set connection_type [string range $connection_type 0 23]
        if { $ua ne "" } {
            if { ![hf_are_printable_characters_q $details] } {
                set ua ""
            }
        }
        # ua_id or ua && conn type
        if { $ua_id ne "" } {
            # read
            if { $r_up_p } {
                set success_p [db_0or1row hf_ua_id_read_w_up "select ua.details as ua, ua.connection_type, up.details as hfup from hf_ua ua, hf_up up, hf_ua_up_map hm where ua.instance_id=:instance_id and ua.ua_id=ua_id and ua.instance_id=up.instance_id and ua.ua_id=hm.ua_id and hm.up_id=up.up_id"  ]
            } else {
                set hfup ""
                set success_p [db_0or1row hf_ua_id_read "select details as ua, connection_type from hf_ua where instance_id =:instance_id and ua_id=:ua_id" ]
            }
        }
        set demystify_proc [parameter::get -package_id $instance_id -parameter DemystifyProc -default hf_demystify]
        set demystify_key [parameter::get -package_id $instance_id -parameter DemystifyKey -default ""]
        set decode_proc [parameter::get -package_id $instance_id -parameter DecodeProc -default hf_decode]
        set decode_key [parameter::get -package_id $instance_id -parameter DecodeKey -default ""]
        if { $success_p == 0 && $ua ne "" } {
            # read
            if { $r_up_p } {

                set ua_ik [safe_eval [list ${demystify_proc} ${demystify_key} $details]]
                set success_p [db_0or1row hf_ua_read_w_up "select ua.ua_id, ua.connection_type, up.details as hfup from hf_ua ua, hf_up up, hf_ua_up_map hm where ua.instance_id=:instance_id and ua.ua=:ua_ik and ua.instance_id=up.instance_id and ua.ua_id=hm.ua_id and hm.up_id=up.up_id"  ]
            } else {
                set hfup ""
                set success_p [db_0or1row hf_ua_read "select ua_id, connection_type from hf_ua where instance_id =:instance_id and ua=:ua" ]
            }    
        }
        if { $success_p } {
            if { $details eq "" } {
                set details [safe_eval [list ${demystify_proc} ${demystify_key} $ua]]
            }
            if { $r_up_p } {
                set up [safe_eval [list ${decode_proc} ${decode_key} $hfup]
            }
            set i_list [list ua_id ua connection_type instance_id up details]
            foreach i $i_list {
                set hf_ua_arr($i) [set $i]
            }
        }
    }
    return $success_p
}

ad_proc -private hf_ss_copy {
    asset_id
    asset_label_new
    {instance_id ""}
    {new_asset_id ""}
} {
    Copy a templated service.
} {
    set success_p [hf_nc_go_ahead "" "ss"]
    set ua_id_new ""
    set ns_id_new ""
    set ss_list hf_ss_read $asset_id $instance_id
    qf_lists_to_vars $ss_list [hf_ss_keys]
    if { $ua_id ne "" } {
        hf_ua_read $ua_id "" "" $instance_id
        # ua_id ua connection_type instance_id up details
        #hf_ua_write $ua $connection_type "" $instance_id
        template::util::array_to_vars hf_ua_arr
        set ua_id_new [hf_ua_write $ua $connection_type "" $instance_id]
        hf_up_write $ua_id_new $up $instance_id
    }
    if { $ns_id ne "" } {
        set ns_list [lindex $ns_id_lists [hf_ns_read $ns_id]]
        qf_lists_to_vars $ns_list [list ns_id active_p name_record]
        set new_ns_id [hf_ns_write "" $name_record $active_p $instance_id]
    }
    if { $asset_label_new eq "" } {
        set asset_label_new $name
    }
    set ss_id_new [db_ss_write "" $asset_label_new $title $asset_type_id $keywords $description $content $comments $trashed_p $trashed_by $template_p $templated_p $publish_p $monitor_p $popularity $triage_priority $op_status $ua_id_new $ns_id_new $qal_product_id $qal_customer_id $instance_id $user_id $last_modified $created $ss_server_name $ss_service_name $ss_daemon_ref $ss_protocol $ss_port $ss_ua_id $ss_ss_type $ss_ss_subtype $ss_ss_undersubtype $ss_ss_ultrasubtype $ss_config_uri $ss_memory_bytes $ss_details]
    if { [hf_asset_id_exists $new_asset_id "" $instance_id] } {
        db_dml { hf_ss_map_insert_1 insert into hf_ss_map
            (instance_id,ss_id,hf_id)
            values (:instance_id,:ss_id_new,:new_asset_id)
        }
    }
    # Each asset can have multiple ss_id
    set ss_id_list [hf_ss_ids $ss_id $instance_id]
    foreach child_ss_id $ss_id_list {
        set ua_id_new ""
        set ns_id_new ""
        set child_ss_list hf_ss_read $child_ss_id $instance_id
        qf_lists_to_vars $child_ss_list [hf_ss_keys]
        if { $ua_id ne "" } {
            hf_ua_read $ua_id "" "" $instance_id
            # ua_id ua connection_type instance_id up details
            #hf_ua_write $ua $connection_type "" $instance_id
            template::util::array_to_vars hf_ua_arr
            set ua_id_new [hf_ua_write $ua $connection_type "" $instance_id]
            hf_up_write $ua_id_new $up $instance_id
        }
        if { $ns_id ne "" } {
            set ns_list [lindex $ns_id_lists [hf_ns_read $ns_id]]
            qf_lists_to_vars $ns_list [list ns_id active_p name_record]
            set ns_id_new [hf_ns_write "" $name_record $active_p $instance_id]
        }
        set ss_ss_id_new [db_ss_write "" $name $title $asset_type_id $keywords $description $content $comments $trashed_p $trashed_by $template_p $templated_p $publish_p $monitor_p $popularity $triage_priority $op_status $ua_id_new $ns_id_new $qal_product_id $qal_customer_id $instance_id $user_id $last_modified $created $ss_server_name $ss_service_name $ss_daemon_ref $ss_protocol $ss_port $ss_ua_id $ss_ss_type $ss_ss_subtype $ss_ss_undersubtype $ss_ss_ultrasubtype $ss_config_uri $ss_memory_bytes $ss_details]
        db_dml { hf_ss_map_insert_1 insert into hf_ss_map
            (instance_id,ss_id,hf_id)
            values (:instance_id,:ss_id_new,:ss_ss_id_new)
        }
    }

    return $success_p
}


ad_proc -private hf_vh_copy {
    asset_id
    asset_label_new
    {instance_id ""}
    {new_vm_id ""}
} {
    Copy a templated virtual host record. Associates with same virtual machine as original, unless specified in new_vm_id.
} {
    set success_p [hf_nc_go_ahead "" "vh"]
    set ua_id_new ""
    set ns_id_new ""
    set vh_list hf_vh_read $asset_id $instance_id
    qf_lists_to_vars $vh_list [hf_vh_keys]
    if { $ua_id ne "" } {
        hf_ua_read $ua_id "" "" $instance_id
        # ua_id ua connection_type instance_id up details
        #hf_ua_write $ua $connection_type "" $instance_id
        template::util::array_to_vars hf_ua_arr
        set ua_id_new [hf_ua_write $ua $connection_type "" $instance_id]
        hf_up_write $ua_id_new $up $instance_id
    }
    if { $ns_id ne "" } {
        set ns_list [lindex $ns_id_lists [hf_ns_read $ns_id]]
        qf_lists_to_vars $ns_list [list ns_id active_p name_record]
        set ns_id_new [hf_ns_write "" $name_record $active_p $instance_id]
    }
    set as_ua_id $ua_id
    if { $v_ua_id ne "" } {
        hf_ua_read $v_ua_id "" "" $instance_id
        # ua_id ua connection_type instance_id up details
        #hf_ua_write $ua $connection_type "" $instance_id
        template::util::array_to_vars hf_ua_arr
        set v_ua_id_new [hf_ua_write $ua $connection_type "" $instance_id]
        hf_up_write $v_ua_id_new $up $instance_id
    }
    if { $v_ns_id ne "" } {
        set v_ns_list [lindex $ns_id_lists [hf_ns_read $v_ns_id]]
        qf_lists_to_vars $ns_list [list v_ns_id active_p name_record]
        set v_ns_id_new [hf_ns_write "" $name_record $active_p $instance_id]
    }
    if { [hf_asset_id_exists $new_vm_id "vm" $instance_id] } {
        set vm_id $new_vm_id
    }
    set vh_id_new [db_vh_write "" $name $title $asset_type_id $keywords $description $content $comments $trashed_p $trashed_by $template_p $templated_p $publish_p $monitor_p $popularity $triage_priority $op_status $ua_id_new $ns_id_new $qal_product_id $qal_customer_id $instance_id $user_id $last_modified $created $template_id $v_ua_id_new $v_ns_id_new $domain_name $details $vm_id]

    return $success_p
}


ad_proc -private hf_vm_copy {
    asset_id
    asset_label_new
    {instance_id ""}
} {
    Copy a VM and all its properties.
} {
    set success_p [hf_nc_go_ahead "" "vm"]
    set ua_id_new ""
    set ns_id_new ""
    set vm_list hf_vm_read $asset_id $instance_id
    qf_lists_to_vars $vm_list [hf_vm_keys]
    if { $ua_id ne "" } {
        hf_ua_read $ua_id "" "" $instance_id
        # ua_id ua connection_type instance_id up details
        #hf_ua_write $ua $connection_type "" $instance_id
        template::util::array_to_vars hf_ua_arr
        set ua_id_new [hf_ua_write $ua $connection_type "" $instance_id]
        hf_up_write $ua_id_new $up $instance_id
    }
    if { $ns_id ne "" } {
        set ns_id ""
        #        set ns_list \[lindex $ns_id_lists \[hf_ns_read $ns_id\]\]
        #        qf_lists_to_vars $ns_list \[list ns_id active_p name_record\]
        #        set ns_id_new \[hf_ns_write "" $name_record $active_p $instance_id\]
    }
    if { $vm_ns_id ne "" && $vm_ns_id ne $ns_id } {
        #        set vm_ns_list \[lindex $ns_id_lists \[hf_ns_read $ns_id\]\]
        #        qf_lists_to_vars $ns_list \[list vm_ns_id vm_active_p vm_name_record\]
        #        set vm_ns_id_new \[hf_ns_write "" $vm_name_record $vm_active_p $instance_id\]
    }
    if { $vm_ip_id ne "" } {
        set vm_ip_id "" 
    }
    if { $vm_ni_id ne "" } {
        set vm_ni_id ""
    }
    if { $asset_label_new eq "" } {
        set asset_label_new $name
    }
    set vm_id_new [db_vm_write "" $asset_label_new $title $asset_type_id $keywords $description $content $comments $trashed_p $trashed_by $template_p $templated_p $publish_p $monitor_p $popularity $triage_priority $op_status $ua_id $ns_id $qal_product_id $qal_customer_id $instance_id $user_id $last_modified $created $vm_domain_name $vm_ip_id $vm_ni_id $vm_ns_id $vm_type_id $vm_resource_path $vm_mount_union $vm_details]
    # Copy all vhosts associated with vm
    set vh_ids_list [db_list hf_vm_vh_ids_read "select vh_id from hf_vm_vh_map where instance_id=:instance_id and asset_id=:vm_id"]
    foreach vm_vh_id $vh_ids_list {
        hf_vh_copy $vm_vh_id "" $instance_id $vm_id_new
    }
    # copy ss associated with vm
    set ss_ids_list [db_list hv_vm_ss_ids_read "select ss_id from hf_ss_map where instance_id=:instance_id and hf_id=:vm_id"]
    foreach vm_ss_id $ss_ids_list {
        hf_ss_copy $vm_ss_id "" $instance_id $vm_id_new
    }
    return $success_p
}


ad_proc -private hf_nc_proc_context_set {
} {
    Set floating context
} {
    set a [ns_thread id]
    upvar 1 $a b
    set b $a
    set n "::hf::monitor::do::"
    set ${n}${a} $a
    #ns_log Notice "hf_nc_proc_context_set: context set: '${a}' info level '[info level]' namespace current '[namespace current]'"
    return 1
}

ad_proc -private hf_nc_proc_in_context_q {
    {namespace_name "::hf::monitor::do::"}
} {
    Checks if a scheduled proc is running in context of its namespace.
} {
    #    {namespace_name "::"}
    # To work as expected, each proc in namespace must call this function
    set a [ns_thread id]
    upvar 3 $a $a
    #ns_log Notice "acs_nc_proc_in_context_q: local vars [info vars]"
    if { ![info exists $a] || ![info exists ${namespace_name}${a} ] || [set $a] ne [set ${namespace_name}${a} ]} {
        ns_log Warning "hf_nc_proc_in_context_q: namespace '${namespace_name}' no! ns_thread id '${a}' info level '[info level]' namespace current '[namespace current]' "
       # ns_log Notice "::${a} [info exists ::${a}] "
       # ns_log Notice "::hf::${a} [info exists ::hf::${a}] "
       # ns_log Notice "::hf::monitor::${a} [info exists ::hf::monitor::${a}] "
       # ns_log Notice "::hf::monitor::do::${a} [info exists ::hf::monitor::do::${a}] "
       # ns_log Warning " set ${namespace_name}$a '[set ${namespace_name}${a} ]'"
        #ad_script_abort
        set context_p 0
    } else {
        upvar 2 $a $a
        set context_p 1
    }
    #ns_log Notice "hf_nc_proc_in_context_q: ns_thread name [ns_thread name] ns_thread id [ns_thread id] ns_info threads [ns_info threads] ns_info scheduled [ns_info scheduled]"
    return $context_p
}

#ad_proc -private hf_nc_proc_that_tests_context_checking {
#} {
#    This is a dummy proc that checks if context checker is working.
#} {
#    ns_log Notice "hf_nc_proc_that_tests_context_checking: info level '[info level]' namespace current '[namespace current]'"
#    set allowed_p [hf_nc_go_ahead ]
#    ns_log Notice "hf_nc_proc_that_tests_context_checking: context check. PASSED."
#}

#ad_proc -private hf_check_randoms {
#    {context ""}
#} {
#    Compares output of random functions, to see if there is a difference 
#    when run in scheduled threads vs. connected threads.
#} {
#    set a [expr { srand(round(fmod([clock clicks],[clock seconds]))) } ]
#    ns_log Notice "hf_check_randoms: context [ns_thread name]: ${context}"
#    ns_log Notice "hf_check_randoms: clock clicks '[clock clicks]' '[clock clicks]' '[clock clicks]'"
#     ns_log Notice "hf_check_randoms: clock seconds '[clock seconds]' '[clock seconds]' '[clock seconds]'"
#    ns_log Notice "hf_check_randoms: srand '[expr { srand(round(fmod([clock clicks],[clock seconds]))) } ]' '[expr { srand(round(fmod([clock clicks],[clock seconds]))) } ]' '[expr { srand(round(fmod([clock clicks],[clock seconds]))) } ]'"
#    ns_log Notice "hf_check_randoms: rand '[expr { rand() } ]' '[expr { rand() } ]' '[expr { rand() } ]'"
#    ns_log Notice "hf_check_randoms: random '[random]' '[random]' '[random]'"
#}

