# hosting-farm/tcl/hosting-farm-asset-util-procs.tcl
ad_library {

    utilities for hosting-farm assets
    @creation-date 25 May 2013
    @Copyright (c) 2014-2016 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl-2.0.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com


}


ad_proc -private hf_asset_ids_for_user { 
    user_id
} {
    Returns asset_ids available to user_id as list 
} {
    upvar 1 instance_id instance_id
    set asset_ids_list [list ]
    if { [qf_is_natural_number $user_id] } {
        set customer_ids_list [hf_customer_ids_for_user $user_id]
        # get asset_ids assigned to customer_ids
        set asset_ids_list [list ]
        foreach customer_id $customer_ids_list {
            set assets_list [hf_asset_ids_for_customer $instance_id $customer_id]
            foreach asset_id $assets_list {
                lappend asset_ids_list $asset_id
            }
        }
    }
    return $asset_ids_list
}


ad_proc -private hf_customer_id_of_asset_id {
    asset_id
} {
    returns customer_id of asset_id
} {
    upvar 1 instance_id instance_id
    # this is handy for helping fulfill hf_permission_p requirements
    # so do not create an infinite loop by referencing a permissions proc like this:
    # hf_ui_go_ahead_q read
    set f_id [hf_f_id_of_asset_id $asset_id]
    set customer_id ""
    db_0or1row hf_customer_id_of_asset_id "select qal_customer_id from hf_assets where instance_id = :instance_id and id=:f_id order by last_modified desc"
    return $customer_id
}


ad_proc -private hf_asset_type_id_list {
 } {
    Returns list of all asset_type_id
} {
    upvar 1 instance_id instance_id
    #set as_type_list \[list dc hw vm vh ss ip ni ot\]
    if { [exists_and_not_null $instance_id] } {
        set as_type_list [db_list hf_asset_type_id_by_i {select distinct id from hf_asset_type where instance_id=:instance_id}]
    } else {
        set as_type_list [db_list hf_asset_type_id_all {select distinct id from hf_asset_type}]
    }
    return $as_type_list
}

ad_proc -private hf_asset_id_exists_q { 
    asset_id
    {asset_type_id ""}
} {
    Returns 1 if asset_id exists, else returns 0

    @param asset_id      The asset_id to check.
    @param asset_type_id If not blank, also verifies that asset is of this type.

    @return  1 if asset_id exists, otherwise 0.
} {
    upvar 1 instance_id instance_id
    set asset_type_id_q $asset_type_id
    set read_p [hf_ui_go_ahead_q read]
    set asset_exists_p 0
    # We can use results hf_ui_go_ahead_q to partially deduce answer
    if { $read_p } {
        if { $asset_type_id ne "" } {
            if { $asset_type_id ne $asset_type_id_q } {
                set asset_exists_p 0
            } else {
                set asset_exists_p 1
            }
        } else {
            set asset_exists_p [db_0or1row hf_asset_get_id {select name from hf_assets where id=:asset_id and instance_id=:instance_id } ]
        }
    }
    if { !$asset_exists_p } {
        ns_log Notice "hf_asset_id_exists_q: asset_id does not exist. asset_id '${asset_id}' asset_type_id '${asset_type_id}' instance_id '${instance_id}'"
    }
    return $asset_exists_p
}

ad_proc -private hf_user_id_of_asset_id {
    asset_id
} {
    Returns primary user_id for asset_id, or empty string if not found.
} {
    # log_read needs to be adjusted so monitor notifications work for anyone with admin role for asset_id
    set user_id ""
    set asset_id [qf_is_natural_number $asset_id]
    db_0or1row hf_assets_read_uid "select user_id from hf_assets where asset_id=:asset_id"
    return $user_id
}


ad_proc -private hf_f_id_active_q { 
    f_id
} {
    Returns 1 if f_id exists, is untrashed, and not stopped else returns 0

    @param f_id      The f_id of asset_id to check.

    @return  asset_id , or 0
} {
    upvar 1 instance_id instance_id
    set active_q 0
    set exists_and_is_untrashed_p [hf_asset_id_of_f_id_if_untrashed $asset_id]
    if { $exists_and_is_untrashed_p } {
        hf_asset_stats $asset_id "time_stop"
        if { $time_stop ne "" } {
            set active_q 1
        }
    } 
    return $active_p
}


