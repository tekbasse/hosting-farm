#hosting-farm/tcl/hosting-farm-attr-biz-procs.tcl
ad_library {

    business logic for hosting-farm asset attributes
    @creation-date 29 May 2016
    @Copyright (c) 2014-2016 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl-2.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com

    # Asset attributes can be created, writen/revised, trashed and deleted.
    # Deleted option should only be available if an asset is trashed. 

}


ad_proc -private hf_attribute_ua_delete {
    ua_id_list
} {
    Deletes ua. ua may be a one or a list. User must be a package admin.
} {
    set success_p 1
    if { $ua_id_list ne "" } {
        set user_id [ad_conn user_id]
        set instance_id [ad_conn package_id]
        set admin_p [permission::permission_p -party_id $user_id -object_id $package_id -privilege admin]
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
                    db_dml hf_uas_up_delete { delete from hf_up where up_id in ( select up_id from hf_ua_up_map where instance_id=:instance_id and ua_id in ([template::util::tcl_to_sql_list $ua_list])) }
                    db_dml hf_uas_map_delete { delete from hf_ua_up_map where instance_id=:instance_id and ua_id in ([template::util::tcl_to_sql_list $ua_list]) }
                    db_dml hf_uas_delete { delete from hf_ua where instance_id=:instance_id and ua_id in ([template::util::tcl_to_sql_list $ua_list]) }
                    db_dml hf_ua_attr_map_del { delete from hf_sub_asset_map where instance_id=:instance_id and sub_f_id in ([template::util::tcl_to_sql_list $ua_list]) }
                } on_error {
                    set success_p 0
                }
            } else{
                set success_p 0
            }
        }
    }
    return $success_p
}

ad_proc -private hf_attribute_ns_delete {
    ns_id_list
} {
    Deletes hf_ns_records. ns_id_list may be a one or a list. User must be a package admin.
} {
    set sucess_p 1
    if { $ns_id_list ne "" } {
        set user_id [ad_conn user_id]
        set instance_id [ad_conn package_id]
        set admin_p [permission::permission_p -party_id $user_id -object_id $package_id -privilege admin]
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
                    db_dml hf_ns_ids_delete { delete from hf_ns_records where instance_id=:instance_id and ns_id in ([template::util::tcl_to_sql_list $ns_list]) }
                    db_dml hf_ns_attr_map_del { delete from hf_sub_asset_map where instance_id=:instance_id and sub_f_id in ([template::util::tcl_to_sql_list $ns_list]) }
                } on_error {
                    set success_p 0
                }
            } else{
                set success_p 0
            }
        }
    }
    return $success_p
}

ad_proc -private hf_attribute_ip_delete {
    ip_id_list
} {
    Deletes hf_ip_addresses records. ip_id_list may be a one or a list. User must be a package admin.
} {
    set success_p 1
    if { $ip_id_list ne "" } {
        set user_id [ad_conn user_id]
        set instance_id [ad_conn package_id]
        set admin_p [permission::permission_p -party_id $user_id -object_id $package_id -privilege admin]
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
                    db_dml hf_ip_ids_delete { delete from hf_ip_addresses where instance_id=:instance_id and ip_id in ([template::util::tcl_to_sql_list $ip_list]) }
                    db_dml hf_ip_attr_map_del { delete from hf_sub_asset_map where instance_id=:instance_id and sub_f_id in ([template::util::tcl_to_sql_list $ip_list]) }
                } on_error {
                    set success_p 0
                }
            } else{
                set success_p 0
            }
        }
    }
    return $success_p
}



ad_proc -private hf_attribute_ni_delete {
    ni_id_list
} {
    Deletes hf_network_interfaces records. ni_id_list may be a one or a list. User must be a package admin.
} {
    set success_p 1
    if { $ni_id_list ne "" } {
        set user_id [ad_conn user_id]
        set instance_id [ad_conn package_id]
        set admin_p [permission::permission_p -party_id $user_id -object_id $package_id -privilege admin]
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
                    db_dml hf_ni_ids_delete { delete from hf_network_interfaces where instance_id=:instance_id and ni_id in ([template::util::tcl_to_sql_list $ni_list]) }
                    db_dml hf_ni_attr_map_del { delete from hf_sub_asset_map where instance_id=:instance_id and sub_f_id in ([template::util::tcl_to_sql_list $ni_list]) }
                } on_error {
                    set success_p 0
                }
            } else{
                set success_p 0
            }
        }
    }
    return $success_p
}


ad_proc -private hf_attribute_ss_delete {
    ss_id_list
} {
    Deletes hf_service records.  ss_id_list may be a one or a list. User must be a package admin.
} {
    set success_p 1
    if { $ss_id_list ne "" } {
        set user_id [ad_conn user_id]
        set instance_id [ad_conn package_id]
        set admin_p [permission::permission_p -party_id $user_id -object_id $package_id -privilege admin]
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
                    db_dml hf_ss_ids_delete { delete from hf_services where instance_id=:instance_id and ss_id in ([template::util::tcl_to_sql_list $ss_list]) }
                    db_dml hf_ss_attr_map_del { delete from hf_sub_asset_map where instance_id=:instance_id and sub_f_id in ([template::util::tcl_to_sql_list $ss_list]) }
                } on_error {
                    set success_p 0
                }
            } else{
                set success_p 0
            }
        }
    }
    return $success_p
}

ad_proc -private hf_attribute_vh_delete {
    vh_id_list
} {
    Deletes hf_vhosts records.  vh_id_list may be a one or a list. User must be a package admin.
} {
    set success_p 1
    if { $vh_id_list ne "" } {
        set user_id [ad_conn user_id]
        set instance_id [ad_conn package_id]
        set admin_p [permission::permission_p -party_id $user_id -object_id $package_id -privilege admin]
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
                    db_dml hf_vh_ids_delete { delete from hf_vhosts where instance_id=:instance_id and vh_id in ([template::util::tcl_to_sql_list $vh_list]) }
                    db_dml hf_vh_attr_map_del { delete from hf_sub_asset_map where instance_id=:instance_id and sub_f_id in ([template::util::tcl_to_sql_list $vh_list]) }
                } on_error {
                    set success_p 0
                }
            } else{
                set success_p 0
            }
        }
    }
    return $success_p
}


