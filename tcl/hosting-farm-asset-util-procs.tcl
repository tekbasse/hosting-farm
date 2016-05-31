hosting-farm/tcl/hosting-farm-asset-util-procs.tcl
ad_library {

    utilities for hosting-farm assets
    @creation-date 25 May 2013
    @Copyright (c) 2014-2016 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl-2.0.html
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

ad_proc -private hf_f_id_exists {
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

ad_proc -public hf_lists_filter_by_alphanum {
    user_input_list
} {
    Returns a list of list of items that are alphanumeric from a list of lists.
} {
    set filtered_row_list [list ]
    set filtered_list [list ]
    foreach input_row_unfiltered $user_input_list {
        set filtered_row_list [list ]
        foreach input_unfiltered $input_row_unfiltered {
            # added dash and underscore, because these are often used in alpha/text references
            if { [regsub -all -nocase -- {[^a-z0-9,\.\-\_]+} $input_unfiltered {} input_filtered] } {
                lappend filtered_row_list $input_filtered
            }
        }
        lappend filtered_list $filtered_row_list
    }
    return $filtered_list
}

ad_proc -public hf_list_filter_by_alphanum {
    user_input_list
} {
    Returns a list of alphanumeric items from user_input_list
} {
    set filtered_list [list ]
    foreach input_unfiltered $user_input_list {
        # added dash and underscore, because these are often used in alpha/text references
        if { [regsub -all -nocase -- {[^a-z0-9,\.\-\_]+} $input_unfiltered {} input_filtered ] } {
            lappend filtered_list $input_filtered
        }
    }
    return $filtered_list
}

ad_proc -public hf_list_filter_by_decimal {
    user_input_list
} {
    set filtered_list [list ]
    foreach input_unfiltered $user_input_list {
        if { [qf_is_decimal $input_unfiltered] } {
            lappend filtered_list $input_unfiltered
        }
    }
    return $filtered_list
}

ad_proc -public hf_list_filter_by_natural_number {
    user_input_list
} {
    set filtered_list [list ]
    foreach input_unfiltered $user_input_list {
        if { [qf_is_natural_number $input_unfiltered] } {
            lappend filtered_list $input_unfiltered
        }
    }
    return $filtered_list
}

ad_proc -private hf_natural_number_list_validate {
    natural_number_list
} {
    Retuns 1 if list only contains natural numbers, otherwise returns 0
} {
    set nn_list [hf_list_filter_by_natural_number $natural_number_list]
    if { [llength $nn_list] != [llength $natural_number_list] } {
        set natnums_p 0
    } else {
        set natnums_p 1
    }
    return $natnums_p
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


ad_proc -private hf_attribute_ua_delete {
    ua_id_list
} {
    Deletes ua. ua may be a one or a list. User must be a package admin.
} {
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
    return $success_p
}

ad_proc -private hf_attribute_ns_delete {
    ns_id_list
} {
    Deletes hf_ns_records. ns_id_list may be a one or a list. User must be a package admin.
} {
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
    return $success_p
}

ad_proc -private hf_attribute_ip_delete {
    ip_id_list
} {
    Deletes hf_ip_addresses records. ip_id_list may be a one or a list. User must be a package admin.
} {
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
                db_dml hf_ip_ids_delete { delete from hf_ip_addresses where instance_id=:instance_id and ip_id in ([template::util::tcl_to_sql_list $ip_list])) }
                db_dml hf_ip_attr_map_del { delete from hf_sub_asset_map where instance_id=:instance_id and sub_f_id in ([template::util::tcl_to_sql_list $ip_list]) }
            } on_error {
                set success_p 0
            }
        } else{
            set success_p 0
        }
    }
    return $success_p
}



