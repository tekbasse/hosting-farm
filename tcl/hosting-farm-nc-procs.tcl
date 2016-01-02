# hosting-farm/tcl/hosting-farm-nc-procs.tcl
ad_library {

    no-connection procedures for hosting-farm package, a repo file for scheduled procs and dev convenience of apm reload
    @creation-date 2015-12-30
    @Copyright (c) 2015 Benjamin Brink
    @license GNU General Public License 3, see project home or http://www.gnu.org/licenses/gpl-3.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com

}

# using standard namespace to avoid caching of data that can happen in separate namespaces
ad_proc -private hf_nc_go_ahead {
} {
    Confirms process is not run via connection, or is run by an admin
} {
    if { [ns_conn isconnected] } {
        set user_id [ad_conn user_id]
        set instance_id [ad_conn package_id]
        set go_ahead [permission::permission_p -party_id $user_id -object_id $instance_id -privilege admin]
        if { !$go_ahead } {
            ns_log Warning "hf_nc_go_head failed. Called by user_id ${user_id}, instance_id ${instance_id}"
        }
    } else {
        set go_ahead 1
    }
    if { !$go_ahead } {
        ad_script_abort
    }

    return $go_ahead
}


ad_proc -private hf_nc_ip_read {
    ip_id
    instance_id
    arr_name
} {
    Adds elements to an array. Creates array if it doesn't exist.
} {
    upvar 1 $arr_name obj_arr
    set success [hf_nc_go_ahead ]
    if { $success } {
        # element list
        set ip_el_list [list ipv4_addr ipv4_status ipv6_addr ipv6_status]
        set asset_id $ip_id
        set ip_list [db_list_of_lists hf_ip_address_prop_get1 "select ipv4_addr, ipv4_status, ipv6_addr, ipv6_status from hf_ip_addresses where instance_id=:instance_id and ip_id in (select ip_id from hf_asset_ip_map where asset_id=:asset_id and instance_id=:instance_id)"]
        set ip_el_len [llength $ip_el_list]
        for {set i 0} {$i < $ip_el_len} {incr i} {
            set el [lindex $ip_el_list $i]
            set $obj_arr(${el}) [lindex $ip_list $i]
        }
    }
    return $success
}

ad_proc -private hf_nc_asset_read {
    asset_id
    instance_id
    arr_name
} {
    Adds elements to an array. Creates array if it doesn't exist.
} {
    upvar 1 $arr_name obj_arr
    set success [hf_nc_go_ahead ]
    if { $success } {
        # element list
        set as_el_list [list label templated_p template_p flags]
        set as_list [db_list_of_lists hf_as_prop_get1 "select label, templated_p, template_p, flags from hf_assets where instance_id=:instance_id and id=:asset_id"] 
        set as_el_len [llength $as_el_list]
        for {set i 0} {$i < $as_el_len} {incr i} {
            set el [lindex $as_el_list $i]
            set $obj_arr(${el}) [lindex $as_list $i]
        }
    }
    return $success
}

ad_proc -private hf_nc_hw_read {
    asset_id
    instance_id
    arr_name
} {
    Adds elements to an array. Creates array if it doesn't exist.
} {
    upvar 1 $arr_name obj_arr
    set success [hf_nc_go_ahead ]
    if { $success } {
        # element list
        set hw_el_list [list system_name backup_sys ns_id os_id]
        set hw_list [db_list_of_lists hf_hardware_prop_get1 "select system_name, backup_sys, ns_id, os_id from hf_hardware where instance_id=:instance_id and hw_id=:asset_id)"]
        set hw_el_len [llength $hw_el_list]
        for {set i 0} {$i < $hw_el_len} {incr i} {
            set el [lindex $hw_el_list $i]
            set $obj_arr(${el}) [lindex $hw_list $i]
        }
    }
    return $success
}

ad_proc -private hf_nc_ni_read {
    ni_id
    instance_id
    arr_name
} {
    Adds elements to an array. Creates array if it doesn't exist.
} {
    upvar 1 $arr_name obj_arr
    set success [hf_nc_go_ahead ]
    if { $success } {
        # element list
        set ni_el_list [list os_dev_ref bia_mac_address ul_mac_address ipv4_addr_range ipv6_addr_range ]
        set ni_list [db_list_of_lists hf_network_interfaces_prop_get1 "select os_dev_ref, bia_mac_address, ul_mac_address ipv4_addr_range, ipv6_addr_range from hf_network_interfaces where instance_id=:instance_id and ni_id=:ni_id"]
        set ni_el_len [llength $ni_el_list]
        for {set i 0} {$i < $ni_el_len} {incr i} {
            set el [lindex $ni_el_list $i]
            set $obj_arr(${el}) [lindex $ni_list $i]
        }
    }
    return $success
}

ad_proc -private hf_nc_os_read {
    asset_id
    instance_id
    arr_name
} {
    Adds elements to an array. Creates array if it doesn't exist.
} {
    upvar 1 $arr_name obj_arr
    set success [hf_nc_go_ahead ]
    if { $success } {
        # element list
        set os_el_list [list label brand version kernel orphaned_p requires_upgrade_p]
        set os_list [db_list_of_lists hf_operating_systems_prop_get1 "select label, brand, version, kernel, orphaned_p, requires_upgrade_p from hf_operating_systems where instance_id=:instance_id and os_id=:os_id"]
        set os_el_len [llength $os_el_list]
        for {set i 0} {$i < $os_el_len} {incr i} {
            set el [lindex $os_el_list $i]
            set $obj_arr(${el}) [lindex $os_list $i]
        }
    }
    return $success
}