ad_proc -private hf_attribute_vm_delete {
    vm_id_list
} {
    Deletes hf_virtual_machines records.  vm_id_list may be a one or a list. User must be a package admin.
} {
    set success_p 1
    if { $vm_id_list ne "" } {
        set user_id [ad_conn user_id]
        set instance_id [ad_conn package_id]
        set admin_p [permission::permission_p -party_id $user_id -object_id $package_id -privilege admin]
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
                    db_dml hf_vm_ids_delete { delete from hf_virtual_machines where instance_id=:instance_id and vm_id in ([template::util::tcl_to_sql_list $vm_list]) }
                    db_dml hf_vm_attr_map_del { delete from hf_sub_asset_map where instance_id=:instance_id and sub_f_id in ([template::util::tcl_to_sql_list $vm_list]) }
                } on_error {
                    set success_p 0
                }
            } else{
                set success_p 0
            }
        }
    }
    return $success_p
}


ad_proc -private hf_attribute_hw_delete {
    hw_id_list
} {
    Deletes hf_hardware records.  hw_id_list may be a one or a list. User must be a package admin.
} {
    set success_p 1
    if { $hw_id_list ne "" } {
        set user_id [ad_conn user_id]
        set instance_id [ad_conn package_id]
        set admin_p [permission::permission_p -party_id $user_id -object_id $package_id -privilege admin]
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
                    db_dml hf_hw_ids_delete { delete from hf_hardware where instance_id=:instance_id and hw_id in ([template::util::tcl_to_sql_list $hw_list]) }
                    db_dml hf_hw_attr_map_del { delete from hf_sub_asset_map where instance_id=:instance_id and sub_f_id in ([template::util::tcl_to_sql_list $hw_list]) }
                } on_error {
                    set success_p 0
                }
            } else{
                set success_p 0
            }
        }
    }
    return $success_p
}


ad_proc -private hf_attribute_dc_delete {
    dc_id_list
} {
    Deletes hf_data_centers records.  dc_id_list may be a one or a list. User must be a package admin.
} {
    set success_p 1
    if { $dc_id_list ne "" } {
        set user_id [ad_conn user_id]
        set instance_id [ad_conn package_id]
        set admin_p [permission::permission_p -party_id $user_id -object_id $package_id -privilege admin]
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
                    db_dml hf_dc_ids_delete { delete from hf_data_centers where instance_id=:instance_id and dc_id in ([template::util::tcl_to_sql_list $dc_list]) }
                    db_dml hf_dc_attr_map_del { delete from hf_sub_asset_map where instance_id=:instance_id and sub_f_id in ([template::util::tcl_to_sql_list $dc_list]) }
                } on_error {
                    set success_p 0
                }
            } else{
                set success_p 0
            }
        }
    }
    return $success_p
}


ad_proc -private hf_attribute_monitor_delete {
    monitor_id_list
} {
    Deletes monitor_id records.  monitor_id_list may be a one or a list. User must be a package admin.
} {
    set success_p 1
    if { $monitor_id_list ne "" } {
        set user_id [ad_conn user_id]
        set instance_id [ad_conn package_id]
        set admin_p [permission::permission_p -party_id $user_id -object_id $package_id -privilege admin]
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
                    db_dml hf_monitor_fdc_delete { delete from hf_monitor_freq_dist_curves where monitor_id in ([template::util::tcl_to_sql_list $monitor_id_list]) and instance_id=:instance_id }
                    db_dml hf_monitor_stats_delete { delete from hf_monitor_statistics where monitor_id in ([template::util::tcl_to_sql_list $monitor_id_list]) and instance_id=:instance_id }
                    db_dml hf_monitor_status_delete { delete from hf_monitor_status where monitor_id in ([template::util::tcl_to_sql_list $monitor_id_list]) and instance_id=:instance_id }
                    db_dml hf_monitor_cnc_delete { delete from hf_monitor_config_n_control where monitor_id in ([template::util::tcl_to_sql_list $monitor_id_list]) and instance_id=:instance_id and asset_id=:f_id }
                    db_dml hf_monitor_log_delete { delete from hf_monitor_log where monitor_id in ([template::util::tcl_to_sql_list $monitor_id_list]) and instance_id=:instance_id and asset_id=:f_id }
                } on_error {
                    set success_p 0
                }
            } else{
                set success_p 0
            }
        }
    }
    return $success_p
}


ad_proc -private hf_asset_label_change {
    asset_id
    new_label
} {
    Changes the asset_name where the asset is referenced from asset_id. Returns 1 if successful, otherwise 0.

    @param asset_id  The label of the asset.
    @param new_label   The new label.
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set write_p [hf_ui_go_ahead_q write]
    set success_p 0
    if { $write_p } {
        db_transaction {
            db_dml hf_label_change_asset_map { update hf_asset_rev_map
                set label=:new_label where asset_id=:asset_id and instance_id=:instance_id 
            }
            db_dml hf_label_change_hf_assets { update hf_assets
                set last_modified = current_timestamp, label=:new_label where asset_id=:asset_id and instance_id=:instance_id 
            }
            set success_p 1
        } on_error {
            set success_p 0
        }
    }
    return $success_p
}


