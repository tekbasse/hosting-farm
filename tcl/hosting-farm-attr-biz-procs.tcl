# hosting-farm/tcl/hosting-farm-attr-biz-procs.tcl
ad_library {

    business logic of attributes for Hosting Farm
    @creation-date 29 May 2016
    @Copyright (c) 2014-2016 Benjamin Brink
    @license GNU General Public License 2, 
    @see project home or http://www.gnu.org/licenses/gpl-2.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 193, Marylhurst, OR 97036-0193 usa
    @email: tekbasse@yahoo.com

    # Asset attributes can be created, writen/revised, trashed and deleted.
    # Deleted option should only be available if an asset is trashed. 

}


ad_proc -private hf_ua_delete {
    ua_id_list
} {
    Deletes ua. ua may be a one or a list. User must be a package admin.
} {
    set success_p 1
    if { $ua_id_list ne "" } {
        set user_id [ad_conn user_id]
        set instance_id [qc_set_instance_id]
        set admin_p [permission::permission_p -party_id $user_id -object_id \
                         [ad_conn package_id] -privilege admin]
        set success_p $admin_p
        if { $admin_p } {
            if { [llength $ua_id_list] > 0 } {
                set validated_p [hf_list_filter_by_natural_number $ua_id_list]
                set ua_list $ua_id_list
            } else {
                set ua_id [lindex $ua_id_list 0]
                set validated_p [hf_is_natural_number $ua_id]
                set ua_list [list $ua_id]
            }
            if { $validated_p } {
                db_transaction {
                    set ups_list [hf_up_id_of_ua_id ]
                    db_dml hf_uas_up_delete "delete from hf_up \
                            where up_id in \
                            ([template::util::tcl_to_sql_list $ups_list]) "
                    db_dml hf_uas_map_delete "delete from hf_ua_up_map \
                            where instance_id=:instance_id and ua_id in \
                            ([template::util::tcl_to_sql_list $ua_list]) "
                    db_dml hf_uas_delete "delete from hf_ua \
                            where instance_id=:instance_id and ua_id in \
                            ([template::util::tcl_to_sql_list $ua_list]) "
                    db_dml hf_ua_attr_map_del "delete from hf_sub_asset_map \
                            where instance_id=:instance_id and sub_f_id in \
                            ([template::util::tcl_to_sql_list $ua_list]) "
                } on_error {
                    set success_p 0
                }
            } else {
                set success_p 0
            }
        }
    }
    return $success_p
}

ad_proc -private hf_ns_delete {
    ns_id_list
} {
    Deletes hf_ns_records.
    ns_id_list may be a one or a list.
    User must be a package admin.
} {
    set sucess_p 1
    if { $ns_id_list ne "" } {
        set user_id [ad_conn user_id]
        set instance_id [qc_set_instance_id]
        set admin_p [permission::permission_p -party_id $user_id \
                         -object_id [ad_conn package_id] -privilege admin]
        set success_p $admin_p
        if { $admin_p } {
            if { [llength $ns_id_list] > 0 } {
                set validated_p [hf_list_filter_by_natural_number $ns_id_list]
                set ns_list $ns_id_list
            } else {
                set ns_id [lindex $ns_id_list 0]
                set validated_p [hf_is_natural_number $ns_id]
                set ns_list [list $ns_id]
            }
            if { $validated_p } {
                db_transaction {
                    db_dml hf_ns_ids_delete "delete from hf_ns_records \
                            where instance_id=:instance_id and ns_id in \
                            ([template::util::tcl_to_sql_list $ns_list]) "
                    db_dml hf_ns_attr_map_del "delete from hf_sub_asset_map \
                            where instance_id=:instance_id and sub_f_id in \
                            ([template::util::tcl_to_sql_list $ns_list]) "
                } on_error {
                    set success_p 0
                }
            } else {
                set success_p 0
            }
        }
    }
    return $success_p
}

ad_proc -private hf_ip_delete {
    ip_id_list
} {
    Deletes hf_ip_addresses records.
    ip_id_list may be a one or a list.
    User must be a package admin.
} {
    set success_p 1
    if { $ip_id_list ne "" } {
        set user_id [ad_conn user_id]
        set instance_id [qc_set_instance_id]
        set admin_p [permission::permission_p -party_id $user_id \
                         -object_id [ad_conn package_id] -privilege admin]
        set success_p $admin_p
        if { $admin_p } {
            if { [llength $ip_id_list] > 0 } {
                set validated_p [hf_list_filter_by_natural_number $ip_id_list]
                set ip_list $ip_id_list
            } else {
                set ip_id [lindex $ip_id_list 0]
                set validated_p [hf_is_natural_number $ip_id]
                set ip_list [list $ip_id]
            }
            if { $validated_p } {
                db_transaction {
                    db_dml hf_ip_ids_delete "delete from hf_ip_addresses \
                            where instance_id=:instance_id and ip_id in \
                            ([template::util::tcl_to_sql_list $ip_list]) "
                    db_dml hf_ip_attr_map_del "delete from hf_sub_asset_map \
                            where instance_id=:instance_id and sub_f_id in \
                            ([template::util::tcl_to_sql_list $ip_list]) "
                } on_error {
                    set success_p 0
                }
            } else {
                set success_p 0
            }
        }
    }
    return $success_p
}



