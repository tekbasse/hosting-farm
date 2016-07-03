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
    foreach {key value} $sam_list {
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
    if { [llength [set_difference_named_v vm_list [hf_vm_keys]]] > 0 } {
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


ad_proc -private hf_ua_defaults {
    array_name
} {
    Sets defaults for an hf_network_interfaces record into array_name
    if element does not yet exist in array. 
} {
    upvar 1 $array_name ua_arr
    upvar 1 instance_id instance_id
    set ua [list instance_id $instance_id \
                f_id "" \
                ua_id "" \
                ua "" \
                connection_type "" \
                pw "" \
                details]
    set ua_list [list ]
    foreach {key value} $ua {
        lappend ua_list $key
        if { ![info exists ua_arr(${key}) ] } {
            set ua_arr(${key}) $value
        }
    }
    if { [llength [set_difference_named_v ua_list [hf_ua_keys]]] > 0 } {
        ns_log Warning "hf_ua_defaults: Update this proc. \
It is out of sync with hf_ua_keys"
    }
    return 1
}


ad_proc -private hf_roles_init {
    instance_id
} {
    Initialize roles for a hosting-farm instance.
} {
    # role is <division>_<role_level> where role_level are privileges.
    # r_d_lists is abbrev for role_defaults_list
    if { [llength [hf_roles $instance_id] ] == 0 } { 
        set r_d_lists \
            [list \
                 [list main_admin "Main Admin" "Primary administrator"] \
                 [list main_manager "Main Manager" "Primary manager"] \
                 [list main_staff "Main Staff" "Main monitor"] \
                 [list technical_admin "Technical Admin" "Primary technical administrator"] \
                 [list technical_manager "Technical Manager" "Oversees daily technical operations"] \
                 [list technical_staff "Technical Staff" "Monitors asset performance etc"] \
                 [list billing_admin "Billing Admin" "Primary billing administrator"] \
                 [list billing_manager "Billing Manager" "Oversees daily billing operations"] \
             [list billing_staff "Billing Staff" "Monitors billing, bookkeeping etc."] \
                 [list site_developer "Site Developer" "Builds websites etc"] ]
        
        # admin to have admin permissions, 
        # manager to have read/write permissions, 
        # staff to have read permissions
        foreach def_role_list $r_d_lists {
            # No need for instance_id since these are system defaults
            set label [lindex $def_role_list 0]
            set title [lindex $def_role_list 1]
            set description [lindex $def_role_list 2]
            db_dml default_roles_cr {
                insert into hf_role
                (label,title,description)
                values (:label,:title,:description)
            }
            db_dml default_roles_cr_i {
                insert into hf_role
                (label,title,description,instance_id)
                values (:label,:title,:description,:instance_id)
                
            }
        }
        return 1
    }
}


ad_proc -private hf_property_init {
    instance_id
} {
    Initialize permissions properties for a hosting-farm instance
} {
    # ns could be an asset or attribute
    # For now, ns is an attribute (ie requires an asset besides the ns),
    # but maybe we give it special permissions 
    # or other asset-like qualities for now.
    # p_d_lists is abbrev for props_defaults_lists
    set exists_p [db_0or1row hf_property_exists_q "select id from hf_property where instance_id=:instance_id limit 1"]
    if { !$exists_p } {
        set p_d_lists \
            [list \
                 [list main_contact_record "Main Contact Record"] \
                 [list admin_contact_record "Administrative Contact Record"] \
                 [list tech_contact_record "Technical Contact Record"] \
                 [list permissions_properties "Permissions properties"] \
                 [list permissions_roles "Permissions roles"] \
                 [list permissions_privileges "Permissions privileges"] \
                 [list non_assets "non-assets ie customer records etc."] \
                 [list published "World viewable"] \
                 [list assets "Assets"] \
                 [list ss "Asset: Software as a service"] \
                 [list dc "Asset: Data center"] \
                 [list hw "Asset: Hardware"] \
                 [list vm "Asset: Virtual machine"] \
                 [list vh "Asset: Virtual host"] \
                 [list ns "Asset property: Domain name record"] \
                 [list ot "Asset: other"] ]
        foreach def_prop_list $p_d_lists {
            set asset_type_id [lindex $def_prop_list 0]
            set title [lindex $def_prop_list 1]
            db_dml default_props_cr {
                insert into hf_property
                (asset_type_id,title)
                values (:asset_type_id,:title)
            }
            
            db_dml default_props_cr_i {
                insert into hf_property
                (asset_type_id,title,instance_id)
                values (:asset_type_id,:title,:instance_id)
            }
        }
    }
    return 1
}


ad_proc -private hf_privilege_init {
    instance_id
} {
    Initialize permissions privileges for a hosting-farm instance
} {
    # This is the first run of the first instance. 
    # In general:
    # admin roles to have admin permissions, 
    # manager to have read/write permissions, 
    # staff to have read permissions
    # techs to have write privileges on tech stuff, 
    # admins to have write privileges on contact stuff
    # write includes trash, admin includes create where appropriate
    set exists_p [db_0or1row hf_property_role_privilege_map_exists_q "select property_id from hf_property_role_privilege_map where instance_id=:instance_id"]
    if { !$exists_p } {
        # only package system admin has delete privilege
        set privs_larr(admin) [list "create" "read" "write" "admin"]
        set privs_larr(developer) [list "create" "read" "write"]
        set privs_larr(manager) [list "read" "write"]
        set privs_larr(staff) [list "read"]
        
        set division_types_list [list tech billing main site]
        set props_larr(tech) [list tech_contact_record assets non_assets published ss dc hw vm vh ns ot]
        set props_larr(billing) [list admin_contact_record non_assets published]
        #set props_larr(main)  is in all general cases, 
        set props_larr(main) [list main_contact_record admin_contact_record non_assets tech_contact_record assets non_assets published]
        set props_larr(site) [list non_assets published]
        # perimissions_* are for special cases where tech admins need access to set special case permissions.
        
        set roles_lists [db_list_of_lists hf_roles_n { select id,label,title,description from hf_role where instance_id=:instance_id } ]
        set props_lists [db_list_of_lists hf_property_n { select asset_type_id,id from hf_property where instance_id=:instance_id } ]
        foreach role_list $roles_lists {
            set role_id [lindex $role_list 0]
            set role_label [lindex $role_list 1]
            set u_idx [string first "_" $role_label]
            incr u_idx
            set role_level [string range $role_label $u_idx end]
            set division [string range $role_label 0 $u_idx-2]
            if { $division eq "technical" } {
                # division abbreviates technical
                set division "tech"
            }
            foreach prop_list $props_lists {
                set asset_type_id [lindex $prop_list 0]
                set property_id [lindex $prop_list 1]
                # For each role_id and property_id create privileges
                # Privileges are base on 
                #     $privs_larr($role) and props_larr(asset_type_id)
                # For example, 
                #     $privs_larr(manager) = list read write
                #     $props_larr(billing) = admin_contact_record non_assets published
                
                if { [lsearch $props_larr($division) $asset_type_id ] > -1 } {
                    # This division has privileges.
                    # Add privileges for the role_id
                    if { $role_level ne "" } {
                        foreach priv $privs_larr($role_level) {
                            set exists_p [db_0or1row default_privileges_check { select property_id as test from hf_property_role_privilege_map where property_id=:property_id and role_id=:role_id and privilege=:priv } ]
                            if { !$exists_p } {
                                db_dml default_privileges_cr {
                                    insert into hf_property_role_privilege_map
                                    (property_id,role_id,privilege)
                                    values (:property_id,:role_id,:priv)
                                }
                                db_dml default_privileges_cr_i {
                                    insert into hf_property_role_privilege_map
                                    (property_id,role_id,privilege,instance_id)
                                    values (:property_id,:role_id,:priv,:instance_id)
                                }
                            }
                            ns_log Notice "hosting-farm/tcl/hosting-farm-init.tcl.127: Added privilege '${priv}' to role '${division}' role_id '${role_id}' role_label '${role_label}'"
                        }
                    } else {
                        ns_log Notice "hosting-farm/tcl/hosting-farm-init.tcl.130: No role_level (admin/manager/staff) for role_id '${role_id}' role_label '${role_label}'"
                    }
                }
            }
        }
    }
    return 1
}


ad_proc -private hf_asset_type_id_init {
    instance_id
} {
    Initialize permissions asset_type_ids for a hosting-farm instance
} {
    if { [llength [hf_asset_type_id_list] ] == 0 } {
        set ast_d_lists \
            [list \
                 [list ss "#hosting-farm.SAAS#" "#hosting-farm.Software_as_a_service#"] \
                 [list dc "#hosting-farm.dc#" "#hosting-farm.Data_center#"] \
                 [list hw "#hosting-farm.hw#" "#hosting-farm.Hardware#"] \
                 [list vm "#hosting-farm.vm#" "#hosting-farm.Virtual_machine#"] \
                 [list vh "#hosting-farm.vh#" "#hosting-farm.Virtual_host#"] \
                 [list ns "#hosting-farm.ns#" "#hosting-farm.Name_service#"] \
                 [list ot "#hosting-farm.ot#" "#hosting-farm.Other#"] ]
        foreach def_as_type_list $ast_d_lists {
            set asset_type_id [lindex $def_as_type_list 0]
            set label [lindex $def_as_type_list 1]
            set name [lindex $def_as_type_list 2]
            db_dml default_as_types_cr {
                insert into hf_asset_type
                (id,label,name)
                values (:asset_type_id,:label,:name)
            }
            db_dml default_as_types_cr_i {
                insert into hf_asset_type
                (id,label,name,instance_id)
                values (:asset_type_id,:label,:name,:instance_id)
            }
        }
    }
    return 1
}

ad_proc -private hf_demo_init {
    instance_id
} {
    Initialize demo assets and attributes for a hosting-farm instance
} {
    set assets_defaults_lists [list \
                                   [list ss "HostingFarm"] ]
    foreach def_asset_list $assets_defaults_lists {
        set asset_type_id [lindex $def_asset_list 0]
        set name [lindex $def_asset_list 1]
        set label [string tolower $name]
        set kernel [lindex $def_asset_list 2]
        # instance name:
        set title [apm_instance_name_from_id $instance_id]
        #db_dml default_assets_cr {
        #  insert into hf_assets
        #  (asset_type_id,label,user_id,instance_id)
        #  values (:asset_type_id,:label,:sysowner_user_id,:instance_id)
        #}
        # use the api
        # Make an example local system profile
        set uname "uname"
        set system_type [exec $uname]
        set spc_idx [string first " " $system_type]
        if { $spc_idx > -1 } {
            set system_type2 [string trim [string tolower [string range $system_type 0 $spc_idx]]]
        } else {
            set system_type2 [string trim [string tolower $system_type]]
        }
        set http_port [ns_config -int nssock port 80]
        set ss_config_file [ns_info config]
        set ss_nsd_file [ns_info nsd]
        set ss_nsd_name [ns_info name]
        set nowts [dt_systime -gmt 1]
        # Add an os record
        array set os_arr [list \
                              instance_id $instance_id \
                              label $label \
                              brand $system_type2 \
                              version $system_type \
                              kernel $kernel ]
        set os_id [hf_os_write os_arr]

        # Make an asset of type ss

        array set ss_arr [list asset_id ""\
                              label $label \
                              name $name \
                              asset_type_id "ss" \
                              user_id $sysowner_user_id ]
        set ss_arr(f_id) [hf_asset_write ss_arr]
        # set attribute (fid) is 
        array set ss_arr [list \
                              server_name $ss_nsd_name \
                              service_name $name \
                              daemon_ref $ss_nsd_file \
                              protocol "http" \
                              port $http_port \
                              config_uri $ss_config_file ]
        set ss_id [hf_ss_write ss_arr]
        unset ss_arr

        # problem server tests
        set nowts [dt_systime -gmt 1]

        # make an bad bot service (ss)
        set randlabel [hf_domain_example]
        array set ss_arr [list \
                              label $randlabel \
                              name "$randlabel problem SS" \
                              asset_type_id "ss" \
                              instance_id $instance_id \
                              user_id $sysowner_user_id]
        set ss_arr(f_id) [hf_asset_create ss_arr]

        array set ss_arr [list \
                              instance_id $instance_id \
                              server_name $randlabel \
                              service_name "badbot@" \
                              daemon_ref "/usr/local/badbot" \
                              protocol "http" \
                              port [randomRange 50000] \
                              ss_type "maybe bad" \
                              config_uri "/dev/null" ]
        set ss_arr(ss_id) [hf_ss_write ss_arr]


        # make a bad vm
        set randlabel [hf_domain_example]
        array set asset_arr [list \
                                 asset_type_id "vm" \
                                 label $randlabel \
                                 name "${randlabel} problem" \
                                 user_id $sysowner_user_id ]
        set asset_arr(fid) [hf_asset_create asset_arr]

        array set asset_arr [list \
                                 domain_name $randlabel \
                                 os_id $os_id ]
        set vm_id [hf_vm_write asset_arr ]

        # make a bad vh
        # only assets can be monitored (not non-primary attributes)
        array unset asset_arr
        set randlabel [hf_domain_example]
        array set asset_arr [list \
                                 asset_type_id "vh" \
                                 label $randlabel \
                                 name "${randlabel} problem VH" \
                                 user_id $sysowner_user_id ]
        set asset_arr(f_id) [hf_asset_create asset_arr]
        set vh_domain [hf_domain_example ""]
        array set asset_arr [list \
                                 domain_name $vh_domain]
        set asset_arr(vh_id) [hf_vh_write asset_arr ]
        array set asset_arr [list \
                                 name_record "/* problem NS record for $vh_domain */" \
                                 active_p "1"]
        set asset_arr(ns_id) [hf_ns_write asset_arr]

        # make a bad dc
        array unset asset_arr
        set randlabel [hf_domain_example]
        array set asset_arr [list \
                                 asset_type_id "dc" \
                                 label $randlabel \
                                 name "${randlabel} problem DC" \
                                 user_id $sysowner_user_id ]
        set asset_arr(f_id) [hf_asset_create asset_arr ]
        array set asset_arr [list \
                                 affix [enerate_random_string] \
                                 description "maybe problem DC" \
                                 details "This is for checking monitor simulations"]
        set dc_id [hf_dc_write asset_arr]
    }
    return 1
}

ad_proc -private hf_chars {
    chars
    {booster_p "1"}
} {
    Returns a set if chars is empty string.
} {
    if { $chars eq "" } {
        if { !$booster_p } {
            for { set i 65} {$i < 127 } {incr i } {
                regexp -- {[[:alnum:]]} [format $b $i] ii
                append c $ii
            }
            set d [length $c]
            incr d -1
            for { set i 0} {$i < 33} { incr i } {
                set ii [randomRange $d] 
                append chars [string range $ii $ii]
            }
        } else {
            set c_list [40 6 58 6 91 4 33 0 35 3]
            set b "%c"
            foreach {c d} $c_list {
                set d [expr { $c + $d + 1 } ]
                for {set i $c} { $i < $d } { incr i }  {
                    append chars [format $b $i]
                }
            }
            for { set i 65} {$i < 127 } {incr i } {
                regexp -- {[[:alnum:]]} [format $b $i] ii
                append chars $ii
            }
        }
    }
    return $chars
}