ad_proc -private hf_vh_write {
    vh_id
    label
    name
    asset_type_id
    keywords
    description
    content
    comments
    trashed_p
    trashed_by
    template_p
    templated_p
    publish_p
    monitor_p
    popularity
    triage_priority
    op_status
    ua_id
    ns_id
    qal_product_id
    qal_customer_id
    instance_id
    user_id
    last_modified
    created
    template_id
    v_ua_id
    v_ns_id
    domain_name
    details
    vm_id
} {
    writes or creates an vh asset_type_id. If asset_id (vh_id) is blank, a new one is created. The new asset_id is returned if successful, otherwise empty string is returned.
} {
    # hf_assets.instance_id, id, template_id, user_id, last_modified, created, asset_type_id, qal_product_id, qal_customer_id, label, keywords, description, content, coments, templated_p, template_p, time_start, time_stop, ns_id, ua_id, op_status, trashed_p, trashed_by, popularity, flags, publish_p, monitor_p, triage_priority
    
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    set new_vh_id ""
    set error_p 0
    if { $asset_type_id eq "vh" } {
        if { $vh_id ne "" } {
            # validate vh_id. If vh_id not an vh or does not exist, set vh_id ""
            if { ![hf_asset_id_exists $vh_id $instance_id "vh"] } {
                # make a new one instead of overwriting another asset type
                set vh_id ""
            }
        }
    } else {
        set vh_id ""
        set error_p 1
    }        
    if { $vh_id eq "" } {
        # hf_asset_create checks permission to create
        set vh_id_new [hf_asset_create $label $name $asset_type_id $content $keywords $description $comments $template_p $templated_p $publish_p $monitor_p $popularity $triage_priority $op_status $ua_id $ns_id $qal_product_id $qal_customer_id $template_id $flags $instance_id $user_id]
    } else {
        # hf_asset_write checks permission to write
        set vh_id_new [hf_asset_write $label $name $asset_type_id $content $keywords $description $comments $template_p $templated_p $publish_p $monitor_p $popularity $triage_priority $op_status $ua_id $ns_id $qal_product_id $qal_customer_id $template_id $vh_id $flags $instance_id $user_id]
    }
    if { $vh_id_new ne "" } {
        # insert vh asset in hf_vhosts and hf_vm_vh_map
        db_dml vh_asset_create {insert into hf_vhosts
            (vh_id,ua_id,ns_id,domain_name,details,instance_id)
            values (:vh_id,:ua_id,:ns_id,:domain_name,:details,:instance_id)
        }
        db_dml vh_asset_assign_vm {insert into hf_vm_vh_map 
            (vm_id,vh_id,instance_id)
            values (:vm_id,:vh_id,:instance_id)
        }
    } 
    if { $error_p } {
        ns_log Warning "hf_vh_write.1265: Requested to over/write asset_type_id '${asset_type_id}' vh_id '{$vh_id}'. Creating asset_id '${vh_id_new}' instead."
    }
    return $vh_id_new
}



ad_proc -private hf_dc_write {
    dc_id
    label
    name
    asset_type_id
    keywords
    description
    content
    comments
    trashed_p
    trashed_by
    template_p
    templated_p
    publish_p
    monitor_p
    popularity
    triage_priority
    op_status
    ua_id
    ns_id
    qal_product_id
    qal_customer_id
    instance_id
    user_id
    last_modified
    created
    dc_affix
    dc_description
    dc_details 
} {
    writes or creates a dc asset_type_id. If asset_id (dc_id) is blank, a new one is created. The new asset_id is returned if successful, otherwise empty string is returned.
} {
    # hf_data_centers.instance_id, dc_id, affix, description, details
    # hf_assets.instance_id, id, template_id, user_id, last_modified, created, asset_type_id, qal_product_id, qal_customer_id, label, keywords, description, content, coments, templated_p, template_p, time_start, time_stop, ns_id, ua_id, op_status, trashed_p, trashed_by, popularity, flags, publish_p, monitor_p, triage_priority
    hf_ui_go_ahead_q write dc_id

    set new_dc_id ""
    if { $asset_type_id eq "dc" } {
        if { $dc_id ne "" } {
            # validate dc_id. If dc_id not a dc or does not exist, set dc_id ""
            if { ![hf_asset_id_exists $dc_id $instance_id "dc"] } {
                set dc_id ""
            }
        }
        
        if { $dc_id eq "" } {
            # hf_asset_create checks permission to create
            set dc_id_new [hf_asset_create $label $name $asset_type_id $content $keywords $description $comments $template_p $templated_p $publish_p $monitor_p $popularity $triage_priority $op_status $ua_id $ns_id $qal_product_id $qal_customer_id $template_id $flags $instance_id $user_id]
        } else {
            # hf_asset_write checks permission to write
            set dc_id_new [hf_asset_write $label $name $asset_type_id $content $keywords $description $comments $template_p $templated_p $publish_p $monitor_p $popularity $triage_priority $op_status $ua_id $ns_id $qal_product_id $qal_customer_id $template_id $dc_id $flags $instance_id $user_id]
        }
        if { $dc_id_new ne "" } {
            # insert dc asset hf_datacenters
            db_dml dc_asset_create {insert into hf_data_centers
                (instance_id, dc_id, affix, description, details)
                values (:instance_id,:dc_id_new,:dc_affix,:dc_description,:dc_details) }
        } 
    } else {
        ns_log Notice "hf_dc_write.1606: Wrong asset_type_id '${asset_type_id}'. Write denied. label '${label}' name '${name}' content '${content}' keywords '${keywords}' description '${description}' comments '${comments}' template_p '${template_p}' templated_p '${templated_p}' publish_p '${publish_p}' monitor_p '${monitor_p}' popularity '${popularity}' triage_priority '${triage_priority}' op_status '${op_status}' ua_id '${ua_id}' ns_id '${ns_id}' qal_product_id '${qal_product_id}' qal_customer_id '${qal_customer_id}' template_id '${template_id}' dc_id '${dc_id}' flags '${flags}' instance_id '${instance_id}' user_id '${user_id}'"
    }
    return $dc_id_new
}