ad_proc -private hf_ni_delete {
    ni_id_list
} {
    Deletes hf_network_interfaces records.
    ni_id_list may be a one or a list.
    User must be a package admin.
} {
    set success_p 1
    if { $ni_id_list ne "" } {
        set user_id [ad_conn user_id]
        set instance_id [qc_set_instance_id]
        set admin_p [permission::permission_p -party_id $user_id \
                         -object_id [ad_conn package_id] -privilege admin]
        set success_p $admin_p
        if { $admin_p } {
            if { [llength $ni_id_list] > 0 } {
                set validated_p [hf_list_filter_by_natural_number $ni_id_list]
                set ni_list $ni_id_list
            } else {
                set ni_id [lindex $ni_id_list 0]
                set validated_p [hf_is_natural_number $ni_id]
                set ni_list [list $ni_id]
            }
            if { $validated_p } {
                db_transaction {
                    db_dml hf_ni_ids_delete "delete from hf_network_interfaces \
                            where instance_id=:instance_id and ni_id in \
                            ([template::util::tcl_to_sql_list $ni_list])"
                    db_dml hf_ni_attr_map_del "delete from hf_sub_asset_map \
                            where instance_id=:instance_id and sub_f_id in \
                            ([template::util::tcl_to_sql_list $ni_list])"
                } on_error {
                    set success_p 0
                }
            } else {
                set success_p 0
            }
        }
    }
    return $success_p
}


ad_proc -private hf_ss_delete {
    ss_id_list
} {
    Deletes hf_service records.
    ss_id_list may be a one or a list.
    User must be a package admin.
} {
    set success_p 1
    if { $ss_id_list ne "" } {
        set user_id [ad_conn user_id]
        set instance_id [qc_set_instance_id]
        set admin_p [permission::permission_p -party_id $user_id \
                         -object_id [ad_conn package_id] -privilege admin]
        set success_p $admin_p
        if { $admin_p } {
            if { [llength $ss_id_list] > 0 } {
                set validated_p [hf_list_filter_by_natural_number $ss_id_list]
                set ss_list $ss_id_list
            } else {
                set ss_id [lindex $ss_id_list 0]
                set validated_p [hf_is_natural_number $ss_id]
                set ss_list [list $ss_id]
            }
            if { $validated_p } {
                db_transaction {
                    db_dml hf_ss_ids_delete "delete from hf_services \
                            where instance_id=:instance_id and ss_id in \
                            ([template::util::tcl_to_sql_list $ss_list]) "
                    db_dml hf_ss_attr_map_del "delete from hf_sub_asset_map \
                            where instance_id=:instance_id and sub_f_id in \
                            ([template::util::tcl_to_sql_list $ss_list]) "
                } on_error {
                    set success_p 0
                }
            } else {
                set success_p 0
            }
        }
    }
    return $success_p
}

ad_proc -private hf_vh_delete {
    vh_id_list
} {
    Deletes hf_vhosts records.
    vh_id_list may be a one or a list.
    User must be a package admin.
} {
    set success_p 1
    if { $vh_id_list ne "" } {
        set user_id [ad_conn user_id]
        set instance_id [qc_set_instance_id]
        set admin_p [permission::permission_p -party_id $user_id \
                         -object_id [ad_conn package_id] -privilege admin]
        set success_p $admin_p
        if { $admin_p } {
            if { [llength $vh_id_list] > 0 } {
                set validated_p [hf_list_filter_by_natural_number $vh_id_list]
                set vh_list $vh_id_list
            } else {
                set vh_id [lindex $vh_id_list 0]
                set validated_p [hf_is_natural_number $vh_id]
                set vh_list [list $vh_id]
            }
            if { $validated_p } {
                db_transaction {
                    db_dml hf_vh_ids_delete "delete from hf_vhosts \
                            where instance_id=:instance_id and vh_id in \
                            ([template::util::tcl_to_sql_list $vh_list]) "
                    db_dml hf_vh_attr_map_del "delete from hf_sub_asset_map \
                            where instance_id=:instance_id and sub_f_id in \
                            ([template::util::tcl_to_sql_list $vh_list]) "
                } on_error {
                    set success_p 0
                }
            } else {
                set success_p 0
            }
        }
    }
    return $success_p
}


ad_proc -private hf_vm_delete {
    vm_id_list
} {
    Deletes hf_virtual_machines records.
    vm_id_list may be a one or a list.
    User must be a package admin.
} {
    set success_p 1
    if { $vm_id_list ne "" } {
        set user_id [ad_conn user_id]
        set instance_id [qc_set_instance_id]
        set admin_p [permission::permission_p -party_id $user_id \
                         -object_id [ad_conn package_id] -privilege admin]
        set success_p $admin_p
        if { $admin_p } {
            if { [llength $vm_id_list] > 0 } {
                set validated_p [hf_list_filter_by_natural_number $vm_id_list]
                set vm_list $vm_id_list
            } else {
                set vm_id [lindex $vm_id_list 0]
                set validated_p [hf_is_natural_number $vm_id]
                set vm_list [list $vm_id]
            }
            if { $validated_p } {
                db_transaction {
                    db_dml hf_vm_ids_delete "delete from hf_virtual_machines \
                            where instance_id=:instance_id and vm_id in \
                            ([template::util::tcl_to_sql_list $vm_list]) "
                    db_dml hf_vm_attr_map_del "delete from hf_sub_asset_map \
                            where instance_id=:instance_id and sub_f_id in \
                            ([template::util::tcl_to_sql_list $vm_list]) "
                } on_error {
                    set success_p 0
                }
            } else {
                set success_p 0
            }
        }
    }
    return $success_p
}


ad_proc -private hf_hw_delete {
    hw_id_list
} {
    Deletes hf_hardware records.
    hw_id_list may be a one or a list.
    User must be a package admin.
} {
    set success_p 1
    if { $hw_id_list ne "" } {
        set user_id [ad_conn user_id]
        set instance_id [qc_set_instance_id]
        set admin_p [permission::permission_p -party_id $user_id \
                         -object_id [ad_conn package_id] -privilege admin]
        set success_p $admin_p
        if { $admin_p } {
            if { [llength $hw_id_list] > 0 } {
                set validated_p [hf_list_filter_by_natural_number $hw_id_list]
                set hw_list $hw_id_list
            } else {
                set hw_id [lindex $hw_id_list 0]
                set validated_p [hf_is_natural_number $hw_id]
                set hw_list [list $hw_id]
            }
            if { $validated_p } {
                db_transaction {
                    db_dml hf_hw_ids_delete "delete from hf_hardware \
                            where instance_id=:instance_id and hw_id in \
                            ([template::util::tcl_to_sql_list $hw_list]) "
                    db_dml hf_hw_attr_map_del "delete from hf_sub_asset_map \
                            where instance_id=:instance_id and sub_f_id in \
                            ([template::util::tcl_to_sql_list $hw_list]) "
                } on_error {
                    set success_p 0
                }
            } else {
                set success_p 0
            }
        }
    }
    return $success_p
}


