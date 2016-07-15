#hosting-farm/tcl/hosting-farm-attr-util-procs.tcl
ad_library {

    utility library of attributes for Hosting Farm
    @creation-date 5 June 2013
    @Copyright (c) 2014 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl-2.0.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com
    

}

# following defined in permissions-procs.tcl
# hf_customer_ids_for_user
# hf_active_asset_ids_of_customer 

# API for various asset attributes
#  in each case, add ecds-pagination bar when displaying. 
#  defaults to all allowed by user permissions


ad_proc -private hf_asset_primary_attr {
    asset_id
} {
    Returns primary sub_asset_id for asset_id, or empty string if not
    existing.

    Each asset is of a type asset_type_id and has a record in hf_assets.
    Each asset has a primary attribute. 
    A primary attribute is of the same type as asset_type_id,
    and of the associated attribute table, 
    hf_virtual_machines for vm asset_type_id for example.
    If the asset has more than one of attribute of same type,
    the primary attributed is the one with the lowest sub_sort_order.
} {
    upvar 1 instance_id instance_id

    set f_id [hf_f_id_of_asset_id $asset_id]
    set sub_f_id [hf_primary_sub_f_id $f_id]
    return $sub_f_id
}

ad_proc -private hf_asset_features {
    {asset_type_id_list ""}
} {
    returns a tcl_list_of_lists of features with attributes.
    Each feature is related to one asset_type_id

    @return asset_type_id This is something like vm, vh, ss etc.
    @return feature_id    Uniquely identifies feature record
    @return label         An abbreviation identifying the feature.
    @return feature_type  For grouping features
    @return publish_p     Answers question. Publish this feature?
    @return title         Feature title
    @return description   A description of feature.
} {
    upvar 1 instance_id instance_id
    hf_ui_go_ahead_q read "" published
    set new_as_type_id_list [hf_list_filter_by_visible $asset_type_id_list ]
    set keys_list [db_list_of_lists hf_asset_type_features_get "select [hf_asset_feature_keys ","] where instance_id=:instance_id and asset_type_id in ([template::util::tcl_to_sql_list $new_as_type_id_list])"]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}


ad_proc -private hf_asset_feature_keys {
} {
    Returns an ordered list of keys for hf_asset_type_features
} {
    set keys_list [list instance_id id asset_type_id label feature_type publish_p title description]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}


ad_proc -private hf_asset_type_write {
    label
    title
    description
    id
} {
    Creates or writes asset type.
    If id record exists, updates id. Otherwise creates a new record.
    User must be a site admin.
    @return 1 if successful. Otherwise returns 0.
} {
    set user_id [ad_conn user_id]
    set instance_id [ad_conn package_id]
    set admin_p [permission::permission_p -party_id $user_id -object_id \
                     $package_id -privilege admin]
    set success_p $admin_p
    if { $admin_p } {
        set at_list [hf_asset_type_id_list]
        if { $id ni $at_list } {
            # create new id
            db_dml asset_type_create "insert into hf_asset_type ([hf_asset_type_keys ","]) values ([hf_asset_type_keys ",:"])"
        } else {
            db_dml asset_type_write {update hf_asset_type
                set label=:label,title=:title,description=:description where instance_id=:instance_id and id=:id}
        }
    }
    return $success_p
}

ad_proc -private hf_asset_type_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_asset_type
} {
    # see also hf_asset_type_feature_keys.
    set keys_list [list instance_id id label name halt_proc start_proc details]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}


ad_proc -private hf_asset_type_feature_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_asset_type_features
} {
    set keys_list [list asset_type_id feature_id label feature_type publish_p name details]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}

ad_proc -private hf_ns_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_network_interfaces
} {
    set keys_list [list instance_id ns_id active_p name_record time_trashed time_created]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}


ad_proc -private hf_ni_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_network_interfaces
} {
    set keys_list [list instance_id ni_id os_dev_ref bia_mac_address ul_mac_address ipv4_addr_range ipv6_addr_range time_trashed time_created]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}

ad_proc -private hf_ip_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_ip_addresses.
} {
    set keys_list [list instance_id ip_id ipv4_addr ipv4_status ipv6_addr ipv6_status time_trashed time_created]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}


ad_proc -private hf_hw_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_hardware.
} {
    set keys_list [list instance_id hw_id system_name backup_sys os_id description details time_trashed time_created]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}


ad_proc -private hf_dc_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_data_centers.
} {
    set keys_list [list instance_id dc_id affix description details time_trashed time_created]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}



ad_proc -private hf_vh_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_vhosts.
} {
    set keys_list [list instance_id vh_id domain_name details time_trashed time_created]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}



ad_proc -private hf_vm_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_virtual_machines
} {
    set keys_list [list instance_id vm_id domain_name os_id server_type resource_path mount_union details time_trashed time_created]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}


ad_proc -private hf_vm_quota_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_vm_quotas
} {
    set keys_list [list instance_id plan_id description base_storage base_traffic base_memory base_sku over_storage_sku over_traffic_sku over_memory_sku storage_unit traffic_unit memory_unit vmm_memory status_id vm_type max_domain private_vps time_trashed time_created]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}


ad_proc -private hf_ss_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_services
} {
    set keys_list [list instance_id ss_id server_name service_name daemon_ref protocol port ss_type ss_subtype ss_undersubtype ss_ultrasubtype config_uri memory_bytes details time_trashed time_created] 
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}