ad_proc -private hf_asset_id_current_q { 
    asset_id
} {
    Returns 1 if asset_id is the current revision for asset_id.

    @param asset_id      The asset_id to check.

    @return  1 if true, otherwise returns 0.
} {
    upvar 1 instance_id instance_id
    set active_q 0
    set trashed_p 0
    set exists_p [db_0or1row hf_asset_id_current_q { select f_id from hf_asset_rev_map 
        where asset_id=:asset_id and instance_id=:instance_id } ]
    ns_log Notice "hf_asset_active_q: asset_id requested is trashed or does not exist. asset_id '{$asset_id}' instance_id '${instance_id}'"
    return $exists_p
}

ad_proc -private hf_asset_id_of_f_id_if_untrashed { 
    f_id
} {
    Returns asset_id if f_id exists and is untrashed, else returns 0

    @param f_id      The f_id to check.

    @return asset_id if f_id exists and untrashed, otherwise 0.
} {
    upvar 1 instance_id instance_id
    set asset_id 0
    set exists_p [db_0or1row hf_f_id_of_asset_id_tr { select asset_id from hf_asset_rev_map 
        where f_id=:f_id and instance_id=:instance_id and trashed_p='0' } ]
    ns_log Notice "hf_asset_active_q: asset_id requested is trashed or does not exist. asset_id '{$asset_id}' instance_id '${instance_id}'"
    
    return $asset_id
}


ad_proc -private hf_label_of_asset_id {
    asset_id
} {
    @param asset_id  

    @return label of asset with asset_id, or empty string if not exists or active.
} {
    upvar 1 instance_id instance_id
    set label ""
    set exists_p [db_0or1row hf_label_of_asset_id { select label from hf_asset_rev_map 
        where asset_id=:asset_id and instance_id=:instance_id } ]
    if { !$exists_p } {
        ns_log Notice "hf_label_of_asset_id: label does not exist for asset_id '${asset_id}' instance_id '${instance_id}'"
    }
    return $label
}

ad_proc -private hf_asset_id_of_label {
    label
} {
    @param label  Label of asset

    @return asset_id of asset with label, or empty string if not exists or active.
} {
    upvar 1 instance_id instance_id
    set asset_id ""
    set exists_p [db_0or1row hf_asset_id_of_label { select asset_id from hf_asset_rev_map 
        where label=:label and instance_id=:instance_id }]
    if { !$exists_p } {
        ns_log Notice "hf_asset_id_of_label: asset_id does not exist for label '${label}' instance_id '${instance_id}'"
    }
    return $asset_id
}


ad_proc -private hf_asset_id_change {
    asset_id_new
    {label ""}
    {asset_id ""}
} {
    Changes the active revision of asset with asset_label to asset_id. 

    @param asset_id_new   The new asset_id
    @param label         The label of the asset.
    @param asset_id      An asset_id of the asset.

    @return   Returns 1 if success, otherwise returns 0.
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    # convert label to asset_id
    if { $asset_id eq "" && $label ne "" } {
        set asset_id [hf_asset_id_of_label $label]
    }
    set write_p [hf_ui_go_ahead_q write]
    set success_p 0
    if { $write_p } {
        # new and current asset
        db_dml hf_asset_id_change { update hf_asset_rev_map
            set asset_id=:asset_id_new where label=:asset_label and instance_id=:instance_id }
        db_dml hf_asset_id_change_active { update hf_assets
            set last_modified = current_timestamp where id=:asset_id and instance_id=:instance_id }
        set success_p 1
    } else {
        ns_log Notice "hf_asset_id_change: no write allowed for asset_id_new '{$asset_id_new}' label '${label}' asset_id '${asset_id}'"
    }
    return $success_p
}


ad_proc -private hf_f_id_exists_q {
    f_id
} {
    @param f_id

    @return 1 if exists, otherwise returns 0.
} {
    set exists_p [db_0or1row hf_f_id_exists_p "select f_id from hf_asset_rev_map where f_id=:f_id" ]
    return $exists_p
}