ad_proc -private hf_dc_delete {
    dc_id_list
} {
    Deletes hf_data_centers records.
    dc_id_list may be a one or a list.
    User must be a package admin.
} {
    set success_p 1
    if { $dc_id_list ne "" } {
        set user_id [ad_conn user_id]
        set instance_id [qc_set_instance_id]
        set admin_p [permission::permission_p -party_id $user_id \
                         -object_id [ad_conn package_id] -privilege admin]
        set success_p $admin_p
        if { $admin_p } {
            if { [llength $dc_id_list] > 0 } {
                set validated_p [hf_list_filter_by_natural_number $dc_id_list]
                set dc_list $dc_id_list
            } else {
                set dc_id [lindex $dc_id_list 0]
                set validated_p [hf_is_natural_number $dc_id]
                set dc_list [list $dc_id]
            }
            if { $validated_p } {
                db_transaction {
                    db_dml hf_dc_ids_delete "delete from hf_data_centers \
                            where instance_id=:instance_id and dc_id in \
                            ([template::util::tcl_to_sql_list $dc_list]) "
                    db_dml hf_dc_attr_map_del "delete from hf_sub_asset_map \
                            where instance_id=:instance_id and sub_f_id in \
                            ([template::util::tcl_to_sql_list $dc_list]) "
                } on_error {
                    set success_p 0
                }
            } else {
                set success_p 0
            }
        }
    }
    return $success_p
}


ad_proc -private hf_monitor_delete {
    monitor_id_list
} {
    Deletes monitor_id records.
    monitor_id_list may be a one or a list.
    User must be a package admin.
} {
    set success_p 1
    if { $monitor_id_list ne "" } {
        set user_id [ad_conn user_id]
        set instance_id [qc_set_instance_id]
        set admin_p [permission::permission_p -party_id $user_id \
                         -object_id [ad_conn package_id] -privilege admin]
        set success_p $admin_p
        if { $admin_p } {
            if { [llength $monitor_id_list] > 0 } {
                set validated_p [hf_list_filter_by_natural_number $monitor_id_list]
                set monitor_list $monitor_id_list
            } else {
                set monitor_id [lindex $monitor_id_list 0]
                set validated_p [hf_is_natural_number $monitor_id]
                set monitor_list [list $monitor_id]
            }
            if { $validated_p } {
                db_transaction {
                    db_dml hf_monitor_fdc_delete "delete from hf_monitor_freq_dist_curves \
                            where instance_id=:instance_id and \
                            monitor_id in \
                            ([template::util::tcl_to_sql_list $monitor_id_list])"
                    db_dml hf_monitor_stats_delete "delete from hf_monitor_statistics \
                            where instance_id=:instance_id and \
                            monitor_id in \
                            ([template::util::tcl_to_sql_list $monitor_id_list])"
                    db_dml hf_monitor_status_delete "delete from hf_monitor_status \
                            where instance_id=:instance_id and \
                            monitor_id in \
                            ([template::util::tcl_to_sql_list $monitor_id_list])"
                    db_dml hf_monitor_cnc_delete "delete from hf_monitor_config_n_control \
                            where instance_id=:instance_id and \
                            asset_id=:f_id and \
                            monitor_id in \
                            ([template::util::tcl_to_sql_list $monitor_id_list])"
                    db_dml hf_monitor_log_delete "delete from hf_monitor_log \
                            where instance_id=:instance_id and \
                            asset_id=:f_id and \
                            monitor_id in \
                            ([template::util::tcl_to_sql_list $monitor_id_list])"
                } on_error {
                    set success_p 0
                }
            } else {
                set success_p 0
            }
        }
    }
    return $success_p
}


