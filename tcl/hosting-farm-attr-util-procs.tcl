#hosting-farm/tcl/hosting-farm-attr-util-procs.tcl
ad_library {

    misc API for hosting-farm asset attributes
    @creation-date 5 June 2013
    @Copyright (c) 2014 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl-2.0.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com
    

}

# following defined in permissions-procs.tcl
# hf_customer_ids_for_user
# hf_active_asset_ids_for_customer 

# API for various asset attributes
#  in each case, add ecds-pagination bar when displaying. 
#  defaults to all allowed by user permissions


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
    set keys_list [db_list_of_lists hf_asset_type_features_get "select [hf_asset_feature_keys ","] where instance_id =:instance_id and asset_type_id in ([template::util::tcl_to_sql_list $new_as_type_id_list])"]
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
} {
    Returns an ordered list of keys for hf_asset_type
} {
    set keys_list [list as set_type_id feature_id label feature_type publish_p title description from from hf_asset_type_features]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}

ad_proc -private hf_sub_asset_map_keys {
} {
    Returns an ordered list of keys for hf_sub_asset_map
} {
    set keys_list [list f_id type_id sub_f_id sub_type_id sub_sort_order sub_label attribute_p trashed_p]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}

ad_proc -private hf_ns_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_network_interfaces
} {
    set keys_list [list instance_id id active_p name_record time_trashed time_created]
    set keys_list [set_union $keys_list [hf_sub_asset_map_keys]]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}


ad_proc -private hf_ni_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_network_interfaces
} {
    set keys_list [list instance_id ni_id os_dev_ref bia_mac_address ul_mac_address ipv4_addr_range ipv6_addr_range time_trashed time_created]
    set keys_list [set_union $keys_list [hf_sub_asset_map_keys]]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}

ad_proc -private hf_ip_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_ip_addresses.
} {
    set keys_list [list instance_id ip_id ipv4_addr ipv4_status ipv6_addr ipv6_status time_trashed time_created]
    set keys_list [set_union $keys_list [hf_sub_asset_map_keys]]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}


ad_proc -private hf_hw_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_hardware.
} {
    set keys_list [list instance_id hw_id system_name backup_sys os_id description details time_trashed time_created]
    set keys_list [set_union $keys_list [hf_sub_asset_map_keys]]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}


ad_proc -private hf_dc_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_data_centers.
} {
    set keys_list [list instance_id dc_id affix description details time_trashed time_created]
    set keys_list [set_union $keys_list [hf_sub_asset_map_keys]]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}



ad_proc -private hf_vh_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_vhosts.
} {
    set keys_list [list instance_id vh_id domain_name details time_trashed time_created]
    set keys_list [set_union $keys_list [hf_sub_asset_map_keys]]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}



ad_proc -private hf_vm_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_virtual_machines
} {
    set keys_list [list instance_id vm_id domain_name os_id type_id resource_path mount_union details time_trashed time_created]
    set keys_list [set_union $keys_list [hf_sub_asset_map_keys]]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}


ad_proc -private hf_vm_quota_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_vm_quotas
} {
    set keys_list [list instance_id plan_id description base_storage base_traffic base_memory base_sku over_storage_sku over_traffic_sku over_memory_sku storage_unit traffic_unit memory_unit qemu_memory status_id vm_type max_domain private_vps time_trashed time_created]
    set keys_list [set_union $keys_list [hf_sub_asset_map_keys]]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}


ad_proc -private hf_ss_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_services
} {
    set keys_list [list instance_id ss_id server_name service_name daemon_ref protocol port ss_type ss_subtype ss_undersubtype ss_ultrasubtype config_uri memory_bytes details time_trashed time_created] 
    set keys_list [set_union $keys_list [hf_sub_asset_map_keys]
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
        set ip_id_exists_p 1 [db_0or1row ip_id_exists_q "select ip_id from hf_ip_addresses where instance_id =:instance_id and ip_id=:ip_id_q"]
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
        set ni_id_exists_p 1 [db_0or1row ni_id_exists_q "select ni_id from hf_network_interfaces where instance_id =:instance_id and ni_id = :ni_id_q"]
    }
    return $ni_id_exists_p
}


ad_proc -private hf_os_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_operating_systems
} {
    set keys_list [list instance_id os_id label brand version kernel orphaned_p requires_upgrade_p description time_trashed time_created]
    set keys_list [set_union $keys_list [hf_sub_asset_map_keys]]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}