ad_proc -private hf_sub_asset_map_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_sub_asset_map.
} {
    set keys_list [list instance_id f_id type_id sub_f_id sub_type_id sub_sort_order sub_label attribute_p trashed_p last_updated]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}

ad_proc -private hf_ip_id_exists_q {
    ip_id_q
    {instance_id ""}
} {
    Checks if ip_id in hf_ip_addresses exists. 1 true, 0 false
} {
    set ip_id_exists_p 0
    if { [qf_is_natural_number_p $ip_id] } {
        set ip_id_exists_p [db_0or1row ip_id_exists_q {
            select ip_id 
            from hf_ip_addresses 
            where instance_id=:instance_id 
            and ip_id=:ip_id_q } ]
    }
    return $ip_id_exists_p
}


ad_proc -private hf_ni_id_exists_q {
    ni_id_q
    {instance_id ""}
} {
    Checks if ni_id in hf_network_interfaces exists. 1 true, 0 false
} {
    set ni_id_exists_p 0
    if { [qf_is_natural_number_p $ni_id] } {
        set ni_id_exists_p [db_0or1row ni_id_exists_q {
            select ni_id 
            from hf_network_interfaces 
            where instance_id=:instance_id 
            and ni_id=:ni_id_q } ]
    }
    return $ni_id_exists_p
}


ad_proc -private hf_os_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_operating_systems
} {
    set keys_list [list instance_id os_id label brand version kernel orphaned_p requires_upgrade_p description time_trashed time_created]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}

ad_proc -private hf_primary_sub_f_id {
    f_id
} {
    Returns the primary sub_f_id of f_id, if one exists. Otherwise returns an empty string.
} {
    # A stricter version of hf_asset_primary_attr
    set sub_f_id ""
    db_0or1row hf_sub_asset_id_prime_get {select sub_f_id 
        from hf_sub_asset_map 
        where f_id=:f_id 
        and type_id=sub_type_id
        and attribute_p!='0'
        and trashed_p!='1'
        and instance_id=:instance_id
        order by sub_sort_order asc limit 1}
    return $sub_f_id
} 

ad_proc -private hf_f_id_of_sub_f_id {
    sub_f_id
    {primary_p "0"}
} {
    Returns the f_id of sub_f_id. f_id is the asset connected to attribute sub_f_id.
    If primary_p is 1, returns the f_id only if sub_f_id is the primary attribute for f_id.

    @return f_id, or "" if does not exist
} {
    upvar 1 instance_id instance_id
    set f_id ""
    set exists_p [db_0or1row hf_sub_asset_map_f_id_of_sub_f_id {
        select f_id, sub_type_id 
        from hf_sub_asset_map 
        where sub_f_id=:sub_f_id 
        and instance_id=:instance_id } ]
    if { $exists_p && $primary_p } {
        set sub_f_id_primary [hf_primary_sub_f_id $f_id]
        if { $sub_f_id_primary ne $sub_f_id } {
            set f_id ""
        } 
    }
    return $f_id
}


ad_proc -private hf_sub_f_id_current_q { 
    sub_f_id
} {
    Returns 1 if sub_f_id is the current revision for sub_f_id.

    @param sub_f_id      The sub_f_id to check.

    @return  1 if true, otherwise returns 0.
} {
    upvar 1 instance_id instance_id
    set current_p 0
    if {[qf_is_natural_number $sub_f_id ] } {
        set current_p [db_0or1row hf_sub_f_id_current_q { 
            select f_id from hf_sub_asset_map 
            where sub_f_id=:sub_f_id 
            and trashed_p!='1'
            and instance_id=:instance_id } ]
        if { !$current_p } {
            ns_log Notice "hf_sub_f_id_current_q: not current. \
 sub_f_id '${sub_f_id}' instance_id '${instance_id}'"
        }
    }
    return $current_p

}

ad_proc -private hf_sub_asset {
    sub_f_id
    {f_id ""}
} {
    Returns a list of values from hf_sub_asset_map in order of hf_sub_asset_map_keys, or empty list if not found. If f_id is supplied, scopes to f_id.
} {
    upvar 1 instance_id instance_id
    if { [qf_is_natural_number $f_id] } {
        set xtra_sql "and f_id=:f_id "
    } else {
        set xtra_sql ""
    }
    set sam0_list [db_list_of_lists hf_sub_asset_map_read "select [hf_sub_asset_map_keys ","] from hf_sub_asset_map where sub_f_id=:sub_f_id ${xtra_sql}and instance_id=:instance_id"]
    set sam_list [lindex $sam0_list 0]
    return $sam_list
}

ad_proc -private hf_sub_f_id_current { 
    sub_f_id
    {f_id ""}
} {
    Returns current sub_f_id if sub_f_id references current or trashed sub_f_id, else returns 0. This assumes hf_sub_asset_map.sub_label has not changed between revisions.  If f_id is supplied, also confirms sub_f_id is dependent on f_id.

    @param sub_f_id      The sub_f_id to check.

    @return sub_f_id one sub_f_id exists and untrashed, otherwise 0.
} {
    upvar 1 instance_id instance_id
    set sub_f_id_orig $sub_f_id
    set sub_f_id 0
    set sam_list [hf_sub_asset $sub_f_id_orig $f_id]
    if { [llength $sam_list] > 0 } {
        qf_lists_to_vars $sam_list [hf_sub_asset_map_keys]
        set exists_p [db_0or1row hf_f_id_of_sub_f_id_tr { 
            select sub_f_id 
            from hf_sub_asset_map 
            where f_id=:f_id
            and sub_label=:sub_label
            and sub_type_id=:sub_type_id
            and attribute_p=:attribute_p
            and trashed_p!='1'
            and instance_id=:instance_id } ]
        if { !$exists_p } {
            ns_log Notice "hf_sub_f_id_current: not found. \
 sub_f_id '${sub_f_id}' instance_id '${instance_id}'"
        }
    }
    return $sub_f_id
}


