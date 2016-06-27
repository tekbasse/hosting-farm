# hosting-farm/tcl/hosting-farm-defaults-procs.tcl
ad_library {

    misc API for hosting-farm defaults
    @creation-date 6 June 2016
    @Copyright (c) 2016 Benjamin Brink
    @license GNU General Public License 2,
    @see project home or http://www.gnu.org/licenses/gpl-2.0.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com
    

}

ad_proc -private hf_asset_defaults {
    array_name
} {
    Sets defaults for an hf_assets record into array_name
    if element does not yet exist in array. 
} {
    upvar 1 $array_name asset_arr
    upvar 1 instance_id instance_id
    set nowts [dt_systime -gmt 1]
    set asset [list asset_id "" \
                   label "" \
                   name "" \
                   asset_type_id "" \
                   trashed_p "0" \
                   trashed_by "" \
                   template_p "0" \
                   templated_p "" \
                   publish_p "0" \
                   monitor_p "0" \
                   popularity "" \
                   triage_priority "" \
                   op_status "" \
                   qal_product_id "" \
                   qal_customer_id "" \
                   instance_id $instance_id \
                   user_id "" \
                   last_modified $nowts \
                   created "" \
                   flags "" \
                   template_id "" \
                   f_id "" ]
    set asset_list [list ]
    foreach {key value} $asset {
        lappend asset_list $key
        if { ![info exists asset_arr(${key}) ] } {
            set asset_arr(${key}) $value
        }
    }
    if { [llength [set_difference_named_v asset_list [hf_asset_keys]]] > 0 } {
        ns_log Warning "hf_asset_defaults: Update this proc. \
It is out of sync with hf_asset_keys"
    }
    return 1
}


ad_proc -private hf_sub_asset_map_defaults {
    array_name
    { attribute_p "1" }
} {
    Sets defaults for an hf_sub_asset_map record into array_name
    if element does not yet exist in array.
} {
    upvar 1 $array_name sam_arr
    upvar 1 instance_id instance_id
    set nowts [dt_systime -gmt 1]

    set sam_list [list f_id "" \
                      type_id "" \
                      sub_f_id "" \
                      sub_type_id "" \
                      sub_sort_order "" \
                      sub_label "" \
                      attribute_p $attribute_p \
                      trashed_p "0" ]
    foreach {key value} $sam {
        if { ![info exists sam_arr(${key}) ] } {
            set sam_arr(${key}) $value
        }
    }
    return 1
}


ad_proc -private hf_ss_defaults {
    array_name
} {
    Sets defaults for an hf_service record into array_name
    if element does not yet exist in array. 
} {
    upvar 1 $array_name ss_arr
    upvar 1 instance_id instance_id
    set nowts [dt_systime -gmt 1]
    set ss [list instance_id $instance_id \
                ss_id "" \
                server_name "" \
                service_name "" \
                daemon_ref "" \
                protocol "http" \
                port "" \
                ss_type "" \
                ss_subtype "" \
                ss_undersubtype "" \
                ss_ultrasubtype "" \
                config_uri "" \
                memory_bytes "" \
                details "" \
                time_trashed "" \
                time_created $nowts]
    set ss_list [list ]
    foreach {key value} $ss {
        lappend ss_list $key
        if { ![info exists ss_arr(${key}) ] } {
            set ss_arr(${key}) $value
        }
    }
    if { [llength [set_difference_named_v ss_list [hf_ss_keys]]] > 0 } {
        ns_log Warning "hf_ss_defaults: Update this proc. \
It is out of sync with hf_ss_keys"
    }
    return 1
}


ad_proc -private hf_monitor_configs_defaults {
    array_name
} {
    Sets defaults for an hf_monitor_config_n_control record into array_name
    if element does not yet exist in array. 
} {
    upvar 1 $array_name monitor_configs_arr
    upvar 1 instance_id instance_id
    set nowts [dt_systime -gmt 1]
    set monitor_configs [list instance_id $instance_id \
                             monitor_id "" \
                             asset_id "" \
                             label "" \
                             active_p "0" \
                             portions_count "" \
                             calculation_switches "" \
                             health_percentile_trigger "" \
                             health_threshold "" \
                             interval_s "" \
                             alert_by_privilege "" \
                             alert_by_role ""]
    set monitor_configs_list [list ]
    foreach {key value} $monitor_configs {
        lappend monitor_configs_list $key
        if { ![info exists monitor_configs_arr(${key}) ] } {
            set monitor_configs_arr(${key}) $value
        }
    }
    if { [llength [set_difference_named_v monitor_configs_list \
                       [hf_monitor_configs_keys]]] > 0 } {
        ns_log Warning "hf_monitor_configs_defaults: Update this proc. \
It is out of sync with hf_monitor_configs_keys"
    }
    return 1
}


