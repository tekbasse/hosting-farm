#hosting-farm/tcl/hosting-farm-asset-biz-procs.tcl
ad_library {

    Asset business logic for Hosting Farm
    @creation-date 25 May 2013
    @Copyright (c) 2014-2016 Benjamin Brink
    @license GNU General Public License 2
    @see project home or http://www.gnu.org/licenses/gpl-2.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com

    # Assets can be created, writen/revised, trashed and deleted.
    # Deleted option should only be available if an asset is trashed. 

}




ad_proc -private hf_asset_op_status_change {
    asset_id
    new_op_status
} {
    Changes the asset_name where the asset is referenced from asset_id. Returns 1 if successful, otherwise 0.

    @param asset_id  The op_status of the asset.
    @param new_op_status   The new op_status.
} {


    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set write_p 0
    set new_op_status_len [string length $new_op_status]
    if { $new_op_status_len < 21 } {
        set write_p [hf_ui_go_ahead_q write]
        if { $write_p } {
            db_dml hf_op_status_change_hf_assets { update hf_assets
                set last_modified=current_timestamp, 
                op_status=:new_op_status 
                where asset_id=:asset_id 
                and instance_id=:instance_id 
            }
        }
    }
    return $write_p
}


ad_proc -private hf_asset_monitor {
    asset_id
    monitor_p
} {
    Changes the state of monitoring for an asset where the asset is referenced from asset_id. 
    Returns 1 if successful, otherwise 0.

    @param asset_id  The asset_id of the asset.
    @param monitor_p   Answers question: Activate monitors? 1 = yes, 0 = no.
    @return 1 or 0
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set monitor_p [qf_is_true $monitor_p]
    set write_p [hf_ui_go_ahead_q write]
    if { $write_p } {
        db_dml hf_monitors_change_hf_assets { update hf_assets
            set last_modified=current_timestamp, 
            monitor_p=:monitor_p 
            where asset_id=:asset_id 
            and instance_id=:instance_id 
        }
    }
    return $write_p
}

ad_proc -private hf_asset_publish {
    asset_id
    publish_p
} {
    Changes the state of publishing for an asset where the asset is referenced from asset_id. 
    Returns 1 if successful, otherwise 0.

    @param asset_id  The asset_id of the asset.
    @param publish_p   Answers question: Activate publishs? 1 = yes, 0 = no.
    @return 1 or 0
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set publish_p [qf_is_true $publish_p]
    set write_p [hf_ui_go_ahead_q write]
    if { $write_p } {
        db_dml hf_publishs_change_hf_assets { update hf_assets
            set last_modified=current_timestamp, 
            publish_p=:publish_p 
            where asset_id=:asset_id 
            and instance_id=:instance_id 
        }
    }
    return $write_p
}


ad_proc -private hf_asset_popularity_change {
    asset_id
    new_popularity
} {
    Changes the asset_name where the asset is referenced from asset_id. 
    Returns 1 if successful, otherwise 0.

    @param asset_id  The popularity of the asset.
    @param new_popularity   The new popularity value.
    @return 1 or 0
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set write_p 0
    set new_popularity_len [string length $new_popularity]
    if { $new_popularity_len < 21 } {
        set write_p [hf_ui_go_ahead_q write]
        if { $write_p } {
            db_dml hf_popularity_change_hf_assets { update hf_assets
                set last_modified=current_timestamp, 
                popularity=:new_popularity 
                where asset_id=:asset_id 
                and instance_id=:instance_id 
            }
        }
    }
    return $write_p
}


ad_proc -private hf_asset_triage_priority_change {
    asset_id
    new_triage_priority
} {
    Changes the asset_name where the asset is referenced from asset_id. 
    Returns 1 if successful, otherwise 0.

    @param asset_id  The triage_priority of the asset.
    @param new_triage_priority   The new triage_priority value.
    @return 1 or 0
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set write_p 0
    set new_triage_priority_len [string length $new_triage_priority]
    if { $new_triage_priority_len < 21 } {
        set write_p [hf_ui_go_ahead_q write]
        if { $write_p } {
            db_dml hf_triage_priority_change_hf_assets { update hf_assets
                set last_modified=current_timestamp, 
                triage_priority=:new_triage_priority 
                where asset_id=:asset_id 
                and instance_id=:instance_id 
            }
        }
    }
    return $write_p
}