ad_proc -private hf_label_of_sub_f_id {
    sub_f_id
} {
    @param sub_f_id  

    @return label of attribute with sub_f_id, or empty string if not exists.
} {
    upvar 1 instance_id instance_id
    set sub_label ""
    set exists_p [db_0or1row hf_label_of_sub_f_id { select sub_label from hf_sub_asset_map 
        where sub_f_id=:sub_f_id and instance_id=:instance_id } ]
    if { !$exists_p } {
        ns_log Notice "hf_label_of_sub_f_id: not found. sub_f_id '${sub_f_id}' instance_id '${instance_id}'"
    }
    return $sub_label
}

ad_proc -private hf_sub_f_id_of_label {
    label
    {f_id ""}
} {
    Returns list of sub_f_id of untrashed attributes with same label, 
    or an empty list if none found.
    If f_id is included, query is scoped to the immediate f_id dependents, where there should be no more than one untrashed label .
    
    @param label  

    @return sub_f_id 
} {
    upvar 1 instance_id instance_id
    set sub_f_id_list [list ]
    if { $f_id ne "" } {
        set sub_f_id_list [db_list hf_sub_f_id_of_label_f_id { 
            select sub_f_id from hf_sub_asset_map 
            where sub_label=:label 
            and f_id=:f_id
            and instance_id=:instance_id 
            and trashed_p!='1'
        }]

    } else {
        set sub_f_id_list [db_0or1row hf_sub_f_id_of_label { 
            select sub_f_id from hf_sub_asset_map 
            where sub_label=:label 
            and instance_id=:instance_id
            and trashed_p!='1'
        }]
    }
    set sub_f_id_list_len [llength $sub_f_id_list]
    if { $sub_f_id_list_len == 0  } {
        ns_log Notice "hf_sub_f_id_of_label: not found. label '${label}' instance_id '${instance_id}' '${f_id}'"
    }
    return $sub_f_id_list
}

ad_proc -private hf_asset_attribute_map_create {
    asset_id
    sub_label
    sub_asset_type_id
} {
    Link a new attribute to an existing asset. This includes for creating primary attribute case for each asset.
} {
    upvar 1 instance_id instance_id
    set sub_f_id ""
    set f_id [hf_f_id_of_asset_id $asset_id]
    set type_id [hf_asset_type_id_of_asset_id $f_id]
    if { $type_id ne "" } {
        set allowed_sub_type_id_list [hf_types_allowed_by $type_id]
        if { $sub_asset_type_id in $allowed_sub_type_id_list } {
            set sub_type_id $sub_asset_type_id
            set sub_sort_order [hf_asset_cascade_count $f_id]
            if { $sub_type_id eq $type_id && $sub_label eq "" } {
                # give it a label
                if { $sub_sort_order == 1 } {
                    # assume this is primary attribute.
                    set sub_label [hf_label_of_f_id $f_id]
                } else {
                    set sub_label [string range [hf_label_of_f_id $f_id] 0 50]
                    append sub_label "-"
                    append sub_label $sub_sort_order
                }
            } elseif { $sub_label eq "" } {
                set sub_label $sub_type_id
                append sub_label "-"
                append sub_label $sub_sort_order
            }                
            set sub_sort_order [expr { $sub_sort_order * 20 } ]
            set nowts [dt_systime -gmt 1]
            set sub_f_id [db_nextval hf_id_seq]

            #set time_created $nowts
            set last_updated $nowts
            # translate api conventions to internal map refs

            set trashed_p 0
            set attribute_p 1
            ns_log Notice "hf_asset_attribute_map_create.492: f_id ${f_id} sub_f_id ${sub_f_id} sub_sort_order ${sub_sort_order}"
            db_dml hf_asset_attribute_map_cr "insert into hf_sub_asset_map \
 ([hf_sub_asset_map_keys ","]) values ([hf_sub_asset_map_keys ",:"])"
        } else {
            ns_log Notice "hf_asset_attribute_map_create.505: sub_asset_type_id '${sub_asset_type_id}' cannot be dependent of type_id '${type_id}'"
        }
    }
    return $sub_f_id
}

ad_proc -private hf_sub_f_id_exists_q {
    sub_f_id
} {
    upvar 1 instance_id instance_id
    if { [hf_label_of_sub_f_id $sub_f_id] eq "" } {
        set sub_f_id_exists_p 0
    } else {
        set sub_f_id_exists_p 1
    }
    return $sub_f_id_exists_p
}