ad_proc -private hf_f_id_of_asset_id {
    asset_id
} {
    Returns hf_asset.f_id given any revision asset_id of f_id, otherwise returns empty string.

    @param asset_id

    @return f_id
} {
    upvar 1 instance_id instance_id
    set f_id ""
    db_0or1row hf_asset_get_f_id_of_asset_id { select f_id from hf_assets where instance_id=:instance_id and id=:asset_id }
    return $f_id
}

ad_proc -private hf_asset_id_current_of_f_id { 
    f_id
} {
    Returns current asset_id given f_id, otherwise returns empty string.

    @param f_id  hf_asset.f_id for an asset.

    @return asset_id The current asset_id mapped to the label and f_id, else returns empty string.
} {
    upvar 1 instance_id instance_id
    set asset_id ""
    db_0or1row hf_asset_get_asset_id_of_f_id { select asset_id from hf_asset_rev_map 
        where instance_id=:instance_id and f_id=:f_id }
    return $asset_id
}


ad_proc -private hf_asset_id_current_of_label { 
    label
} {
    Returns asset_id if asset is published (untrashed) for instance_id, else returns empty string.
} {
    upvar 1 instance_id instance_id
    set asset_id ""
    db_0or1row hf_asset_get_id_of_label {select asset_id from hf_label_map 
        where label=:label and instance_id=:instance_id and not ( trashed_p = '1' ) } 
    return $asset_id
}

ad_proc -private hf_asset_id_current {
    asset_id
} {
    Returns current asset_id given any revision asset_id of asset.

    @param asset_id  One of any revision of asset_id

    @return asset_id The current, active asset_id, otherwise empty string.
} {
    upvar 1 instance_id instance_id
    set asset_id_current ""
    set f_id [hf_f_id_of_asset_id $asset_id]
    if { $f_id ne "" } {
        set asset_id_current [hf_asset_id_current_of_f_id $f_id]
    }
    return $asset_id_current
}


ad_proc -private hf_asset_keys {
    {separator ""}
} {
    Returns an ordered list of keys that is parallel to the ordered list returned by hf_asset_read.

    If separator is not "", returns a string joined with separator.
    @see hf_keys_by
} {
    set keys_list [list \
                       asset_id \
                       label \
                       name \
                       asset_type_id \
                       trashed_p \
                       trashed_by \
                       template_p \
                       templated_p \
                       publish_p \
                       monitor_p \
                       popularity \
                       triage_priority \
                       op_status \
                       qal_product_id \
                       qal_customer_id \
                       instance_id \
                       user_id \
                       last_modified \
                       created \
                       flags \
                       template_id \
                      f_id]
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}


ad_proc -private hf_asset_rev_map_update {
    label
    f_id
    asset_id
    trashed_p
} {
    Creates or updates an asset map given f_id exists. If f_id does not exist, creates a new map record.
} {
    upvar 1 instance_id instance_id

    # Does f_id exist?
    if { [hf_f_id_exists_q $f_id] } {
        ns_log Notice "hf_asset_rev_map_update: update label '${label}' asset_id '${asset_id}' trashed_p '${trashed_p}' instance_id '${instance_id}'"
        db_dml hf_asset_label_update { update hf_asset_rev_map
            set asset_id=:asset_id and label=:label where f_id=:f_id and instanece_id=:instance_id }
    } else {
        ns_log Notice "hf_asset_rev_map_update: create label '${label}' asset_id '${asset_id}' trashed_p '${trashed_p}' instance_id '${instance_id}'"
        db_dml hf_asset_label_create { insert into hf_asset_rev_map
            ( label, asset_id, trashed_p, instance_id )
            values ( :label, :asset_id, :trashed_p, :instance_id ) }
    }
    return 1
}

ad_proc -private hf_asset_attributes {
    f_id
} {
    Returns list of untrashed attribute ids for f_id. 
} {
    set id_list [db_list hf_asset_attrs "select sub_type_id from hf_sub_asset_map where f_id=:f_id and sub_type_id=:asset_type_id and attribute_p='1' and instance_id=:instance_id"]
    return $id_list
}

ad_proc -private hf_asset_attributes_by_type {
    f_id
    asset_type_id
} {
    Returns a list of untrashed ids of asset_type_id for f_id.
} {
    set id_list [db_list hf_asset_attr_for_type "select sub_type_id from hf_sub_asset_map where f_id=:f_id and attribute_p='1' and instance_id=:instance_id"]
    return $id_list
}