ad_proc -private hf_os_defaults {
    array_name
} {
    Sets defaults for an hf_operating_systems record into array_name
    if element does not yet exist in array. 
} {
    upvar 1 $array_name os_arr
    upvar 1 instance_id instance_id
    set nowts [dt_systime -gmt 1]
    set os [list instance_id $instance_id \
                os_id "" \
                label "" \
                brand "" \
                version "" \
                kernel "" \
                orphaned_p "0" \
                requires_upgrade_p "1" \
                description "" \
                time_trashed "" \
                time_created $nowts]
    set os_list [list ]
    foreach {key value} $os {
        lappend os_list $key
        if { ![info exists os_arr(${key}) ] } {
            set os_arr(${key}) $value
        }
    }
    if { [llength [set_difference_named_v os_list [hf_os_keys]]] > 0 } {
        ns_log Warning "hf_os_defaults: Update this proc. \
It is out of sync with hf_os_keys"
    }
    return 1
}


ad_proc -private hf_vm_quota_defaults {
    array_name
} {
    Sets defaults for an hf_vm_quotas record into array_name
    if element does not yet exist in array. 
} {
    upvar 1 $array_name vm_quota_arr
    upvar 1 instance_id instance_id
    set nowts [dt_systime -gmt 1]
    set vm_quota [list instance_id $instance_id \
                      plan_id "" \
                      description "" \
                      base_storage "" \
                      base_traffic "" \
                      base_memory "" \
                      base_sku "" \
                      over_storage_sku "" \
                      over_traffic_sku "" \
                      over_memory_sku "" \
                      storage_unit "" \
                      traffic_unit "" \
                      memory_unit "" \
                      qemu_memory "" \
                      status_id "" \
                      vm_type "" \
                      max_domain "" \
                      private_vps "" \
                      time_trashed "" \
                      time_created $nowts]
    set vm_quota_list [list ]
    foreach {key value} $vm_quota {
        lappend vm_quota_list $key
        if { ![info exists vm_quota_arr(${key}) ] } {
            set vm_quota_arr(${key}) $value
        }
    }
    if { [llength [set_difference_named_v vm_quota_list [hf_vm_quota_keys]]] > 0 } {
        ns_log Warning "hf_vm_quota_defaults: Update this proc. \
It is out of sync with hf_vm_quota_keys"
    }
    return 1
}



ad_proc -private hf_vm_defaults {
    array_name
} {
    Sets defaults for an hf_virtual_machines record into array_name
    if element does not yet exist in array. 
} {
    upvar 1 $array_name vm_arr
    upvar 1 instance_id instance_id
    set nowts [dt_systime -gmt 1]
    set vm [list instance_id $instance_id \
                vm_id "" \
                domain_name "" \
                os_id "" \
                type_id "" \
                resource_path "" \
                mount_union "" \
                details "" \
                time_trashed "" \
                time_created $nowts]
    set vm_list [list ]
    foreach {key value} $vm {
        lappend vm_list $key
        if { ![info exists vm_arr(${key}) ] } {
            set vm_arr(${key}) $value
        }
    }
    if { [llength [set_difference_named_v vm [hf_vm_keys]]] > 0 } {
        ns_log Warning "hf_vm_defaults: Update this proc. \
It is out of sync with hf_vm_keys"
    }
    return 1
}


ad_proc -private hf_vh_defaults {
    array_name
} {
    Sets defaults for an hf_vhosts record into array_name
    if element does not yet exist in array. 
} {
    upvar 1 $array_name vh_arr
    upvar 1 instance_id instance_id
    set nowts [dt_systime -gmt 1]
    set vh [list instance_id $instance_id \
                vh_id "" \
                domain_name "" \
                details "" \
                time_trashed "" \
                time_created $nowts]
    set vh_list [list ]
    foreach {key value} $vh {
        lappend vh_list $key
        if { ![info exists vh_arr(${key}) ] } {
            set vh_arr(${key}) $value
        }
    }
    if { [llength [set_difference_named_v vh_list [hf_vh_keys]]] > 0 } {
        ns_log Warning "hf_vh_defaults: Update this proc. \
It is out of sync with hf_vh_keys"
    }
    return 1
}