ad_proc -private hf_attribute_sub_label_update {
    sub_f_id
    new_sub_label
} {
    Changes the attribute_name
    where the attribute is referenced from sub_f_id.
    Returns new sub_f_id; Or empty string if sub_f_id not found.
    @param sub_f_id  The sub_f_id of the asset.
    @param new_sub_label   The new sub_label.
    @return sub_f_id or ""
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set new_sub_label_len [string length $new_sub_label]
    if { $new_sub_label_len != 0 && $new_sub_label_len < 65 } {
        set sub_f_id_new ""
        set sub_asset_list [hf_sub_asset $sub_f_id]
        qf_lists_to_vars $sub_asset_list [hf_sub_asset_map_keys]
        if { [llength $sub_asset_list] > 0 } {
            # trash old attribute record also
            # except for ua case. It doesn't trash.
            db_transaction {
                switch -exact -- $sub_type_id {
                    dc { 
                        set dc_list [hf_dc_read $sub_f_id]
                        qf_lists_to_array dc_arr $dc_list [hf_dc_keys]
                        set dc_arr(dc_id) ""
                        set sub_f_id__new [hf_dc_write dc_arr]
                    }
                    hw { 
                        set hw_list [hf_hw_read $sub_f_id]
                        qf_lists_to_array hw_arr $hw_list [hf_hw_keys]
                        set hw_arr(hw_id) ""
                        set sub_f_id__new [hf_hw_write hw_arr]
                    }
                    vm { 
                        set vm_list [hf_vm_read $sub_f_id]
                        qf_lists_to_array vm_arr $vm_list [hf_vm_keys]
                        set vm_arr(vm_id) ""
                        set sub_f_id__new [hf_vm_write vm_arr]
                    }
                    vh { 
                        set vh_list [hf_vh_read $sub_f_id]
                        qf_lists_to_array vh_arr $vh_list [hf_vh_keys]
                        set vh_arr(vh_id) ""
                        set sub_f_id__new [hf_vh_write vh_arr]
                    }
                    ss { 
                        set ss_list [hf_ss_read $sub_f_id]
                        qf_lists_to_array ss_arr $ss_list [hf_ss_keys]
                        set ss_arr(ss_id) ""
                        set sub_f_id__new [hf_ss_write ss_arr]
                    }
                    ip { 
                        set ip_list [hf_ip_read $sub_f_id]
                        qf_lists_to_array ip_arr $ip_list [hf_ip_keys]
                        set ip_arr(ip_id) ""
                        set sub_f_id__new [hf_ip_write ip_arr]
                    }
                    ni { 
                        set ni_list [hf_ni_read $sub_f_id]
                        qf_lists_to_array ni_arr $ni_list [hf_ni_keys]
                        set ni_arr(ni_id) ""
                        set sub_f_id__new [hf_ni_write ni_arr]
                    }
                    ns { 
                        set ns_list [hf_ns_read $sub_f_id]
                        qf_lists_to_array ns_arr $ns_list [hf_ns_keys]
                        set ns_arr(ns_id) ""
                        set sub_f_id__new [hf_ns_write ns_arr]
                    }
                    ua { 
                        # don't trash ua record.. not possible.
                        # update hf_ua and hf_ua_up_map
                        # with a new id
                        set sub_f_id_new [db_nextval hf_id_seq]
                        db_dml hf_ua_id_update {
                            update hf_ua
                            set ua_id=:sub_f_id_new
                            where ua_id=:sub_f_id 
                            and instance_id=:instance_id }
                        db_dml hf_ua_up_map_update {
                            update hf_ua_up_map
                            set ua_id=:sub_f_id_new
                            where ua_id=:sub_f_id
                            and instance_id=:instance_id }
                    }
                    default {
                        ns_log Warning "hf_attribute_sub_label_update.456: \
 Unknown sub_type_id '${sub_type_id}' \
 sub_f_id '${sub_f_id} new_sub_label '${new_sub_label}'"
                    }
                }
                set nowts [dt_systime -gmt 1]
                if { $sub_f_id_new ne "" } {
                    # trash existing map record

                        db_dml hf_sub_label_trash_1 {
                            update hf_sub_asset_map
                            set trashed_p='1',
                            last_updated=:nowts
                            where sub_f_id=:sub_f_id 
                            and instance_id=:instance_id
                        }

                    # update map dependencies
                        db_dml hf_attribute_map_f_id_u1 { 
                            update hf_sub_asset_map
                            set f_id=:sub_f_id_new,
                            last_updated=:nowts
                            where f_id=:sub_f_id 
                            and instance_id=:instance_id
                            and trashed_p!='1'
                        }
                    }

                    # make new map record
                    set sub_f_id $sub_f_id_new
                    set sub_label $new_sub_label
                    set last_updated $nowts
                    db_dml hf_attributes_sub_label_cr "insert into hf_sub_asset_map \
 ([hf_sub_asset_map_keys ","]) values ([hf_sub_asset_map_keys ",:"])"

                } on_error {
                    ns_log Warning "hf_attribute_sub_label_update.524: error '${errmsg}'"
                }
            }
        }
    return $sub_f_id_new
}

ad_proc -private hf_vh_trash {
    vh_id
} {
    Trashes a vh record
} {
    upvar 1 instance_id instance_id
    set nowts [dt_systime -gmt 1]
    db_dml hf_vh_trash {
        update hf_vhosts
        set time_trashed=:nowts
        where vh_id=:vh_id
        and instance_id=:instance_id }
    return 1
}

ad_proc -private hf_dc_trash {
    dc_id
} {
    Trashes a dc record
} {
    upvar 1 instance_id instance_id
    set nowts [dt_systime -gmt 1]
    db_dml hf_dc_trash {
        update hf_data_centers
        set time_trashed=:nowts
        where dc_id=:dc_id
        and instance_id=:instance_id }
    return 1
}

ad_proc -private hf_hw_trash {
    hw_id
} {
    Trashes a hw record
} {
    upvar 1 instance_id instance_id
    set nowts [dt_systime -gmt 1]
    db_dml hf_hw_trash {
        update hf_hardware
        set time_trashed=:nowts
        where hw_id=:hw_id
        and instance_id=:instance_id }
    return 1
}

ad_proc -private hf_vm_trash {
    vm_id
} {
    Trashes a vm record
} {
    upvar 1 instance_id instance_id
    set nowts [dt_systime -gmt 1]
    db_dml hf_vm_trash {
        update hf_virtual_machines
        set time_trashed=:nowts
        where vm_id=:vm_id
        and instance_id=:instance_id }
    return 1
}

ad_proc -private hf_ip_trash {
    ip_id
} {
    Trashes a ip record
} {
    upvar 1 instance_id instance_id
    set nowts [dt_systime -gmt 1]
    db_dml hf_ip_trash {
        update hf_ip_addresses
        set time_trashed=:nowts
        where ip_id=:ip_id
        and instance_id=:instance_id }
    return 1
}

ad_proc -private hf_ss_trash {
    ss_id
} {
    Trashes a ss record
} {
    upvar 1 instance_id instance_id
    set nowts [dt_systime -gmt 1]
    db_dml hf_ss_trash {
        update hf_services
        set time_trashed=:nowts
        where ss_id=:ss_id
        and instance_id=:instance_id }
    return 1
}

ad_proc -private hf_ni_trash {
    ni_id
} {
    Trashes a ni record
} {
    upvar 1 instance_id instance_id
    set nowts [dt_systime -gmt 1]
    db_dml hf_ni_trash {
        update hf_network_interfaces
        set time_trashed=:nowts
        where ni_id=:ni_id
        and instance_id=:instance_id }
    return 1
}