ad_proc -private hf_asset_attribute_types {
    f_id
} {
    Returns a list of untrashed, distinct asset_type_ids for f_id.
} {
    set type_id_list [db_list hf_asset_type "select distinct sub_type_id from hf_sub_asset_map where f_id=:f_id and sub_type_id=:asset_type_id and attribute_p='1' and instance_id=:instance_id"]
    return $type_id_list
}


ad_proc -private hf_asset_subassets {
    f_id
} {
    Returns a list of untrashed f_id of direct subassets of asset.
} {
    set asset_id_list [db_list hf_subassets_of_f_id "select sub_f_id from hf_sub_asset_map where f_id=:f_id and instance_id=:instance_id and and attribute_p!='1' and trashed_p!='1'"]
    return $asset_id_list
}

ad_proc -private hf_asset_subassets_by_type {
    f_id
    asset_type_id
} {
    Returns a list of f_id of untrashed, direct subassets of asset that are of type asset_type_id.
} {
    set asset_id_list [db_list hf_subassets_of_f_id "select sub_f_id from hf_sub_asset_map where f_id=:f_id and sub_type_id=:asset_type_id and instance_id=:instance_id and attribute_p!='1' and trashed_p!='1'"]
    return $asset_id_list
}



ad_proc -private hf_asset_subassets_cascade {
    f_id
} {
    Returns a list of untrashed f_id of subassets.
} {
    set current_id_list [list $f_id]
    # to search for more.
    set next_id_list [list ]
    # final list
    set final_id_list [list ]
    set current_id_list_len 1
    set q_count 0
    while { $current_id_list_len > 0 } {
        foreach s_id $current_id_list {
            set new_list [db_list hf_subassets_of_f_id "select sub_f_id from hf_sub_asset_map where f_id=:s_id and instance_id=:instance_id and and attribute_p!='1' and trashed_p!='1'"]
            foreach sb_id $new_list {
                lappend next_id_list $sb_id
                lappend final_id_list $s_id
            }
        }
        set current_id_list $next_id_list
        set current_id_list_len [llength $current_id_list]
    }
    return $final_id_list
}

ad_proc -private hf_asset_subassets_count {
    f_id
} {
    Returns count of all subassets and trashed revisions of f_id.
    This is useful for creating a chronological sort order
} {
    set current_id_list [list $f_id]
    # to search for more.
    set next_id_list [list ]
    # final list
    set final_id_list [list ]
    set current_id_list_len 1
    set q_count 0
    while { $current_id_list_len > 0 } {
        foreach s_id $current_id_list {
            set new_list [db_list hf_subassets_all_of_f_id "select sub_f_id from hf_sub_asset_map where f_id=:s_id and instance_id=:instance_id and and attribute_p!='1'"]
            foreach sb_id $new_list {
                lappend next_id_list $sb_id
                lappend final_id_list $s_id
            }
        }
        set current_id_list $next_id_list
        set current_id_list_len [llength $current_id_list]
    }
    set count [llength $final_id_list ]
}


ad_proc -private hf_asset_subassets_by_type_cascade {
    f_id
    asset_type_id
} {
    Returns a list of f_id of untrashed, subassets that are of type asset_type_id.
} {
    set current_id_list [list $f_id]
    # to search for more.
    set next_id_list [list ]
    # final list
    set final_id_list [list ]
    set current_id_list_len 1
    set q_count 0
    while { $current_id_list_len > 0 } {
        foreach s_id $current_id_list {
            set new_list [db_list hf_subassets_of_f_id "select sub_f_id from hf_sub_asset_map where f_id=:s_id and sub_type_id=:asset_type_id and instance_id=:instance_id and attribute_p!='1' and trashed_p!='1'"]
            foreach sb_id $new_list {
                lappend next_id_list $sb_id
                lappend final_id_list $s_id
            }
        }
        set current_id_list $next_id_list
        set current_id_list_len [llength $current_id_list]
    }
    return $final_id_list
}

