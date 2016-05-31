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

# API for various asset types:
#   in each case, add ecds-pagination bar when displaying. defaults to all allowed by user permissions



ad_proc -private hf_vh_keys {
} {
    Returns an ordered list of keys that is parallel to the ordered list returned by hf_vh_read: label name asset_type_id keywords description content comments trashed_p trashed_by template_p templated_p publish_p monitor_p popularity triage_priority op_status ua_id ns_id qal_product_id qal_customer_id instance_id user_id last_modified created template_id v_ua_id v_ns_id domain_name details vm_id
} {
    set vh_list [list label name asset_type_id keywords description content comments trashed_p trashed_by template_p templated_p publish_p monitor_p popularity triage_priority op_status ua_id ns_id qal_product_id qal_customer_id instance_id user_id last_modified created template_id v_ua_id v_ns_id domain_name details vm_id]
    return $vh_list
}



ad_proc -private hf_asset_features {
    {instance_id ""}
    {asset_type_id_list ""}
} {
    returns a tcl_list_of_lists of features with attributes in order of: asset_type_id, feature_id, label, feature_type, publish_p, title, description
} {
    hf_ui_go_ahead_q read "" published

    # asset type doesn't involve specific client data, so no permissions check required
    # validate/filter the asset_type_id_list for nonqualifying reference types
    set new_as_type_id_list [list ]
    foreach asset_type_id $asset_type_id_list {
        if { [ad_var_type_check_number_p $asset_type_id] } {
            lappend new_as_type_id_list $asset_type_id
        }
    }

    # hf_asset_type_features.instance_id feature_id asset_type_id label feature_type publish_p title description
    # hf_asset_feature_map.instance_id asset_id feature_id
    set feature_list [db_list_of_lists hf_asset_type_features_get "select asset_type_id, feature_id, label, feature_type, publish_p, title, description from from hf_asset_type_features where instance_id =:instance_id and asset_type_id in ([template::util::tcl_to_sql_list $new_as_type_id_list])"]
    return $feature_list
}


# basic API

ad_proc -private hf_asset_type_write {
    label
    title
    description
    {id ""}
    {instance_id ""}
} {
    creates or writes asset type, if id is blank, returns id of new asset type; otherwise returns 1 if id exists and db updated. 
} {
    set admin_p [hf_ui_go_ahead_q admin "" "" 0]
    set asset_type_id ""
    set return_val $admin_p
    if { $admin_p } {
        if { $id eq "" } {
            # create new id
            set asset_type_id [db_nextval hf_id_seq]
            db_dml asset_type_create {insert into hf_asset_type
                (instance_id,id,label,title,description)
                values (:instance_id,:asset_type_id,:label,:title,:description) }
            set return_val $asset_type_id
        } else {
            # check if id exists
            db_0or1row asset_type_id_ck "select label as id_ck from hf_asset_type where instance_id =:instance_id and id=:id"
            if { [info exists id_ck] } {
                db_dml asset_type_write {update hf_asset_type
                    set label =:label, title =:title, description=:description where instance_id =:instance_id and id=:id}
            } else {
                set return_val 0
            }
        }
    }
    return $return_val
}


ad_proc -private hf_vm_keys {
} {
    Returns an ordered list of keys that is parallel to the ordered list returned by hf_vm_read: label name asset_type_id keywords description content comments trashed_p trashed_by template_p templated_p publish_p monitor_p popularity triage_priority op_status ua_id ns_id qal_product_id qal_customer_id instance_id user_id last_modified created template_id vm_domain_name vm_ip_id vm_ni_id vm_ns_id vm_os_id vm_type_id vm_resource_path vm_mount_union vm_details
} {
    set vm_list [list label name asset_type_id keywords description content comments trashed_p trashed_by template_p templated_p publish_p monitor_p popularity triage_priority op_status ua_id ns_id qal_product_id qal_customer_id instance_id user_id last_modified created template_id vm_domain_name vm_ip_id vm_ni_id vm_ns_id vm_os_id vm_type_id vm_resource_path vm_mount_union vm_details
    return $vm_list
}

ad_proc -private hf_ss_keys {
} {
    Returns an ordered list of keys that is parallel to the ordered list returned by hf_ss_read: label name asset_type_id keywords description content comments trashed_p trashed_by template_p templated_p publish_p monitor_p popularity triage_priority op_status ua_id ns_id qal_product_id qal_customer_id instance_id user_id last_modified created template_id ss_server_name ss_service_name ss_daemon_ref ss_protocol ss_port ss_ua_id ss_ss_type ss_ss_subtype ss_ss_undersubtype ss_ss_ultrasubtype ss_config_uri ss_memory_bytes ss_details
} {
    set ss_list [list label name asset_type_id keywords description content comments trashed_p trashed_by template_p templated_p publish_p monitor_p popularity triage_priority op_status ua_id ns_id qal_product_id qal_customer_id instance_id user_id last_modified created template_id ss_server_name ss_service_name ss_daemon_ref ss_protocol ss_port ss_ua_id ss_ss_type ss_ss_subtype ss_ss_undersubtype ss_ss_ultrasubtype ss_config_uri ss_memory_bytes ss_details]
    return $ss_list
}


ad_proc -private hf_ip_id_exists_q {
    ip_id_q
    {instance_id ""}
} {
    Checks if ip_id in hf_ip_addresses exists. 1 true, 0 false
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }

    set ip_id_exists_p 0
    if { [ad_var_type_check_number_p $ip_id] } {
        db_0or1row ip_id_exists_q "select ip_id from hf_ip_addresses where instance_id =:instance_id and ip_id = :ip_id_q"
        if { $ip_id ne "" && $ip_id > 0 } {
            set ip_id_exists_p 1
        }
    }
    return $ip_id_exists_p
}

ad_proc -private hf_ni_id_exists_q {
    ni_id_q
    {instance_id ""}
} {
    Checks if ni_id in hf_network_interfaces exists. 1 true, 0 false
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }

    set ni_id_exists_p 0
    if { [ad_var_type_check_number_p $ni_id] } {
        db_0or1row ni_id_exists_q "select ni_id from hf_network_interfaces where instance_id =:instance_id and ni_id = :ni_id_q"
        if { $ni_id ne "" && $ni_id > 0 } {
            set ni_id_exists_p 1
        }
    }
    return $ni_id_exists_p
}



ad_proc -private hf_ua_keys {
} {
    Returns an ordered list of keys that is parallel to the ordered list returned by hf_ua_read: ua_id ua connection_type instance_id pw details
} {
    set ua_list [list ua_id ua connection_type instance_id pw details]
    return $ua_list
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
    if { [regexp -- {^[[:graph:]]+$} $ua scratch ] } {
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
        if { ![regexp -- {^[[:graph:]]+$} $details scratch ] } {
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