ad_proc -private hf_ns_trash {
    ns_id
} {
    Trashes a ns record
} {
    upvar 1 instance_id instance_id
    set nowts [dt_systime -gmt 1]
    db_dml hf_ns_trash {
        update hf_ns_records
        set time_trashed=:nowts
        where ns_id=:ns_id
        and instance_id=:instance_id }
    return 1
}

ad_proc -private hf_attribute_trash {
    sub_f_id
} {
    Trashes attribute referenced by sub_f_id
} {
    upvar 1 instance_id instance_id
    set success_p 0
    set sub_asset_list [hf_sub_asset $sub_f_id]
    if { [llength $sub_asset_list] > 0 } {
        qf_lists_to_vars $sub_asset_list [hf_sub_asset_map_keys]
        if { $sub_type_id in [list vh vm dc hw ss ip ni ns ua] } {
            set trashed_p [qf_is_true $trashed_p]
            if { !$trashed_p } {
                db_transaction {
                    db_dml hf_sub_asset_map_trash_u {update hf_sub_asset_map
                        set trashed_p='1'
                        where sub_f_id=:sub_f_id
                    }
                    switch -exact $sub_type_id {
                        vh {
                            hf_vh_trash $sub_f_id
                        }
                        vm {
                            hf_vm_trash $sub_f_id
                        }
                        dc {
                            hf_dc_trash $sub_f_id
                        }
                        hw {
                            hf_hw_trash $sub_f_id
                        }
                        ss {
                            hf_ss_trash $sub_f_id
                        }
                        ip {
                            hf_ip_trash $sub_f_id
                        }
                        ni {
                            hf_ni_trash $sub_f_id
                        }
                        ns {
                            hf_ns_trash $sub_f_id
                        }
                        ua {
                            # Trash is not reversable for ua.
                        }
                    }
                }
            }
            set success_p 1
        } else {
            ns_log Warning "hf_attribute_trash.749: unable to trash sub_f_id '${sub_f_id}' sub_type_id '${sub_type_id}'"
        }
    } else {
        ns_log Warning "hf_attribute_trash.751: unable to trash sub_f_id '${sub_f_id}'"
    }
    return $success_p
}


ad_proc -private hf_vh_write {
    vh_arr_name
} {
    Writes a new revision to an existing hf_vhosts record.
    If vh_id is empty, creates a new hf_vhosts record.
    A new sub_f_id is returned if successful.
    Otherwise empty string is returned.
    @param array_name
    @return sub_f_id or ""
} {
    # requires f_id
    upvar 1 $vh_arr_name arr_name
    upvar 1 instance_id instance_id

    hf_vh_defaults arr_name
    hf_sub_asset_map_defaults arr_name
    qf_array_to_vars arr_name [hf_vh_keys]
    qf_array_to_vars arr_name [hf_sub_asset_map_keys]
    qf_array_to_vars arr_name [list asset_type_id label]
    if { $type_id eq "" } {
        set type_id $asset_type_id
    }
    if { $sub_label eq "" } {
        if { $label ne "" && $sub_type_id eq $type_id } {
            set sub_label $label
        } else {
            set sub_label $sub_type_id
        }
        append sub_label [hf_asset_cascade_count $f_id]
    }
    
    set sub_f_id $vh_id
    set vh_id_new [hf_sub_asset_map_update $f_id $type_id $sub_label $sub_f_id vh $attribute_p]
    if { $vh_id_new ne "" } {
        # record revision/new
        set vh_id $vh_id_new
        db_dml vh_asset_create "insert into hf_vhosts \
 ([hf_vh_keys ","]) values ([hf_vh_keys ",:"])"
    } else {
        ns_log Warning "hf_vh_write: rejected '[array get arr_name]'"
    }
    return $vh_id_new
}

ad_proc -private hf_dc_write {
    dc_arr_name
} {
    Writes a new revision to an existing hf_data_centers record.
    If dc_id is empty, creates a new hf_data_centers record.
    A new sub_f_id is returned if successful.
    Otherwise empty string is returned.
    @param array_name
    @return sub_f_id or ""

} {
    # requires f_id
    upvar 1 $dc_arr_name arr_name
    upvar 1 instance_id instance_id

    hf_dc_defaults arr_name
    hf_sub_asset_map_defaults arr_name
    qf_array_to_vars arr_name [hf_dc_keys]
    qf_array_to_vars arr_name [hf_sub_asset_map_keys]
    qf_array_to_vars arr_name [list asset_type_id label]
    if { $type_id eq "" } {
        set type_id $asset_type_id
    }
    set sub_type_id "dc"
    hf_sub_label_define_empty
    set sub_f_id $dc_id
    set dc_id_new [hf_sub_asset_map_update $f_id $type_id $sub_label $sub_f_id $sub_type_id $attribute_p]
    if { $dc_id_new ne "" } {
        # record revision/new
        set dc_id $dc_id_new
        db_dml dc_asset_create "insert into hf_data_centers \
 ([hf_dc_keys ","]) values ([hf_dc_keys ",:"])"
    } else {
        ns_log Warning "hf_dc_write: rejected '[array get arr_name]'"
    }
    return $dc_id_new
}


ad_proc -private hf_hw_write {
    hw_arr_name
} {
    Writes a new revision to an existing hf_hardware record.
    If hw_id is empty, creates a new hf_hardware record.
    A new sub_f_id is returned if successful.
    Otherwise empty string is returned.
    @param array_name
    @return sub_f_id or ""

} {
    # requires f_id
    upvar 1 $hw_arr_name arr_name
    upvar 1 instance_id instance_id

    hf_hw_defaults arr_name
    hf_sub_asset_map_defaults arr_name
    qf_array_to_vars arr_name [hf_hw_keys]
    qf_array_to_vars arr_name [hf_sub_asset_map_keys]
    qf_array_to_vars arr_name [list asset_type_id label]
    if { $type_id eq "" } {
        set type_id $asset_type_id
    }
    set sub_type_id "hw"
    hf_sub_label_define_empty
    set sub_f_id $hw_id
    set hw_id_new [hf_sub_asset_map_update $f_id $type_id $sub_label $sub_f_id $sub_type_id $attribute_p]
    if { $hw_id_new ne "" } {
        # record revision/new
        set hw_id $hw_id_new
        db_dml hw_asset_create "insert into hf_hardware \
 ([hf_hw_keys ","]) values ([hf_hw_keys ",:"])"
    } else {
        ns_log Warning "hf_hw_write: rejected '[array get arr_name]'"
    }
    return $hw_id_new
}