ad_proc -private hf_f_id_of_sub_f_id {
    sub_f_id
} {
    Returns the f_id of sub_f_id. f_id is the asset connected to attribute sub_f_id.

    @return f_id, or "" if does not exist
} {
    upvar 1 instance_id instance_id
    set f_id ""
    db_0or1row hf_sub_asset_map_f_id_of_sub_f_id "select f_id from hf_sub_asset_map where sub_f_id=:sub_f_id"
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
    set active_q 0
    set trashed_p 0
    set exists_p [db_0or1row hf_sub_f_id_current_q { select f_id from hf_sub_asset_map 
        where sub_f_id=:sub_f_id and instance_id=:instance_id } ]
    ns_log Notice "hf_sub_f_id_current_q: not found. sub_f_id '{$sub_f_id}' instance_id '${instance_id}'"
    return $exists_p
}

ad_proc -private hf_sub_f_id_of_f_id_if_untrashed { 
    f_id
} {
    Returns sub_f_id if f_id exists and is untrashed, else returns 0

    @param f_id      The f_id to check.

    @return sub_f_id if f_id exists and untrashed, otherwise 0.
} {
    upvar 1 instance_id instance_id
    set sub_f_id 0
    set exists_p [db_0or1row hf_f_id_of_sub_f_id_tr { select sub_f_id from hf_sub_asset_map 
        where f_id=:f_id and instance_id=:instance_id and trashed_p='0' } ]
    ns_log Notice "hf_sub_f_id_of_f_id_if_untrashed: not found. sub_f_id '{$sub_f_id}' instance_id '${instance_id}'"
    
    return $sub_f_id
}


ad_proc -private hf_label_of_sub_f_id {
    sub_f_id
} {
    @param sub_f_id  

    @return label of attribute with sub_f_id, or empty string if not exists or active.
} {
    upvar 1 instance_id instance_id
    set label ""
    set exists_p [db_0or1row hf_label_of_sub_f_id { select label from hf_sub_asset_map 
        where sub_f_id=:sub_f_id and instance_id=:instance_id } ]
    if { !$exists_p } {
        ns_log Notice "hf_label_of_sub_f_id: not found. '${sub_f_id}' instance_id '${instance_id}'"
    }
    return $label
}

