#hosting-farm/tcl/hosting-farm-attr-view-procs.tcl
ad_library {

    attribute views and constructors for Hosting Farm
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
    if { [llength $new_as_type_id_list] > 0 } {
        set return_list_of_lists [db_list_of_lists hf_asset_type_read "select id, label, title, description from hf_asset_type where instance_id =:instance_id and id in ([template::util::tcl_to_sql_list $new_as_type_id_list])" ]
    } else {
        set return_list_of_lists [list ]
    }
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
    {one_as_list_p "1"}
} {
    Returns records from hf_data_centers as a list of lists. See hf_dc_keys. 
    If only one id is requested and one_as_list_p is true, a list is returned instead of a list of lists.
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
    if { [llength $dc_id_list] == 1 && $one_as_list_p } {
        # expecting to return only 1 row
        set return_lists [lindex $return_lists 0]
    }
    return $return_lists
}


ad_proc -private hf_hw_read {
    {hw_id_list ""}
    {one_as_list_p "1"}
} {
    Returns records from hf_hardware as a list of lists. See hf_hw_keys
    If only one id is requested and one_as_list_p is true, a list is returned instead of a list of lists.
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
    if { [llength $hw_id_list] == 1 && $one_as_list_p } {
        # expecting to return only 1 row
        set return_lists [lindex $return_lists 0]
    }
    return $return_lists
}


ad_proc -private hf_vm_read {
    {vm_id_list ""}
    {one_as_list_p "1"}
} {
    Returns records from hf_virtual_machines as a list of lists. See hf_vm_keys
    If only one id is requested and one_as_list_p is true, a list is returned instead of a list of lists.
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set vm_ids_list [hf_list_filter_by_natural_number $vm_id_list]
    set return_lists [list ]
    foreach vm_id $vm_id_list {
        set read_p [hf_ui_go_ahead_q read vm_id "" 0]
        if { $read_p } {
            set rows_list [db_list_of_lists hf_vm_detail_get "select [hf_vm_keys ","] from hf_virtual_machines where instance_id =:instance_id and vm_id=:vm_id"]
            set row_list [lindex $rows_list 0]
            if { [llength $row_list] > 0 } {
                lappend return_lists $row_list
            }
        }
    }
    if { [llength $vm_id_list] == 1 && $one_as_list_p } {
        # expecting to return only 1 row
        set return_lists [lindex $return_lists 0]
    }
    return $return_lists
}


ad_proc -private hf_vh_read {
    {vh_id_list ""}
    {one_as_list_p "1"}
} {
    Returns records from hf_vhosts as a list of lists. See hf_vh_keys
    If only one id is requested and one_as_list_p is true, a list is returned instead of a list of lists.
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set vh_ids_list [hf_list_filter_by_natural_number $vh_id_list]
    set return_lists [list ]
    foreach vh_id $vh_id_list {
        set read_p [hf_ui_go_ahead_q read vh_id "" 0]
        if { $read_p } {
            set rows_list [db_list_of_lists hf_vh_detail_get "select [hf_vh_keys ","] from hf_vhosts where instance_id =:instance_id and vh_id=:vh_id"]
            set row_list [lindex $rows_list 0]
            if { [llength $row_list] > 0 } {
                lappend return_lists $row_list
            }
        }
    }
    if { [llength $vh_id_list] == 1 && $one_as_list_p } {
        # expecting to return only 1 row
        set return_lists [lindex $return_lists 0]
    }
    return $return_lists
}


ad_proc -private hf_ss_read {
    {ss_id_list ""}
    {one_as_list_p "1"}
} {
    Returns records from hf_services as a list of lists. See hf_ss_keys
    If only one id is requested and one_as_list_p is true, a list is returned instead of a list of lists.
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set ss_ids_list [hf_list_filter_by_natural_number $ss_id_list]
    set return_lists [list ]
    foreach ss_id $ss_id_list {
        set read_p [hf_ui_go_ahead_q read ss_id "" 0]
        if { $read_p } {
            set rows_list [db_list_of_lists hf_ss_detail_get "select [hf_ss_keys ","] from hf_services where instance_id =:instance_id and ss_id=:ss_id"]
            set row_list [lindex $rows_list 0]
            if { [llength $row_list] > 0 } {
                lappend return_lists $row_list
            }
        }
    }
    if { [llength $ss_id_list] == 1 && $one_as_list_p } {
        # expecting to return only 1 row
        set return_lists [lindex $return_lists 0]
    }
    return $return_lists
}