ad_proc -public hf_asset_create { 
    asset_arr_name
} {
    Creates hf asset from array, where values are passed using the array
    index names that coorrespond with hf_asset_keys.
    Returns asset_id, or "" if error. See hf_asset_keys for element names.

    @param asset_array_name
    @return asset_id, or "" if error
    @see hf_asset_keys

} {
    upvar 1 $asset_arr_name asset_arr
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    hf_asset_defaults asset_arr
    qf_array_to_vars asset_arr [hf_asset_keys]
    set create_p [hf_ui_go_ahead_q create f_id "" 0]
    set asset_id ""
    if { $create_p } {
        set asset_id [db_nextval hf_id_seq]
        # Always create a new asset. Updates are for hf_asset_write.
        # Not just when: if  $f_id eq ""
        set f_id $asset_id
        set nowts [dt_systime -gmt 1]
        set last_modified $nowts
        set created $nowts
        set trashed_p [qf_is_true $trashed_p]
        
        db_transaction {
            db_dml hf_asset_create "insert into hf_assets
                ([hf_asset_keys ","])
            values ([hf_asset_keys ",:"])" 
            hf_asset_rev_map_update $label $f_id $asset_id $trashed_p
            ns_log Notice "hf_asset_create: asset_type_id '${asset_type_id}' asset_id '$asset_id' \
f_id '$f_id' label '$label' instance_id '$instance_id' user_id '$user_id'"
        } on_error {
            set asset_id 0
            ns_log Error "hf_asset_create: general psql error during db_dml \
for label $label"
        }
    }
    return $asset_id
}


ad_proc -public hf_asset_write {
    asset_arr_name
} {
    Writes a new revision of an existing asset.
    asset_id is an existing revision of template_id.
    Returns the new asset_id or a blank asset_id if unsuccessful.
    @param array_name
    @return asset_id or ""
} {
    upvar 1 $asset_arr_name asset_arr
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    hf_asset_defaults asset_arr
    qf_array_to_vars asset_arr [hf_asset_keys]
    set write_p [hf_ui_go_ahead_q write f_id "" 0]
    set new_asset_id ""
    if { $write_p } {
        set asset_exists_p [hf_f_id_exists_q $f_id]
        if { $asset_exists_p } {
            set old_asset_id $asset_id
            set asset_id [db_nextval hf_id_seq]
            set nowts [dt_systime -gmt 1]
            set last_modified $nowts
            set created $nowts
            set trashed_p [qf_is_true $trashed_p]
            db_transaction {
                db_dml hf_asset_write "insert into hf_assets
                ([hf_asset_keys ","])
                values ([hf_asset_keys ",:"])"
                hf_asset_rev_map_update $label $f_id $asset_id $trashed_p
                ns_log Notice "hf_asset_write: \
 asset_id '${asset_id}' old_asset_id '${old_asset_id}'"
            } on_error {
                ns_log Notice "hf_asset_write: \
id '${asset_id}' f_id '${f_id}' name '${name}' instance_id '${instance_id}' \
user_id '${user_id}'"
                ns_log Error "hf_asset_write: general db error during db_dml"
            }
        } 
    } 
    return $new_asset_id
}