ad_proc -private hf_attribute_map_update {
    old_id
    {new_id ""}
} {
    Update the map of an existing attribute
    with a new id.
    If new_id is blank or matches an existing attribute, 
    a new sub_f_id is created. 
    Returns an empty string if there was an error.

    @param old_id Previous sub_f_id of attribute
    @param new_id New sub_f_id of attribute

    @returns new_id
} {
    upvar 1 instance_id instance_id
    set success_p 0
    set sub_f_id_new ""
    # 2. link updated attribute to existing asset/attribute 
    #    (including primary asset case) if attribute.label (sub_label) is same.
    #    The updated attribute will be issued a different id and map updated

    #    if the label changes, Is this different than a new attribute?
    #    Keep and trash the old attribute id and map, and create a new map
    #    using hf_attribute_sub_label_update
    set sub_f_id_new ""
    if { $new_id ne "" } {
        set new_f_id_exists_p [hf_f_id_exists_q $new_id]
        set new_sub_f_id_exists_p [hf_sub_f_id_exists_q $new_id]
        if { !$new_f_id_exists_p && !$new_sub_f_id_exists_p } {
            # new_id seems unused..
            set sub_f_id_new $new_id
        }
    } 
    if { $sub_f_id_new eq "" } {
        set sub_f_id_new [db_nextval hf_id_seq]
    }
    # update existing attrbute maps
    set nowts [dt_systime -gmt 1]
    ns_log Notice "hf_attribute_map_update.551: old_id '${old_id}' new_id '${new_id}'"
    db_transaction {
        db_dml hf_attribute_map_sub_f_id_update { 
            update hf_sub_asset_map
            set sub_f_id=:sub_f_id_new,
            last_updated=:nowts
            where sub_f_id=:old_id
            and instance_id=:instance_id
            and trashed_p!='1'
        }
        db_dml hf_attribute_map_f_id_update { 
            update hf_sub_asset_map
            set f_id=:sub_f_id_new,
            last_updated=:nowts
            where f_id=:old_id 
            and instance_id=:instance_id
            and trashed_p!='1'
        }
    } on_error {
        ns_log Warning "hf_attribute_map_update.519: Error: '${errmsg}'"
    }
    return $sub_f_id_new
}

ad_proc -private hf_assets_map_create {
    f_id
    sub_f_id
} {
    Link existing asset to another existing asset.
    @param f_id The asset f_id that will be parent of the two.
    @param sub_f_id The asset f_id that will be child of the two.
    @return 1 if success, otherwwise returns 0.
} {
    upvar 1 instance_id instance_id
    set success_p 0
    set asset_id [hf_asset_id_current_of_f_id $f_id]
    set sub_asset_id [hf_asset_id_current_of_f_id $sub_f_id]
    if { $asset_id ne ""  && $sub_asset_id ne "" } {
        set type_id [hf_asset_type_id_of_asset_id $f_id]
        set stats_list [hf_asset_stats $sub_asset_id [list label asset_type_id]]
        if { $type_id ne "" && $asset_type_id ne "" } {
            set nowts [dt_systime -gmt 1]
            set last_updated $nowts
            set sub_type_id $asset_type_id
            set sub_label [string range $label 0 64]
            set sub_sort_order [expr { [hf_asset_cascade_count $f_id] * 20 } ]
            set trashed_p 0
            set attribute_p 0
            set success_p 1
            ns_log Notice "hf_assets_map_create.598: f_id '${f_id}' sub_f_id '${sub_f_id}' sub_sort_order '${sub_sort_order}'"
            db_dml hf_assets_map_cr "insert into hf_sub_asset_map \
 ([hf_sub_asset_map_keys ","]) values ([hf_sub_asset_map_keys ",:"])"
        }
    } else {
            ns_log Notice "hf_assets_map_create.614: sub_asset_type_id '${sub_asset_type_id}' cannot be dependent of type_id '${type_id}'"
    }
    return $success_p
}

ad_proc -private hf_attributes_map_create {
    f_id
    sub_label
    sub_asset_type_id
} {
    Creates a map between an existing attribute and a new attribute.
    The existing attribute's sub_f_id is called an f_id here
    because the sub_f_id becomes an f_id for purposes of this map.
    These attributes must have different labels.
    @param f_id ie sub_f_id of existing attribute
    @param sub_label of new attribute
    @param sub_asset_type_id of new attribute
    @return sub_f_id of new attribute
} {
    # 4. link new attribute to existing attribute. 
    #    hf_attributes_map_create
    #    If this were done via hf_sub_asset_map.sub_label references 
    #    instead of f_id/sub_f_id
    #    because id of attributes change with each revision,
    #    and sub_label will not expected to change..
    #    The mapping system would have to be significantly altered.
    #    Instead, 
    #     all cases of the changed id must be updated at the same time
    #    See case 2. (hf_attribute_map_update)
    # Why do the sub_labels have to differ?  
    # To help enforce unqiue sub_labels per level of hierarchy and 
    # maybe to help prevent cases of asset primary attribute morphology
    # being used in attribute-attribute inheritance --where
    # sub_label and asset.label are perhaps expected to be same.
    
    set sub_f_id ""
    set sub_label_new $sub_label
    set sam_list [hf_sub_asset $f_id]
    qf_lists_to_vars $sam_list [hf_sub_asset_map_keys]
    if { $sub_label ne "" && $sub_label ne $sub_label_new } {
        set allowed_sub_type_id_list [hf_types_allowed_by $type_id]
        if { $sub_asset_type_id in $allowed_sub_type_id_list } {
            set nowts [dt_systime -gmt 1]
            set sub_f_id [db_nextval hf_id_seq]
            set sub_sort_order [expr { [hf_asset_cascade_count $f_id ] * 20 } ]
            set last_updated $nowts
            # translate api conventions to internal map refs
            set sub_type_id $sub_asset_type_id
            set trashed_p 0
            set attribute_p 1
            ns_log Notice "hf_attributes_map_create.652: f_id '${f_id}' sub_f_id '${sub_f_id}' sub_sort_order '${sub_sort_order}'"
            db_dml hf_attributes_map_cr "insert into hf_sub_asset_map \
 ([hf_sub_asset_map_keys ","]) values ([hf_sub_asset_map_keys ",:"])"
        } else {
            ns_log Notice "hf_attributes_map_create.666: sub_asset_type_id '${sub_asset_type_id}' cannot be dependent of type_id '${type_id}'"
        }
    }
    return $sub_f_id
}