ad_proc -private hf_vm_write {
    vm_arr_name
} {
    Writes a new revision to an existing hf_virtual_machines record.
    If vm_id is empty, creates a new hf_virtual_machines record.
    A new sub_f_id is returned if successful.
    Otherwise empty string is returned.
    @param array_name
    @return sub_f_id or ""

} {
    # requires f_id
    upvar 1 $vm_arr_name arr_name
    upvar 1 instance_id instance_id

    hf_vm_defaults arr_name
    hf_sub_asset_map_defaults arr_name
    qf_array_to_vars arr_name [hf_vm_keys]
    qf_array_to_vars arr_name [hf_sub_asset_map_keys]
    qf_array_to_vars arr_name [list asset_type_id label]
    if { $type_id eq "" } {
        set type_id $asset_type_id
    }
    set sub_type_id "vm"
    hf_sub_label_define_empty
    set sub_f_id $vm_id
    set vm_id_new [hf_sub_asset_map_update $f_id $type_id $sub_label $sub_f_id vm $attribute_p]
    if { $vm_id_new ne "" } {
        # record revision/new
        set vm_id $vm_id_new
        db_dml vm_asset_create "insert into hf_virtual_machines \
 ([hf_vm_keys ","]) values ([hf_vm_keys ",:"])"
    } else {
        ns_log Warning "hf_vm_write: rejected '[array get arr_name]'"
    }
    return $vm_id_new
}

ad_proc -private hf_ss_write {
    ss_arr_name
} {
    Writes a new revision to an existing hf_services record.
    If ss_id is empty, creates a new hf_services record.
    A new sub_f_id is returned if successful.
    Otherwise empty string is returned.
    @param array_name
    @return sub_f_id or ""

} {
    # requires f_id
    upvar 1 $ss_arr_name arr_name
    upvar 1 instance_id instance_id
    
    hf_ss_defaults arr_name
    hf_sub_asset_map_defaults arr_name
    qf_array_to_vars arr_name [hf_ss_keys]
    qf_array_to_vars arr_name [hf_sub_asset_map_keys]
    qf_array_to_vars arr_name [list asset_type_id label]
    if { $type_id eq "" } {
        set type_id $asset_type_id
    }
    set sub_type_id "ss"
    hf_sub_label_define_empty
    set sub_f_id $ss_id
    set ss_id_new [hf_sub_asset_map_update $f_id $type_id $sub_label $sub_f_id $sub_type_id $attribute_p]
    if { $ss_id_new ne "" } {
        # record revision/new
        set ss_id $ss_id_new
        db_dml ss_asset_create "insert into hf_services \
 ([hf_ss_keys ","]) values ([hf_ss_keys ",:"])"
    }
    return $ss_id_new
}

ad_proc -private hf_ip_write {
    ip_arr_name
} {
    Writes a new revision to an existing hf_ip_addresses record.
    If ip_id is empty, creates a new hf_ip_addresses record.
    A new sub_f_id is returned if successful.
    Otherwise empty string is returned.
    @param array_name
    @return sub_f_id or ""

} {
    # requires f_id
    upvar 1 $ip_arr_name arr_name
    upvar 1 instance_id instance_id

    hf_ip_defaults arr_name
    hf_sub_asset_map_defaults arr_name
    qf_array_to_vars arr_name [hf_ip_keys]
    qf_array_to_vars arr_name [hf_sub_asset_map_keys]
    qf_array_to_vars arr_name [list asset_type_id label]
    if { [string is true -strict $ipv4_status] } {
        set ipv4_status 1
    } elseif { [string is false -strict $ipv4_status] } {
        set ipv4_status 0
    } else {
        ns_log Warning "hf_ip_write.743: ipv4_status '${ipv4_status}' not valid. set to '0'."
        set ipv4_status 0
    }
    if { [string is true -strict $ipv6_status] } {
        set ipv6_status 1
    } elseif { [string is false -strict $ipv6_status] } {
        set ipv6_status 0
    } else {
        ns_log Warning "hf_ip_write.753: ipv6_status '${ipv6_status}' not valid. set to '0'."
        set ipv6_status 0
    }
    if { $type_id eq "" } {
        set type_id $asset_type_id
    }
    set sub_type_id "ip"
    hf_sub_label_define_empty
    set attribute_p [qf_is_true $attribute_p 1]
    set sub_f_id $ip_id
    set ip_id_new [hf_sub_asset_map_update $f_id $type_id $sub_label $sub_f_id $sub_type_id $attribute_p]
    if { $ip_id_new ne "" } {
        # record revision/new
        set ip_id $ip_id_new
        db_dml ip_asset_create "insert into hf_ip_addresses \
 ([hf_ip_keys ","]) values ([hf_ip_keys ",:"])"
    } else {
        ns_log Warning "hf_ip_write: rejected '[array get arr_name]'"
    }
    return $ip_id_new
}