ad_proc -public hf_asset_delete {
    asset_id
} {
    Deletes a revision of an asset. Revision must already have been trashed.
    Returns  1 if successful, otherwise returns 0.
    @param asset_id

    @return 1 or 0

} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    # user must have delete permission or be the creation owner.
    set delete_p [hf_ui_go_ahead_q delete "" "" 0]
    set calling_user_id $user_id
    # user_id is now the creator user_id
    hf_asset_stats $asset_id user_id trashed_p
    if { !$delete_p && $user_id eq $calling_user_id } {
        set delete_p 1
    }
    # revision must have been trashed first
    if { $delete_p } {
        # delete a revision, but not the current one
        if { [hf_asset_revison_current_q $asset_id] } {
            # In q-wiki, the process is to
            # 1. Point to another untrashed revision if available
            # 2. Otherwise point an available trashed revision
            #    and mark as trashed
            # 3. Delete the entire asset
            #    if no other trashed or untrashed revsions exist.
            # This is not expected behavior here.
            
            # Deleting an asset this way is not permitted. Reject.
            # Must leave at least one trashed for archives.
            set delete_p 0
            ns_log Notice "hf_asset_revision_delete.164: Cannot delete \
an asset by deleting current revision trashed_p '${trashed_p}'."
        }
    }
    if { $delete_p && $trashed_p } {
        db_dml hf_asset_rev_delete { delete from hf_assets 
            where asset_id=:asset_id and 
            instance_id=:instance_id 
            and trashed_p = '1'
        }
    } else {
        set delete_p 0
    }
    return $delete_p
}    

ad_proc -public hf_f_id_delete {
    f_id
} {
    Deletes all revisions of asset. Package admins only.
    Returns 1 if deleted. Returns 0 if there were any issues.
    @param f_id
    @return 1 or 0
} {
    upvar 1 instance_id instance_id
    set user_id [ad_conn user_id]
    set instance_id [ad_conn package_id]
    set admin_p [permission::permission_p -party_id $user_id -object_id $package_id -privilege admin]
    set success_p 0
    
    set asset_id [hf_asset_id_of_f_id_if_untrashed $f_id]
    if { $asset_id > 0 } {
        # cannot delete an untrashed asset
        ns_log Notice "hf_f_id_delete.196: cannot delete an untrashed asset. user_id '${user_id}' instance_id '${instance_id}' f_id '${f_id}'"
        set admin_p 0
    }

    if { $admin_p } {
        ns_log Notice "hf_f_id_delete.201: called by user_id '${user_id}' instance_id '${instance_id}'"
        # delete all sub assets and their attributes
        set sub_list [hf_asset_subassets $f_id]
        ns_log Notice "hf_f_id_delete.203: trashing dependent f_id list '${sub_list}'"
        foreach sub_f_id $sub_list {
            hf_f_id_delete $f_id
        }
        # delete all asset attributes

        # hf_monitor_id
        set monitor_id_list [hf_monitor_logs $f_id]
        hf_monitor_delete $monitor_id_list
        
        # hf_services
        set ua_attr_list [hf_attributes_by_type_cascade $f_id "ua"]
        hf_ua_delete $ua_attr_list
        
        # hf_services
        set ss_attr_list [hf_attributes_by_type_cascade $f_id "ss"]
        hf_ss_delete $ss_attr_list
                
        # hf_vh_hosts
        set vh_attr_list [hf_attributes_by_type_cascade $f_id "vh"]
        hf_vh_delete $vh_attr_list
        
        # hf_ip_addresses
        set ip_attr_list [hf_attributes_by_type_cascade $f_id "ip"]
        hf_ip_delete $ip_attr_list

        # hf_network_interfaces
        set ni_attr_list [hf_attributes_by_type_cascade $f_id "ni"]
        hf_ni_delete $ni_attr_list

        # hf_virtual_machines
        set vm_attr_list [hf_attributes_by_type_cascade $f_id "vm"]
        hf_attriubte_vm_delete $vm_attr_list

        # hf_hardware
        set hw_attr_list [hf_attributes_by_type_cascade $f_id "hw"]
        hf_hw_delete $hw_attr_list

        # hf_data_centers
        set dc_attr_list [hf_attributes_by_type_cascade $f_id "dc"]
        hf_dc_delete $dc_attr_list
        
        # delete all revisions of f_id 
        db_dml hf_asset_delete { delete from hf_assets 
            where f_id=:f_id and instance_id=:instance_id and trashed_p = '1' }
        db_dml hf_asset_rev_map_delete { delete from hf_asset_rev_map
            where f_id=:f_id and instance_id=:instance_id }

        set success_p 1

    }
    return $success_p
}