ad_proc -private hf_hw_write {
    hw_id
    label
    name
    asset_type_id
    keywords
    description
    content
    comments
    trashed_p
    trashed_by
    template_p
    templated_p
    publish_p
    monitor_p
    popularity
    triage_priority
    op_status
    ua_id
    ns_id
    qal_product_id
    qal_customer_id
    instance_id
    user_id
    last_modified
    created
    hw_system_name
    hw_backup_sys
    hw_ni_id
    hw_os_id
    hw_description
    hw_details
} {
    writes or creates an hw asset_type_id. If asset_id (hw_id) is blank, a new one is created. The new asset_id is returned if successful, otherwise empty string is returned.
} {
    # hf_assets.instance_id, id, template_id, user_id, last_modified, created, asset_type_id, qal_product_id, qal_customer_id, label, keywords, description, content, coments, templated_p, template_p, time_start, time_stop, ns_id, ua_id, op_status, trashed_p, trashed_by, popularity, flags, publish_p, monitor_p, triage_priority
    #  hf_hardware.instance_id, hw_id, system_name, backup_sys, ni_id, os_id, description, details
    if { $hw_id ne "" } {
        hf_ui_go_ahead_q write hw_id
    } else {
        hf_ui_go_ahead_q create hw_id
    }
    set new_hw_id ""
    if { $asset_type_id eq "hw" } {
        if { $hw_id ne "" } {
            # validate hw_id. If hw_id not an hw or does not exist, set hw_id ""
            if { ![hf_asset_id_exists $hw_id $instance_id "hw"] } {
                set hw_id ""
            }
        }
        
        if { $hw_id eq "" } {
            # hf_asset_create checks permission to create
            set hw_id_new [hf_asset_create $label $name $asset_type_id $content $keywords $description $comments $template_p $templated_p $publish_p $monitor_p $popularity $triage_priority $op_status $ua_id $ns_id $qal_product_id $qal_customer_id $template_id $flags $instance_id $user_id]
        } else {
            # hf_asset_write checks permission to write
            set hw_id_new [hf_asset_write $label $name $asset_type_id $content $keywords $description $comments $template_p $templated_p $publish_p $monitor_p $popularity $triage_priority $op_status $ua_id $ns_id $qal_product_id $qal_customer_id $template_id $hw_id $flags $instance_id $user_id]
        }
        if { $hw_id_new ne "" } {
            # insert hw asset hf_hardware
            db_dml hw_asset_create {insert into hf_hardware
                (instance_id, hw_id, system_name, backup_sys, ni_id, os_id, description, details)
                values (:instance_id,:hw_id_new,:hw_system_name,:hw_backup_sys,:hw_ni_id,:hw_os_id,:hw_description,:hw_details) }
        } 
    } else {
        ns_log Notice "hf_dc_write.1709: Wrong asset_type_id '${asset_type_id}'. Write denied. label '${label}' name '${name}' content '${content}' keywords '${keywords}' description '${description}' comments '${comments}' template_p '${template_p}' templated_p '${templated_p}' publish_p '${publish_p}' monitor_p '${monitor_p}' popularity '${popularity}' triage_priority '${triage_priority}' op_status '${op_status}' ua_id '${ua_id}' ns_id '${ns_id}' qal_product_id '${qal_product_id}' qal_customer_id '${qal_customer_id}' template_id '${template_id}' hw_id '${hw_id}' flags '${flags}' instance_id '${instance_id}' user_id '${user_id}'"
    }
    return $hw_id_new
}


ad_proc -private hf_vm_write {
    vm_id
    label
    name
    asset_type_id
    keywords
    description
    content
    comments
    trashed_p
    trashed_by
    template_p
    templated_p
    publish_p
    monitor_p
    popularity
    triage_priority
    op_status
    ua_id
    ns_id
    qal_product_id
    qal_customer_id
    instance_id
    user_id
    last_modified
    created
    vm_domain_name
    vm_ip_id
    vm_ni_id
    vm_ns_id
    vm_type_id
    vm_resource_path
    vm_mount_union
    vm_details
} {
    writes or creates an vm asset_type_id. If asset_id (vm_id) is blank, a new one is created. The new asset_id is returned if successful, otherwise empty string is returned.
} {
    if { $vm_id ne "" } {
        hf_ui_go_ahead_q write vm_id
    } else {
        hf_ui_go_ahead_q create vm_id
    }
    # hf_assets.instance_id, id, template_id, user_id, last_modified, created, asset_type_id, qal_product_id, qal_customer_id, label, keywords, description, content, coments, templated_p, template_p, time_start, time_stop, ns_id, ua_id, op_status, trashed_p, trashed_by, popularity, flags, publish_p, monitor_p, triage_priority

    set new_vm_id ""
    if { $asset_type_id eq "vm" } {
        if { $vm_id ne "" } {
            # validate vm_id. If vm_id not an vm or does not exist, set vm_id ""
            if { ![hf_asset_id_exists $vm_id $instance_id "vm"] } {
                set vm_id ""
            }
        }
        
        if { $vm_id eq "" } {
            # hf_asset_create checks permission to create
            set vm_id_new [hf_asset_create $label $name $asset_type_id $content $keywords $description $comments $template_p $templated_p $publish_p $monitor_p $popularity $triage_priority $op_status $ua_id $ns_id $qal_product_id $qal_customer_id $template_id $flags $instance_id $user_id]
        } else {
            # hf_asset_write checks permission to write
            set vm_id_new [hf_asset_write $label $name $asset_type_id $content $keywords $description $comments $template_p $templated_p $publish_p $monitor_p $popularity $triage_priority $op_status $ua_id $ns_id $qal_product_id $qal_customer_id $template_id $vm_id $flags $instance_id $user_id]
        }
        if { $vm_id_new ne "" } {
            # insert vm asset hf_virtual_machines
            # hf_virtual_machines.instance_id, vm_id, domain_name, ip_id, ni_id, ns_id, type_id, resource_path, mount_union, details
            db_dml vm_asset_create {insert into hf_virtual_machines
                (instance_id, vm_id, domain_name, ip_id, ni_id, ns_id, type_id, resource_path, mount_union, details)
                values (:instance_id, :new_vm_id, :vm_domain_name, :vm_ip_id, :vm_ni_id, :vm_ns_id, :vm_type_id, :vm_resource_path, :vm_mount_union, :vm_details) }
        } 
    } else {
        ns_log Notice "hf_vm_write.1815: Wrong asset_type_id '${asset_type_id}'. Write denied. label '${label}' name '${name}' content '${content}' keywords '${keywords}' description '${description}' comments '${comments}' template_p '${template_p}' templated_p '${templated_p}' publish_p '${publish_p}' monitor_p '${monitor_p}' popularity '${popularity}' triage_priority '${triage_priority}' op_status '${op_status}' ua_id '${ua_id}' ns_id '${ns_id}' qal_product_id '${qal_product_id}' qal_customer_id '${qal_customer_id}' template_id '${template_id}' vm_id '${vm_id}' flags '${flags}' instance_id '${instance_id}' usr_id '${user_id}'"
    }
    return $vm_id_new
}