ad_proc -private hf_dc_defaults {
    array_name
} {
    Sets defaults for an hf_data_centers record into array_name
    if element does not yet exist in array. 
} {
    upvar 1 $array_name dc_arr
    upvar 1 instance_id instance_id
    set nowts [dt_systime -gmt 1]
    set dc [list instance_id $instance_id \
                dc_id "" \
                affix "" \
                description "" \
                details "" \
                time_trashed "" \
                time_created $nowts]
    set dc_list [list ]
    foreach {key value} $dc {
        lappend dc_list $key
        if { ![info exists dc_arr(${key}) ] } {
            set dc_arr(${key}) $value
        }
    }
    if { [llength [set_difference_named_v dc_list [hf_dc_keys]]] > 0 } {
        ns_log Warning "hf_dc_defaults: Update this proc. \
It is out of sync with hf_dc_keys"
    }
    return 1
}



ad_proc -private hf_hw_defaults {
    array_name
} {
    Sets defaults for an hf_hardware record into array_name
    if element does not yet exist in array. 
} {
    upvar 1 $array_name hw_arr
    upvar 1 instance_id instance_id
    set nowts [dt_systime -gmt 1]
    set hw [list instance_id $instance_id \
                hw_id "" \
                system_name "" \
                backup_sys "" \
                os_id "" \
                description "" \
                details "" \
                time_trashed "" \
                time_created $nowts]
    set hw_list [list ]
    foreach {key value} $hw {
        lappend hw_list $key
        if { ![info exists hw_arr(${key}) ] } {
            set hw_arr(${key}) $value
        }
    }
    if { [llength [set_difference_named_v hw_list [hf_hw_keys]]] > 0 } {
        ns_log Warning "hf_hw_defaults: Update this proc. \
It is out of sync with hf_hw_keys"
    }
    return 1
}


ad_proc -private hf_ip_defaults {
    array_name
} {
    Sets defaults for an hf_ip_addresses record into array_name
    if element does not yet exist in array. 
} {
    upvar 1 $array_name ip_arr
    upvar 1 instance_id instance_id
    set nowts [dt_systime -gmt 1]
    set ip [list instance_id $instance_id \
                ip_id "" \
                ipv4_addr "" \
                ipv4_status "" \
                ipv6_addr "" \
                ipv6_status "" \
                time_trashed "" \
                time_created $nowts]
    set ip_list [list ]
    foreach {key value} $ip {
        lappend ip_list $key
        if { ![info exists ip_arr(${key}) ] } {
            set ip_arr(${key}) $value
        }
    }
    if { [llength [set_difference_named_v ip_list [hf_ip_keys]]] > 0 } {
        ns_log Warning "hf_ip_defaults: Update this proc. \
It is out of sync with hf_ip_keys"
    }
    return 1
}


ad_proc -private hf_ni_defaults {
    array_name
} {
    Sets defaults for an hf_network_interfaces record into array_name
    if element does not yet exist in array. 
} {
    upvar 1 $array_name ni_arr
    upvar 1 instance_id instance_id
    set nowts [dt_systime -gmt 1]
    set ni [list instance_id $instance_id \
                ni_id "" \
                os_dev_ref "" \
                bia_mac_address "" \
                ul_mac_address "" \
                ipv4_addr_range "" \
                ipv6_addr_range "" \
                time_trashed "" \
                time_created $nowts]
    set ni_list [list ]
    foreach {key value} $ni {
        lappend ni_list $key
        if { ![info exists ni_arr(${key}) ] } {
            set ni_arr(${key}) $value
        }
    }
    if { [llength [set_difference_named_v ni_list [hf_ni_keys]]] > 0 } {
        ns_log Warning "hf_ni_defaults: Update this proc. \
It is out of sync with hf_ni_keys"
    }
    return 1
}


ad_proc -private hf_ns_defaults {
    array_name
} {
    Sets defaults for an hf_records record into array_name
    if element does not yet exist in array. 
} {
    upvar 1 $array_name ns_arr
    upvar 1 instance_id instance_id
    set nowts [dt_systime -gmt 1]
    set ns [list instance_id $instance_id \
                id "" \
                active_p "" \
                name_record "" \
                time_trashed "" \
                time_created $nowts]
    set ns_list [list ]
    foreach {key value} $ns {
        lappend ns_list $key
        if { ![info exists ns_arr(${key}) ] } {
            set ns_arr(${key}) $value
        }
    }
    if { [llength [set_difference_named_v ns_list [hf_ns_keys]]] > 0 } {
        ns_log Warning "hf_ns_defaults: Update this proc. \
It is out of sync with hf_ns_keys"
    }
    return 1
}