ad_proc -private hf_sub_f_id_of_label {
    label
} {
    @param label  Label of attribute

    @return sub_f_id of attribute with label, or empty string if not exists or active.
} {
    upvar 1 instance_id instance_id
    set sub_f_id ""
    set exists_p [db_0or1row hf_sub_f_id_of_label { select sub_f_id from hf_sub_asset_map 
        where label=:label and instance_id=:instance_id }]
    if { !$exists_p } {
        ns_log Notice "hf_sub_f_id_of_label: not found. '${label}' instance_id '${instance_id}'"
    }
    return $sub_f_id
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

ad_proc -private hf_ua_keys {
    {separator ""}
} {
    Returns an ordered list of keys for hf_ua
} {
    set keys_list [list ua_id ua connection_type instance_id pw details]
    set keys_list [set_union $keys_list [hf_sub_asset_map_keys]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}


ad_proc -private hf_up_ck {
    ua
    up_submitted
    {connection_type ""}
    {instance_id ""}
} {
    checks submitted against existing. returns 1 if matches, otherwise returns 0.
} {
    set ck_ok_p 0
    set log_p 1
    if { [hf_are_visible_characters_q $ua ] } {
        set log_p 0
        if { ![qf_is_natural_number $instance_id] } {
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
        set vka_list [list ]
        foreach {k v} [hf_key] {
            lappend vka_list $v
            lappend vka_list $k
        }
        set sdetail [string map $vka_list $ua]
        set vkp_list [list ]
        foreach {k v} [hf_key] {
            lappend vkp_list $v
            lappend vkp_list $k
        }
        set upp [string map $vkp_list $up_submitted]
        set ck_ok_p [db_0or1row hf_ua_ck_up {select ua.ua_id from hf_ua ua, hf_up up, hf_ua_up_map hm where ua.instance_id=:instance_id and ua.instance_id=up.instance_id and ua.ua_id=hm.ua_id and ua.connection_type=:connection_type and ua.details=:sdetail and hm.up_id=up.up_id and up.details=:upp}  ]
    } else {
        if { [ns_conn isconnected] } {
            set user_id [ad_conn user_id]
            ns_log Warning "hf_up_ck(2680): Poor call rejected. submitted ua '${ua}' and '${up_submitted}' for conn '${connection_type}' requested by user_id ${user_id}."
        } else {
            ns_log Warning "hf_up_ck(2682): Poor call rejected. submitted ua '${ua}' and '${up_submitted}' for conn '${connection_type}' requested by process without a connection."
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
    if { ![qf_is_natural_number $instance_id] } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { ![qf_is_natural_number $ua_id] } {
        set ua_id ""
        set success_p 0
    }
    if { $up ne "" } {
        if { ![hf_are_visible_characters_q $details] } {
            set up ""
            set success_p 0
        }
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    # ideally, must have admin_p to create
    # otherwise hf_up_ck must be 1 to update
    # Not practical to enforce at this level.
    # maybe could use user_id and instance_id???
    # Record it in the log.

    if { $success_p } {

        set up_exists_p [db_0or1row ua_id_exists_p "select ua_id as ua_id_db from hf_ua where ua_id=:ua_id and instance_id=:instance_id"]
        set vk_list [list ]
        foreach {k v} [hf_key] {
            lappend vk_list $v
            lappend vk_list $k
        }
        set details [string map $vk_list $up]
        if { $up_exists_p } {
            ns_log Notice "hf_ua_write.2991: user_id '${user_id}' changed password for ua_id '${ua_id}' instance_id '${instance_id}'"
            db_dml hf_up_update {
                update hf_up set details=:details where instance_id=:instance_id and up_id is in (select up_id from hf_ua_up_map where ua_id=:ua_id and instance_id=:instance_id)
            }
        } else {
            # create
            set new_up_id [db_nextval hf_id_seq]
            ns_log Notice "hf_ua_write.2998: user_id '${user_id}' created password for ua_id '${ua_id}' instance_id '${instance_id}'"
            db_transaction {
                db_dml hf_up_create {
                    insert into hf_up (up_id, instance_id, details)
                    values (:new_up_id,:instance_id,:details)
                }
                db_dml hf_up_map_it {
                    insert into hf_ua_up_map (ua_id, up_id, instance_id)
                    values (:ua_id,:up_id,:instance_id)
                }
            }
        }    
    }
    if { !$success_p } {
        ns_log Warning "hf_ua_write.3008: failed. Should not happen."
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
        set success_p [db_0or1row hf_up_of_ua_id "select details from hf_up where instance_id=:instance_id and up_id in (select up_id from hf_ua_up_map where ua_id=:ua_id and instance_id=:instance_id"]
        if { $success_p } {
            set hfk_list [hf_key]
            set up [string map $hfk_list $details]
        }
    } else {
        ns_log Warning "hf_up_of_ua_id: request denied for user_id '${user_id}' instance_id '${instance_id}' ua_id '${ua_id}' allowed_p ${allowed_p}"
    }
    return $up
}

ad_proc -private hf_key {
    {key ""}
} {
    Returns key value list. Creates first if it doesn't exist.
} {
    if { $key eq "" } {
        if { ![db_0or1row "select fk from hf_sched_params"]} {
            set fk [ad_generate_random_string 32]
            db_dml hf_fk_cr { insert into hf_sched_params fk values (:fk) }
        }
    } else {
        set fk $key
    }
    set fp [file join [acs_root_dir] hosting-farm [ad_urlencode_path $fk]]
    if { ![file exists $fp] } {
        file mkdir [file path $fp]
        set k_list [hf_key_create]
        set k2_list [list ]
        foreach { key value } $k_list {
            lappend k2_list $value
            lappend k2_list $key
        }
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
    {characters ""}
} {
    Returns a list of key value pairs for scrambling a string.
    Scrambles characters in a string.
    If characters is blank, uses a printable ascii subset.
} {
    if { $characters eq "" } {
        set characters ""
        for { set i 48 } { $i < 59 } { incr i } {
            append characters [format %c $i]
        }
        for { set i 60 } { $i < 91 } { incr i } {
            append characters [format %c $i]
        }
        for { set i 97 } { $i < 122 } { incr i } {
            append characters [format %c $i]
        }
    }
    set commons_list [list a e i o u y 0 1 2 9 A E I O U Y ]

    set keys_list [lsort -unique [split $characters ""]]
    # how many commons in keys_list?
    set commons_count 0
    foreach common $commons_list {
        if { [lsearch -exact $keys_list $common] > -1 } {
            incr commons_count
        }
    }

    set availables_list $keys_list
    set i 0
    set doubles_list [list ]   
    while { $i < $commons_count } {
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
    # explicitly stated
    # [hf_asset_type_id_list \]
    # y for yes
    # n for no
    set y_list [list ]
    switch -exact $asset_type_id {
        dc {
            set y_list [list dc hw vm vh ss ip ni ns]
        }
        hw {
            set y_list [list hw vm vh ss ip ni ns]
        }
        vm { 
            set y_list [list vh ss ip ni ns]
        }
        vh {
            set y_list [list ss ns ]
        }
        ss { 
            set y_list [list ns ]
        }
        ip {
            set y_list $at_list
        }
    }
    # To use a slower, allowed unless explicitly stated, rules set:
    # set y_list \[set_difference_named_v at_list $n_list\]
    return $y_list
}