ad_proc -private hf_ss_write {
    ss_id
    label
    name
    asset_type_id
    keywords
    description
    content
    comments
    trashed_p
    trashed_by
    template_p
    templated_p
    publish_p
    monitor_p
    popularity
    triage_priority
    op_status
    ua_id
    ns_id
    qal_product_id
    qal_customer_id
    instance_id
    user_id
    last_modified
    created
    ss_server_name
    ss_service_name
    ss_daemon_ref
    ss_protocol
    ss_port
    ss_ua_id
    ss_ss_type
    ss_ss_subtype
    ss_ss_undersubtype
    ss_ss_ultrasubtype
    ss_config_uri
    ss_memory_bytes
    ss_details
} {
    writes or creates an ss asset_type_id. If asset_id (ss_id) is blank, a new one is created. The new asset_id is returned if successful, otherwise empty string is returned.
} {
    # hf_assets.instance_id, id, template_id, user_id, last_modified, created, asset_type_id, qal_product_id, qal_customer_id, label, keywords, description, content, coments, templated_p, template_p, time_start, time_stop, ns_id, ua_id, op_status, trashed_p, trashed_by, popularity, flags, publish_p, monitor_p, triage_priority
    # hf_services.instance_id ss_id server_name service_name daemon_ref protocol port ua_id ss_type ss_subtype ss_undersubtype ss_ultrasubtype config_uri memory_bytes details
    if { $ss_id ne "" } {
        hf_ui_go_ahead_q write ss_id
    } else {
        hf_ui_go_ahead_q create ss_id
    }

    set new_ss_id ""
    set error_p 0
    if { $asset_type_id eq "ss" } {
        if { $ss_id ne "" } {
            # validate ss_id. If ss_id not an ss or does not exist, set ss_id ""
            if { ![hf_asset_id_exists $ss_id $instance_id "ss"] } {
                set ss_id ""
            }
        }
    } else {
        set error_p 1
        set ss_id ""
    }
    if { $ss_id eq "" } {
        # hf_asset_create checks permission to create
        set ss_id_new [hf_asset_create $label $name $asset_type_id $content $keywords $description $comments $template_p $templated_p $publish_p $monitor_p $popularity $triage_priority $op_status $ua_id $ns_id $qal_product_id $qal_customer_id $template_id $flags $instance_id $user_id]
    } else {
        # hf_asset_write checks permission to write
        set ss_id_new [hf_asset_write $label $name $asset_type_id $content $keywords $description $comments $template_p $templated_p $publish_p $monitor_p $popularity $triage_priority $op_status $ua_id $ns_id $qal_product_id $qal_customer_id $template_id $ss_id $flags $instance_id $user_id]
    }
    if { $ss_id_new ne "" } {
        # insert ss asset hf_services
        db_dml ss_asset_create {insert into hf_services
            (instance_id, ss_id, server_name, service_name, daemon_ref, protocol, port, ua_id, ss_type, ss_subtype, ss_undersubtype, ss_ultrasubtype, config_uri, memory_bytes, details)
            values (:instance_id,:ss_id_new,:ss_server_name,:ss_service_name,:ss_daemon_ref,:ss_protocol,:ss_port,:ss_ua_id,:ss_ss_type,:ss_ss_subtype,:ss_ss_undersubtype,:ss_ss_ultrasubtype,:ss_config_uri,:ss_memory_bytes,:ss_details)}
    } 
    if { $error_p } {
        ns_log Warning "hf_ss_write.2245: Requested to over/write asset_type_id '${asset_type_id}' ss_id '{$ss_id}'. Creating asset_id '${ss_id_new}' instead."
    }
    return $ss_id_new
}


ad_proc -private hf_ip_write {
    asset_id
    ip_id
    ipv4_addr
    ipv4_status
    ipv6_addr
    ipv6_status
    {instance_id ""}
} {
    writes or creates an ip record. If ip_id is blank, a new one is created, and the new ip_id returned. The ip_id is returned if successful, otherwise 0 is returned. Does not check for address collisions.
} {
    set return_id 0

    # check permissions, get customer_id of asset
    if { [qf_is_natural_number $asset_id] && [qf_is_natural_number $instance_id ] } {
        set admin_p [hf_ui_go_ahead_q admin "" "" 0]
        if { $admin_p } {

            # validate for db
            # ipv4_status and ipv6_status must be integers
            # length of ipv4_addr must be less than 16
            # length of ipv6_addr must be less than 40
            if { [qf_is_natural_number $ipv4_status] && [qf_is_natural_number $ipv6_status] && [string length $ipv4_addr] < 16 && [string length $ipv6_addr] < 40 } {

                if { [hf_asset_id_exists $asset_id "" $instance_id] } {
                    # if ip_id exists but not found asset_id or vm_id, then fail
                    # write/create to hf_virtual_machines (ip_id,vm_id) and hf_ip_addresses
                    if { [hf_ip_id_exists $ip_id] } {
                        #write/update
                        db_dml ip_address_write2vm {update hf_ip_addresses
                            set ipv4_addr =:ipv4_addr, ipv4_status=:ipv4_status, ipv6_addr=:ipv6_addr, ipv6_status=:ipv6_status where instance_id =:instance_id and id=:ip_id
                        }
                    } else {
                        #create/insert

                        # get asset_type_id
                        set asset_stats_list [hf_asset_stats $asset_id $instance_id]
                        set asset_type_id [lindex $asset_stats_list 2]
                        set ip_id [db_nextval hf_id_seq]
                        db_transaction {
                            if { $asset_type_id eq "vm" } {
                                db_dml ip_address_write2vm { update hf_virtual_machines
                                    set ip_id=:ip_id where instance_id=:instance_id,vm_id =:asset_id
                                } 
                            } elseif { $asset_type_id ne "" } {
                                # write/create to hf_asset_ip_map (asset_id,ip_id) and hf_ip_addresses
                                db_dml ip_address_write2ip_map { insert into hf_asset_ip_map
                                    (instance_id,asset_id,ip_id) 
                                    values (:instance_id,:asset_id,:ip_id) 
                                }    
                            }
                            db_dml hf_ip_addresses_create {insert into hf_ip_addresses
                                (instance_id,ip_id,ipv4_addr,ipv4_status,ipv6_addr,ipv6_status) 
                                values (:instance_id,:ip_id,:ipv4_addr,:ipv4_status,:ipv6_addr,:ipv6_status)
                            }
                            set return_id $ip_id
                        } 
                    }
                }
            }
        }
    }
    return $return_id
}