ad_proc -private hf_sub_asset_map_update {
    f_id
    asset_type_id
    sub_label
    sub_f_id
    sub_asset_type_id
    {attribute_p ""}
} {
    Updates or creates a new map record.

    @return sub_f_id_new Returns a new sub_f_id to assign to new attribute record. Otherwise returns an empty string if unsuccessful.
} {
    # This proc is the heart of asset / attribute inheritance behavior.
    # It needs to handle these cases:
    # 0. primary asset case consists of special case of case 1.
    #    an asset and an attribute of same type that describes asset detail.
    # 1. link new attribute to existing asset  (including primary asset case)
    #    hf_asset_attribute_map_create

    # 2. link updated attribute to existing asset/attribute 
    #    hf_attribute_map_update
    #    (including primary asset case) if attribute.label (sub_label) is same.
    #    The updated attribute will be issued a different id and map updated.
    #    If the label changes, Is this different than a new attribute?
    #    Keep and trash the old attribute id and map, and create a new map.
    # 3. link existing asset to existing (other) asset
    #    hf_assets_map_create
    # 4. link new attribute to existing attribute. 
    #    hf_attributes_map_create
    #    If this were done via hf_sub_asset_map.sub_label references 
    #    instead of f_id/sub_f_id
    #    because id of attributes change with each revision,
    #    and sub_label will not expected to change..
    #    The mapping system would have to be significantly altered.
    #    Instead, 
    #     all cases of the changed id must be updated at the same time
    #    See case 2.

    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    # determine if f_id is an asset.
    set f_id_asset_p [hf_f_id_exists_q $f_id]
    set f_id_attr_p 0
    if { !$f_id_asset_p && [qf_is_natural_number $f_id] } {
        # is f_id an attribute?
        set f_id_attr_p [hf_sub_f_id_current_q $f_id]
    }
    # determin if sub_f_id is an asset, attribute, or blank (a new attribute)
    set sub_f_id_attr_new_p 0
    set sub_f_id_asset_p 0
    set sub_f_id_attr_p 0
    if { [qf_is_natural_number $sub_f_id] } {
        set sub_f_id_asset_p [hf_f_id_exists_q $sub_f_id]
        if { !$sub_f_id_asset_p } {
            set sub_f_id_attr_p [hf_sub_f_id_current_q $sub_f_id]
        }
    }
    if { !$sub_f_id_asset_p && !$sub_f_id_attr_p } {
        set sub_f_id ""
        set sub_f_id_attr_new_p 1
        set sub_f_id_attr_p 1
    }
    set sub_f_id_new ""
    # Call the appropriate proc from the cases above.
    if { $f_id_asset_p && $sub_f_id_attr_new_p } {
        # case 1
        set sub_f_id_new [hf_asset_attribute_map_create $f_id $sub_label $sub_asset_type_id]
    } elseif { $f_id_asset_p && $sub_f_id_asset_p } {
        # case 3
        set sub_f_id_new [hf_assets_map_create $f_id $sub_f_id]
    } elseif { $f_id_attr_p && $sub_f_id_attr_new_p } {
        # case 4
        set sub_f_id_new [hf_attributes_map_create $f_id $sub_label $sub_asset_type_id]
    } elseif { $sub_f_id_attr_p } {
        # case 2
        set sub_f_id_new [hf_attribute_map_update $sub_f_id]
    } else {
        ns_log Warning "hf_sub_asset_map_update.747: case not found for f_id '${f_id}' sub_f_id '${sub_f_id}'"
    }
    return $sub_f_id_new
}

ad_proc -private hf_up_id_of_ua_id {
    ua_list
} {
    Returns one or more up_id as a list.
} {
    upvar 1 instance_id instance_id
    set up_id_list [db_list up_id_of_ua_id_r
                    select up_id from hf_ua_up_map \
                        where instance_id=:instance_id and \
                        ua_id in ([template::util::tcl_to_sql_list $ua_list])]
    return $ua_list
}

ad_proc -private hf_ua_id_of_f_id_label {
    f_id
    sub_label
} {
    f_id of the asset or attribute. sub_label is the label assigned to the ua.

    @param f_id
    @param sub_label

    @return ua_id, or empty string if none found.
} {
    upvar 1 instance_id instance_id
    set sub_f_id ""
    set f_id_list [list $f_id]
    # if sub_f_id is primary, also check f_id
    set f_id_pri [hf_f_id_of_sub_f_id $sub_f_id 1]
    if { $f_id_pri ne "" } {
        lappend f_id_list $f_id_pri
    }
    db_0or1row hf_sub_asset_map_ua_id_r1 { select sub_f_id from hf_sub_asset_map
        where f_id in ([template::util::tcl_to_sql_list $f_id_list])
        and sub_label=:sub_label 
        and instance_id=:instance_id }
    return $sub_f_id
}