ad_proc -private hf_asset_trash_f_id {
    f_id
} {
    Trashes all revisions of an asset.
    @param f_id
    @return 1
} {
    upvar 1 instance_id instance_id
    db_transaction {
        db_dml hf_asset_rev_map_trash_f {update hf_asset_rev_map 
            set trashed_p='1' 
            where f_id=:f_id 
            and instance_id=:instance_id }
        db_dml hf_assets_trash_f {update hf_assets 
            set trashed_p='1'
            where f_id=:f_id
            and instance_id=:instance_id }
    }
    return 1
}

ad_proc -public hf_asset_trash {
    asset_id
} {
    Trashes an asset revision ie asset_id. Returns 1 if succeeds, else returns 0.
    @param asset_id
    @return 1 or 0

} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set write_p [hf_ui_go_ahead_q write "" "" 0]
    set success_p $write_p
    if { $write_p } {
        set asset_exists_p [hf_asset_id_exists_q $asset_id]
        if { $asset_exists_p } {
            hf_asset_stats $asset_id trashed_p
            if { $trashed_p } {
                # cannot trash a trashed asset.
                # Need to send a fail signal for test audits
                set success_p 0
                ns_log Warning "hf_asset_trash: asset_id '${asset_id}' already trashed."
            } else {
                set nowts [dt_systime -gmt 1]
                set last_modified $nowts
                db_transaction {
                    db_dml hf_asset_trash {update hf_assets
                        set trashed_p='1' 
                        where asset_id=:asset_id 
                        and instance_id=:instance_id}
                    if { [hf_asset_id_current_q $asset_id ] } {
                        set f_id [hf_f_id_of_asset_id $asset_id]
                        hf_asset_trash_f_id $f_id
                    }
                } on_error {
                    ns_log Warning "hf_asset_trash: error for asset_id '${asset_id}'"
                    set success_p 0
                }
            }
        } 
    } 
    return $success_p
}


ad_proc -public hf_asset_untrash {
    asset_id
} {
    Untrashes an asset revision ie asset_id. 
    Returns 1 if succeeds, else returns 0.
    @param asset_id
    @return 1 or 0
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set write_p [hf_ui_go_ahead_q write "" "" 0]
    set success_p $write_p
    if { $write_p } {
        set asset_exists_p [hf_asset_id_exists_q $asset_id]
        if { $asset_exists_p } {
            set nowts [dt_systime -gmt 1]
            set last_modified $nowts
            db_transaction {
                db_dml hf_asset_untrash {update hf_assets 
                    set trashed_p='0' 
                    where asset_id=:asset_id 
                    and instance_id=:instance_id }
                if { [hf_asset_id_current_q $asset_id ] } {
                    db_dml hf_asset_rev_map_trash { update hf_asset_rev_map 
                        set trashed_p='0' 
                        where asset_id=:asset_id 
                        and instance_id=:instance_id }
                }
            } on_error {
                ns_log Warning "hf_asset_untrash: error for asset_id '${asset_id}'"
                set success_p 0
            }
        } 
    } 
    return $success_p
}

