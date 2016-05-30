#hosting-farm/tcl/hosting-farm-asset-biz-procs.tcl
ad_library {

    business logic for hosting-farm assets
    @creation-date 25 May 2013
    @Copyright (c) 2014-2016 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl-2.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com

    # Assets can be created, writen/revised, trashed and deleted.
    # Deleted option should only be available if an asset is trashed. 

}


ad_proc -public hf_asset_create { 
    label
    name
    asset_type_id
    keywords
    description
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
    flags
    template_id
    f_id
    content
    comments
} {
    Creates hf asset. returns asset_id, or 0 if error. See documentation for expectations.

    @return asset_id, or 0 if error
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set create_p [hf_ui_go_ahead_q create f_id "" 0]
    set asset_id 0
    if { $create_p } {
        set asset_id [db_nextval hf_id_seq]
        if { $f_id eq "" } {
            set f_id $asset_id
        }
        set nowts [dt_systime -gmt 1]
        set last_modified $nowts
        set created $nowts
        db_transaction {
            db_dml hf_asset_create " insert into hf_assets
                ([hf_asset_keys ","])
            values ([hf_asset_keys ",:"])" 
            hf_asset_rev_map_update $label $f_id $asset_id $trashed_p
            ns_log Notice "hf_asset_create: hf_asset_create id '$asset_id' f_id '$f_id' label '$label' instance_id '$instance_id' user_id '$user_id'"
        } on_error {
            set asset_id 0
            ns_log Error "hf_asset_create: general psql error during db_dml for label $label"
        }
    }
    return $asset_id
}