ad_proc -private hf_ua_id_of_f_id_ua {
    f_id
    ua
} {
    f_id of the asset or attribute. ua is ua input from user ie pre coded.
} {
    upvar 1 instance_id instance_id
    set mystify_proc [parameter::get -package_id $instance_id -parameter MystifyProc -default hf_mystify]
    set sdetail [safe_eval [list ${mystify_proc} $ua]]
    set ua_id ""
    set f_id_list [list $f_id]
    # f_id may be  sub_f_id of primary. If so, also check f_id or visa versa.
    set f_id_pri [hf_f_id_of_sub_f_id $sub_f_id 1]
    if { $f_id_pri ne "" } {
        lappend f_id_list $f_id_pri
    }
    db_0or1row hf_sub_asset_map_ua_id_r2 { select sam.sub_f_id as ua_id 
        from hf_sub_aset_map sam, hf_ua hu 
        where hu.details=:sdetail
        and hu.instance_id=sam.instance_id
        and sam.instance_id=:instance_id
        and sam.sub_f_id=hu.ua_id
        and sam.f_id in ([template::util::tcl_to_sql_list $f_id_list]) }
    return $ua_id
}

ad_proc -private hf_ua_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_ua
} {
    set keys_list [list ua_id ua connection_type instance_id up details]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}

ad_proc -private hf_encode {
    string
    {key_list ""}
} {
    upvar 1 instance_id instance_id
    if { $key_list eq "" || [llength $key_list ] < 2 } {
        # other choices: hf_chars 1,  hf_key
        set key_list [hf_key]
    }
    set vka_list [list ]
    foreach {k v} $key_list {
        lappend vka_list $v
        lappend vka_list $k
    }
    set x [string map $vka_list $string]
    return $x
}

ad_proc -private hf_decode {
    string
    {key_list ""}
} {
    upvar 1 instance_id instance_id
    if { $key_list eq "" || [llength $key_list ] < 2 } {
        set key_list [hf_key]
    }
    set x [string map $key_list $string]
    return $x
}


ad_proc -private hf_mystify {
    string
    {key_list ""}
} {
    upvar 1 instance_id instance_id
    if { $key_list eq "" || [llength $key_list ] < 2 } {
        # other choices: hf_chars 1,  hf_key
        set key_list [hf_key "abcdefghijklmnopqrstuvwxyz0123456789_" ]
    }
    set vka_list [list ]
    foreach {k v} $key_list {
        lappend vka_list $v
        lappend vka_list $k
    }
    set x [string map $vka_list $string]
    return $x
}

ad_proc -private hf_demystify {
    string
    {key_list ""}
} {
    upvar 1 instance_id instance_id
    if { $key_list eq "" || [llength $key_list ] < 2 } {
        set key_list [hf_key "abcdefghijklmnopqrstuvwxyz0123456789_" ]
    }
    set x [string map $key_list $string]
    return $x
}

ad_proc -private hf_up_ck {
    ua
    up_submitted
    ua_id
    {instance_id ""}
} {
    Checks submitted against existing. 

    @param ua_id is f_id  or sub_f_id for cases where associated with an asset or attribute and ua_id is unknown

    @return 1 if matches, otherwise returns 0. 
} {
    set ck_ok_p 0
    set log_p 1
    set connected_p [ns_conn isconnected]
    if {[qf_is_natural_number $ua_id] } {
        if { [hf_are_safe_and_visible_characters_q $ua ] } {
            set log_p 0
            if { ![qf_is_natural_number $instance_id] && $connected_p } {
                # set instance_id package_id
                set instance_id [ad_conn package_id]
                if { $ua eq "" } {
                    set log_p 1
                }
            }
        }
        if { !$log_p } {
            # validation and limits
            set connection_type [string range $connection_type 0 23]
            set mystify_proc [parameter::get -package_id $instance_id -parameter MystifyProc -default hf_mystify]
            set encode_proc [parameter::get -package_id $instance_id -parameter EncodeProc -default hf_encode]
            set sdetail [safe_eval [list ${mystify_proc} $ua]]
            set uup  [safe_eval [list ${encode_proc} $up_submitted]]
            # f_id may be asset f_id or ua_id.
            set f_id_list [hf_asset_attributes_by_type $ua_id "ua"]
            lappend ua_id_list $ua_id
            set ck_ok_p [db_0or1row hf_ua_ck_up {select ua.ua_id from hf_ua ua, hf_up up, hf_ua_up_map hm where ua.instance_id=:instance_id and ua.instance_id=up.instance_id and ua.ua_id=hm.ua_id and ua.ua_id in ([template::util::tcl_to_sql_list $ua_id_list]) and ua.details=:sdetail and hm.up_id=up.up_id and up.details=:upp}  ]
        } else {
            if { $connected_p } {
                set user_id [ad_conn user_id]
                ns_log Warning "hf_up_ck(2680): Poor call rejected. submitted ua '${ua}' and '${up_submitted}' for conn '${connection_type}' requested by user_id ${user_id}."
            } else {
                ns_log Warning "hf_up_ck(2682): Poor call rejected. submitted ua '${ua}' and '${up_submitted}' for conn '${connection_type}' requested by process without a connection."
            }
        }
    }
    return $ck_ok_p
}