ad_proc -private hf_asset_attributes_cascade {
    f_id
} {
    Returns a list of untrashed f_id of attributes.
} {
    set current_id_list [list $f_id]
    # to search for more.
    set next_id_list [list ]
    # final list
    set final_id_list [list ]
    set current_id_list_len 1
    set q_count 0
    while { $current_id_list_len > 0 } {
        foreach s_id $current_id_list {
            set new_list [db_list hf_attributes_of_f_id "select sub_f_id from hf_sub_asset_map where f_id=:s_id and instance_id=:instance_id and and attribute_p='1' and trashed_p!='1'"]
            foreach sb_id $new_list {
                lappend next_id_list $sb_id
                lappend final_id_list $s_id
            }
        }
        set current_id_list $next_id_list
        set current_id_list_len [llength $current_id_list]
    }
    return $final_id_list
}

ad_proc -private hf_asset_attributes_by_type_cascade {
    f_id
    asset_type_id
} {
    Returns a list of f_id of untrashed, attributes that are of type asset_type_id.
} {
    set current_id_list [list $f_id]
    # to search for more.
    set next_id_list [list ]
    # final list
    set final_id_list [list ]
    set current_id_list_len 1
    set q_count 0
    while { $current_id_list_len > 0 } {
        foreach s_id $current_id_list {
            set new_list [db_list hf_attributes_of_f_id "select sub_f_id from hf_sub_asset_map where f_id=:s_id and sub_type_id=:asset_type_id and instance_id=:instance_id and attribute_p='1' and trashed_p!='1'"]
            foreach sb_id $new_list {
                lappend next_id_list $sb_id
                lappend final_id_list $s_id
            }
        }
        set current_id_list $next_id_list
        set current_id_list_len [llength $current_id_list]
    }
    return $final_id_list
}


# see hf_asset_do
# The following tables are involved in managing asset direct api

ad_proc -private hf_call_write {
    hf_call_id
    proc_name
    {asset_type_id ""}
    {asset_template_id ""}
    {asset_id ""}
    {instance_id ""}
} {
    Writes a new/update call and associates it to one or more specific asset_type. To remove an existing record, set proc_name blank for hf_call_id.
    At least one asset_id, asset_type_id or asset_template_id must be nonempty.
} {
    set admin_p [hf_ua_go_ahead_q admin "" "" 0]
    set success_p 0
    set no_errors_p 1
    set remove_p 0
    if { $admin_p } {
        # param validation
        set hf_call_id_exists_p [qf_is_natural_number $hf_call_id]
        set asset_type_id [string range $asset_type_id 0 23]
        if { $asset_type_id ne "" } {
            if { ![hf_are_visible_characters_q $asset_type_id ] } {
                set asset_type_id ""
                set no_errors_p 0
                ns_log Warning "hf_call_write(2942): user_id ${user_id} attempted to write including unprintable characters asset_type_id '${asset_type_id}'"
            }
        }
        if { ![qf_is_natural_number $asset_template_id] } {
            ns_log Warning "hf_call_write(2948): user_id ${user_id} attempted to write with nonstandard asset_template_id '${asset_template_id}'"
            set asset_template_id ""
            set no_errors_p 0
        }
        if { ![qf_is_natural_number $asset_id] } {
            ns_log Warning "hf_call_write(2954): user_id ${user_id} attempted to write with nonstandard asset_id '${asset_id}'"
            set asset_id ""
            set no_errors_p 0
        }
        if { $hf_call_id_exists_p } {
            # verify hf_call_id, or set hf_call_id_exists_p 0 no_errors_p 0
            if { $proc_name eq "" } {
                # This write is to blank out ie remove an existing record
                set remove_p 1
            }
        }
        if { $hf_call_id_exists_p == 0 && $no_errors_p && $proc_name ne "" } {
            # Check proc_name in context with asset_ids, see proc hf_asset_do at circa line 310
            # Actually, don't check for asset_id resolution as determined at execution.
            # Just make sure that hf_call_id matches with proc_name, or report an error.
            set proc_name [string range $proc_name 0 39]

            # get the appropriate hf_call_id
            # Cannot use db_0or1row, because there maybe multiple assignments of proc_name
            #db_0or1row hf_calls_ck_id {select id as hf_calls_db_id from hf_calls where instance_id=:instance_id and proc_name=:proc_name}
            set query_suffix ""
            if { $asset_type_id ne ""  } {
                append query_suffix "and asset_type_id=:asset_type_id"
            }
            if { $asset_template_id ne "" } {
                append query_suffix "and asset_template_id=:asset_template_id"
            }
            if { $asset_id ne "" } {
                append query_suffix "and asset_id=:asset_id"
            }
            set hc_id_list [db_list hf_calls_db_ids "select id from hf_calls where instance_id=:instance_id and proc_name=:proc_name ${query_suffix}"]
            if { [llength $hc_id_list] == 1 } {
                set hf_call_id_exists_p 1
                set hf_call_id [lindex $hc_id_list 0]
            } else {
                ns_log Notice "hf_call_write(2968): user_id ${user_id} attempted to write to multiple records for instance_id '${instance_id}' proc_name '${proc_name}' query_suffix '${query_suffix}'. Check for UI issue."
                set no_errors_p 0
            }
        }
        if { $hf_call_id_exists_p && $no_errors_p } {
            if { $remove_p } {
                # remove record
                db_1row hf_calls_read1 "select proc_name from hf_calls where id=:hf_call_id and instance_id=:instance_id"
                ns_log Notice "hf_call_write(2998): user_id ${user_id} deleted hf_calls.id '${hf_call_id}'  instance_id '${instance_id}' proc_name '${proc_name}'"
                db_dml hf_calls_delete1 {
                    delete from hf_calls where id=:hf_call_id and instance_id=:instance_id
                }
            } else {
                # Update
                db_dml hf_calls_update1 {
                    update hf_calls set asset_type_id=:asset_type_id,asset_template_id=:asset_template_id,asset_id=:asset_id where id=:hf_call_id
                }
            }
        } elseif { $no_errors_p } {
            # write new
            set id [db_nextval hf_id_seq]
            set query_suffix ""
            db_dml hf_calls_write1 {
                insert into hf_calls 
                (instance_id,id,proc_name,asset_type_id,asset_template_id,asset_id)
                values (:instance_id,:id,:proc_name,:asset_type_id,:asset_template_id,:asset_id)
            }
        }
        
    } else {
        set no_errors_p 0
        ns_log Warning "hf_call_write: user_id '${user_id}' denied. hf_call_id '${hf_call_id}' proc_name '${proc_name}' instance_id '${instance_id}' asset_type_id '${asset_type_id}' asset_template_id '${asset_template_id}' asset_id '${asset_id}' "
    }
    if { $no_errors_p == 0 } {
        set success_p 0
    }
    return $success_p
}