ad_proc -private hf_ni_write {
    asset_id
    ni_id
    os_dev_ref
    bia_mac_address
    ul_mac_address
    ipv4_addr_range
    ipv6_addr_range
    {instance_id ""}
} {
    Writes or creates an network interface for an asset_id.
    If ni_id is empty, a new one is created, and the new ni_id returned.
    The ni_id is returned if successful, otherwise 0 is returned.
} {
    set return_ni_id 0

    # check permissions, get customer_id of asset
    if { [qf_is_natural_number $asset_id] } {
        set admin_p [hf_ui_go_ahead_q admin "" "" 0]
        if { $admin_p } {
            
            # validate
            if { [string length $os_dev_ref] < 21 && [string length $bia_mac_address] < 21 && [string length $ul_mac_address] < 21 && [string length $ipv4_addr_range] < 21 && [string length $ipv6_addr_range] < 51 } {
                # does asset_id exist?
                # if asset_id not found, then fail
                if { [hf_asset_id_exists $asset_id "" $instance_id] } {
                    db_transaction { 
                        set hf_ni_id_exists_p [hf_ni_id_exists $ni_id]
                        set return_ni_id $ni_id
                        if { $hf_ni_id_exists_p } {
                            # update existing record
                            db_dml network_interfaces_write2 {update hf_network_interfaces
                                set os_dev_ref=:os_dev_ref, bia_mac_address=:bia_mac_address, ul_mac_address=:ul_mac_address, ipv4_addr_range=:ipv4_addr_range, ipv6_addr_range=:ipv6_addr_range 
                                where instance_id =:instance_id and ni_id=:ni_id
                            }
                        } else {
                            # create new ni_id, hf_network_interfaces record
                            set ni_id [db_nextval hf_id_seq]
                            set return_ni_id $ni_id
                            db_dml { insert into hf_network_interfaces 
                                (instance_id,ni_id,os_dev_ref,bia_mac_address,ul_mac_address,ipv4_addr_range,ipv6_addr_range)
                                values (:instance_id,ni_id,:os_dev_ref,:bia_mac_address,:ul_mac_address,:ipv4_addr_range,:ipv6_addr_range)
                            }
                            #create linkages
                            # get asset_type_id
                            set asset_stats_list [hf_asset_stats $asset_id $instance_id]
                            set asset_type_id [lindex $asset_stats_list 2]
                            set asset_ni_id [lindex $asset_stats_list 15]

                            # include linkage to hf_asset and maybe
                            # if hf_hardware one is defined, use hw_ni_map for extras
                            # if hf_asset is used and a dc, use dc_ni_map for others


                            switch -exact -- $asset_type_id {
                                vm {
                                    # hf_virtual_machines.ni_id and chf_assets.ni_id should be same and not exist
                                    set vm_stats_list [hf_vm_read $asset_id $instance_id]
                                    set vm_ni_id [lindex $vm_stats_list 17]
                                    if { $vm_ni_id eq "" || $asset_ni_id eq "" } {
                                        # assume blank
                                        if { $vm_ni_id ne $asset_ni_id } {
                                            # for debugging purposes, signal if both are not blank and same (shouldn't happen)
                                            ns_log Warning "hf_ni_write(2120): vm_ni_id ne asset_ni_id, vm_ni_id '${vm_ni_id}', asset_ni_id '${asset_ni_id}' This ni_id is now orphaned in hf_virtual_machines."
                                        }
                                        # For now, these should be same in both places.
                                        # See note in sql/postgresql/hosting-farm-create.sql
                                        # to remove ni_id from hf_virtual_machines as duplicate.
                                        db_dml update_asset_ni_id_1 { update hf_assets set ni_id=:ni_id where instance_id =:instance_id and id=:asset_id }
                                        db_dml update_hf_vm_ni_id_1 { update hf_virtual_machines set ni_id=:ni_id where instance_id=:instance_id and vm_id=:asset_id }
                                    } else {
                                        set return_ni_id 0
                                        ns_log Warning "hf_ni_write(2130): Refused request to add a second network_interface to vm/asset_id '$asset_id'."
                                    }
                                }
                                hw {
                                    # if hf_hardware.ni_id exists and hf_assets.ni_id exists, use hf_hw_ni_map
                                    set hw_stats_list [hf_hw_read $asset_id $instance_id]
                                    set hw_ni_id [lindex $hw_stats_list 17]
                                    if { $hw_ni_id eq "" || $asset_ni_id eq "" } {
                                        if { $hw_ni_id ne $asset_ni_id } {
                                            # for debugging purposes, signal if both are not blank and same (shouldn't happen)
                                            ns_log Warning "hf_ni_write(2140): hw_ni_id ne asset_ni_id, hw_ni_id '${hw_ni_id}', asset_ni_id '${asset_ni_id}' This ni_id is now orphaned in hf_hardware."
                                        }
                                        # For now, these should be same in both places.
                                        # See note in sql/postgresql/hosting-farm-create.sql
                                        # to remove ni_id from hf_hardware as duplicate.
                                        db_dml update_asset_ni_id_2 { update hf_assets set ni_id=:ni_id where instance_id =:instance_id and id=:asset_id }
                                        db_dml update_hf_hw_ni_id_1 { update hf_hardware set ni_id=:ni_id where instance_id=:instance_id and hw_id=:asset_id }
                                    } else {
                                        #  create hf_hw_ni_map
                                        db_dml { insert into hf_hw_ni_map (instance_id,hw_id,ni_id)
                                            values (:instance_id,:hw_id,:ni_id)
                                        }
                                    }
                                }
                                dc {
                                    if { $asset_ni_id eq "" } {
                                        db_dml update_asset_ni_id_3 { update hf_assets set ni_id=:ni_id where instance_id =:instance_id and id=:asset_id }
                                    } else {
                                        #  create hf_dc_ni_map
                                        db_dml { insert into hf_dc_ni_map (instance_id,dc_id,ni_id)
                                            values (:instance_id,:dc_id,:ni_id)
                                        }
                                    }
                                }
                                default {
                                    if { $asset_ni_id eq "" } {
                                        db_dml update_asset_ni_id_4 { update hf_assets set ni_id=:ni_id where instance_id =:instance_id and id=:asset_id }
                                    } else {
                                        # no additional ones allowed
                                        set return_ni_id 0
                                        ns_log Warning "hf_ni_write(2170): Refused request to add a second network_interface to ${asset_type_id} with asset_id '$asset_id'."
                                    }
                                }
                            }
                            # previous brace is end of switch
                        }
                    }
                    # end db_transaction
                }
            }
        }
    }
    return $return_ni_id
}


