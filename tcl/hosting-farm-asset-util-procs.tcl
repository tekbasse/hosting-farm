#hosting-farm/tcl/hosting-farm-asset-util-procs.tcl
ad_library {

    utilities for hosting-farm assets
    @creation-date 25 May 2013
    @Copyright (c) 2014-2016 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl-2.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com


}


ad_proc -private hf_nc_proc_context_set {
} {
    Set floating context
} {
    set a [ns_thread id]
    upvar 1 $a b
    set b $a
    set n "::hf::monitor::do::"
    set ${n}${a} $a
    #ns_log Notice "hf_nc_proc_context_set: context set: '${a}' info level '[info level]' namespace current '[namespace current]'"
    return 1
}

ad_proc -private hf_nc_proc_in_context_q {
    {namespace_name "::hf::monitor::do::"}
} {
    Checks if a scheduled proc is running in context of its namespace.
} {
    #    {namespace_name "::"}
    # To work as expected, each proc in namespace must call this function
    set a [ns_thread id]
    upvar 3 $a $a
    #ns_log Notice "acs_nc_proc_in_context_q: local vars [info vars]"
    if { ![info exists $a] || ![info exists ${namespace_name}${a} ] || [set $a] ne [set ${namespace_name}${a} ]} {
        ns_log Warning "hf_nc_proc_in_context_q: namespace '${namespace_name}' no! ns_thread id '${a}' info level '[info level]' namespace current '[namespace current]' "
       # ns_log Notice "::${a} [info exists ::${a}] "
       # ns_log Notice "::hf::${a} [info exists ::hf::${a}] "
       # ns_log Notice "::hf::monitor::${a} [info exists ::hf::monitor::${a}] "
       # ns_log Notice "::hf::monitor::do::${a} [info exists ::hf::monitor::do::${a}] "
       # ns_log Warning " set ${namespace_name}$a '[set ${namespace_name}${a} ]'"
        #ad_script_abort
        set context_p 0
    } else {
        upvar 2 $a $a
        set context_p 1
    }
    #ns_log Notice "hf_nc_proc_in_context_q: ns_thread name [ns_thread name] ns_thread id [ns_thread id] ns_info threads [ns_info threads] ns_info scheduled [ns_info scheduled]"
    return $context_p
}

#ad_proc -private hf_nc_proc_that_tests_context_checking {
#} {
#    This is a dummy proc that checks if context checker is working.
#} {
#    ns_log Notice "hf_nc_proc_that_tests_context_checking: info level '[info level]' namespace current '[namespace current]'"
#    set allowed_p [hf_nc_go_ahead ]
#    ns_log Notice "hf_nc_proc_that_tests_context_checking: context check. PASSED."
#}

#ad_proc -private hf_check_randoms {
#    {context ""}
#} {
#    Compares output of random functions, to see if there is a difference 
#    when run in scheduled threads vs. connected threads.
#} {
#    set a [expr { srand(round(fmod([clock clicks],[clock seconds]))) } ]
#    ns_log Notice "hf_check_randoms: context [ns_thread name]: ${context}"
#    ns_log Notice "hf_check_randoms: clock clicks '[clock clicks]' '[clock clicks]' '[clock clicks]'"
#     ns_log Notice "hf_check_randoms: clock seconds '[clock seconds]' '[clock seconds]' '[clock seconds]'"
#    ns_log Notice "hf_check_randoms: srand '[expr { srand(round(fmod([clock clicks],[clock seconds]))) } ]' '[expr { srand(round(fmod([clock clicks],[clock seconds]))) } ]' '[expr { srand(round(fmod([clock clicks],[clock seconds]))) } ]'"
#    ns_log Notice "hf_check_randoms: rand '[expr { rand() } ]' '[expr { rand() } ]' '[expr { rand() } ]'"
#    ns_log Notice "hf_check_randoms: random '[random]' '[random]' '[random]'"
#}

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

ad_proc -private hf_asset_revision_current_q { 
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
    set exists_p [db_0or1row hf_f_id_from_asset_id_tr { select asset_id from hf_asset_rev_map 
        where f_id=:f_id and instance_id=:instance_id and trashed_p='0' } ]
    ns_log Notice "hf_asset_active_q: asset_id requested is trashed or does not exist. asset_id '{$asset_id}' instance_id '${instance_id}'"
    
    return $asset_id
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


ad_proc -private hf_label_from_asset_id {
    asset_id
} {
    @param asset_id  

    @return label of asset with asset_id, or empty string if not exists or active.
} {
    upvar 1 instance_id instance_id
    set label ""
    set exists_p [db_0or1row hf_label_from_asset_id { select label from hf_asset_rev_map 
        where asset_id=:asset_id and instance_id=:instance_id } ]
    if { !$exists_p } {
        ns_log Notice "hf_label_from_asset_id: label does not exist for asset_id '${asset_id}' instance_id '${instance_id}'"
    }
    return $label
}

ad_proc -private hf_asset_id_from_label {
    label
} {
    @param label  Label of asset

    @return asset_id of asset with label, or empty string if not exists or active.
} {
    upvar 1 instance_id instance_id
    set asset_id ""
    set exists_p [db_0or1row hf_asset_id_from_label { select asset_id from hf_asset_rev_map 
        where label=:label and instance_id=:instance_id }]
    if { !$exists_p } {
        ns_log Notice "hf_asset_id_from_label: asset_id does not exist for label '${label}' instance_id '${instance_id}'"
    }
    return $asset_id
}


ad_proc -private hf_change_asset_id {
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
        set asset_id [hf_asset_id_from_label $label]
    }
    set write_p [hf_ui_go_ahead_q write]
    set success_p 0
    if { $write_p } {
        # new and current asset
        db_dml hf_change_revision { update hf_asset_rev_map
            set asset_id=:asset_id_new where label=:asset_label and instance_id=:instance_id }
        db_dml hf_change_revision_active { update hf_assets
            set last_modified = current_timestamp where id=:asset_id and instance_id=:instance_id }
        set success_p 1
    } else {
        ns_log Notice "hf_change_asset_id: no write allowed for asset_id_new '{$asset_id_new}' label '${label}' asset_id '${asset_id}'"
    }
    return $success_p
}