ad_proc -private hf_ni_write {
    ni_arr_name
} {
    Writes a new revision to an existing hf_network_interfaces record.
    If ni_id is empty, creates a new hf_network_interfaces record.
    A new sub_f_id is returned if successful.
    Otherwise empty string is returned.
    @param array_name
    @return sub_f_id or ""

} {
    # requires f_id
    upvar 1 $ni_arr_name arr_name
    upvar 1 instance_id instance_id

    hf_ni_defaults arr_name
    hf_sub_asset_map_defaults arr_name
    qf_array_to_vars arr_name [hf_ni_keys]
    qf_array_to_vars arr_name [hf_sub_asset_map_keys]
    qf_array_to_vars arr_name [list asset_type_id label]
    if { $type_id eq "" } {
        set type_id $asset_type_id
    }
    set sub_type_id "ni"
    hf_sub_label_define_empty
    set sub_f_id $ni_id
    set ni_id_new [hf_sub_asset_map_update $f_id $type_id $sub_label $sub_f_id $sub_type_id $attribute_p]
    if { $ni_id_new ne "" } {
        # record revision/new
        set ni_id $ni_id_new
        db_dml ni_asset_create "insert into hf_network_interfaces ([hf_ni_keys ","]) values ([hf_ni_keys ",:"])"
    } else {
        ns_log Warning "hf_ni_write.967: rejected '[array get arr_name]'"
    }
    return $ni_id_new
}



ad_proc -private hf_os_write {
    os_arr_name
} {
    Writes an hf_operating_systems record.
    If os_id is empty, creates a new hf_operating_systems record.
    Otherwise empty string is returned.
    @param array_name
    @return sub_f_id or ""

} {
    upvar 1 $os_arr_name arr_name
    upvar 1 instance_id instance_id

    hf_os_defaults arr_name
    qf_array_to_vars arr_name [hf_os_keys]
    set os_list [hf_os_read $os_id]
    db_transaction {
        set nowts [dt_systime -gmt 1]
        if { [llength $os_list ] > 2 } {
            # existing record, update status first
            db_dml hf_os_update {update hf_operating_systems 
                set time_trashed=:nowts 
                where os_id=:os_id }
        }
        set os_id [db_nextval hf_id_seq]
        # record revision/new
        set time_created $nowts
        db_dml hf_os_create "insert into hf_operating_systems \
 ([hf_os_keys ","]) values ([hf_os_keys ",:"])"
    }
    return $os_id
}

ad_proc -private hf_ns_write {
    ns_arr_name
} {
    Writes a new revision to an existing hf_ns_records record.
    If ns_id is empty, creates a new hf_ns_records record.
    A new sub_f_id is returned if successful.
    Otherwise empty string is returned.
    @param array_name
    @return sub_f_id or ""

} {
    # requires f_id
    upvar 1 $ns_arr_name arr_name
    upvar 1 instance_id instance_id

    hf_ns_defaults arr_name
    hf_sub_asset_map_defaults arr_name
    qf_array_to_vars arr_name [hf_ns_keys]
    qf_array_to_vars arr_name [hf_sub_asset_map_keys]
    qf_array_to_vars arr_name [list asset_type_id label]
    if { $type_id eq "" } {
        set type_id $asset_type_id
    }
    set sub_type_id "ns"
    hf_sub_label_define_empty
    set attribute_p [qf_is_true $attribute_p 1]
    set sub_f_id $ns_id
    set ns_id_new [hf_sub_asset_map_update $f_id $type_id $sub_label $sub_f_id $sub_type_id $attribute_p]
    if { $ns_id_new ne "" } {
        # record revision/new
        set ns_id $ns_id_new
        db_dml ns_asset_create "insert into hf_ns_records \
 ([hf_ns_keys ","]) values ([hf_ns_keys ",:"])"
    } else {
        ns_log Warning "hf_ns_write: rejected '[array get arr_name]'"
    }
    return $ns_id_new
}


ad_proc -private hf_vm_quota_write {
    vm_quota_arr_name
} {
    Writes a new revision to an existing hf_vm_quotas record.
    If vm_quota_id is empty, creates a new hf_vm_quotas record.
    A new sub_f_id is returned if successful.
    Otherwise empty string is returned.
    @param array_name
    @return sub_f_id or ""

} {
    upvar 1 $vm_quota_arr_name arr_name
    upvar 1 instance_id instance_id

    hf_vm_quota_defaults arr_name
    qf_array_to_vars arr_name [hf_vm_quota_keys]

    if { $plan_id ne "" } {
        set exists_p [db_0or1row hf_vm_quota_read_ck {
            select plan_id as plan_id_ck from hf_vm_quotas
            where plan_id=:plan_id
            and instance_id=:instance_id
            and time_trashed is null } ]
    } else {
        set exists_p 0
    }
    db_transaction {
        set nowts [dt_systime -gmt 1]
        if { $exists_p } {
            db_dml hf_vm_quotas_trash_plan_id {
                update hf_vm_quotas
                set time_trashed=:nowts
                where plan_id=:plan_id
                and instance_id=:instance_id
                and time_trashed is null
            }
        } else {
            set plan_id [db_nextval hf_id_seq]
        }
        db_dml hf_vm_quota_create "insert into hf_vm_quotas \
 ([hf_vm_quota_keys ","]) values ([hf_vm_quota_keys ",:"])"
    }
    return $plan_id
}

