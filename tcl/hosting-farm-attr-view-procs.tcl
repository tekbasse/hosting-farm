#hosting-farm/tcl/hosting-farm-attr-view-procs.tcl
ad_library {

    views and constructors for hosting-farm asset attributes
    @creation-date 28 May 2016
    @Copyright (c) 2014-2016 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl-2.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com

}


# Asset attributes can be created, revised, trashed and deleted.
# Deleted option should only be available if an attribute is trashed. 


ad_proc -private hf_oses {
    {instance_id ""}
    {os_id_list ""}
    {orphaned_p 1}
    {requires_upgrade_p 1}
} {
    returns an ordered list of lists of operating systems and their direct properties. Defaults to all oses. Set orphaned_p 0 to not include orphaned ones. Set requires_upgrade_p to 0 to only include current, supported ones.
    Ordered list: os_id label brand version kernel orphaned_p requires_upgrade_p description
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    # no permissions needed     set user_id \[ad_conn user_id\]
    # build sql_extra
    set sql_extra ""
    if { $orphaned_p ne 1 } {
        set orphaned_p 0
        append sql_extra " and ( orphaned_p is null or orphaned_p <> '1' )"
    }
    if { $requires_upgrade_p ne 1 } {
        set requires_upgrade_p 0
        append sql_extra " and ( requires_upgrade_p is null or requires_upgrade_p <> '1' )"
    }
    if { $os_id_list ne "" } {
        set clean_os_id_list [list ]
        foreach os_id $os_id_list {
            # verify os_id_list elements are numbers
            if { [qf_is_natural_number $os_id] } {
                lappend clean_os_id_list $os_id
            }
        }
        if { [llength $clean_os_id_list] > 0 } {
            append sql_extra " and os_id in ([template::util::tcl_to_sql_list $clean_os_id_list])"
        }
    }
    set os_detail_list [db_list_of_lists hf_operating_systems_get "select os_id, label, brand, version, kernel, orphaned_p, requires_upgrade_p, description from hf_operating_systems where instance_id = :instance_id ${sql_extra}"]
    return $os_detail_list
}


ad_proc -private hf_asset_type_read {
    type_id_list
    {instance_id ""}
} {
    returns an existing asset_type in a list of lists: {label1, title1, description1} {labelN, titleN, descriptionN} or blank list if none found. Bad id's are ignored.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    # validate/filter the asset_type_id_list for nonqualifying reference types
    set new_as_type_id_list [list ]
    foreach asset_type_id $type_id_list {
        if { [ad_var_type_check_number_p $asset_type_id] } {
            lappend new_as_type_id_list $asset_type_id
        }
    }
    
    set return_list_of_lists [db_list_of_lists hf_asset_type_read "select id, label, title, description from hf_asset_type where instance_id =:instance_id and id in ([template::util::tcl_to_sql_list $new_as_type_id_list])" ]
    
    return $return_list_of_lists
}

ad_proc -private hf_asset_types {
    {label_match ""}
    {instance_id ""}
} {
    returns matching asset types as a list of list: {id,label,title,description}, if label is nonblank, returns asset types that glob match the passed label value via tcl match.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set all_asset_types_list_of_lists [db_list_of_lists hf_asset_types_get {select id,label, title, description from hf_asset_type where instance_id =:instance_id} ]
    if { $label_match ne "" } {
        set return_list_of_lists [list ]
        foreach asset_type_list $all_asset_types_list_of_lists {
            if { [string match -nocase $label_match [lindex $asset_type_list 1]] } {
                lappend return_list_of_lists $asset_type_list
            }
        }
    } else {
        set return_list_of_lists $all_asset_types_list_of_lists
    }
    return $return_list_of_lists
}




ad_proc -private hf_dc_read {
    {dc_id_list ""}
} {
    Returns records from hf_data_centers as a list of lists. See hf_dc_keys
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set dc_ids_list [hf_list_filter_by_natural_number $dc_id_list]
    set return_lists [list ]
    foreach dc_id $dc_id_list {
        set read_p [hf_ui_go_ahead_q read dc_id "" 0]
        if { $read_p } {
            set rows_list [db_list_of_lists hf_dc_detail_get "select [hf_dc_keys ","] from hf_data_centers where instance_id =:instance_id and dc_id=:dc_id"]
            set row_list [lindex $rows_list 0]
            if { [llength $row_list] > 0 } {
                lappend return_lists $row_list
            }
        }
    }
    return $return_lists
}