ad_proc -private hf_up_write {
    ua_id
    up
    {instance_id ""}
} {
    writes or creates a up. Fails if up is blank. Returns 1 if successful, otherwise returns 0.
} {
    set success_p 1
    
    # validation and limits
    if { ![qf_is_natural_number $instance_id] && $instance_id ne "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { ![qf_is_natural_number $ua_id] } {
        set ua_id ""
        set success_p 0
    }
    if { $up ne "" } {
        if { ![hf_are_safe_and_visible_characters_q $up] } {
            set up ""
            set success_p 0
        }
    }
    if { $success_p } {
        set encode_proc [parameter::get -package_id $instance_id -parameter EncodeProc -default hf_encode]
        set details [safe_eval [list ${encode_proc} $up]]
        set up_exists_p [db_0or1row ua_id_exists_p {
            select up_id as up_id_db 
            from hf_ua_up_map 
            where ua_id=:ua_id 
            and instance_id=:instance_id } ]
        if { [ns_conn isconnected] } {
            set user_id [ad_conn user_id]
        } else {
            set user_id ""
        }
        # ideally, must have admin_p to create
        # otherwise hf_up_ck must be 1 to update
        # Not practical to enforce at this level.
        # maybe could use user_id and instance_id???
        # Record it in the log.
        if { $up_exists_p } {
            ns_log Notice "hf_up_write.2991: user_id '${user_id}' changed password for ua_id '${ua_id}' instance_id '${instance_id}'"
            db_dml hf_up_update {
                update hf_up set details=:details where instance_id=:instance_id and up_id=:up_id and instance_id=:instance_id)
        }
    } else {
        # create
        set new_up_id [db_nextval hf_id_seq]
        ns_log Notice "hf_up_write.2998: user_id '${user_id}' created password for ua_id '${ua_id}' instance_id '${instance_id}'"
        db_transaction {
            db_dml hf_up_create {
                insert into hf_up (up_id, instance_id, details)
                values (:new_up_id,:instance_id,:details)
            }
            db_dml hf_up_map_it {
                insert into hf_ua_up_map (ua_id, up_id, instance_id)
                values (:ua_id,:new_up_id,:instance_id)
            }
        }
    }    
}
if { !$success_p & $up ne "" } {
    ns_log Warning "hf_up_write.3008: failed. Should not happen."
}
return $success_p
}

ad_proc -private hf_up_of_ua_id {
    ua_id
    {instance_id ""}
} {
    gets up of ua
} {
    set allowed_p [hf_ui_go_ahead_q admin "" "" 0]
    set success_p 1
    set up ""
    if { ![qf_is_natural_number $ua_id] } {
        set ua_id ""
        set success_p 0
    }

    if { $success_p && $allowed_p } {
        set success_p [db_0or1row hf_up_of_ua_id {
            select details 
            from hf_up 
            where instance_id=:instance_id 
            and up_id in (
                          select up_id 
                          from hf_ua_up_map 
                          where ua_id=:ua_id 
                          and instance_id=:instance_id ) } ]
        if { $success_p } {
            set decode_proc [parameter::get -package_id $instance_id -parameter DecodeProc -default hf_decode]
            set up [safe_eval [list ${decode_proc} $details]]
        }
    } else {
        ns_log Warning "hf_up_of_ua_id: request denied for user_id '${user_id}' instance_id '${instance_id}' ua_id '${ua_id}' allowed_p ${allowed_p}"
    }
    return $up
}

ad_proc -private hf_key {
    {key ""}
} {
    Returns key value list. Creates key if it doesn't exist.
} {
    upvar 1 instance_id instance_id
    if { $key eq "" } {
        if { ![db_0or1row hf_sched_params_fk_r { select fk from hf_sched_params } ] } {
            set fk [hf_chars $key 0]
            db_dml hf_fk_cr { insert into hf_sched_params (fk) values (:fk) }
        }
    } else {
        set fk $key
    }
    if { [exists_and_not_null instance_id] } {
        append key [format %x $instance_id]
    }
    set fp [file join [acs_root_dir] hosting-farm [ad_urlencode_path $fk]]
    if { ![file exists $fp] } {
        ns_log Notice "hf_key.696: file '${fp}' does not exist. Creating."
        set file_path [file dirname $fp]
        if { ![file exists $file_path] } {
            file mkdir $file_path
        }
        set k_list [hf_key_create $key]
        set k2_list [list ]
        foreach { key value } $k_list {
            lappend k2_list $value
            lappend k2_list $key
        }
        set fileId [open $fp w]
        puts $fileId [join $k2_list \t]
        close $fileId
    } 
    set fileId [open $fp r]
    set k ""
    while { ![eof $fileId] } {
        gets $fileId line
        append k $line
    }
    close $fileId
    set kv_list [split $k "\t"]
    return $kv_list
}