ad_proc -public hf_f_id_trash {
    f_id
} {
    Trashes all revisions of f_id.
    Returns 1 if successful, otherwise returns 0
    @param f_id
    @return 1 or 0
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set write_p [hf_ui_go_ahead_q write "" "" 0]
    set success_p $write_p
    if { $write_p } {
        set asset_exists_p [hf_asset_id_exists_q $asset_id]
        if { $asset_exists_p } {
            set nowts [dt_systime -gmt 1]
            set last_modified $nowts
            db_transaction {
                db_dml hf_assets_f_id_trash { update hf_assets 
                    set trashed_p='1' 
                    where f_id=:f_id 
                    and instance_id=:instance_id 
                    and trashed_p!='1' }
                if { [hf_asset_id_current_q $f_id ] } {
                    db_dml hf_asset_rev_map_trash { update hf_asset_rev_map 
                        set trashed_p='0' 
                        where asset_id=:asset_id 
                        and instance_id=:instance_id }
                }
            } on_error {
                ns_log Warning "hf_f_id_trash: error for f_id '${f_id}'"
                set success_p 0
            }
        } 
    } 

}

ad_proc -public hf_f_id_untrash {
    f_id
} {
    Untrashes most recently active asset_id of f_id
    Returns 1 if successful, otherwise returns 0
    @param f_id
    @return 1 or 0
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set write_p [hf_ui_go_ahead_q write f_id "" 0]
    set success_p $write_p
    if { $write_p } {
        set asset_id [hf_asset_id_current_of_f_id $f_id]
        if { $asset_id ne "" } {
            set nowts [dt_systime -gmt 1]
            set last_modified $nowts
            db_transaction {
                db_dml hf_asset_untrash { update hf_assets 
                    set trashed_p='0' 
                    where asset_id=:asset_id 
                    and instance_id=:instance_id }
                db_dml hf_asset_rev_map_trash { update hf_asset_rev_map 
                    set trashed_p='0' 
                    where asset_id=:asset_id 
                    and instance_id=:instance_id }
            } on_error {
                ns_log Warning "hf_f_id_untrash: error for f_id '${f_id}'"
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
    Changes the asset_name where the asset is referenced from asset_id. 
    Returns 1 if successful, otherwise 0.

    @param asset_id  The label of the asset.
    @param new_label   The new label.
    @return 1 or 0
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
                set last_modified=current_timestamp, 
                label=:new_label 
                where asset_id=:asset_id 
                and instance_id=:instance_id }
            set success_p 1
        } on_error {
            set success_p 0
        }
    }
    return $success_p
}