ad_proc -private hf_hw_read {
    {hw_id_list ""}
} {
    Returns records from hf_hardware as a list of lists. See hf_hw_keys
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set hw_ids_list [hf_list_filter_by_natural_number $hw_id_list]
    set return_lists [list ]
    foreach hw_id $hw_id_list {
        set read_p [hf_ui_go_ahead_q read hw_id "" 0]
        if { $read_p } {
            set rows_list [db_list_of_lists hf_hw_detail_get "select [hf_hw_keys ","] from hf_hardware where instance_id =:instance_id and hw_id=:hw_id"]
            set row_list [lindex $rows_list 0]
            if { [llength $row_list] > 0 } {
                lappend return_lists $row_list
            }
        }
    }
    return $return_list
}


##code
ad_proc -private hf_vm_read {
    vm_id
    {instance_id ""}
} {
    reads full detail of one vm. This is not redundant to hf_vms. This accepts only 1 id and includes all attributes and no summary counts of dependents.
    Returns ordered list: label,name,asset_type_id,keywords,description,content,comments,trashed_p,trashed_by,template_p,templated_p,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created,template_id vm_domain_name, vm_ip_id, vm_ni_id, vm_ns_id, vm_os_id, vm_type_id, vm_resource_path, vm_mount_union, vm_details

} {
    hf_ui_go_ahead_q read vm_id

    set attribute_list [hf_asset_read $vm_id $instance_id $user_id]
    # Returns asset contents of asset_id. Returns asset as list of attribute values: label,name,asset_type_id,keywords,description,content,comments,trashed_p,trashed_by,template_p,templated_p,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created,template_id
    set asset_type_id [lindex $attribute_list 2]
    # is asset_id of type vm?
    set return_list [list ]
    if { $asset_type_id eq "vm" } {
        set return_list $attribute_list
        # get, append remaining detail

        # hf_virtual_machines.instance_id, vm_id, domain_name, ip_id, ni_id, ns_id, type_id, resource_path, mount_union, details
        set vm_detail_list [db_list_of_lists hf_vm_detail_get "select domain_name, ip_id, ni_id, ns_id, os_id, type_id, resource_path, mount_union, details from hf_virtual_machines where instance_id =:instance_id and vm_id =:vm_id"]
        set vm_detail_list [lindex $vm_detail_list 0]
        foreach vm_att_list $vm_detail_list {
            lappend return_list $vm_att_list
        }
    }
    return $return_list
}


ad_proc -private hf_vh_read {
    vh_id
    {instance_id ""}
} {
    reads full detail of one virtual host asset. This is not redundant to hf_vhs. This accepts only 1 id and includes all attributes and no summary counts of dependents.
    Returns ordered list: label,name,asset_type_id,keywords,description,content,comments,trashed_p,trashed_by,template_p,templated_p,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created,template_id,v_ua_id, v_ns_id, domain_name details, vm_id
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]

    set attribute_list [hf_asset_read $vh_id $instance_id $user_id]
    # Returns asset contents of asset_id. Returns asset as list of attribute values: label,name,asset_type_id,keywords,description,content,comments,trashed_p,trashed_by,template_p,templated_p,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created,template_id
    set asset_type_id [lindex $attribute_list 2]
    # is asset_id of type vh?
    set return_list [list ]
    if { $asset_type_id eq "vh" } {
        set return_list $attribute_list
        # get, append remaining detail
        # from hf_vhosts, hf_vm_vh_map
        set vh_detail_list [db_list_of_lists hf_vh_read1 "select ua_id, ns_id, domain_name, details where instance_id=:instance_id and vh_id=:vh_id"]
        set vh_vm_id [db_1row hf_vh_vm_read1 "select vm_id from hf_vm_vh_map where instance_id=:instance_id and vh_id=:vh_id"]
        set vh_detail_list [lindex $vh_detail_list 0]
        foreach vh_att_list $vh_detail_list {
            lappend return_list $vh_att_list
        }
        lappend $vm_id
    } 
    return $return_list
}