ad_proc -private hf_attribute_ni_delete {
    ni_id_list
} {
    Deletes hf_network_interfaces records. ni_id_list may be a one or a list. User must be a package admin.
} {
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
                db_dml hf_ni_ids_delete { delete from hf_network_interfaces where instance_id=:instance_id and ni_id in ([template::util::tcl_to_sql_list $ni_list])) }
                db_dml hf_ni_attr_map_del { delete from hf_sub_asset_map where instance_id=:instance_id and sub_f_id in ([template::util::tcl_to_sql_list $ni_list]) }
            } on_error {
                set success_p 0
            }
        } else{
            set success_p 0
        }
    }
    return $success_p
}


ad_proc -private hf_attribute_ss_delete {
    ss_id_list
} {
    Deletes hf_service records.  ss_id_list may be a one or a list. User must be a package admin.
} {
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
                db_dml hf_ss_ids_delete { delete from hf_services where instance_id=:instance_id and ss_id in ([template::util::tcl_to_sql_list $ss_list])) }
                db_dml hf_ss_attr_map_del { delete from hf_sub_asset_map where instance_id=:instance_id and sub_f_id in ([template::util::tcl_to_sql_list $ss_list]) }
            } on_error {
                set success_p 0
            }
        } else{
            set success_p 0
        }
    }
    return $success_p
}

ad_proc -private hf_attribute_vh_delete {
    vh_id_list
} {
    Deletes hf_vhosts records.  vh_id_list may be a one or a list. User must be a package admin.
} {
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
                db_dml hf_vh_ids_delete { delete from hf_vhosts where instance_id=:instance_id and vh_id in ([template::util::tcl_to_sql_list $vh_list])) }
                db_dml hf_vh_attr_map_del { delete from hf_sub_asset_map where instance_id=:instance_id and sub_f_id in ([template::util::tcl_to_sql_list $vh_list]) }
            } on_error {
                set success_p 0
            }
        } else{
            set success_p 0
        }
    }
    return $success_p
}


ad_proc -private hf_attribute_vm_delete {
    vm_id_list
} {
    Deletes hf_virtual_machines records.  vm_id_list may be a one or a list. User must be a package admin.
} {
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
                db_dml hf_vm_ids_delete { delete from hf_virtual_machines where instance_id=:instance_id and vm_id in ([template::util::tcl_to_sql_list $vm_list])) }
                db_dml hf_vm_attr_map_del { delete from hf_sub_asset_map where instance_id=:instance_id and sub_f_id in ([template::util::tcl_to_sql_list $vm_list]) }
            } on_error {
                set success_p 0
            }
        } else{
            set success_p 0
        }
    }
    return $success_p
}


ad_proc -private hf_attribute_hw_delete {
    hw_id_list
} {
    Deletes hf_hardware records.  hw_id_list may be a one or a list. User must be a package admin.
} {
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
                db_dml hf_hw_ids_delete { delete from hf_hardware where instance_id=:instance_id and hw_id in ([template::util::tcl_to_sql_list $hw_list])) }
                db_dml hf_hw_attr_map_del { delete from hf_sub_asset_map where instance_id=:instance_id and sub_f_id in ([template::util::tcl_to_sql_list $hw_list]) }
            } on_error {
                set success_p 0
            }
        } else{
            set success_p 0
        }
    }
    return $success_p
}


ad_proc -private hf_attribute_dc_delete {
    dc_id_list
} {
    Deletes hf_data_centers records.  dc_id_list may be a one or a list. User must be a package admin.
} {
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
                db_dml hf_dc_ids_delete { delete from hf_data_centers where instance_id=:instance_id and dc_id in ([template::util::tcl_to_sql_list $dc_list])) }
                db_dml hf_dc_attr_map_del { delete from hf_sub_asset_map where instance_id=:instance_id and sub_f_id in ([template::util::tcl_to_sql_list $dc_list]) }
            } on_error {
                set success_p 0
            }
        } else{
            set success_p 0
        }
    }
    return $success_p
}


ad_proc -private hf_attribute_monitor_delete {
    monitor_id_list
} {
    Deletes monitor_id records.  monitor_id_list may be a one or a list. User must be a package admin.
} {
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
    return $success_p
}