ad_proc -private hf_call_delete {
    hf_call_id
    {asset_type_id ""}
    {asset_template_id ""}
    {asset_id ""}
    {instance_id ""}
} {
    Deletes hf_call_id 
} {
    hf_ua_go_ahead_q admin
    # set proc_name ""
    set success_p [hf_call_write $hf_call_id "" $asset_type_id $asset_template_id $asset_id $instance_id]
}

ad_proc -private hf_call_read {
    hf_call_id
    {asset_type_id ""}
    {asset_template_id ""}
    {asset_id ""}
    {instance_id ""}
} {
    Returns proc_name to use with specified asset of highest specificity to allow for system-wide exceptions
    of calling another proc_name for a more specific asset etc.

} {
    hf_ui_go_ahead_q read
    set proc_name ""
    if { $read_p } {
        # param validation
        set hf_call_id_exists_p [qf_is_natural_number $hf_call_id]
        set asset_type_id [string range $asset_type_id 0 23]
        if { $asset_type_id ne "" } {
            if { ![hf_are_visible_characters_q $asset_type_id ] } {
                set asset_type_id ""
                set no_errors_p 0
                ns_log Warning "hf_call_read(3062): user_id ${user_id} attempted to read including unprintable characters asset_type_id '${asset_type_id}'"
            }
        }
    }
    if { ![qf_is_natural_number $asset_template_id] } {
        ns_log Warning "hf_call_read(3066): user_id ${user_id} attempted to read with nonstandard asset_template_id '${asset_template_id}'"
        set asset_template_id ""
        set no_errors_p 0
    }
    if { ![qf_is_natural_number $asset_id] } {
        ns_log Warning "hf_call_read(3071): user_id ${user_id} attempted to read with nonstandard asset_id '${asset_id}'"
        set asset_id ""
        set no_errors_p 0
    }
    if { $hf_call_id_exists_p } {
        # verify hf_call_id, or set hf_call_id_exists_p 0 no_errors_p 0
        if { $proc_name eq "" } {
            # This write is to blank out ie remove an existing record
            set remove_p 1
        }
    }
    if { $hf_call_id_exists_p == 0 && $no_errors_p && $proc_name ne "" } {
        # Check proc_name in context with asset_ids, see proc hf_asset_do at circa line 310
        # Actually, don't check for asset_id resolution as determined at execution.
        # Just make sure that hf_call_id matches with proc_name, or report an error.
        set proc_name [string range $proc_name 0 39]

        # get the appropriate hf_call_id
        # Cannot use db_0or1row, because there maybe multiple assignments of proc_name
        set query_suffix ""
        if { $asset_type_id ne "" || $asset_template_id ne "" || $asset_id ne "" } {
            set query_suffix ") or (asset_type_id=:asset_type_id or asset_template_id=:asset_template_id or asset_id=:asset_id"
        } 
        set hc_proc_lists [db_list_of_lists hf_calls_db_ids "select proc_name, asset_id, asset_template_id, asset_type_id from hf_calls where instance_id=:instance_id and id=:hf_call_id and ( ( asset_type_id='' and asset_type_id='' and asset_template_id='' ${query_suffix}) )"]
        set hf_procs_count [llength $hc_proc_lists]
        if { $hf_procs_count == 0 } {
            ns_log Notice "hf_call_read(3110): no proc_name for hf_call_id '$hf_call_id' user_id ${user_id} instance_id '${instance_id}' query_suffix '${query_suffix}'. Check for UI issue."
            set no_errors_p 0
        } else {
            # Get the most specific proc_name from available list
            # prioritize
            # asset_id most specific (10)
            # asset_template_id (9)
            # asset_type_id (8)
            # blank blank blank (7) standard
            # other other other (0) <- fail (not retrieved by query)
            set priority_lists [list ]
            for {set i 0} {i < $hf_procs_count} {incr i} {
                set priority 7
                set proc_list [lindex $hf_proc_lists $i]
                # proc_name, asset_id, asset_template_id, asset_type_id
                if { [lindex $proc_list 1] eq $asset_id } {
                    set priority 10
                } elseif { [lindex $proc_list 2] eq $asset_template_id } {
                    set priority 9
                } elseif { [lindex $proc_list 3] eq $asset_type_id } {
                    set priority 8
                }
                lappend $proc_list $priority
                lappend priority_lists $proc_list
            }
            set prioritized_lists [lsort -index 4 -decreasing $priority_lists]
            set proc_name [lindex [lindex $prioritized_lists 0] 0]
        }
    }
    return $proc_name
}