ad_proc -private hf_ss_read {
    ss_id
    {instance_id ""}
} {
    reads full detail of one ss. This is not redundant to hf_sss. This accepts only 1 id and includes all attributes and no summary counts of dependents.
    Returns ordered list: label,name,asset_type_id,keywords,description,content,comments,trashed_p,trashed_by,template_p,templated_p,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created,template_id ss_server_name ss_service_name ss_daemon_ref ss_protocol ss_port ss_ua_id ss_ss_type ss_ss_subtype ss_ss_undersubtype ss_ss_ultrasubtype ss_config_uri ss_memory_bytes ss_details
} {
    hf_ui_go_ahead_q read ss_id

    set attribute_list [hf_asset_read $ss_id $instance_id $user_id]
    # Returns asset contents of asset_id. Returns asset as list of attribute values: label,name,asset_type_id,keywords,description,content,comments,trashed_p,trashed_by,template_p,templated_p,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created,template_id
    set asset_type_id [lindex $attribute_list 2]
    # is asset_id of type ss?
    set return_list [list ]
    if { $asset_type_id eq "ss" } {
        set return_list $attribute_list
        # get, append remaining detail
        # hf_services.instance_id ss_id server_name service_name daemon_ref protocol port ua_id ss_type ss_subtype ss_undersubtype ss_ultrasubtype config_uri memory_bytes details
        set ss_detail_list [db_list_of_lists hf_ss_detail_get "select server_name, service_name, ss_type, ss_subtype, ss_undersubtype, ss_ultrasubtype, daemon_ref, protocol, port, ua_id, config_uri, memory_bytes, details from hf_services where instance_id =:instance_id and ss_id =:ss_id"]
        set ss_detail_list [lindex $ss_detail_list 0]
        foreach ss_att_list $ss_detail_list {
            lappend return_list $ss_att_list
        }
    }
    return $return_list
}


ad_proc -private hf_ip_read {
    ip_id
    {instance_id ""}
} {
    reads full detail of one ip address: ipv4_addr ipv4_status ipv6_addr ipv6_status. This is not redundant to hf_ips. This accepts only 1 id and includes all attributes (no summary counts)
} {
    hf_ui_go_ahead_q read ip_id

    # to check permissions here, would require:
    # get asset_id via a new proc hf_id_of_ip_id, but that would return multiple asset_ids (VMs + machine etc).
    # checking permissions  would require hf_ids_of_ip_id.. and that would be slow for large sets
    # hf_ip_read/write etc should only be called from within a private proc. and is publically available via inet services anyway..

    # get ip data
    set return_list [list ]
    if { [qf_is_natural_number $ip_id ] } {
        set return_list [db_list_of_lists hf_ip_detail_get "select ipv4_addr, ipv4_status, ipv6_addr, ipv6_status from hf_ip_addresses where instance_id =:instance_id and ip_id =:ip_id"]
        set return_list [lindex $return_list 0]
    }
    return $return_list
}


ad_proc -private hf_ni_read {
    {ni_id ""}
    {instance_id ""}
} {
    reads full detail of one ni. This is not redundant to hf_nis. This accepts only 1 ns_id and includes all attributes (no summary counts):  os_dev_ref, ipv4_addr_range, ipv6_addr_range, bia_mac_address, ul_mac_address
} {
    set return_list [list ]
    if { [qf_is_natural_number $ni_id] && [qf_is_natural_number $instance_id] } {
        set return_list [db_list_of_lists hf_network_interfaces_read1 "select os_dev_ref, bia_mac_address, ul_mac_address, ipv4_addr_range, ipv6_addr_range from hf_network_interfaces where instance_id=:instance_id and ni_id =:ni_id"]
        set return_list [lindex $return_list 0]
    }
    return $return_list
}