ad_proc -private hf_key_create {
    {chars ""}
} {
    Returns a list of key value pairs for scrambling a string.
    Scrambles chars in a string.
    If chars is blank, uses a default set.
} {
    upvar 1 instance_id instance_id
    if { $chars eq "" } {
        set chars [hf_chars $chars 1]
    }
    regsub -all -- {[\]\;]} $chars "" chars
    set b "%"
    append b "c"
    set i 0
    set ii_list [list 97 4 4 6 6 4 -73 1 8 8 4 4 6 6 4 ]
    if { [string length $chars] < 58 } {
        lappend ii_list 25 2 -7 1 -10
    }
    foreach ii $ii_list {
        incr i $ii
        lappend med_list [format $b $i]
    }
    set keys_list [lsort -unique [split $chars ""]]
    # how many med in keys_list?
    set med_count 0
    foreach m $med_list {
        if { [lsearch -exact $keys_list $m] > -1 } {
            incr med_count
        }
    }

    set availables_list $keys_list
    set i 0
    set doubles_list [list ]   
    while { $i < $med_count } {
        ns_log Notice "hf_key_create.741: begin while.."
        set pos [expr { int( [random] * [llength $availables_list] ) } ]
        lappend doubles_list [lrange $availables_list $pos $pos]
        set availables_list [lreplace $availables_list $pos $pos]
        incr i
    }
    set val_list $availables_list 
    set new_doubles_list [list ]
    set temp_avail_list $keys_list
    foreach double $doubles_list {
        set key1 $double
        set pos [expr { int( [random] * [llength $temp_avail_list] ) } ]
        set key2 [lrange $temp_avail_list $pos $pos]
        set availables_list [lreplace $temp_avail_list $pos $pos]
        set key $key1
        append key $key2
        lappend new_doubles_list $key
        set pos1 [lsearch -exact $val_list $key1]
        set val_list [lreplace $val_list $pos1 $pos1]
    }

    foreach val $new_doubles_list {
        lappend val_list $val
    }
    foreach dob $doubles_list {
        if { [lsearch -exact $val_list $dob] > -1 } {
            ns_log Error "hf_key_create: Error double ${dob} exists in val_list '${val_list}'"
        }
    }

    set kv_list [list ]
    foreach key $keys_list {
        set pos [expr { int( [random] * [llength $val_list] ) } ]
        set val [lrange $val_list $pos $pos]
        set val_list [lreplace $val_list $pos $pos]
        lappend kv_list $key
        lappend kv_list $val
    }
    return $kv_list
}


ad_proc -private hf_types_allowed_by {
    asset_type_id
} {
    Returns asset_type_ids allowed to be in/below/a-child-of asset_type_id


    @param type_id of an asset or attribute ie from hf_asset_type_id_list

    @return asset_type_id as a list
} {
    # Assume all cases are not allowed unless 
    # explicitly stated. See proc hf_asset_type_id_list
    # y for yes
    # n for no
    set y_list [list ]
    switch -exact -- $asset_type_id {
        dc {
            set y_list [list dc hw vm vh ss ip ni ns ua]
        }
        hw {
            set y_list [list hw vm vh ss ip ni ns ua]
        }
        vm { 
            set y_list [list vh ss ip ni ns ua]
        }
        vh {
            set y_list [list ss ns ua]
        }
        ss { 
            set y_list [list ns ua]
        }
        ni { 
            set y_list [list ns ua ip]
        }
        ns {
            set y_list [list ni ua ip]
        }
        ip {
            set y_list [list ni ua ns]
        }
        ua {
            set y_list [list ss vh ns]
        }
        default {
            ns_log Warning "hf_types_allowed_by.534: unknown asset_type_id '${asset_type_id}'"
        }
    }
    # To use a slower, allowed unless explicitly stated, rules set:
    # set y_list \[set_difference_named_v at_list $n_list\]
    return $y_list
}

ad_proc -private hf_id_is_attribute_q {
    f_id
} {
    Returns 1 if f_id is an attribute, Returns 0 if f_id is not an attribute; ie f_id is an asset. Returns -1 if f_id doesn't exist.
} {
    upvar 1 instance_id instance_id
    # Consider common cases first.
    set attribute_p -1
    set sub_f_id_exists_p [db_0or1row hf_sub_asset_map_sub_f_id_r {
        select attribute_p 
        from hf_sub_asset_map
        where sub_f_id=:f_id 
        and instance_id=:instance_id } ]
    if { !$sub_f_id_exists_p } {
        set f_id_exists_p [hf_f_id_exists_q $f_id]
        if { $f_id_exists_p } {
            set attribute_p 0
        }
    }
    return $attribute_p
}

ad_proc -private hf_asset_type_id_of_f_id {
    f_id
} {
    Returns asset_type_id of an f_id, where f_id can be a sub_f_id of an attribute, or an f_id of an asset.
    Returns empty string if not found.
} {
    upvar 1 instance_id instance_id
    set asset_type_id ""
    set f_id_orig $f_id
    set exists_p [db_0or1row hf_sub_asset_map_type_r { 
        select f_id,type_id,sub_f_id,sub_type_id 
        from hf_sub_asset_map
        where ( f_id=:f_id or sub_f_id=:f_id )
        and instance_id=:instance_id limit 1 } ]
    if { $exists_p } {
        if { $f_id eq $f_id_orig } {
            set asset_type_id $type_id
        } else {
            # sub_f_id eq f_id_orig
            set asset_type_id $sub_type_id
        }
    } else {
        set asset_type_id [hf_asset_type_id_of_asset_id $f_id_orig]
    }
}

ad_proc -private hf_sub_label_define_empty {
} {
    Define an empty sub_label using a convention
} {
    upvar 1 label label
    upvar 1 sub_label sub_label
    upvar 1 f_id f_id
    upvar 1 sub_type_id sub_type_id
    upvar 1 instance_id instance_id
    if { $sub_label eq "" } {
        set ct [hf_asset_cascade_count $f_id]
       if { $label ne "" } {
            set sub_label $label
        } else {
            set sub_label $sub_type_id
        }
        if { $ct > 1 } {
            append sub_label "-"
            append sub_label $ct
        }
    }
}