ad_proc -private hf_ip_read {
    {ip_id_list ""}
    {one_as_list_p "1"}
} {
    Returns records from hf_ip_addresses as a list of lists. See hf_ip_keys
    If only one id is requested and one_as_list_p is true, a list is returned instead of a list of lists.
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set ip_ids_list [hf_list_filter_by_natural_number $ip_id_list]
    set return_lists [list ]
    foreach ip_id $ip_id_list {
        set read_p [hf_ui_go_ahead_q read ip_id "" 0]
        if { $read_p } {
            set rows_list [db_list_of_lists hf_ip_detail_get "select [hf_ip_keys ","] from hf_ip_addresses where instance_id =:instance_id and ip_id=:ip_id"]
            set row_list [lindex $rows_list 0]
            if { [llength $row_list] > 0 } {
                lappend return_lists $row_list
            }
        }
    }
    if { [llength $ip_id_list] == 1 } {
        # expecting to return only 1 row
        set return_lists [lindex $return_lists 0]
    }
    return $return_lists
}

ad_proc -private hf_ni_read {
    {ni_id_list ""}
    {one_as_list_p "1"}
} {
    Returns records from hf_network_interfaces as a list of lists. See hf_ni_keys
    If only one id is requested and one_as_list_p is true, a list is returned instead of a list of lists.
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set ni_ids_list [hf_list_filter_by_natural_number $ni_id_list]
    set return_lists [list ]
    foreach ni_id $ni_id_list {
        set read_p [hf_ui_go_ahead_q read ni_id "" 0]
        if { $read_p } {
            set rows_list [db_list_of_lists hf_ni_detail_get "select [hf_ni_keys ","] from hf_network_interfaces where instance_id =:instance_id and ni_id=:ni_id"]
            set row_list [lindex $rows_list 0]
            if { [llength $row_list] > 0 } {
                lappend return_lists $row_list
            }
        }
    }
    if { [llength $ni_id_list] == 1 } {
        # expecting to return only 1 row
        set return_lists [lindex $return_lists 0]
    }
    return $return_lists
}


ad_proc -private hf_ns_read {
    {ns_id_list ""}
    {one_as_list_p "1"}
} {
    Returns records from hf_ns_records as a list of lists. See hf_ns_keys
    If only one id is requested and one_as_list_p is true, a list is returned instead of a list of lists.
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set ns_ids_list [hf_list_filter_by_natural_number $ns_id_list]
    set return_lists [list ]
    foreach ns_id $ns_id_list {
        set read_p [hf_ui_go_ahead_q read ns_id "" 0]
        if { $read_p } {
            set rows_list [db_list_of_lists hf_ns_detail_get "select [hf_ns_keys ","] from hf_ns_records where instance_id =:instance_id and ns_id=:ns_id"]
            set row_list [lindex $rows_list 0]
            if { [llength $row_list] > 0 } {
                lappend return_lists $row_list
            }
        }
    }
    if { [llength $ns_id_list] == 1 } {
        # expecting to return only 1 row
        set return_lists [lindex $return_lists 0]
    }
    return $return_lists
}


ad_proc -private hf_os_read {
    os_id_list
} {
    @param os_id_list  One or more os_id.  If no os_id is passed, returns an empty list.

    @return records from hf_operating_systems as a list of lists. 

    @see hf_os_keys for list order
} {
    upvar 1 instance_id instance_id
    set return_list [list ]
    if { $os_id_list ne "" } {
        set os_id_filtered_list [hf_list_filter_by_natural_number $os_id_list]
        set rows_lists [db_list_of_lists hf_os_detail_get "select [hf_os_keys ","] from hf_operating_systems where instance_id =:instance_id and os_id in ([template::util::tcl_to_sql_list $os_id_filtered_list]) and time_trashed is NULL"]
    }
    return $rows_lists
}


ad_proc -private hf_vm_quota_read {
    {plan_id_list ""}
    {instance_id ""}
} {
    Given plan_id_list, returns list of list of:hf_vm_quotas records. See hf_vm_quota_keys
    If plan_id_list is blank, returns all.
} {
    set id_list [hf_list_filter_by_natural_number $plan_id_list]
    if { ![qf_is_natural_number $instance_id] && instance_id ne "" } {
        set instance_id ""
    }
    set vmq_lists [list ]
    if { [llength $id_list] > 0 } {
        set vmq_lists [db_list_of_lists hf_dvmq_read_some "select [hf_vm_quota_keys ","] from hf_vm_quotas where instance_id=:instance_id and plan_id in ([template::util::tcl_to_sql_list $filtered_ids_list])" ]
    } else {
        set vmq_lists [db_list_of_lists hf_dvmq_read_inst "select [hf_vm_quota_keys ","] from hf_vm_quotas where instance_id=:instance_id" ]
    }
    return $vmq_lists
}