ad_proc -private hf_nc_vm_read {
    asset_id
    instance_id
    arr_name
} {
    Adds elements to an array. Creates array if it doesn't exist.
} {
    upvar 1 $arr_name obj_arr
    set success [hf_nc_go_ahead ]
    if { $success } {
        # element list
        set vm_el_list [list domain_name type_id resource_path mount_union ip_id ni_id os_id]
        set vm_list [db_list_of_lists hf_virtual_machines_prop_get1 "select domain_name, type_id, resource_path, mount_union, ip_id, ni_id, ns_id, os_id from hf_virtual_machines where instance_id=:instance_id and vm_id=:asset_id"]
        set vm_el_len [llength $vm_el_list]
        for {set i 0} {$i < $vm_el_len} {incr i} {
            set el [lindex $vm_el_list $i]
            set $obj_arr(${el}) [lindex $vm_list $i]
        }
    }
    return $success
}


ad_proc -private hf_asset_properties {
    asset_id
    array_name
    {instance_id ""}
    {user_id ""}
} {
    passes properties of an asset into array_name; creates array_name if it doesn't exist. Returns 1 if asset is returned, otherwise returns 0.
} {
    upvar $array_name named_arr
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }

    set success_p [db_0or1row hf_assets_asset_type_id_r "select asset_type_id from hf_assets where instance_id=:instance_id and id=:asset_id"]
    if { $success_p } {
        # Don't use hf_* API here. Create queries specific to system call requirements.
        set asset_prop_list [list ]
        switch -- $asset_type_id {
###  move these db calls into procs in hosting-farm-scheduled-procs.tcl as private procs with permission only for no ns_conn or admin_p true. (create proc: is_admin_p )
            dc {
                #set asset_prop_list hf_dcs $instance_id "" $asset_id
                hf_nc_ip_read $asset_id $instance_id $named_arr
                hf_nc_asset_read $asset_id $instance_id $named_arr
            }
            hw {
                #set asset_prop_list [hf_hws $instance_id "" $asset_id]
                hf_nc_asset_read $asset_id $instance_id $named_arr
                if { [hf_nc_hw_read $asset_id $instance_id $named_arr ] } {
                    hf_nc_ni_read $named_arr(ns_id) $instance_id $named_arr
                    hf_nc_ip_read $asset_id $instance_id $named_arr
                    hf_nc_os_read $named_arr(os_id) $instance_id $named_arr
                }
            }
            vm {
                #set asset_prop_list [hf_vms $instance_id "" $asset_id]
                # split query into separate tables to handle more dynamics
                # h_assets  hf_asset_ip_map hf_ip_addresses hf_virutal_machines hf_ua hf_up 
                hf_nc_asset_read $asset_id $instance_id $named_arr
                hf_nc_vm_read $asset_id $instance_id $named_arr
                # hf_up_get_from_ua_id ua_id instance_id 
            }
            vh {
                #set asset_prop_list [hf_vhs $instance_id "" $asset_id]
#how is this called? vh_id?  if asset_id is passed as vh_id, then code must find vm asset_id for vh_id
                hf_nc_asset_read $asset_id $instance_id $named_arr
                hf_nc_vm_read $asset_id $instance_id $named_arr
                hf_nc_ip_read $asset_id $instance_id $named_arr
                hf_nc_os_read $named_arr(os_id) $instance_id $named_arr
                hf_nc_vh_read $vh_id $instance_id $named_arr
                set asset_prop_list [db_list_of_lists hf_vh_prop_get "select a.label as label, a.templated_p as templated_p, a.template_p as template_p, a.flags as flags, x.ipv4_addr as ipv4_addr, x.ipv4_status as ipv4_status, x.ipv6_addr as ipv6_addr, x.ipv6_status as ipv6_status, v.domain_name as domain_name, v.type_id as vm_type_id, v.resource_path as vm_resource_path, v.mount_union as mount_union, vh.domain_name as vh_domain from hf_assets a, hf_asset_ip_map i, hf_ip_addresses x, hf_virtual_machines v, hf_vm_vh_map hv, hf_vhosts vh  where a.instance_id=:instance_id and a.id=:asset_id and a.asset_type_id=:asset_type_id and i.instance_id=:instance_id and i.asset_id=:asset_id and x.instance_id=:instance_id and v.instance_id=a.instance_id and vh.instance_id=a.instance_id and i.ip_id=x.ip_id and a.id=i.vm_id and a.id=v.vm_id and hv.vm_id=a.id and hv.vh_id=:vhost_id"]
                set asset_key_list [list label templated_p template_p flags ipv4_addr ipv4_status ipv6_addr ipv6_status domain_name vm_type_id vm_resource_path mount_union vh_domain vh_user vh_pasw]
                # hf_up_get_from_ua_id ua_id Instance_id
            }
            hs,ss {
                # see ss, hs hosting service is saas: ss
                # hf_ss_map ss_id, hf_id, hf_services,
                # maybe ua_id hf_up
                set asset_prop_list [db_list_of_lists hf_ss_prop_get ""]
                set asset_key_list [list ]
                
            }
            ns {
                # ns , custom domain name service records
            }
            ot { 
                # other, nothing specific. Supply generic info.
            }

            default {
                ns_log Warning "hf_asset_properties: missing asset_type_id in switch options. asset_type_id '${asset_type_id}'"
            }
        }
    } else {
        ns_log Warning "hf_asset_properties: no asset_id '${asset_id}' found. instance_id '${instance_id}' user_id '${user_id}' array_name '${array_name}'"
    }
    return $success_p
}