ad_proc -private hf_os_read {
    {os_id_list ""}
    {instance_id ""}
} {
    reads full detail of OSes; if os_id_list is blank, returns all records. os_id, label, brand, version, kernel, orphaned_p, requires_upgrade_p, description
} {
    set new_os_lists [list ]
    if { [qf_is_natural_number $instance_id] } {
        if { $os_id_list eq "" } {
            set os_lists [db_list_of_lists hf_os_read_inst { select os_id, label, brand, version, kernel, orphaned_p, requires_upgrade_p, description from hf_operating_systems where instance_id =:instance_id } ]
        } else {
            set filtered_ids_list [list ]
            foreach os_id $os_id_list {
                if { [qf_is_natural_number $os_id] } {
                    lappend filtered_ids_list $os_id
                }
            }
            set os_lists [db_list_of_lists hf_os_read_some "select os_id, label, brand, version, kernel, orphaned_p, requires_upgrade_p, description from hf_operating_systems where instance_id =:instance_id and os_id in ([template::util::tcl_to_sql_list $filtered_ids_list])" ]
        }
        # set all *_p values as either 1 or 0
        # this should already be handled via hf_os_write,
        #  but in case data is imported.. code expects consistency.
        set new_os_lists [list ]
        foreach os_list $os_lists {
            set new_list $os_list
            set orphaned_p [lindex $os_list 5]
            set requires_upgrade_p [lindex $os_list 6]
            if { $orphaned_p ne "1" } {
                set new_list [linsert $new_list 5 "0"]
            }
            if { $requires_upgrade_p ne "1" } {
                set new_list [linsert $new_list 6 "0"]
            }
            lappend new_os_lists $new_list
        }
    }
    return $new_os_lists
}


ad_proc -private hf_ns_read {
    {ns_id_list ""}
    {instance_id ""}
} {
    reads full detail of domain records.
} {
    if { [qf_is_natural_number $instance_id] } {
        set ns_lists [list ]
        if { $ns_id_list eq "" } {
            set ns_lists [db_list_of_lists hf_dns_read_inst { select id, active_p, name_record from hf_ns_records where instance_id=:instance_id } ]
        } else {
            set filtered_ids_list [list ]
            foreach ns_id $ns_id_list {
                if { [qf_is_natural_number $ns_id] } {
                    lappend filtered_ids_list $ns_id
                }
            }
            set ns_lists [db_list_of_lists hf_dns_read_some "select id, active_p, name_record from hf_ns_records where instance_id=:instance_id and ns_id in ([template::util::tcl_to_sql_list $filtered_ids_list])" ]
        }
        # set all *_p values as either 1 or 0
        set new_ns_lists [list ]
        foreach ns_list $ns_lists {
            set active_p [lindex $ns_list 1]
            if { $active_p ne "1" } {
                set active_p "0"
            }
            set new_list [lreplace $ns_list 1 1 $active_p]
            lappend new_ns_lists $new_list
        }
    }
    return $new_ns_lists
}



ad_proc -private hf_vm_quota_read {
    {plan_id_list ""}
    {instance_id ""}
} {
    Given plan_id_list, returns list of list of: plan_id description base_storage base_traffic base_memory base_sku over_storage_sku over_traffic_sku over_memory_sku storage_unit traffic_unit memory_unit qemu_memory status_id vm_type max_domain private_vps.
    If plan_id_list is blank, returns all.
} {
    if { [qf_is_natural_number $instance_id] } {
        
        set vmq_lists [list ]
        if { $plan_id_list eq "" } {
            set vmq_lists [db_list_of_lists hf_dvmq_read_inst { select plan_id, description, base_storage, base_traffic, base_memory, base_sku, over_storage_sku, over_traffic_sku, over_memory_sku, storage_unit, traffic_unit, memory_unit, qemu_memory, status_id, vm_type, max_domain, private_vps from hf_vm_quotas where instance_id=:instance_id } ]
        } else {
            set filtered_ids_list [list ]
            foreach plan_id $plan_id_list {
                if { [qf_is_natural_number $plan_id] } {
                    lappend filtered_ids_list $plan_id
                }
            }
            set vmq_lists [db_list_of_lists hf_dvmq_read_some "select plan_id, description, base_storage, base_traffic, base_memory, base_sku, over_storage_sku, over_traffic_sku, over_memory_sku, storage_unit, traffic_unit, memory_unit, qemu_memory, status_id, vm_type, max_domain, private_vps from hf_vm_quotas where instance_id=:instance_id and plan_id in ([template::util::tcl_to_sql_list $filtered_ids_list])" ]
        }
    }
    return $vmq_lists
}