ad_proc -private hf_asset_create_from_asset_template {
    customer_id
    asset_id
    asset_label_new
    {instance_id ""}
} {
    Creates a new asset record based on an existing template. Also schedules a scheduled proc for system maintenance part of process.
    Returns 1 if successful, otherwise returns 0.
    @return 1 or 0
} {


    set read_p [hf_ui_go_ahead_q read "" published 0]
    set create_p [hf_permission_p $user_id $customer_id assets create $instance_id]
    set status_p $create_p

    if { $create_p } {
        # Copy other tables linked to asset.
        # The usual hf_{asset_type_id}_read doesn't work here, because
        # hf_dc, hf_hw and friends are designed for UI exposure of limited variables,
        # whereas the hf_nc_* and copying an asset must include all subsystems and parts.
        # See hf_asset_properties for possibilities by type.

        # dc,hw in switch:
        # Subtle difference between dc and hw.
        # A dc can have 1 property exposed without
        # necessitating a specific hw asset.
        # Assume a simple asset for now, which is default
        switch -exact -- $asset_type_id {
            vm {
                hf_vm_copy $asset_id $asset_label_new $instance_id
            }
            vh {
                hf_vh_copy $asset_id $asset_label_new $instance_id
            }
            ss {
                hf_ss_copy $asset_id $asset_label_new $instance_id
            }
            default {
                set asset_list [hf_asset_read $instance_id $asset_id]
                qf_lists_to_vars $asset_list [hf_asset_read_keys]
                
                if { $monitor_p } {
                    #  Identify monitors
                    set monitor_ids_list [hf_monitor_logs $asset_id $instance_id]
                    foreach id $monitor_ids_list {
                        set config_n_control_list [hf_monitor_configs_read $monitor_id $instance_id]
                        # db procs don't use arrays, so have to put into vars.
                        qf_lists_to_vars $config_n_control_list [hf_monitor_configs_keys]
                        # cnc keys: instance_id monitor_id asset_id label active_p portions_count calculation_switches health_percentile_trigger health_threshold interval_s alert_by_privilege alert_by_role
                        hf_monitor_configs_write $label $active_p $portions_count $calculation_switches $health_percentile_trigger $health_threashold $interval_s $new_asset_id "" $instance_id $alert_by_privilege $alert_by_role
                    }
                }
                # Copy hf_ua table entry. 
                set ua_id_new ""
                if { $ua_id ne "" } {
                    set ua_list [hf_ua_read $ua_id ""]
                    #vars: ua_id ua connection_type instance_id up details
                    qf_lists_to_vars $ua_list [hf_ua_keys]
                    set ua_id_new [hf_ua_write $ua $connection_type "" $instance_id]
                    if { $ua_id_new > 0 } { 
                        hf_up_write $ua_id_new $up $instance_id
                    } else {
                        ns_log Warning "hf_asset_create_from_asset_template.257: Problem creating account for asset_id '${new_asset_id}'"
                    }
                }
                # Copy hf_ns table entry. 
                set ns_id_new ""
                if { $ns_id ne "" } {
                    set ns_list [hf_ns_read $ns_id $instance_id]
                    qf_lists_to_vars $ns_list [list id active_p name_record]
                    set ns_id_new [hf_ns_write "" $name_record $active_p $instance_id]
                }
                #
                # template_p, publish_p, popularity should start false(0) for all copy cases,  op_status s/b ""
                set new_asset_id [hf_asset_create $asset_label_new $name $asset_type_id $content $keywords $description $comments 0 $templated_p 0 $monitor_p 0 $triage_priority "" $ua_id_new $ns_id_new $qal_product_id $customer_id $template_id $flags $instance_id $user_id]
                #hf_asset_create params: label, name, asset_type_id, content, keywords, description, comments, template_p, templated_p, publish_p, monitor_p, popularity, triage_priority, op_status, ua_id, ns_id, qal_product_id, qal_customer_id, template_id, flags, instance_id, user_id

            }
        }
    }

    
    # Schedule process that performs system maintenance part.
    # password and ns changes should take place here, to keep process sequential
    # and not be broken by a process prioritization re-sort.

    return $status_p
}

ad_proc -private hf_asset_create_from_asset_label {
    asset_label_orig
    asset_label_new
    {instance_id ""}
} {
    Creates a new asset with asset_label based on an existing asset. 
    Also scheduels a scheduled proc for system maintenance part of process.
    Returns 1 if successful, otherwise 0.
    @return 1 or 0
} {
    set asset_id_orig [hf_asset_id_of_label $asset_label_orig $instance_id]
    set status_p [hf_asset_create_from_asset_template $customer_id $asset_label_orig $asset_label_new $instance_id]
    return $status_p
}