ad_proc -private hf_os_write {
    os_id
    label
    brand
    version
    kernel
    orphaned_p
    requires_upgrade_p
    description 
    {instance_id ""}
} {
    writes or creates an os asset_type_id. If os_id is blank, a new one is created, and the new asset_id returned. The asset_id is returned if successful, otherwise 0 is returned.
} {
    hf_ui_go_ahead_q admin

    set success_p 0
    set os_exists_p 0

    if { ![qf_is_natural_number $os_id] } {
        set os_id ""
    }
    if { $os_id ne "" } {
        set os_exists_p [db_0or1row check_os_id_exists "select os_id as os_id_db from hf_operating_systems where os_id=:os_id"]
    }
    # filter data to limits
    set label [string range $label 0 19]
    set brand [string range $brand 0 79]
    set version [string range $version 0 299]
    set kernel [string range $kernel 0 299]
    if { $orphaned_p ne "1" } {
        set orphaned_p 0
    }
    if { $requires_upgrade_p ne "1" } {
        set requires_upgrade_p 0
    }
    
    if { $os_exists_p } {
        # update existing record
        #    set os_lists [db_list_of_lists hf_os_read "select os_id, label, brand, version, kernel, orphaned_p, requires_upgrade_p, description from hf_operating_systems where instance_id =:instance_id and os_id in ([template::util::tcl_to_sql_list $filtered_ids_list])" ]
        db_dml hf_os_update {
            update hf_operating_systems set label=:label, brand=:brand, version=:version, kernel=:kernel, orphaned_p=:orphaned_p, requires_upgrade_p=:requires_upgrade_p,description=:description,instance_id=:instance_id where os_id=:os_id
        }
        set success_p 1
    } else {
        # insert new record
        set os_id [db_nextval hf_id_seq]
        db_dml hf_os_insert {
            insert into hf_operating_systems (label,brand,version,kernel,orphaned_p,requires_upgrade_p,description,instance_id,os_id )
            values (:label,:brand,:version,:kernel,:orphaned_p,:requires_upgrade_p,:description,:instance_id,:os_id)
        }
        set success_p 1
    }
    return $success_p
}



ad_proc -private hf_ns_write {
    ns_id
    name_record
    active_p
    {instance_id ""}
} {
    writes or creates an ns_id. If ns_id is blank, a new one is created, and the new ns_id returned. The ns_id is returned if successful, otherwise 0 is returned.
} {
    # TABLE hf_ns_records (
    #   instance_id integer,
    #   -- ns_id
    #   id          integer not null DEFAULT nextval ( 'hf_id_seq' ),
    #   -- should be validated before allowed to go live.
    #   active_p    integer,
    #   -- DNS records to be added to domain name service
    #   name_record text
    hf_ui_go_ahead_q admin
    set success_p 0
    set ns_exists_p 0
    if { ![qf_is_natural_number $ns_id] } {
        set ns_id ""
    }
    if { $ns_id ne "" } {
        set ns_exists_p [db_0or1row check_ns_id_exists "select id as ns_id_db from hf_ns_records where id=:ns_id"]
    }
    # filter data to limits
    if { $active_p ne "1" } {
        set active_p 0
    }
    if { $ns_exists_p } {
        # update existing record
        db_dml hf_ns_update {
            update hf_ns_records set name_record=:name_record, active_p=:active_p,instance_id=:instance_id where id=:ns_id
        }
        set success_p 1
    } else {
        # insert new record
        set ns_id [db_nextval hf_id_seq]
        db_dml hf_ns_insert {
            insert into hf_ns_records (active_p,name_record,instance_id,id)
            values (:active_p,:name_record,:instance_id,:ns_id)
        }
        set success_p 1
    }
    return $success_p
}