ad_proc -private hf_user_add {
    array_name
} {
    Requires the following array elements: f_id and ua.
    f_id  The asset or attribute to associate user; 
    ua  is User Account;
    asset_type_id of asset_or attribute to associate user (optional);
    connection_type (optional);
    ua_id or sub_f_id (optional) references for updating an existing account;
    up (optional) Set if adding a password.
    @param array_name
    @return sub_f_id or ""
} {
    # requires f_id, ua
    # hf_ua_write does not fit hf_sub_asset_map_update paradigms
    upvar 1 $array_name arr_name
    upvar 1 instance_id instance_id
    hf_ui_go_ahead_q admin

    hf_ua_defaults arr_name
    hf_sub_asset_map_defaults arr_name
    qf_array_to_vars arr_name [hf_ua_keys]
    qf_array_to_vars arr_name [hf_sub_asset_map_keys]
    qf_array_to_vars arr_name [list asset_type_id label]
    set f_id_exists_p 0
    set type_id [hf_asset_type_id_of_f_id $f_id]
    if { $type_id ne "" } {
        set f_id_exists_p 1
    }
    set sub_type_id "ua"
    set sub_f_id_new ""
    set allowed_sub_type_id_list [hf_types_allowed_by $type_id]
    set test_sub_f_id ""
    if { $type_id eq $sub_type_id } {
        set test_sub_f_id [hf_primary_sub_f_id $f_id]
    }
    if { $sub_type_id in $allowed_sub_type_id_list || ( $type_id eq $sub_type_id && $test_sub_f_id eq "" ) } {
        if { $ua_id eq "" } {
            set ua_id $sub_f_id
        }
        set sub_f_id $ua_id
        # Manually added hf_sub_asset_map_update code at this point
        # so hf_ua_write controls db_next_val 
        # and hf_up api handled directly.
        set trashed_p 0
        set attribute_p 1
        set sub_f_id_exists_p 0
        if { $ua_id ne "" } {
            set sub_type_id [hf_asset_type_id_of_f_id $sub_f_id]
            if { $sub_type_id eq "ua" } {
                set sub_f_id_exists_p 1
            } else {
                ns_log Warning "hf_user_add.963: denied. \
 attribute ref sub_f_id '${sub_f_id}' does not exist. fid '${f_id} ua_id '${ua_id}'"
            }
        } 
        if { $f_id_exists_p } {
            set sub_f_id_new [hf_ua_write $ua $connection_type $ua_id $up]
            if { $sub_f_id_new ne "" } {
                set nowts [dt_systime -gmt 1]
                if { $sub_f_id_exists_p } {
                    db_dml hfua_sub_asset_map_update { update hf_sub_asset_map
                        set last_updated=:nowts
                        where f_id=:f_id 
                        and sub_f_id=:sub_f_id
                        and instance_id=:instance_id}
                } else {
                    #  $sub_f_id ne $sub_f_id_new 
                    set sub_f_id $sub_f_id_new
                    set ct [hf_asset_cascade_count $f_id]
                    set sub_sort_order [expr { $ct * 20 } ]
                    set last_updated $nowts
                    if { $sub_label eq "" } {
                        if { $connection_type ne "" } {
                            append sub_label "${connection_type}:"
                        }
                        append sub_label ua $ct
                    }
                    # translate api conventions to internal map refs
                    db_dml hfua_sub_asset_map_create "insert into hf_sub_asset_map \
 ([hf_sub_asset_map_keys ","]) values ([hf_sub_asset_map_keys ",:"])"
                }
            } else {
                ns_log Warning "hf_user_add.1280: hf_ua_write failed. sub_f_id_new '${sub_f_id_new}'"
            }
        } else {
            ns_log Warning "hf_user_add.1283: f_id '${f_id}' does not exist."
        }
    } else {
        ns_log Warning "hf_user_add.1288: sub_type_id 'ua' not allowed as sub of type_id '${type_id}'"
    }
    return $sub_f_id_new
}



ad_proc -private hf_ua_write {
    ua
    connection_type
    {ua_id ""}
    {up ""}
} {
    writes or creates a ua.
    If ua_id is blank, a new one is created.
    If successful,  ua_id is returned, otherwise 0.
    If up is nonempty, associates a up with ua.
    @return ua_id or 0

} {
    upvar 1 instance_id instance_id

    hf_ui_go_ahead_q admin

    if { [hf_are_printable_characters_q $ua ] } {    
        set log_p 0
        set id_exists_p 0

        # validation and limits
        set connection_type [string range $connection_type 0 23]

        set mystify_proc [qc_parameter_get MystifyProc $instance_id hf_mystify]

        set mystify_key [qc_parameter_get MystifyKey $instance_id ""]
        set sdetail [safe_eval [list ${mystify_proc} $mystify_key $ua]]

        # hf_sub_asset_map_update internal convention is not fit for purpose with hf_ua and friends.

        if { $ua_id ne "" } {
            # update
            # does ua_id exist?
            if { [qf_is_natural_number $ua_id] } {
                set id_exists_p [db_0or1row hf_ua_id_get {select ua_id as ua_id_ck 
                    from hf_ua where instance_id=:instance_id and ua_id=:ua_id}]
            }
            if { $id_exists_p } {
                db_dml hf_ua_update {
                    update hf_ua set details=:sdetail,connection_type=:connection_type
                        where ua_id=:ua_id and instance_id=:instance_id
                }
                if { $up ne "" } {
                    set not_log_p [hf_up_write $ua_id $up $instance_id]
                }
            } else {
                ns_log Notice "hf_ua_write.1336: ua_id '${ua_id}' does not exist. instance_id '${instance_id}'"
            }
        }
        if { !$id_exists_p } {
            # create
            set ua_id [db_nextval hf_id_seq]
            db_dml hf_ua_create {insert into hf_ua (instance_id,ua_id,details,connection_type) 
                values (:instance_id,:ua_id,:sdetail,:connection_type)}
            if { $up ne "" } {
                set not_log_p [hf_up_write $ua_id $up $instance_id]
            }
        }
        if { $log_p } {
            if { [ns_conn isconnected] } {
                set user_id [ad_conn user_id]
                ns_log Warning "hf_ua_write(2511): Poor call. \
New ua '${details}' created by user_id ${user_id} \
called with blank instance_id."
            } else {
                ns_log Warning "hf_ua_write(2513): Poor call. \
New ua '${details}' with ua_id ${ua_id} ua_id '${ua_id}' created without a connection \
and called with blank instance_id."
            }
        }
    } else {
        if { [ns_conn isconnected] } {
            set user_id [ad_conn user_id]
            ns_log Warning "hf_ua_write(2552): Poor call rejected. \
New ua '${details}' for conn '${connection_type}' requested with unprintable \
 or no characters by user_id ${user_id}."
        } else {
            ns_log Warning "hf_ua_write(2513): Poor call rejected. \
New ua '${details}' for conn '${connection_type}' requested with unprintable \
or no characters by process without a connection."
        }
    }
    return $ua_id
}