ad_proc -private hf_call_role_write {
    call_id
    role_id
    {instance_id ""}
} {
    Writes an association  between an hf_call and a role
} {
    set success_p 0
    set admin_p [hf_ua_go_ahead_q admin "" permissions_roles 0]
    if { $admin_p && [qf_is_natural_number $call_id] && [qf_is_natural_number $role_id] } {
        if { [hf_call_read $call_id] ne "" && [llength [hf_role_read $role_id]] > 0 } {
            # if record already exists, do nothing, else add
            set exists_p [db0or1row call_role_map_ck {select role_id as role_id_of_db from hf_call_role_map where instance_id=:instance_id and call_id=:call_id and role_id=:role_id} ]
            if { $exists_p } {
                ns_log Notice "hf_call_role_write(3155): duplicate write attempted by user_id '${user_id}' params role_id '${role_id}' call_id '${call_id}' instance_id '${instance_id}'"
            } else {
                db_dml hf_call_role_map_w {
                    insert into hf_call_role_map 
                    (instance_id,call_id,role_id)
                    values (:instance_id,:call_id,:role_id)
                }
            }
            set success_p 1
        }
    }
    return $success_p
}


ad_proc -private hf_call_roles_read {
    call_id
    {instance_id ""}
} {
    reads assigned roles for an hf_call.  answers question: what roles are allowed to make call?
} {
    set role_ids_list [list ]
    if { [qf_is_natural_number $instance_id] } {
        if { [qf_is_natural_number $call_id ] } {
            set role_ids_list [db_list hf_call_roles_read "select role_id from hf_call_role_map where instance_id=:instance_id and call_id=:call_id"]
        }
    }
    return $role_ids_list
}


