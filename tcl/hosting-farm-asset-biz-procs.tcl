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
        hf_attribute_monitor_delete $monitor_id_list
        
        # hf_services
        set ua_attr_list [hf_attributes_by_type_cascade $f_id "ua"]
        hf_attribute_ua_delete $ua_attr_list
        
        # hf_services
        set ss_attr_list [hf_attributes_by_type_cascade $f_id "ss"]
        hf_attribute_ss_delete $ss_attr_list
                
        # hf_vh_hosts
        set vh_attr_list [hf_attributes_by_type_cascade $f_id "vh"]
        hf_attribute_vh_delete $vh_attr_list
        
        # hf_ip_addresses
        set ip_attr_list [hf_attributes_by_type_cascade $f_id "ip"]
        hf_attribute_ip_delete $ip_attr_list

        # hf_network_interfaces
        set ni_attr_list [hf_attributes_by_type_cascade $f_id "ni"]
        hf_attribute_ni_delete $ni_attr_list

        # hf_virtual_machines
        set vm_attr_list [hf_attributes_by_type_cascade $f_id "vm"]
        hf_attriubte_vm_delete $vm_attr_list

        # hf_hardware
        set hw_attr_list [hf_attributes_by_type_cascade $f_id "hw"]
        hf_attribute_hw_delete $hw_attr_list

        # hf_data_centers
        set dc_attr_list [hf_attributes_by_type_cascade $f_id "dc"]
        hf_attribute_dc_delete $dc_attr_list
        
        # delete all revisions of f_id 
        db_dml hf_asset_delete { delete from hf_assets 
            where f_id=:f_id and instance_id=:instance_id and trashed_p = '1' }
        db_dml hf_asset_rev_map_delete { delete from hf_asset_rev_map
            where f_id=:f_id and instance_id=:instance_id }

        set success_p 1

    }
    return $success_p
}
##code

ad_proc -public hf_asset_trash {
    asset_id
} {
    Trashes an asset revision ie asset_id. Returns 1 if succeeds, else returns 0.
} {
    
    
}

ad_proc -public hf_asset_untrash {
    asset_id
} {
    Untrashes an asset revision ie asset_id. Returns 1 if succeeds, else returns 0.
} {
    
    
}

ad_proc -public hf_f_id_trash {
    f_id
} {
    Trashes all revisions of f_id.
    Returns 1 if successful, otherwise returns 0
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id

}

ad_proc -public hf_f_id_untrash {
    f_id
} {
    Untrashes most recently active asset_id of f_id
    Returns 1 if successful, otherwise returns 0
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id

}