ad_proc -private hf_asset_templates {
    {label_match ""}
    {inactives_included_p 0}
    {published_p ""}
    {instance_id ""}
} {
    returns active template references (id) and other info via a list of lists, where each list is an ordered tcl list of asset related values: see hf_asset_keys
    @return lists
} {
    # This needs re-worked using revised api
    # scope to user_id
    set user_id [ad_conn user_id]
    set customer_ids_list [hf_customer_ids_for_user $user_id]
    if { $inactives_included_p } {
        set templates_list_of_lists [db_list_of_lists hf_asset_templates_select_all  "select [hf_asset_keys ","] from hf_assets where template_p =:1 and instance_id =:instance_id and asset_id in ( select asset_id from hf_asset_label_map where instance_id = :instance_id ) order by last_modified desc" ]
    } else {
        set templates_list_of_lists [db_list_of_lists hf_asset_templates_select "select [hf_asset_keys ","] from hf_assets where template_p =:1 and instance_id=:instance_id and ( time_stop is null or time_stop < current_timestamp ) and ( trashed_p is null or trashed_p <> '1' ) and asset_id in ( select asset_id from hf_asset_label_map where instance_id = :instance_id ) order by last_modified desc" ]
    }
    # build list of ids that meet at least one criteria
    set return_list [list ]
    foreach template_list $templates_lists_of_lists {
        # first make sure that user_id has access to asset.
        set customer_id [lindex $template_list 6]
        set insert_p 0
        if { $customer_id eq "" || [lsearch -exact $customer_ids_list $customer_id] > -1 } {

            # now check the various requested criteria options. Matching any one or more qualifies.
            # label?
            if { $label_match ne "" && [string match -nocase $label_match [lindex $template_list 7]] } {
                set insert_p 1
            }
            # published_p?
            if { $published_p ne "" } {
                set published_p_val [lindex $template_list 14]
                if { $published_p eq $published_p_val } {
                    set insert_p 1
                }
            }
            if { $insert_p } {
                set insert_p 0
                # just id's:  lappend return_list [lindex $template_list 0]
                lappend return_list $template_list
            }
        }
    }
    return $return_list
}

ad_proc -private hf_asset_do {
    asset_id
    hfl_proc_name
    {instance_id ""}
} {
    Process an hfl_ procedure on asset_id.
    Returns 1 if successful, or 0 if there is an error.
    @return 1 or 0
} {
    set admin_p [hf_ui_go_ahead_q admin "" "" 0]

    set success_p 0
    if { $admin_p } {
        hf_asset_stats $asset_id $instance_id [list asset_type_id template_id]
        set asset_template_id $template_id
        
        set template_ids_name_list [db_list_of_lists hf_calls_read_asset_type_choices { select asset_template_id, asset_id, proc_name from hf_calls where instance_id =:instance_id and asset_type_id =:id } ]
        
        set counter_max [llength $template_ids_name_list ]
        set counter 0
        ## first check all asset_ids
        set proc_name_template ""
        set proc_name_type ""
        # Do we have to loop through all choice cases?  
        # Yes.. Unless we create 3 separate queries instead of one.
        # Unspecific cases would require all three queries. 
        # This loop is instead of 3 separate trips to the db (queries).
        while { $proc_name eq "" && $counter < $counter_max } {
            ns_log Notice "hf_asset_do.550: begin while.."
            set choice_list [lindex $template_ids_name_list $counter]
            # a template_ids_name_list row: asset_template_id asset_id proc_name
            set c_asset_template_id [lindex $choice_list 0]
            set c_asset_id [lindex $choice_list 1]

            # Find the most specific proc_name assignment.

            # Each of these if's should only be true a maximimum of once.
            # Is there a most fine grained (specific) proc_name assigned to this asset_id?
            if { $c_asset_id eq $asset_id } {
                # asset_id is most specific
                set proc_name [lindex $choice_list 2]

                # Does the template of this asset_id have an assigned proc_name?
            } elseif { $asset_template_id eq $c_asset_template_id } {
                # template_id is the next most specific ie all asset_ids with this template_id
                set proc_name_template [lindex $choice_list 2]

                # If other choices aren't available, go with asset_type_id
            } elseif { $c_asset_id eq "" && $c_asset_template_id eq "" } {
                # then go with asset_type_id 
                set proc_name_type  [lindex $choice_list 2]
            }
            incr counter
        }
        # Assign the most specific proc_name
        if { $proc_name eq "" } {
            if { $proc_name_template ne "" } {
                set proc_name $proc_name_template
            } elseif { $proc_name_type ne "" } {
                set proc_name $proc_name_type
            }
        }

        if { $proc_name ne "" } {
            #  add to operations stack that is listened to by an ad_scheduled_proc procedure working in short interval cycles
            # proc_name should be mostly defined in hosting-farm-local-procs
            set success_p [hf::schedule::add $proc_name [list $asset_id $user_id $instance_id] $user_id $instance_id $priority]
        }
    }
    return $success_p
}