ad_proc -private hf_vm_quota_write {
    plan_id
    description
    base_storage
    base_traffic
    base_memory
    base_sku
    over_storage_sku
    over_traffic_sku
    over_memory_sku
    storage_unit
    traffic_unit
    memory_unit
    qemu_memory
    status_id
    vm_type
    max_domain
    private_vps
    {instance_id ""}
} {
    writes or creates a vm_quota. If id is blank, a new one is created, and the new id returned. id is returned if successful, otherwise 0 is returned.
} {
    hf_ui_go_ahead admin

    set success_p 1
    set vmq_exists_p 0
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { ![qf_is_natural_number $plan_id] } {
        set plan_id ""
    }
    if { $plan_id ne "" } {
        set vmq_exists_p [db_0or1row check_plan_id_exists "select id as plan_id_db from hf_vm_quotas where id=:plan_id"]
    }
    # filter data to limits
    set description [string range $description 0 39]
    if { ![qf_is_integer $base_storage] } {
        set base_storage -1
    }
    if { ![qf_is_integer $base_traffic] } {
        set base_traffic -1
    }
    if { ![qf_is_integer $base_memory] } {
        set base_memory -1
    }
    set base_sku [string range $base_sku 0 39]
    set over_storage_sku [string range $over_storage_sku 0 39]
    set over_traffic_sku [string range $over_traffic_sku 0 39]
    set over_memory_sku [string range $over_memory_sku 0 39]
    if { ![qf_is_integer $storage_unit] } {
        set success_p 0
    }
    if { ![qf_is_integer $traffic_unit] } {
        set success_p 0
    }
    if { ![qf_is_integer $memory_unit] } {
        set success_p 0
    }
    if { ![qf_is_integer $qemu_memory] } {
        set success_p 0
    }
    if { ![qf_is_integer $status_id] } {
        set success_p 0
    }
    if { ![qf_is_integer $vm_type] } {
        set success_p 0
    }
    if { ![qf_is_integer $max_domain] } {
        set success_p 0
    }
    if { $private_vps ne "1" } {
        set private_vps "0"
    }
    # hf_vm_quotas.instance_id plan_id description base_storage base_traffic base_memory base_sku over_storage_sku over_traffic_sku over_memory_sku storage_unit traffic_unit memory_unit qemu_memory status_id vm_type max_domain private_vps
    if { $success_p } {
        if { $vmq_exists_p } {
            # update existing record
            db_dml hf_vmq_update {
                update hf_vmq_records set description:=description, base_storage=:base_storage, base_traffic=:base_traffic, base_memory=:base_memory, base_sku=:base_sku, over_storage_sku=:over_storage_sku, over_traffic_sku=:over_traffic_sku, over_memory_sku=:over_memory_sku, storage_unit=:storage_unit, traffic_unit=:traffic_unit, memory_unit=:memory_unit, qemu_memory=:qemu_memory, status_id=:status_id, vm_type=:vm_type, max_domain=:max_domain, private_vps=:private_vps where id=:plan_id and instance_id=:instance_id
            }
        } else {
            # insert new record
            set plan_id [db_nextval hf_id_seq]
            db_dml hf_vmq_insert {
                insert into hf_vmq_records (plan_id, description, base_storage, base_traffic, base_memory, base_sku, over_storage_sku, over_traffic_sku, over_memory_sku, storage_unit, traffic_unit, memory_unit, qemu_memory, status_id, vm_type, max_domain, private_vps,instance_id)
                values (:plan_id,:description,:base_storage,:base_traffic,:base_memory,:base_sku,:over_storage_sku,:over_traffic_sku,:over_memory_sku,:storage_unit,:traffic_unit,:memory_unit,:qemu_memory,:status_id,:vm_type,:max_domain,:private_vps,:instance_id)
            }
        }
    } else {
        ns_log Notice "hf_vm_quota_write: success_p 0 at least one value doesn't fit: '${instance_id}' '${plan_id}' '${description}' '${base_storage}' '${base_traffic}' '${base_memory}' '${base_sku}' '${over_storage_sku}' '${over_traffic_sku}' '${over_memory_sku}' '${storage_unit}' '${traffic_unit}' '${memory_unit}' '${qemu_memory}' '${status_id}' '${vm_type}' '${max_domain}' '${private_vps}'"
    }
    return $success_p
}

ad_proc -private hf_ua_write {
    ua
    connection_type
    {ua_id ""}
    {instance_id ""}
} {
    writes or creates a ua. If ua_id is blank, a new one is created. If successful,  ua_id is returned, otherwise 0.
} {
    # permissions must be careful here. Should have already been vetted. Log anything suspect
    # only admin_p or create_p create new
    
    set new_ua_id 0
    if { [regexp -- {^[[:graph:]]+$} $details scratch ] } {    
        set log_p 0
        if { ![qf_is_natural_number $instance_id] } {
            # set instance_id package_id
            set instance_id [ad_conn package_id]
            if { $ua_id eq "" } {
                set log_p 1
            }
        }
        # validation and limits
        set connection_type [string range $connection_type 0 23]
        set vk_list [list ]
        foreach {k v} [hf_key] {
            lappend vk_list $v
            lappend vk_list $k
        }
        set sdetail [string map $vk_list $details]
        if { $ua_id ne "" } {
            # update
            set id_exists_p 0
            # does ua_id exist?
            if { [qf_is_natural_number $ua_id] } {
                set id_exists_p [db_0or1row hf_ua_id_get "select ua_id as new_ua_id from hf_ua where instance_id =:instance_id and ua_id =:ua_id"]
            }
            if { $id_exists_p } {
                db_dml hf_ua_update {
                    update hf_ua set details=:sdetail, connection_type=:connection_type where ua_id=:ua_id and instance_id=:instance_id
                }
            }
        }
        if { $new_ua_id eq "" }
        # create
        set new_ua_id [db_nextval hf_id_seq]
        db_dml hf_ua_create {
            insert into hf_ua (ua_id, instance_id, details, connection_type)
            values (:new_ua_id,:instance_id,:sdetail,:connection_type)
        }
        if { $log_p } {
            if { [ns_conn isconnected] } {
                set user_id [ad_conn user_id]
                ns_log Warning "hf_ua_write(2511): Poor call. New ua '${details}' created by user_id ${user_id} called with blank instance_id."
            } else {
                ns_log Warning "hf_ua_write(2513): Poor call. New ua '${details}' with ua_id ${ua_id} created without a connection and called with blank instance_id."
            }
        }
    } else {
        if { [ns_conn isconnected] } {
            set user_id [ad_conn user_id]
            ns_log Warning "hf_ua_write(2552): Poor call rejected. New ua '${details}' for conn '${connection_type}' requested with unprintable or no characters by user_id ${user_id}."
        } else {
            ns_log Warning "hf_ua_write(2513): Poor call rejected. New ua '${details}' for conn '${connection_type}' requested with unprintable or no characters by process without a connection."
        }
    }
    return $new_ua_id
}