ad_proc -private hf_asset_rename {
    asset_id
    new_name
} {
    Changes the asset_name where the asset is referenced from asset_id. Returns 1 if successful, otherwise 0.

    @param asset_id  The label of the asset.
    @param new_name   The new name.
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set write_p [hf_ui_go_ahead_q write]
    set success_p 0
    if { $write_p } {
        db_transaction {
            db_dml hf_name_change_asset_map { update hf_asset_rev_map
                set name=:new_name where asset_id=:asset_id and instance_id=:instance_id 
            }
            db_dml hf_name_change_hf_assets { update hf_assets
                set last_modified = current_timestamp, name=:new_name where asset_id=:asset_id and instance_id=:instance_id 
            }
            set success_p 1
        } on_error {
            set success_p 0
        }
    }
    return $success_p
}

ad_proc -private hf_f_id_exists {
    f_id
} {
    @param f_id

    @return 1 if exists, otherwise returns 0.
} {
    set exists_p [db_0or1row hf_f_id_exists_p "select f_id from hf_asset_rev_map where f_id=:f_id" ]
    return $exists_p
}


ad_proc -private hf_f_id_from_asset_id {
    asset_id
} {
    Returns hf_asset.f_id given any revision asset_id of f_id, otherwise returns empty string.

    @param asset_id

    @return f_id
} {
    upvar 1 instance_id instance_id
    set f_id ""
    db_0or1row hf_asset_get_f_id_from_asset_id { select f_id from hf_assets where instance_id=:instance_id and id=:asset_id }
    return $f_id
}

ad_proc -private hf_current_asset_id_from_f_id { 
    f_id
} {
    Returns current asset_id given f_id, otherwise returns empty string.

    @param f_id  hf_asset.f_id for an asset.

    @return asset_id The current asset_id mapped to the label and f_id, else returns empty string.
} {
    upvar 1 instance_id instance_id
    set asset_id ""
    db_0or1row hf_asset_get_asset_id_from_f_id { select asset_id from hf_asset_rev_map 
        where instance_id=:instance_id and f_id=:f_id }
    return $asset_id
}


ad_proc -private hf_current_asset_id_from_label { 
    label
} {
    Returns asset_id if asset is published (untrashed) for instance_id, else returns empty string.
} {
    upvar 1 instance_id instance_id
    set asset_id ""
    db_0or1row hf_asset_get_id_from_label {select asset_id from hf_label_map 
        where label=:label and instance_id=:instance_id and not ( trashed_p = '1' ) } 
    return $asset_id
}

ad_proc -private hf_current_asset_id {
    asset_id
} {
    Returns current asset_id given any revision asset_id of asset.

    @param asset_id  One of any revision of asset_id

    @return asset_id The current, active asset_id, otherwise empty string.
} {
    upvar 1 instance_id instance_id
    set asset_id_current ""
    set f_id [hf_f_id_from_asset_id $asset_id]
    if { $f_id ne "" } {
        set asset_id_current [hf_current_asset_id_from_f_id $f_id]
    }
    return $asset_id_current
}

ad_proc -private hf_asset_stats_keys {
    {separator ""}
} {
    Returns an ordered list of keys that is parallel to the ordered list returned by hf_asset_stats.
    If separator is not "", returns a string joined with separator.
} {
    # naming convention is: label, name, description
    # old way from (q-wiki): name, title, description
    set keys_list [list \
                       asset_id \
                       label \
                       name \
                       asset_type_id \
                       keywords \
                       description \
                       trashed_p \
                       trashed_by \
                       template_p \
                       templated_p \
                       publish_p \
                       monitor_p \
                       popularity \
                       triage_priority \
                       op_status \
                       ua_id \
                       ns_id \
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

ad_proc -private hf_asset_keys {
    {separator ""}
} {
    Returns an ordered list of keys that is parallel to the ordered list returned by hf_asset_read.
    
    Adds content and comments fields to hf_asset_stats_keys list

    @see hf_asset_stats_keys
} {
    set keys_list [hf_asset_stats_keys]
    lappend keys_list "content"
    lappend keys_list "comments"
    set keys [hf_keys_by $keys_list $separator]
    return $keys
}


ad_proc -private hf_keys_by {
    keys_list
    separator
} {
    if { $separator ne ""} {
        set keys ""
        if { $separator eq ",:" } {
            # for db
            set keys ":"
        }
        append keys [join $keys_list $separator]
    } else {
        set keys $keys_list
    }
    return $keys
}

ad_proc -private hf_asset_rev_map_update {
    label
    f_id
    asset_id
    trashed_p
} {
    Creates or updates an asset map.
} {
    upvar 1 instance_id instance_id
    ns_log Notice "hf_asset_rev_map_create: label '${label}' asset_id '${asset_id}' trashed_p '${trashed_p}' instance_id '${instance_id}'"
    # Does f_id exist?
    if { [hf_f_id_exists $f_id] } {
        db_dml hf_asset_label_update { update hf_asset_rev_map
            set asset_id=:asset_id and label=:label where f_id=:f_id and instanece_id=:instance_id }
    } else {
        db_dml hf_asset_label_create { insert into hf_asset_rev_map
            ( label, asset_id, trashed_p, instance_id )
            values ( :label, :asset_id, :trashed_p, :instance_id ) }
    }
    return 1
}