ad_proc -public hf_asset_write {
    asset_id
    label
    name
    asset_type_id
    keywords
    description
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
    flags
    template_id
    f_id
    content
    comments
} {
    Writes a new revision of an existing asset. asset_id is an existing revision of template_id. returns the new asset_id or a blank asset_id if unsuccessful.
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set write_p [hf_ui_go_ahead_q write f_id "" 0]
    set new_asset_id ""
    if { $write_p } {
        set asset_exists_p [hf_f_id_exists $f_id]
        if { $asset_exists_p } {
            set old_asset_id $asset_id
            set asset_id [db_nextval hf_id_seq]
            set nowts [dt_systime -gmt 1]
            set last_modified $nowts
            set created $nowts
            db_transaction {
                db_dml hf_asset_write "insert into hf_assets
                ([hf_asset_keys ","])
                values ([hf_asset_keys ",:"])"
                hf_asset_rev_map_update $label $f_id $asset_id $trashed_p
                ns_log Notice "hf_asset_write:  asset_id '${asset_id}' old_asset_id '${old_asset_id}'"
            } on_error {
                ns_log Notice "hf_asset_write: id '${asset_id}' f_id '${f_id}' name '${name}' instance_id '${instance_id}' user_id '${user_id}'"
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

    @param asset_id

    @return 1 if successful, otherwise returns 0.

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
            # 2. Otherwise point an available trashed revision and mark as trashed
            # 3. Delete the entire asset if no other trashed or untrashed revsions exist.
            # This is not expected behavior here.
            
            # Deleting an asset this way is not permitted. Reject. Must leave at least one trashed for archives.
            set delete_p 0
            ns_log Notice "hf_asset_revision_delete.164: Cannot delete an asset by deleting current revision trashed_p '${trashed_p}'."
        }
    }
    if { $delete_p && $trashed_p } {
        db_dml hf_asset_rev_delete { delete from hf_assets 
            where id=:asset_id and instance_id=:instance_id and trashed_p = '1' }
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
} {
    upvar 1 instance_id instance_id
    set user_id [ad_conn user_id]
    set instance_id [ad_conn package_id]
    set delete_p [permission::permission_p -party_id $user_id -object_id $package_id -privilege admin]
    set success_p 0
    
    set asset_id [hf_asset_id_of_f_id_if_untrashed $f_id]
    if { $asset_id > 0 } {
        # cannot delete an untrashed asset
        ns_log Notice "hf_f_id_delete.196: cannot delete an untrashed asset. user_id '${user_id}' instance_id '${instance_id}' f_id '${f_id}'"
        set delete_p 0
    }

    if { $delete_p } {
        ns_log Notice "hf_f_id_delete.201: called by user_id '${user_id}' instance_id '${instance_id}'"
        # delete all sub assets
        set sub_list [hf_asset_subassets_cascading $f_id]
        ns_log Notice "hf_f_id_delete.203: trashing dependent f_id list '${sub_list}'"
        foreach sub_f_id $sub_list {
            hf_f_id_delete $f_id
        }
        # delete all asset attributes

        # hf_monitor_freq_dist_curves
        set monitor_id_list [hf_monitor_logs $f_id]
        ns_log Notice "hf_f_id_delete.211: deleteing monitor_ids '${hf_monitor_id_list}'"
        db_dml hf_monitor_dc_delete { delete from hf_monitor_freq_dist_curvs where monitor_id in ([template::util::tcl_to_sql_list $monitor_id_list]) and instance_id=:instance_id }
        db_dml hf_monitor_stats_delete { delete from hf_monitor_statistics where monitor_id in ([template::util::tcl_to_sql_list $monitor_id_list]) and instance_id=:instance_id }
        db_dml hf_monitor_status_delete { delete from hf_monitor_status where monitor_id in ([template::util::tcl_to_sql_list $monitor_id_list]) and instance_id=:instance_id }
        db_dml hf_monitor_cnc_delete { delete from hf_monitor_config_n_control where monitor_id in ([template::util::tcl_to_sql_list $monitor_id_list]) and instance_id=:instance_id and asset_id=:f_id }
        db_dml hf_monitor_log_delete { delete from hf_monitor_log where monitor_id in ([template::util::tcl_to_sql_list $monitor_id_list]) and instance_id=:instance_id and asset_id=:f_id }

        # hf_monitor_statistics
        # hf_monitor_status
        # hf_monitor_log
        # hf_monitor_config_n_control
        # hf_ua_up_map hf_up
        # hf_ua
        # hf_services
        # hf_vh_hosts
        # hf_ip_addresses
        # hf_network_interfaces

        # hf_virtual_machines
        set attr_list [hf_asset_attributes $f_id "vm"]
        if { [llength $attr_list > 0 ] } {
            db_dml hf_asset_del_vm_attrs { delete from hf_virtual_machines where hw_id in ([template::util::tcl_to_sql_list $attr_list]) and instance_id=:instance_id }
        }

        # hf_hardware
        set attr_list [hf_asset_attributes $f_id "hw"]
        if { [llength $attr_list > 0 ] } {
            db_dml hf_asset_del_hw_attrs { delete from hf_hardware where hw_id in ([template::util::tcl_to_sql_list $attr_list]) and instance_id=:instance_id }
        }
        # hf_data_centers
        set attr_list [hf_asset_attributes $f_id "dc"]

        if { [llength $attr_list > 0 ] } {
            db_dml hf_asset_del_dc_attrs { delete from hf_data_centers where dc_id in ([template::util::tcl_to_sql_list $attr_list]) and instance_id=:instance_id }
        }
        

        # delete all revisions of f_id 
        db_dml hf_asset_delete { delete from hf_assets 
            where f_id=:f_id and instance_id=:instance_id and trashed_p = '1' }
        db_dml hf_asset_rev_map_delete { delete from hf_asset_rev_map
            where f_id=:f_id and instance_id=:instance_id }
##code
        set success_p 1

    }
    return $success_p
}

ad_proc -public hf_asset_trash {
    asset_id
} {
    Trashes/untrashes asset_id. If trash_p is "1", asset_id is untrashed. Returns 1 if succeeds, else returns 0.
} {
    
    
}

ad_proc -public hf_f_id_trash {
    f_id
} {
    Trashes/untrashes asset_id or template_id (subject to permission check).
    set trash_p to 1 (default) to trash asset. Set trash_p to '0' to untrash. 
    Returns 1 if successful, otherwise returns 0
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id

    # asset_id can be unpublished revision or the published revision, trashed or untrashed
    set label ""

    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
        set untrusted_user_id [ad_conn untrusted_user_id]
    }
    #set write_p \[permission::permission_p -party_id $user_id -object_id $instance_id -privilege write\]
    set customer_id [hf_customer_id_of_asset_id $asset_id $instance_id]
    set write_p [hf_permission_p $user_id $customer_id assets write $instance_id]
    set asset_id_active_p 0

    # if write_p, don't need to scope to user_id == asset_user_id
    if { $write_p } {

        if { $asset_id ne "" } {
            # trash revision
            set template_id [lindex [hf_asset_stats $asset_id $instance_id] 5]
            set label [hf_asset_label_of_id $template_id]
            # wtr = write privilege trash revision
            db_dml hf_asset_trash_wtr { update hf_assets set trashed_p=:trash_p, last_modified = current_timestamp
                where id=:asset_id and instance_id=:instance_id }
            # is asset_id associated with a label ie published?
            set asset_id_active_p [db_0or1row hf_label_of_asset_id { select label from hf_asset_label_map 
                where asset_id=:asset_id and instance_id=:instance_id } ]

        } elseif { $template_id ne "" } {
            set label [hf_asset_label_of_id $template_id]
            # template_id affects all revisions. 
            # asset_id is blank. set asset_id to asset label's asset_id
            set asset_id [hf_asset_id_of_label $label]
            # wtp = write privilege trash asset ie bulk trashing revisions
            db_dml hf_asset_trash_wtp { update hf_assets set trashed_p=:trash_p, last_modified = current_timestamp
                where template_id=:template_id and instance_id=:instance_id }
            set asset_id_trash_p 1
        }

    } else {

        # a user can only un/trash their own entries
        # the user_id scope is applied in the query
        if { $asset_id ne "" } {
            # trash one revision
            set template_id [lindex [hf_asset_stats $asset_id $instance_id] 5]            
            set label [hf_asset_label_of_id $template_id]
            # utr = user privilege trash revision
            db_dml hf_asset_trash_utr { update hf_assets set trashed_p=:trash_p, last_modified = current_timestamp
                where id=:asset_id and instance_id=:instance_id and user_id=:user_id }
            # is asset_id associated with a label ie published?
            set asset_id_active_p [db_0or1row hf_label_of_asset_id { select label from hf_asset_label_map 
                where asset_id=:asset_id and instance_id=:instance_id } ]
            
        } elseif { $template_id ne "" 0 } {
            # trash for all revisions possible for same template_id
            set label [hf_asset_label_of_id $template_id]
            set asset_id [hf_asset_id_of_label $label]
            
            # utp = user privilege trash asset (as many revisions as they created)
            db_dml hf_asset_trash_utp { update hf_assets set trashed_p=:trash_p, last_modified = current_timestamp
                where template_id=:template_id and instance_id=:instance_id and user_id=:user_id }            
            set asset_id_active_p 1
        }
        
    }

#    ns_log Notice "hf_asset_trash: asset_id_active_p '$asset_id_active_p' trash_p '$trash_p'"

    if { $asset_id_active_p && $trash_p } {
        #  need to choose an alternate asset_id if available, since this asset_id is trashed
        ns_log Notice "hf_asset_trash(529). need to change asset_id"
        # asset_id is old_asset_id  
        # select most recent, available new_asset_id
        set new_asset_id_exists [db_0or1row hf_available_asset_id { select id as new_asset_id from hf_assets 
            where template_id=:template_id and instance_id=:instance_id and not (trashed_p = '1') and not ( id=:asset_id ) order by created desc limit 1 } ]
        if { $new_asset_id_exists } {
            ns_log Notice "hf_asset_trash(583): new_asset_id $new_asset_id"
            #  point to the most recent untrashed revision
            if { $asset_id ne $new_asset_id } {
                ns_log Notice "hf_asset_trash: changing active asset_id from $asset_id to $new_asset_id"
                db_dml hf_asset_label_id_update { update hf_asset_label_map set asset_id=:new_asset_id 
                    where instance_id=:instance_id and asset_id=:asset_id }
                # we avoided having to update trashed status for label_map
                set $asset_id_active_p 0
            }
        } 
    }

    if { !$trash_p } {
        # if asset_id of label_map is trashed, untrash it.

        db_0or1row hf_asset_label_trashed_p { select trashed_p as label_trashed_p from hf_asset_label_map
            where label=:label and instance_id=:instance_id }
        set label_trashed_p_exists_p [info exists label_trashed_p]
        if { !$label_trashed_p_exists_p || ( $label_trashed_p_exists_p && $label_trashed_p ne "1" ) } {
            set label_trashed_p 0
        }
        if { $label_trashed_p } {
            set label_asset_id [hf_asset_id_of_label $label $instance_id]
 #           ns_log Notice "hf_asset_trash(603): updating trash and asset_id '$label_asset_id' for label '$label' to asset_id '$asset_id' untrashed"
            db_dml hf_asset_label_map_update2 { update hf_asset_label_map set asset_id=:asset_id, trashed_p=:trash_p
                    where instance_id=:instance_id and asset_id=:label_asset_id }
            set asset_id_active_p 0
        }
        # untrash the label
    }

    # if asset_id active or untrashing asset_id and asset_label trashed
    if { $asset_id_active_p } {
        # published asset_id is affected, set mapped asset trash also.
        ns_log Notice "hf_asset_trash: updating hf_asset_label_map asset_id '$asset_id' instance_id '$instance_id'"
        db_dml hf_asset_label_trash_update { update hf_asset_label_map set trashed_p=:trash_p 
            where asset_id=:asset_id and instance_id=:instance_id }
    }
    return 1
}

