ad_library {

    misc API for hosting-farm
    @creation-date 5 June 2013
    @Copyright (c) 2014 Benjamin Brink
    @license GNU General Public License 3, see project home or http://www.gnu.org/licenses/gpl-3.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com

    # UI for one click (web-based) installers
      # installers install/update/monitor/activate/de-activate software, ie hosted service (hs) or software as a service (ss)
      # asset_type_id = hs or ss
      # code is going to use ss for all cases of hs or ss, because hs sounds like hf and looks like ns, which might increase 
      # errors and make code more difficult to read and debug.

    # A conspicuous alert when system needs user attention (contract expiring, service down etc)
    # Use: util_user_message  For example, see q-wiki/www/q-wiki.tcl 

    # use quotas with alerts
    # quota proc should be a scheduled proc. see ecommerce scheduled procs for example, that updates:
    # storage usage, memory usage and traffic tracking.
    # and another scheduled proc that handles log monitoring/ alarms
    # switchable, configurable automated log monitoring and alarms

    # billing - general invoicing utility for handling initial orders, recurring billing, and quota overages.
    # reseller service features

    # ticket tracker with built-in streamlining for outages/disrutions that deal with multiple/bulk sets of clients
    # social feedback mechanisms

    # asset object description. 
    # Every asset_id has a reference in the hf_assets table, including vhosts and services.
    # Each type may have a separate table containing additional properties.

    # asset_id, hf_id              - generic asset
    #       ->  service, ss_id     - service asset attached to no asset, or a generic asset
    # dc  dc_id                    - datacenter 
    #       ->  ss_id              - service asset attached to (with dependency primarily on) datacenter
    # hw  hw_id                    - hardware
    #       ->  ss_id              - service asset attached to (with dependency primarily on) hardware
    # vm  vm_id                    - virtual machine
    #       ->  ss_id              - service asset attached to (with dependency primarily on) virtual machine
    # vh  vh_id                    - virtual host
    #       ->  ss_id              - service asset attached to (with dependency primarily on) virtual host

# ni, ip, os, ns are not assets, but attributes that can be assigned to assets.

    # objects can easily be passed to procs via an array and upvar
    #  array references don't work in sql, so these use ordered lists

    # For dynamically generated objects, a proc should be written
    # to write a series of avariables to an array, and an array to a set of variables equal to the indexes.
    # somthing similar to qf_get_inputs_as_array, or set array but where the pairs are in separate lists
    # for eks: qf_get_inputs_as_array but added to the q-forms help-procs section:
    # qf_vars_from_array, qf_array_from_vars, qf_array_from_ordered_lists $key_list $value_list 
    # Just found existing ones in acs-templating library:
    # template::util::list_to_array
    # template::util::array_to_vars
}

# following defined in permissions-procs.tcl
# hf_customer_ids_for_user
# hf_active_asset_ids_for_customer 

ad_proc -private hf_asset_ids_for_user { 
    {user_id ""}
    {instance_id ""}
} {
    Returns asset_ids available to user_id as list 
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    set customer_ids_list [hf_customer_ids_for_user $user_id]
    # get asset_ids assigned to customer_ids
    set asset_ids_list [list ]
    foreach customer_id $customer_ids_list {
        set assets_list [hf_asset_ids_for_customer $instance_id $customer_id]
        foreach asset_id $assets_list {
            lappend asset_ids_list $asset_id
        }
    }
    return $asset_ids_list
}

ad_proc -private hf_customer_id_of_asset_id {
    asset_id
    {instance_id ""}
} {
    returns customer_id of asset_id
} {
    # this is handy for helping fulfill hf_permission_p requirements
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set cid_exists [db_0or1row hf_customer_id_of_asset_id "select qal_customer_id from hf_assets where instance_id = :instance_id and id = :asset_id and id in ( select asset_id from hf_asset_label_map where instance_id = :instance_id ) order by last_modified desc"]
    if { !$cid_exists } {
        set customer_id ""
    }
    return $customer_id
}

ad_proc -private hf_asset_create_from_asset_template {
    customer_id
    asset_id
    asset_label_new
    {instance_id ""}
} {
   this should be a proc equivalent to a page that loads template and creates new.. 
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]

    # customer_id of asset_id doesn't matter, because this may a copy of another's asset or template.
    set read_p [hf_permission_p $user_id "" published read $instance_id]
    set create_p [hf_permission_p $user_id $customer_id assets create $instance_id]
    set status $create_p
    if { $create_p } {
        set asset_list [hf_asset_read $instance_id $asset_id]
        # returns: name0,title1,asset_type_id2,keywords3,description4,content5,comments6,trashed_p7,trashed_by8,template_p9,templated_p10,publish_p11,monitor_p12,popularity13,triage_priority14,op_status15,ua_id16,ns_id17,qal_product_id18,qal_customer_id19,instance_id20,user_id21,last_modified22,created23
        if { [llength $asset_list] > 1 } {
            set i 0
            foreach arg $asset_list {
                set aa($i) $arg
                incr i
            }

            # template_p, publish_p, popularity should be false(0) for all copy cases,  op_status s/b ""
            set status [hf_asset_create $asset_label_new $aa(2) $aa(1) $aa(5) $aa(3) $aa(4) $aa(6) 0 $aa(10) 0 $aa(12) 0 $aa(14) "" $aa(16) $aa(17) $aa(18) $customer_id "" "" $instance_id $user_id]
            # params: name, asset_type_id, title, content, keywords, description, comments, template_p, templated_p, publish_p, monitor_p, popularity, triage_priority, op_status, ua_id, ns_id, qal_product_id, qal_customer_id, {template_id ""}, {flags ""}, {instance_id ""}, {user_id ""}
            if { $status } {
## TODO: create should not include the same ns_id or ua_id. create a new entry in hf_ua and hf_ns tables. Delay coding until these procs created:
                #            hf_ua_write
                #            hf_ns_write

                # if publish_p is 1, copy relevant data (done afaik)
                # if monitor_p is 1, copy the monitor settings
            }
        }
    }
    return $status
}

ad_proc -private hf_asset_create_from_asset_label {
    asset_label_orig
    asset_label_new
    {instance_id ""}
} {
   creates a new asset_label based on an existing asset. Returns 1 if successful, otherwise 0.
} {
  ## TODO code: basically duplicate hf_asset_create_from_asset_template, getting id from hf_asset_id_from_label

    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    set customer_ids_list [hf_customer_ids_for_user $user_id]
#     hf_asset_read instance_id asset_id
#     hf_asset_create new_label

    # set asset_id_orig [hf_asset_id_from_label $asset_label_orig $instance_id]

}

ad_proc -private hf_asset_templates {
    {label_match ""}
    {inactives_included_p 0}
    {published_p ""}
    {instance_id ""}
} {
    returns active template references (id) and other info via a list of lists, where each list is an ordered tcl list of asset related values: id,user_id,last_modified,created,asset_type_id,qal_product_id, qal_customer_id,label,keywords,time_start,time_stop,trashed_p,trashed_by,flags,publish_p
} {
    # A variation on hf_assets, if include_inactives_p eq 1 and label_match eq ""
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    # scope to user_id
    set user_id [ad_conn user_id]
    set customer_ids_list [hf_customer_ids_for_user $user_id]
    #    set all_assets_list_of_lists \[db_list_of_lists hf_asset_templates_list {select id,user_id,last_modified,created,asset_type_id,qal_product_id, qal_customer_id,label,keywords,templated_p,time_start,time_stop,ns_id,op_status,trashed_p,trashed_by,popularity,flags,publish_p,monitor_p,triage_priority from hf_assets where template_p =:1 and instance_id =:instance_id} \]
    if { $inactives_included_p } {
        set templates_list_of_lists [db_list_of_lists hf_asset_templates_select_all {select id,user_id,last_modified,created,asset_type_id,qal_product_id, qal_customer_id,label,keywords,time_start,time_stop,trashed_p,trashed_by,flags,publish_p from hf_assets where template_p =:1 and instance_id =:instance_id and id in ( select asset_id from hf_asset_label_map where instance_id = :instance_id ) order by last_modified desc} ]
    } else {
        set templates_list_of_lists [db_list_of_lists hf_asset_templates_select {select id,user_id,last_modified,created,asset_type_id,qal_product_id, qal_customer_id,label,keywords,time_start,time_stop,trashed_p,trashed_by,flags,publish_p from hf_assets where template_p =:1 and instance_id =:instance_id and ( time_stop =null or time_stop < current_timestamp ) and ( trashed_p is null or trashed_p <> '1' ) and id in ( select asset_id from hf_asset_label_map where instance_id = :instance_id ) order by last_modified desc } ]
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

ad_proc -private hf_assets_w_detail {
    {instance_id ""}
    {customer_ids_list ""}
    {label_match ""}
    {inactives_included_p 0}
    {published_p ""}
    {template_p ""}
    {asset_type_id ""}
} {
    returns asset detail with references (id) and other info via a list of lists, where each list is an ordered tcl list of asset related values: id,user_id,last_modified,created,asset_type_id,qal_product_id, qal_customer_id,label,keywords,templated_p,template_p,time_start,time_stop,trashed_p,trashed_by,flags,publish_p
} {
    # A variation on hf_assets
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    # scope to user_id
    set user_id [ad_conn user_id]
    set all_customer_ids_list [hf_customer_ids_for_user $user_id]
    #    set all_assets_list_of_lists \[db_list_of_lists hf_asset_templates_list {select id,user_id,last_modified,created,asset_type_id,qal_product_id, qal_customer_id,label,keywords,templated_p,time_start,time_stop,ns_id,op_status,trashed_p,trashed_by,popularity,flags,publish_p,monitor_p,triage_priority from hf_assets where template_p =:1 and instance_id =:instance_id} \]
    if { $inactives_included_p } {
        set templates_list_of_lists [db_list_of_lists hf_asset_templates_select_all {select id,user_id,last_modified,created,asset_type_id,qal_product_id, qal_customer_id,label,keywords,templated_p,template_p,time_start,time_stop,trashed_p,trashed_by,flags,publish_p from hf_assets where instance_id =:instance_id and id in ( select asset_id from hf_asset_label_map where instance_id = :instance_id ) order by last_modified desc} ]
    } else {
        set templates_list_of_lists [db_list_of_lists hf_asset_templates_select {select id,user_id,last_modified,created,asset_type_id,qal_product_id, qal_customer_id,label,keywords,templated_p,template_p,time_start,time_stop,trashed_p,trashed_by,flags,publish_p from hf_assets where instance_id =:instance_id and time_stop =null and ( trashed_p is null or trashed_p <> '1' ) and id in ( select asset_id from hf_asset_label_map where instance_id = :instance_id ) order by last_modified desc } ]
    }
    # build list of ids that meet at least one criteria
    set return_list [list ]
    foreach template_list $templates_lists_of_lists {
        # first make sure that user_id has access to asset.
        set customer_id [lindex $template_list 6]
        set insert_p 0
        if { $customer_id eq "" || ( [lsearch -exact $all_customer_ids_list $customer_id] > -1 && [lsearch -exact $customer_ids_list $customer_id] ) } {

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
            if { !$insert_p && $template_p ne "" } {
                set template_p_val [lindex $template_list 10]
                if { $template_p eq $template_p_val } {
                    set insert_p 1
                }
            }
            if { !$insert_p && $asset_type_id ne "" } {
                set asset_type_id_val [lindex $template_list 4]
                if { $asset_type_id eq $asset_type_id_val } {
                    set insert_p 1
                }
            }
            if { $insert_p } {
                set insert_p 0
                # just id's:  lappend return_list \[lindex $template_list 0\]
                 lappend return_list $template_list
            }
        }
    }
    return $return_list
}


# API for various asset types:
#   in each case, add ecds-pagination bar when displaying. defaults to all allowed by user permissions

ad_proc -private hf_asset_do {
    asset_id
    hf_local_call_id
    {instance_id ""}
} {
    process hf_local_call_id on asset_id
} {
    # check permission passed to executable
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    set asset_stats_list [hf_asset_stats $asset_id $instance_id]
    # name, title, asset_type_id, keywords, description, template_p, templated_p, trashed_p, trashed_by, publish_p, monitor_p, popularity, triage_priority, op_status, ua_id, ns_id, qal_product_id, qal_customer_id, instance_id, user_id, last_modified, created, flags
    set asset_type_id [lindex $asset_stats_list 2]
    set asset_template_p [lindex $asset_stats_list 5]
    set asset_templated_p [lindex $asset_stats_list 6]
    set asset_template_id [lindex $asset_stats_list 23]

    set template_ids_name_list [db_list_of_lists hf_calls_read_asset_type_choices { select asset_template_id, asset_id, proc_name from hf_calls where instance_id =:instance_id and asset_type_id =:id } ]
    
    set counter_max [llength $template_ids_name_list ]
    set counter 0
    ## first check all asset_ids   REDO following
    set proc_name_template ""
    set proc_name_type ""
    while { $proc_name eq "" && $counter < $counter_max } {
	set choice_list [lindex $template_ids_name_list $counter]
	set c_asset_template_id [lindex $choice_list 0]
	set c_asset_id [lindex $choice_list 1]
	# each of these if's should only be true a maximimum of once.
	if { $c_asset_id eq $asset_id } {
	    set proc_name [lindex $choice_list 2]
	} elseif { $asset_template_id eq $c_asset_template_id } {
	    #  then all template_ids, 
	    set proc_name_template [lindex $choice_list 2]
	} elseif { $c_asset_id eq "" && $c_asset_template_id eq "" } {
	    # then go with asset_type_id 
	    set proc_name_type  [lindex $choice_list 2]
	}
    }
    if { $proc_name eq "" } {
	if { $proc_name_template ne "" } {
	    set proc_name $proc_name_template
	} elseif { $proc_name_type ne "" } {
	    set proc_name $proc_name_type
	}
    }

    if { $proc_name ne "" } {
	##    add to operations stack that is listened to by an ad_scheduled_proc procedure working in short interval cycles
	hf::schedule_add $proc_name [list $asset_id $user_id $instance_id] $user_id $instance_id $priority
    }
  

}
## make procs that return the asset objects given one or more asset ids.
# info tables: 
ad_proc -private hf_dcs {
    {instance_id ""}
    {customer_id_list ""}
    {asset_id_list ""}
    {inactives_included_p 0}
} {
    returns an ordered list of lists of data centers and their direct properties. No duplicate properties are in the list.
    If an asset consists of multiple DCs, each dc is a separate list (ie an asset can take up more than one line or list).
    Ordered list of properties consists of: id,user_id,last_modified,created,asset_type_id,qal_product_id, qal_customer_id,label,keywords,templated_p,template_p,time_start,time_stop,trashed_p,trashed_by,flags,publish_p, ni_id_count, hw_id_count
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    set asset_type_id "dc"
    # get hf_assets: instance_id id, asset_type_id=dc, etc..
    set asset_detail_list [hf_assets_w_detail $instance_id $customer_id_list "" $inactives_included_p "" "" $asset_type_id]
    # id,user_id,last_modified,created,asset_type_id,qal_product_id, qal_customer_id,label,keywords,templated_p,template_p,time_start,time_stop,trashed_p,trashed_by,flags,publish_p
    set asset_id_list [list ]
    foreach one_asset_detail_list $asset_detail_list {
        lappend asset_id_list [lindex $one_asset_detail_list 0]
    }
    # tables hf_data_centers.instance_id,dc_id, affix (was datacentr.short_code), description, details
    set dc_detail_list [db_list_of_lists hf_dc_get "select dc_id, affix, description, details from hf_data_centers where instance_id =:instance_id and dc_id in ([template::util::tcl_to_sql_list $asset_id_list])"]
    # dc_id_list is a subset of asset_id_list
    # to this point, the maximum available dc_id(s) have been returned, and filtered to customer_id_list
 
    # If proc parameters are not blank, filter the results.
    set filter_asset_id_p [expr { $asset_id_list ne "" } ]
    if { $filter_asset_id_p } {
        set return_list [list ]
        set insert_p 0
        # scope to filter
        # this is setup to handle multiple filters, but right now just handling the one..
        foreach one_dc_detail_list $dc_detail_list {
            if { $filter_asset_id_p && [lsearch -exact $asset_id_list [lindex $one_dc_detail_list 0 ] ] > -1 } {
                set insert_p 1
            }
            if { $insert_p } {
                set insert_p 0
                set dc_id [lindex $one_dc_detail_list 0]
                # count only active ones
                db_1row hf_dc_ni_map_count "select count(ni_id) as ni_id_active_count from hf_dc_ni_map where instance_id =:instance_id and dc_id =:dc_id and dc_id in ( select id from hf_assets where ( time_stop =null or time_stop < current_timestamp) and ( trashed_p is null or trashed_p <> '1' ) ) "
                db_1row hf_dc_hw_map_count "select count(hw_id) as hw_id_active_count from hf_dc_hw_map where instance_id =:instance_id and dc_id =:dc_id and dc_id in ( select id from hf_assets where ( time_stop =null or time_stop < current_timestamp) and ( trashed_p is null or trashed_p <> '1' ) ) "
                lappend one_dc_detail_list $ni_id_count $hw_id_count
                lappend return_list $one_dc_detail_list
            }
        }
    } else {
        set return_list $dc_detail_list
    } 
    return $return_list
}

ad_proc -private hf_hws {
    {instance_id ""}
    {customer_id_list ""}
    {asset_id_list ""}
    {inactives_included_p 0}
} {
    returns an ordered list of lists of hardware and their direct properties hw_id, system_name, backup_sys, ni_id, os_id, description, details, count of active VMs
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    set asset_type_id "hw"

    # get hf_assets: instance_id id, asset_type_id=hw, etc..
    set asset_detail_list [hf_assets_w_detail $instance_id $customer_id_list "" $inactives_included_p "" "" $asset_type_id]
    # id,user_id,last_modified,created,asset_type_id,qal_product_id, qal_customer_id,label,keywords,templated_p,template_p,time_start,time_stop,trashed_p,trashed_by,flags,publish_p
    set asset_id_list [list ]
    foreach one_asset_detail_list $asset_detail_list {
        lappend asset_id_list [lindex $one_asset_detail_list 0]
    }

    # get dc_id's that have hw associated with it. We do this because we might be filtering by asset_ids, and we want to include subsets.
    set dc_id_list [hf_dcs $instance_id $customer_id_list $asset_id_list]
    #  tables hf_dc_hw_map.instance_id, dc_id, hw_id
    set hw_id_indirect_list [db_list_of_lists hf_dc_get_hw_ids "select hw_id from hf_dc_hw_map where instance_id =:instance_id and dc_id in ([template::util::tcl_to_sql_list $dc_id_list])"]


    # get hw that are directly assets.
    set asset_detail_list [hf_assets_w_detail $instance_id $customer_id_list "" 1 "" "" $asset_type_id]
    # id,user_id,last_modified,created,asset_type_id,qal_product_id, qal_customer_id,label,keywords,templated_p,template_p,time_start,time_stop,trashed_p,trashed_by,flags,publish_p
    # build full list of hw_ids
    set hw_id_list $hw_id_indirect_list
    foreach one_asset_detail_list $asset_detail_list {
        lappend hw_id_list [lindex $one_asset_detail_list 0]
    }

    # build detail hw list
    #  hf_hardware.instance_id, hw_id, system_name, backup_sys, ni_id, os_id, description, details
    set hw_detail_list [db_list_of_lists hf_hw_get "select hw_id, system_name, backup_sys,ni_id, os_id, description, details from hf_hardware where instance_id =:instance_id and hw_id in ([template::util::tcl_to_sql_list $hw_id_list])"]

    # If proc parameters are not blank, filter the results.
    set filter_asset_id_p [expr { $asset_id_list ne "" } ]
    if { $filter_asset_id_p } {
        set base_return_list [list ]
        set insert_p 0
        # scope to filter
        foreach one_hw_detail_list $hw_detail_list {
            if { $filter_asset_id_p && [lsearch -exact $asset_id_list [lindex $one_hw_detail_list 0 ] ] > -1 } {
                set insert_p 1
            }
            if { $insert_p } {
                set insert_p 0
#                set hw_id \[lindex $one_hw_detail_list 0\]
                lappend base_return_list $one_hw_detail_list
            }
        }
    } else {
        set base_return_list $hw_detail_list
    } 
    # append VM count
    set return_list [list ]
    foreach hw_list $base_return_list {
        set hw_id [lindex $hw_list 0]
        # count only active ones
        db_1row hf_dc_ni_map_count "select count(vm_id) as vm_id_active_count from hf_hw_vm_map where instance_id =:instance_id and hw_id =:hw_id and hw_id in ( select id from hf_assets where ( time_stop =null or time_stop < current_timestamp) and (trashed_p is null or trashed_p <> '1' ) ) "
        set hw_return_list $hw_list
        lappend hw_return_list $vm_id_active_count
        lappend return_list $hw_return_list
    }
    return $return_list
}

ad_proc -private hf_nis {
    {instance_id ""}
    {customer_id_list ""}
    {asset_id_list ""}
    {inactives_included_p 0}
} {
    returns an ordered list of lists of an asset's network interfaces and their properties: 
    asset_id, asset_type_id, ni_id, os_dev_ref, ipv4_addr_range, ipv6_addr_range, bia_mac_address, ul_mac_address
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    # asset_id can be dc, vm, or  hw
    # by limiting ni to direct connections helps keep context with ui

    # use hf_assets_w_detail to get valid asset_id, asset_type_id
    set asset_detail_lists [hf_assets_w_detail $instance_id $customer_id_list "" $inactives_included_p "" "" ""]
    set asset_id_list_arr(dc) [list ]
    set asset_id_list_arr(hw) [list ]
    set asset_id_list_arr(vm) [list ]
    foreach asset_list $asset_detail_lists {
        # build asset_ids_list_arr(dc, hw, vm)
        set asset_id [lindex $asset_list 0]
        set asset_type_id [lindex $asset_list 4]
        lappend asset_id_list_arr($asset_type_id) $asset_id
    }
    
    set ni_detail_lists [list ]
    # foreach asset_type_id_list, query db 

    if { [llength $asset_id_list_arr(dc)] > 0 } {
        # dc
        #  hf_dc_ni_map.instance_id, dc_id, ni_id
        #  hf_network_interfaces.instance_id, ni_id, os_dev_ref, ipv4_addr_range, ipv6_addr_range, bia_mac_address, ul_mac_address
        set asset_lists [db_list_of_lists hf_dc_nis_get "select dc.dc_id, 'dc' as asset_type_id, ni.ni_id, ni.os_dev_ref, ni.ipv4_addr_range, ni.ipv6_addr_range, ni.bia_mac_address, ni.ul_mac_address from hf_dc_ni_map dc, hf_network_interfaces ni where dc.instance_id = ni.instance_id and dc.instance_id =:instance_id and dc.ni_id = ni.ni_id and ni.ni_id in (select ni_id from hf_dc_ni_map where instance_id =:instance_id and dc_id in ([template::util::tcl_to_sql_list $asset_id_list_arr(dc)])"]
        foreach asset_ni_list $asset_lists {
            lappend ni_detail_lists $asset_ni_list
        }
    }

    if { [llength $asset_id_list(hw)] > 0 } {
        #  hf_hw_ni_map.instance_id, hw_id, ni_id
        #  hf_hardware.instance_id, hw_id, system_name, backup_sys, ni_id, os_id, description, details
        set asset_lists [db_list_of_lists hf_hw_nis_get "select hw.hw_id, 'hw' as asset_type_id, ni.ni_id, ni.os_dev_ref, ni.ipv4_addr_range, ni.ipv6_addr_range, ni.bia_mac_address, ni.ul_mac_address from hf_hw_ni_map hw, hf_network_interfaces ni where hw.instance_id = ni.instance_id and hw.instance_id =:instance_id and hw.ni_id = ni.ni_id and ni.ni_id in (select ni_id from hf_hw_ni_map where instance_id =:instance_id and hw_id in ([template::util::tcl_to_sql_list $asset_id_list_arr(hw)])"]
        foreach asset_ni_list $asset_lists {
            lappend ni_detail_lists $asset_ni_list
        }
    }

    # vm are 1:1 mapped, so can reference ni_id directly.         
    if { [llength $asset_id_list(vm)] > 0 } {
        # vm
        # hf_virtual_machines instance_id, vm_id, domain_name, ip_id, ni_id, ns_id, type_id, resource_path, mount_union, details
        set asset_lists [db_list_of_lists hf_vm_nis_get "select vm.hw_id, 'vm' as asset_type_id, ni.ni_id, ni.os_dev_ref, ni.ipv4_addr_range, ni.ipv6_addr_range, ni.bia_mac_address, ni.ul_mac_address from hf_virtual_machines vm, hf_network_interfaces ni where ni.ni_id = vm.ni_id and ni.ni_id in (select ni_id from hf_virtual_machines where instance_id =:instance_id and vm_id in ([template::util::tcl_to_sql_list $asset_id_list_arr(vm)])"]
        foreach asset_ni_list $asset_lists {
            lappend ni_detail_lists $asset_ni_list
        }
    }


    # If proc parameters are not blank, filter the results.
    # results already scoped for customer_id_list via asset_detail_lists
    set filter_asset_id_p [expr { $asset_id_list ne "" } ]
    # right now there is only 1 filter, so check to see if this filter can be bypassed
    if { $filter_asset_id_p } {
        set base_return_list [list ]
        set insert_p 0
        # scope to filter
        foreach ni_list $ni_detail_lists {
            # filter to only asset_id_list
            if { $filter_asset_id_p && [lsearch -exact $asset_id_list [lindex $ni_list 0]] > -1 } {
                set insert_p 1
            }
            # if filtering list by details, do it here

            if { $insert_p } {
                set insert_p 0
                lappend base_return_list $ni_list
            }
        }
    } else {
        set base_return_list $ni_detail_lists
    } 

    # Are there any more details to add? 
    # could be useful to add status info if available, but not right now.
    
    return $base_return_list
}

ad_proc -private hf_asset_type_ua_ids {
    {instance_id ""}
    {customer_id_list ""}
    {asset_id_list ""}
    {asset_type_list ""}
    {inactives_included_p 0}
} {
    This is hf_vms_basic, but for all assets. returns a list of list of asset_ids,types and ua's filtered by customer_id_list and asset_id_list. Blank values assume all cases. each list consists of: asset_id asset_type ua_id
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]

    # get all available asset_ids to user (ie. customers of user) (even ones that might be listed as a different type)
    # a vm is a subset of an hw, which is a subset of a dc.
    set asset_detail_lists [hf_assets_w_detail $instance_id $customer_id_list "" $inactives_included_p "" "" ""]
    set asset_types_list [list ]
    set asset_ids_list [list ]
    foreach asset_list $asset_detail_lists {
        # build asset_ids_list_arr(dc, hw, vm etc)
        set asset_id [lindex $asset_list 0]
        set asset_type_id [lindex $asset_list 4]
        lappend asset_ids_list $asset_id
        lappend asset_id_list_arr($asset_type_id) $asset_id
        if { [lsearch -exact $asset_types_list $asset_type_id] < 0 } {
            lappend asset_types_list $asset_type_id
        }
    }

    if { $customer_id_list eq "" } {
        #get all available hw_ids to user
        set vm_list [list ]

        # get all dc's associated with user, and subsequently, hw under those dc's
        set hw_id_list $asset_id_list_arr(hw)
        if { [llength $asset_id_list_arr(dc)] > 0 } {
            # dc
            set hw_id_indirect_list [db_list_of_lists hf_dc_get_hw_ids2 "select hw_id from hf_dc_hw_map where instance_id =:instance_id and dc_id in ([template::util::tcl_to_sql_list $asset_id_list_arr(dc)])"]
            foreach hw_id $hw_id_indirect_list {
                lappend hw_id_list $hw_id
            }
        }
        # get all vm's mapped to hw_ids
        # hf_hw_vm_map.instance_id, hw_id, vm_id
        set vm_id_list [db_list hf_vm_get_vm_ids "select vm_id from hf_hw_vm_map where instance_id =:instance_id and hw_ic in ([template::util::tcl_to_sql_list $hw_id_list])"]
        
        # get all direct vm's available to user
        # vm is an asset_type_id, so direct vm's are in: asset_id_list_arr(vm) 
        
        # build list of list using collected vm_id's
        foreach vm_id $vm_id_list {
            lappend asset_id_list_arr(vm) $vm_id
        }
    }

    set as_detail_list [db_list_of_lists hf_asset_ua_get "select id, asset_type, ua_id from hf_assets where instance_id =:instance_id and id in ([template::util::tcl_to_sql_list $asset_ids_list])"]

    # If proc parameters are not blank, filter the results.
    # results already scoped for customer_id_list via asset_detail_lists
    set filter_asset_id_p [expr { $asset_id_list ne "" } ]
    set filter_asset_type_p [expr { $asset_type_list ne "" } ]
    if { $filter_asset_id_p } {
        set base_return_list [list ]
        set insert_p 0
        # scope to filter
        foreach as_list $as_detail_list {
            if { $filter_asset_id_p && [lsearch -exact $asset_id_list [lindex $as_list 0]] > -1 } {
                set insert_p 1
            }
            # if filtering list by details, do it here
            if { $filter_asset_type_p && [lsearch -exact $asset_type_list [lindex $as_list 1]] > -1 } {
                set insert_p 1
            }

            if { $insert_p } {
                set insert_p 0
                lappend base_return_list $as_list
            }
        }
    } else {
        set base_return_list $as_detail_list
    } 

    # results in base_return_list, consisting of this ordered list:
    #    asset_id asset_type, ua_id
    return $base_return_list
}

ad_proc -private hf_vms_basic {
    {instance_id ""}
    {customer_id_list ""}
    {asset_id_list ""}
    {inactives_included_p 0}
} {
    returns an ordered list of lists of vm detail
    Ordered list is: vm_id, domain_name, ip_id, ni_id, ns_id, os_id, type_id, resource_path, mount_union, details, count of vhosts on vm
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]

    # get all available asset_ids to user (ie. customers of user) (even ones that might be listed as a different type)
    # a vm is a subset of an hw, which is a subset of a dc.
    set asset_detail_lists [hf_assets_w_detail $instance_id $customer_id_list "" $inactives_included_p "" "" ""]
    set asset_id_list_arr(dc) [list ]
    set asset_id_list_arr(hw) [list ]
    set asset_id_list_arr(vm) [list ]
    foreach asset_list $asset_detail_lists {
        # build asset_ids_list_arr(dc, hw, vm)
        set asset_id [lindex $asset_list 0]
        set asset_type_id [lindex $asset_list 4]
        lappend asset_id_list_arr($asset_type_id) $asset_id
    }

    if { $customer_id_list eq "" } {
        #get all available hw_ids to user
        set vm_list [list ]

        # get all dc's associated with user, and subsequently, hw under those dc's
        set hw_id_list $asset_id_list_arr(hw)
        if { [llength $asset_id_list_arr(dc)] > 0 } {
            # dc
            set hw_id_indirect_list [db_list_of_lists hf_dc_get_hw_ids2 "select hw_id from hf_dc_hw_map where instance_id =:instance_id and dc_id in ([template::util::tcl_to_sql_list $asset_id_list_arr(dc)])"]
            foreach hw_id $hw_id_indirect_list {
                lappend hw_id_list $hw_id
            }
        }
        # get all vm's mapped to hw_ids
        # hf_hw_vm_map.instance_id, hw_id, vm_id
        set vm_id_list [db_list hf_vm_get_vm_ids "select vm_id from hf_hw_vm_map where instance_id =:instance_id and hw_ic in ([template::util::tcl_to_sql_list $hw_id_list])"]
        
        # get all direct vm's available to user
        # vm is an asset_type_id, so direct vm's are in: asset_id_list_arr(vm)
        
        # build list of list using collected vm_id's
        foreach vm_id $vm_id_list {
            lappend asset_id_list_arr(vm) $vm_id
        }
    }

    set vm_id_list $asset_id_list_arr(vm)
    # detail is retrieved from db before applying arbitrary filters, to help optimize db caching
    # hf_virtual_machines.instance_id, vm_id, domain_name, ip_id, ni_id, ns_id, type_id, resource_path, mount_union, details
    set vm_detail_list [db_list_of_lists hf_vm_get_detail "select vm_id, domain_name, ip_id, ni_id, ns_id, os_id, type_id, resource_path, mount_union, details from hf_virtual_machines where instance_id =:instance_id and vm_id in ([template::util::tcl_to_sql_list $vm_id_list])"]

    # If proc parameters are not blank, filter the results.
    # results already scoped for customer_id_list via asset_detail_lists
    set filter_asset_id_p [expr { $asset_id_list ne "" } ]
    if { $filter_asset_id_p } {
        set base_return_list [list ]
        set insert_p 0
        # scope to filter
        foreach vm_list $vm_detail_list {
            if { $filter_asset_id_p && [lsearch -exact $asset_id_list [lindex $vm_list 0]] > -1 } {
                set insert_p 1
            }
            # if filtering list by details, do it here

            if { $insert_p } {
                set insert_p 0
                lappend base_return_list $vm_list
            }
        }
    } else {
        set base_return_list $vm_detail_list
    }

# results in base_return_list, consisting of this ordered list:
# vm_id, domain_name, ip_id, ni_id, ns_id, type_id, resource_path, mount_union, details, count of vhosts on vm
    return $base_return_list
}


ad_proc -private hf_vms {
    {instance_id ""}
    {customer_id_list ""}
    {asset_id_list ""}
} {
    returns an ordered list of lists of an asset's virtual machines and their direct properties. A hardware id is an asset_id. 
    The ordered list is:  vm_id, domain_name, ip_id, ni_id, ns_id, os_id, type_id, resource_path, mount_union, details, count of vhosts on vm, count of services on vm
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    set base_return_list [hf_vms_basic $instance_id $customer_id_list $asset_id_list] 

    # add final details
    # hf_vm_vh_map.instance_id, vm_id, vh_id (include count(vh_id) per vm_id )
    # hf_ss_map.instance_id, ss_id, hf_id (where hf_id is vm_id or vh_id etc)
    set return_list [list ]
    foreach base_list $base_return_list {
        set vm_detail $base_list
        set vm_id [lindex $base_list 0]
        db_1row hf_vm_vh_ct "select count(vh_id) as vh_count from hf_vm_vh_map where instance_id =:instance_id and vm_id =:vm_id "
        db_1row hf_vm_ss_ct "select count(ss_id) as ss_count from hf_ss_map where instance_id =:instance_id and (hf_id =:vm_id or hf_id in (select vh_ids from hf_vm_vh_map where instance_id =:instance_id and vm_id =:vm_id))"
        lappend vm_detail $vh_count
        lappend vm_detail $ss_count
        lappend return_list $vm_detail
    }
    return $return_list
}


ad_proc -private hf_ips {
    {instance_id ""}
    {customer_id_list ""}
    {asset_id_list ""}
    {ip_id_list ""}
} {
    returns an ordered list of lists of ip references and their direct properties. 
    Ordered list is: asset_id,  ip_id, ipv4_addr, ipv4_status, ipv6_addr, ipv6_status
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]

    set base_return_list [hf_vms_basic $instance_id $customer_id_list $asset_id_list] 
# results in base_return_list, consisting of this ordered list:
#    vm_id, domain_name, ip_id, ni_id, ns_id, type_id, resource_path, mount_union, details, count of vhosts on vm
    # of note:  hf_virtual_machines.ip_id    
    set ip_ids_list [list ]
    foreach base_list $base_return_list {
        lappend ip_ids_list [lindex $base_list 2]
    }
    #   hf_ip_addresses.instance_id ip_id ipv4_addr ipv4_status ipv6_addr ipv6_status
    set ip_detail_list [db_list_of_lists hf_ip_addresses_get "select vm.vm_id, ip.ip_id, ip.ipv4_addr, ip.ipv4_status, ip.ipv6_addr, ip.ipv6_status from hf_assets vm, hf_ip_addresses ip where vm.instance_id =ip.instance_id and ip.ip_id = vm.ip_id and vm.instance_id =:instance_id and ip.ip_id in ([template::util::tcl_to_sql_list $ip_ids_list])"
    
    # If proc ip_id_list is not blank, filter the results.
    # results already scoped for customer_id_list via asset_detail_lists
    set filter_ip_id_p [expr { $ip_id_list ne "" } ]
    if { $filter_ip_id_p } {
        set base_return_list [list ]
        set insert_p 0
        # scope to filter
        foreach ip_list $ip_detail_list {
            if { $filter_ip_id_p && [lsearch -exact $ip_id_list [lindex $ip_list 1]] > -1 } {
                set insert_p 1
            }
            # if filtering list by details, do it here

            if { $insert_p } {
                set insert_p 0
                lappend base_return_list $ip_list
            }
        }
    } else {
        set base_return_list $ip_detail_list
    } 
    return $base_return_list
}

ad_proc -private hf_oses {
    {instance_id ""}
    {os_id_list ""}
    {orphaned_p 1}
    {requires_upgrade_p 1}
} {
    returns an ordered list of lists of operating systems and their direct properties. Defaults to all oses. Set orphaned_p 0 to not include orphaned ones. Set requires_upgrade_p to 0 to only include current, supported ones.
    Ordered list: os_id label brand version kernel orphaned_p requires_upgrade_p description
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    # no permissions needed     set user_id \[ad_conn user_id\]
    # build sql_extra
    set sql_extra ""
    if { $orphaned_p ne 1 } {
        set orphaned_p 0
        append sql_extra " and ( orphaned_p is null or orphaned_p <> '1' )"
    }
    if { $requires_upgrade_p ne 1 } {
        set requires_upgrade_p 0
        append sql_extra " and ( requires_upgrade_p is null or requires_upgrade_p <> '1' )"
    }
    if { $os_id_list ne "" } {
        set clean_os_id_list [list ]
        foreach os_id $os_id_list {
            # verify os_id_list elements are numbers
            if { [qf_is_natural_number $os_id] } {
                lappend clean_os_id_list $os_id
            }
        }
        if { [llength $clean_os_id_list] > 0 } {
            append sql_extra " and os_id in ([template::util::tcl_to_sql_list $clean_os_id_list])"
        }
    }
    # not adding os detail to hf_hws or hf_vms to avoid extra joins. These joins can be readily handled via hashing in app.
    # hf_operating_systems.instance_id os_id label brand version kernel orphaned_p requires_upgrade_p description
    set os_detail_list [db_list_of_lists hf_operating_systems_get "select os_id, label, brand, version, kernel, orphaned_p, requires_upgrade_p, description from hf_operating_systems where instance_id = :instance_id ${sql_extra}"]
    return $os_detail_list
}

ad_proc -private hf_vhs {
    {instance_id ""}
    {customer_id_list ""}
    {asset_id_list ""}
    {vh_id_list ""}
} {
    returns an ordered lists of lists of virtual hosts and their direct properties. The ordered list is: vm_id vh_id ua_id ns_id domain_name details count(ss_id)
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    # a common use will be to supply vm_id as asset_id_list.
    set base_return_list [hf_vms_basic $instance_id $customer_id_list $asset_id_list] 

# results in base_return_list, consisting of this ordered list:
#    vm_id, domain_name, ip_id, ni_id, ns_id, type_id, resource_path, mount_union, details
    set vm_ids_list [list ]
    foreach base_list $base_return_list {
        lappend vm_ids_list [lindex $base_list 0]
    }
    # hf_vm_vh_map.instance_id vm_id vh_id
    # every vh_id is mapped to a vm_id
    set vm_vh_list [db_list_of_lists hf_vm_vh_map_get "select vm_id, vh_id from hf_vm_vh_map where instance_id =:instance_id and vh_id in ([template::util::tcl_to_sql_list $vm_ids_list])"]

    if { $vh_id_list ne "" } {
        # filter vm_vh_list to vh_id_list
        set vm_vh_2_list [list ]
        foreach vm_vh_list $vm_vh_list {
            if { [lsearch -exact $vh_id_list [lindex $vm_vh_list 1]] > -1 } {
                lappend vm_vh_2_list $vm_vh_list
            }
        }
        set vm_vh_list $vm_vh_2_list
    }
    set vh_id_list [list ]
    foreach vm_vh_list $vm_vh_list {
        set vh_id [lindex $vm_vh_list 1]
        lappend vh_id_list $vh_id
        # create an array to reverse index later
        set vm_vh_arr($vh_id) [lindex $vm_vh_list 0]
    }
    # hf_hosts.instance_id vh_id ua_id ns_id domain_name details
    set vh_set_list [db_list_of_lists hf_vh_detail_get "select vh_id, ua_id, ns_id, domain_name, details from hf_vhosts where instance_id =:instance_id and vh_id in ([template::util::tcl_to_sql_list $vh_id_list])"]
    # build this list:
    # vm_id vh_id ua_id ns_id domain_name details count(ss_id)
    # don't assume all vh_id are in vh_set_list
    set vh_detail_list [list ]
    foreach vh_list $vh_set_list {
        set vh_one_list [list ]
        set vh_id [lindex $vh_list 0]
        lappend vh_one_list $vm_vh_arr($vh_id)
        foreach vh_el $vh_list {
            lappend vh_one_list $vh_el
        }
        # add more detail
        # hf_ss_map.instance_id hf_id ss_id
        # ss = hosted service
        # hf_ss_map.instance_id, ss_id, hf_id (where hf_id is vm_id or vh_id etc)
        db_1row hf_ss_count_get "select count(ss_id) as ss_id_count from hf_ss_map where instance_id =:instance_id and hf_id =:vh_id"
        lappend vh_one_list $ss_id_count
        lappend vh_detail_list $vh_one_list
    }
    return $vh_detail_list
}

ad_proc -private hf_m_uas {
    {instance_id ""}
    {customer_id_list ""}
    {asset_id_list ""}
    {vh_id_list ""}
    {ss_id_list ""}
} {
    returns an ordered lists of lists of management user accounts and their direct properties for each asset_id.
    Ordered list: asset_id asset_type vh_id ss_id ua_id details connection_type  (ss_id, asset_type and/or vh_id may be blank for some references)
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    # ua's are referenced by: 
        # hf_assets.ua_id
        # hf_vhosts.ua_id
        # hf_services.ua_id

    # build ua_ids_list
    # and compile index list and arrays
    # then
    # build return list
    
    set base_asset_list [hf_asset_type_ua_ids $instance_id $customer_id_list $asset_id_list]

    set as_ids_list [list ]
    set vm_ids_list [list ]
    set ua_ids_list [list ]
    foreach base_list $base_asset_list {
        set asset_id [lindex $base_list 0]
        set asset_type [lindex $base_list 1]
        set ua_id [lindex $base_list 2]
        lappend as_ids_list $asset_id
        lappend ua_ids_list $ua_id
#        set ua_type_arr($ua_id) "as"
        if { $asset_type eq "vm" } {
            lappend vm_ids_list $asset_id
        }
        if { $asset_type ne "ss" } {
            # ss is listed directly, so exclude from indirect checks
            lappend as_wo_ss_ids_list $asset_id
        }
    }
    # get vhost uas
    # every vh_id is mapped to a vm_id
    # hf_vm_vh_map.instance_id vm_id vh_id
    set vm_vh_map_list [db_list_of_lists hf_vm_vh_map_get "select vm_id, vh_id from hf_vm_vh_map where instance_id =:instance_id vh_id in ([template::util::tcl_to_sql_list $vm_ids_list])"]
 
   # filter vm_vh_list to vh_id_list
    if { $vh_id_list ne "" } {
        set vm_vh_2_list [list ]
        foreach vm_vh $vm_vh_list {
            set vh_id [lindex $vm_vh 1]
            if { [lsearch -exact $vh_id_list $vh_id] > -1 } {
                lappend vm_vh_2_list $vm_vh
            }
        }
        set vm_vh_map_list $vm_vh_2_list
    }

    set vh_ids_list [list ]
    foreach vm_vh_list $vm_vh_map_list {
        set vh_id [lindex $vm_vh_list 1]
        lappend vh_ids_list $vh_id
        # create an array to reverse index later
        set vm_vh_arr($vh_id) [lindex $vm_vh_list 0]
    }
    # hf_vhosts.instance_id vh_id ua_id ns_id domain_name details
    set vh_set_list [db_list_of_lists hf_vh_ua_detail_get "select vh_id, ua_id from hf_vhosts where instance_id =:instance_id and vh_id in ([template::util::tcl_to_sql_list $vh_ids_list])"]
    foreach vh_ua_list $vh_set_list {
        set vh_id [lindex $vh_ua_list 0]
        set ua_id [lindex $vh_ua_list 1]
        lappend vh_ids_list $vh_id
        lappend ua_ids_list $ua_id
 #       set ua_type_arr($ua_id) "vh"
    }

    # include cases where ss is a subsite of a vh_id and not referenced by asset_id directly.
    # hf_ss_map.instance_id, ss_id, hf_id (where hf_id is vm_id or vh_id etc)
    #                             ss = hosted service
    # hf_services.instance_id ss_id server_name service_name daemon_ref protocol port ua_id ss_type ss_subtype ss_undersubtype ss_ultrasubtype config_uri memory_bytes details
    set ss_set_list [db_list_of_lists hf_ss_ua_get "select hf_id, ss_id, ua_id from hf_services ss, hf_ss_map vs where ss.instance_id = vs.instance_id and ss.ss_id = vs.ss_id and ss.instance_id =:instance_id and vs.hf_id in ([template::util::tcl_to_sql_list $as_wo_ss_ids_list]) "]
    if { $ss_id_list ne "" } {
        # filter ss_set_list to ss_id_list
        set ss_set_2_list [list ]
        foreach ss_set $ss_set_list {
            set ss_id [lindex $ss_set 1]
            if { [lsearch -exact $ss_id_list $ss_id] > -1 } {
                set vh_id [lindex $ss_ua_list 0]
                set ss_id [lindex $ss_ua_list 1]
                set ua_id [lindex $ss_ua_list 2]
                lappend ss_ids_list $ss_id
                lappend ua_ids_list $ua_id
            #        set ua_type_arr($ua_id) "ss"
                lappend ss_set_2_list $ss_set
            }
        }
        set ss_set_list $ss_set_2_list
    } else {
        foreach ss_ua_list $ss_set_list {
            set vh_id [lindex $ss_ua_list 0]
            set ss_id [lindex $ss_ua_list 1]
            set ua_id [lindex $ss_ua_list 2]
            lappend ss_ids_list $ss_id
            lappend ua_ids_list $ua_id
            #        set ua_type_arr($ua_id) "ss"
        }
    }

    # bulk query
    set ua_detail_list [db_list_of_lists hf_ua_detail_get "select ua_id details connection_type from hf_ua where instance_id =:instance_id and ua_id in ([template::util::tcl_to_sql_list $ua_ids_list])"]
    # convert ua_detail_list to ua_detail_arr
    foreach ua_detail $ua_detail_list {
        set ua_id [lindex $ua_detail 0]
        # build hash table for appending detail later
        set ua_detail_arr($ua_id) $ua_detail
    }

    # build return_list ua_index_list in order of:
    # asset_id asset_type vh_id ss_id ua_id details connection_type    

    set vh_id ""
    set ss_id ""
    foreach as_list $base_asset_list {
        set as_id [lindex $as_list 0]
        set as_type [lindex $as_list 1]
        set ua_id [lindex $as_list 2]
        set ua_list [list $as_id $as_type $vh_id $ss_id $ua_id]
        lappend ua_index_list $ua_list
    }
    
    set as_id ""
    set as_type ""
    foreach ss_ua $ss_set_list {
        set vh_id [lindex $ss_ua 0]
        set ss_id [lindex $ss_ua 1]
        set ua_id [lindex $ss_ua 2]

        set ua_list [list $as_id $as_type $vh_id $ss_id $ua_id]
        lappend ua_index_list $ua_list
    }

    set ss_id ""
    foreach vh_list $vh_detail_list {
        set vm_id [lindex $vh_list 0]
        set vh_id [lindex $vh_list 1]
        set ua_id [lindex $vh_list 2]
        set ua_list [list $as_id $as_type $vh_id $ss_id $ua_id]
        lappend ua_index_list $ua_list
    }

    # append ua detail
    set ua_map_detail_list [list ]
    foreach ua_index $ua_index_list {
        set ua_id [lindex $ua_index 4]
        if { [info exists ua_detail_arr($ua_id) ] } {
            #set ua_final $ua_index
            # don't want to duplicate ua_id
            set ua_final_list [lrange $ua_index 0 4]
            # detail:
            lappend ua_final_list [lindex $ua_detail_arr($ua_id) 1]
            # connection_type:
            lappend ua_final_list [lindex $ua_detail_arr($ua_id) 2]
            lappend ua_map_detail_list $ua_final
        } else {
            ns_log Warning "hf_m_uas(883): missing ua_id '$ua_id' for ua_index: '$ua_index'"
        }
    }
    return $ua_map_detail_list
}


ad_proc -private hf_asset_uas {
    {instance_id ""}
    {customer_id_list ""}
    {asset_id ""}
} {
    returns an ordered lists of lists of user accounts and their direct properties for a virtual machine vm_id or other asset_id
    Ordered list: asset_id asset_type vh_id ss_id ua_id details connection_type  (ss_id, asset_type and/or vh_id may be blank for some references)
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    # ua's referenced by: 
        # hf_assets.ua_id
        # hf_vhosts.ua_id
        # hf_services.ua_id

    # build ua_ids_list
    # and compile index list and arrays
    # then
    # build return list

    set asset_id_list [hf_asset_ids_for_user $user_id]
    set ua_map_detail_list [list ]
    if { [lsearch -exact $asset_id_list $asset_id] > -1 } {

        set base_asset_list [hf_vms_basic $instance_id $customer_id_list $asset_id]
        
        set as_ids_list [list ]
        set vm_ids_list [list ]
        set ua_ids_list [list ]
        foreach base_list $base_asset_list {
            set asset_id [lindex $base_list 0]
            set asset_type [lindex $base_list 1]
            set ua_id [lindex $base_list 2]
            lappend as_ids_list $asset_id
            lappend ua_ids_list $ua_id
            #        set ua_type_arr($ua_id) "as"
            if { $asset_type eq "vm" } {
                lappend vm_ids_list $asset_id
            }
            if { $asset_type ne "ss" } {
                # ss is listed directly, so exclude from indirect checks
                lappend as_wo_ss_ids_list $asset_id
            }

        }
        
        # get vhost uas
        # every vh_id is mapped to a vm_id
        # hf_vm_vh_map.instance_id vm_id vh_id
        set vm_vh_map_list [db_list_of_lists hf_vm_vh_map_get2 "select vm_id, vh_id from hf_vm_vh_map where instance_id =:instance_id and vh_id in ([template::util::tcl_to_sql_list $vm_ids_list])"]
        
        set vh_ids_list [list ]
        foreach vm_vh_list $vm_vh_map_list {
            set vh_id [lindex $vm_vh_list 1]
            lappend vh_ids_list $vh_id
            # create an array to reverse index later
            set vm_vh_arr($vh_id) [lindex $vm_vh_list 0]
        }
        # hf_hosts.instance_id vh_id ua_id ns_id domain_name details
        set vh_set_list [db_list_of_lists hf_vh_ua_detail_get2 "select vh_id, ua_id from hf_hosts where instance_id =:instance_id and vh_id in ([template::util::tcl_to_sql_list $vh_ids_list])"]
        foreach vh_ua_list $vh_set_list {
            set vh_id [lindex $vh_ua_list 0]
            set ua_id [lindex $vh_ua_list 1]
            lappend vh_ids_list $vh_id
            lappend ua_ids_list $ua_id
            #       set ua_type_arr($ua_id) "vh"
        }
        
        # include cases where ss is a subsite of a vh_id and not referenced by asset_id directly.
        # hf_ss_map.instance_id, ss_id, hf_id (where hf_id is vm_id or vh_id etc)
        #                             ss = hosted service
        # hf_services.instance_id ss_id server_name service_name daemon_ref protocol port ua_id ss_type ss_subtype ss_undersubtype ss_ultrasubtype config_uri memory_bytes details
        set ss_set_list [db_list_of_lists hf_ss_ua_get2 "select hf_id, ss_id, ua_id from hf_services ss, hf_ss_map vs where ss.instance_id = vs.instance_id and ss.ss_id = vs.ss_id and ss.instance_id =:instance_id and vs.hf_id in ([template::util::tcl_to_sql_list $as_wo_ss_ids_list]) "]
        foreach ss_ua_list $ss_set_list {
            set vh_id [lindex $ss_ua_list 0]
            set ss_id [lindex $ss_ua_list 1]
            set ua_id [lindex $ss_ua_list 2]
            lappend ss_ids_list $ss_id
            lappend ua_ids_list $ua_id
            #        set ua_type_arr($ua_id) "ss"
        }
        
        
        # bulk query
        set ua_detail_list [db_list_of_lists hf_ua_detail_get2 "select ua_id details connection_type from hf_ua where instance_id =:instance_id and ua_id in ([template::util::tcl_to_sql_list $ua_ids_list])"]
        # convert ua_detail_list to ua_detail_arr
        foreach ua_detail $ua_detail_list {
            set ua_id [lindex $ua_detail 0]
            set ua_detail_arr($ua_id) $ua_detail
        }
        
        # build return_list ua_index_list in order of:
        # asset_id asset_type vh_id ss_id ua_id details connection_type    
        
        set vh_id ""
        set ss_id ""
        foreach as_list $base_asset_list {
            set as_id [lindex $as_list 0]
            set as_type [lindex $as_list 1]
            set ua_id [lindex $as_list 2]
            set ua_list [list $as_id $as_type $vh_id $ss_id $ua_id]
            lappend ua_index_list $ua_list
        }
        
        set as_id ""
        set as_type ""
        foreach ss_ua $ss_set_list {
            set vh_id [lindex $ss_ua 0]
            set ss_id [lindex $ss_ua 1]
            set ua_id [lindex $ss_ua 2]
            
            set ua_list [list $as_id $as_type $vh_id $ss_id $ua_id]
            lappend ua_index_list $ua_list
        }
        
        set ss_id ""
        foreach vh_list $vh_detail_list {
            set vm_id [lindex $vh_list 0]
            set vh_id [lindex $vh_list 1]
            set ua_id [lindex $vh_list 2]
            set ua_list [list $as_id $as_type $vh_id $ss_id $ua_id]
            lappend ua_index_list $ua_list
        }
        
        # append ua detail
        set ua_map_detail_list [list ]
        foreach ua_index $ua_index_list {
            set ua_id [lindex $ua_index 4]
            if { [info exists ua_detail_arr($ua_id) ] } {
                #set ua_final $ua_index
                # don't want to duplicate ua_id
                set ua_final_list [lrange $ua_index 0 4]
                # detail:
                lappend ua_final_list [lindex $ua_detail_arr($ua_id) 1]
                # connection_type:
                lappend ua_final_list [lindex $ua_detail_arr($ua_id) 2]
                lappend ua_map_detail_list $ua_final
            } else {
                ns_log Warning "hf_m_uas(1164): missing ua_id '$ua_id' for ua_index: '$ua_index'"
            }
        }
    }
    return $ua_map_detail_list
}

ad_proc -private hf_sss {
    {instance_id ""}
    {customer_id_list ""}
    {asset_id_list ""}
    {inactives_included_p 0}
} {
    returns an ordered list of lists of software as services (hosted services) and their direct properties. ss_id is a subset of asset_id.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]

    # get all available asset_ids to user (ie. customers of user) 
    set asset_detail_lists [hf_assets_w_detail $instance_id $customer_id_list "" $inactives_included_p "" "" ""]
    set as_ids_list [list ]
    foreach asset_list $asset_detail_lists {
        set asset_id [lindex $asset_list 0]
        lappend as_ids_list $asset_id
    }
    # filter as_id_list by asset_id_list
    if { $asset_id_list ne "" } {
        set filtered_ids_list [list ]
        # scope to filter
        foreach as_id $as_ids_list {
            if { [lsearch -exact $asset_id_list $as_id ] > -1 } {
                lappend filtered_ids_list $as_id
            }
        }
    } else {
        set filtered_ids_list $as_ids_list
    }

    # filter to ss, but also include cases where ss is indirectly referenced, such as via vm or vh types (which may expand the set of asset_ids).
    # hf_ss_map.instance_id, ss_id, hf_id (where hf_id is vm_id or vh_id etc)
    set ss_set_list [db_list_of_lists hf_ss_ua_get2 "select distinct hf_id, ss_id from hf_ss_map where instance_id =:instance_id and ( hf_id in ([template::util::tcl_to_sql_list $filtered_ids_list]) or ss_id in ([template::util::tcl_to_sql_list $filtered_ids_list]) )"]
    # How to handle cases where ids in ss_set_list are not in as_ids_list?
    # Log them; but also include a subset of the data in the return list --enough to identify, but not act on a service.
    # Users want to know if they are about to adversely affect something else.
    set ss_ids_list [list ]
    # scope to filter
    foreach ss_id $ss_set_list {
        if { [lsearch -exact $as_ids_list $ss_id ] > -1 } {
            lappend ss_ids_list $as_id
        }
    }

    # build primary asset table from asset_detail_lists that match ss_ids_list 
    set asset_return_list [list ]
    foreach asset_list $asset_detail_lists {
        set asset_id [lindex $asset_list 0]
        set asset_id_loc [lsearch -exact $ss_ids_list asset_id]
        if { $asset_id_loc > -1 } {
            lappend asset_return_list $asset_list
            # remove ss_id from list
            set ss_ids_list [lreplace $ss_ids_list $asset_id_loc $asset_id_loc]
        }
    }
    # Add basic details of any remaining ss_ids_list elements to asset_return_list
    # details must be consistent with 
    # hf_assets_w_detail: id,user_id,last_modified,created,asset_type_id,qal_product_id, qal_customer_id,label,keywords,templated_p,template_p,time_start,time_stop,trashed_p,trashed_by,flags,publish_p

    # Get basic details from the db directly to bypass permissions. Only get essential, descriptive info; leave all else blank.
    set ss3_asset_list [db_list_of_lists hf_asset_templates_select_v2 "select id,user_id,last_modified,created,asset_type_id,qal_product_id, qal_customer_id,label,'' as keywords,templated_p,template_p,time_start,time_stop,trashed_p,trashed_by,flags,publish_p from hf_assets where instance_id =:instance_id and time_stop =null and ( trashed_p is null or trashed_p <> '1' ) and id in ( [template::util::tcl_to_sql_list $ss_ids_list] ) order by last_modified desc " ]
    # removed keywords
    # name = label? yes. see hf_asset_create_from_asset_template
    
    # add ss3_asset_list to asset_return_list
    foreach ss3_asset $ss3_asset_list {
        lappend asset_return_list $ss3_asset
    }

    # add hf_services detail to asset_return_list
    # hf_services.instance_id ss_id server_name service_name daemon_ref protocol port ua_id ss_type ss_subtype ss_undersubtype ss_ultrasubtype config_uri memory_bytes details
    set attr_list [db_list_of_lists hf_services_getv2 "select ss_id server_name service_name ss_type ss_subtype ss_undersubtype ss_ultrasubtype daemon_ref protocol port ua_id config_uri memory_bytes details from hf_services where instance_id =:instance_id and ss_id in ([template::util::tcl_to_sql_list $ss_ids_list]) or ss_id in ([template_::util::tcl_to_sql_list $filtered_ids_list])"]
    # build hash array of attr_list
    for a1_list $attr_list {
        set ss_id [lindex $a1_list 0]
        # include all info if id in filtered_ids_list
        if { [lsearch -exact $filtered_ids_list $ss_id] > -1 } {
            set att_arr($ss_id) [lrange $a1_list 1 end]
        } else {
            # filter to min info if id in ss_ids_list. 
            # Since ss_id is not in filtered_ids_list, it is in ss_ids_list.
            # filter out: ua_id daemon_ref protocol port config_uri memory_bytes details, replace with blank elements
            set att_arr($ss_id) [lrange $a1_list 1 6]
            lappend att_arr($ss_id) "" "" "" "" "" "" ""
        }
    }
    set new_a_return_list [list ]
    foreach asset_list $asset_return_list {
        set ss_id [lindex $asset_list 0]
        set new_a_list $asset_list
        foreach ii $att_arr($ss_id) {
            lappend new_a_list $ii
        }
        lappend new_a_return_list $new_a_list
    }
    return $new_a_return_list
}




ad_proc -private hf_asset_features {
    {instance_id ""}
    {asset_type_id_list ""}
} {
    returns a tcl_list_of_lists of features with attributes in order of: asset_type_id, feature_id, label, feature_type, publish_p, title, description
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
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
    set feature_list [db_list_of_lists hf_asset_type_features_get "select asset_type_id, feature_id, label, feature_type, publish_p, title, description from from hf_asset_type_features where instance_id =:instance_id and asset_type_id in ([template_::util::tcl_to_sql_list $new_as_type_id_list])"]
    return $feature_list
}


# basic API
# With each change, call hf_monitor_log_create {
#    asset_id, reported_by, user_id .. monitor_id=0}
ad_proc -private hf_asset_type_write {
    label
    title
    description
    {id ""}
    {instance_id ""}
} {
    creates or writes asset type, if id is blank, returns id of new asset type; otherwise returns 1 if id exists and db updated. 
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    set admin_p [hf_permission_p $user_id "" assets write $instance_id]
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


ad_proc -private hf_asset_type_read {
    type_id_list
    {instance_id ""}
} {
    returns an existing asset_type in a list of lists: {label1, title1, description1} {labelN, titleN, descriptionN} or blank list if none found. Bad id's are ignored.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    # validate/filter the asset_type_id_list for nonqualifying reference types
    set new_as_type_id_list [list ]
    foreach asset_type_id $type_id_list {
        if { [ad_var_type_check_number_p $asset_type_id] } {
            lappend new_as_type_id_list $asset_type_id
        }
    }
    
    set return_list_of_lists [db_list_of_lists hf_asset_type_read "select id, label, title, description from hf_asset_type where instance_id =:instance_id and id in ([template::util::tcl_to_sql_list $new_as_type_id_list])" ]
    
    return $return_list_of_lists
}

ad_proc -private hf_asset_types {
    {label_match ""}
    {instance_id ""}
} {
    returns matching asset types as a list of list: {id,label,title,description}, if label is nonblank, returns asset types that glob match the passed label value via tcl match.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set all_asset_types_list_of_lists [db_list_of_lists hf_asset_types_get {select id,label, title, description from hf_asset_type where instance_id =:instance_id} ]
    if { $label_match ne "" } {
        set return_list_of_lists [list ]
        foreach asset_type_list $all_asset_types_list_of_lists {
            if { [string match -nocase $label_match [lindex $asset_type_list 1]] } {
                lappend return_list_of_lists $asset_type_list
            }
        }
    } else {
        set return_list_of_lists $all_asset_types_list_of_lists
    }
    return $return_list_of_lists
}



ad_proc -private hf_dc_read {
    {dc_id ""}
    {instance_id ""}
} {
    reads full detail of dcs. This is not redundant to hf_dcs. This is for 1 dc_id. It includes all attributes and no summary counts of dependents. Returns general asset contents followed by specific dc details. dc description is contextual to dc, whereas asset description is in context of all assets. Returns ordered list: name,title,asset_type_id,keywords,description,content,comments,trashed_p,trashed_by,template_p,templated_p,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created, dc_affix, dc_description, dc_details 
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    # Since the dependency tree is large, no dependencies are checked

    set attribute_list [hf_asset_read $dc_id $instance_id $user_id]
    # Returns asset contents of asset_id. Returns asset as list of attribute values: name,title,asset_type_id,keywords,description,content,comments,trashed_p,trashed_by,template_p,templated_p,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created
    set asset_type_id [lindex $attribute_list 2]
    # is asset_id of type dc?
    set return_list [list ]
    if { $asset_type_id eq "dc" } {
        set return_list $attribute_list
        # get, append remaining detail

        # tables hf_data_centers.instance_id,dc_id, affix (was datacentr.short_code), description, details
        set dc_detail_list [db_list hf_dc_detail_get "select affix, description, details from hf_data_centers where instance_id =:instance_id and dc_id=:dc_id"]
        foreach dc_att_list $dc_detail_list {
            lappend return_list $dc_att_list
        }
    }
    return $return_list
}

ad_proc -private hf_dc_write {
    dc_id
    name
    title
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
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    set new_dc_id ""
    if { $dc_id ne "" } {
        # validate dc_id. If dc_id not a dc or does not exist, set dc_id ""
        if { ![hf_asset_id_exists $dc_id $instance_id "dc"] } {
            set dc_id ""
        }
    }

    if { $dc_id eq "" } {
        # hf_asset_create checks permission to create
        set dc_id_new [hf_asset_create $label $name $asset_type_id $title $content $keywords $description $comments $template_p $templated_p $publish_p $monitor_p $popularity $triage_priority $op_status $ua_id $ns_id $qal_product_id $qal_customer_id $template_id $flags $instance_id $user_id]
    } else {
        # hf_asset_write checks permission to write
        set dc_id_new [hf_asset_write $label $name $title $asset_type_id $content $keywords $description $comments $template_p $templated_p $publish_p $monitor_p $popularity $triage_priority $op_status $ua_id $ns_id $qal_product_id $qal_customer_id $template_id $dc_id $flags $instance_id $user_id]
    }
    if { $dc_id_new ne "" } {
        # insert dc asset hf_datacenters
        db_dml dc_asset_create {insert into hf_data_centers
            (instance_id, dc_id, affix, description, details)
            values (:instance_id,:dc_id_new,:dc_affix,:dc_description,:dc_details) }
    } 
    return $dc_id_new
}


ad_proc -private hf_hw_read {
    hw_id
    {instance_id ""}
} {
    reads full detail of one hw. This is not redundant to hf_hws. This accepts only 1 id and includes all attributes and no summary counts of dependents.
    Returns ordered list: name,title,asset_type_id,keywords,description,content,comments,trashed_p,trashed_by,template_p,templated_p,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created, hw_system_name, hw_backup_sys, hw_ni_id, hw_os_id, hw_description, hw_details
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    # Since the dependency tree is large, no dependencies are checked
    set attribute_list [hf_asset_read $hw_id $instance_id $user_id]
    # Returns asset contents of asset_id. Returns asset as list of attribute values: name,title,asset_type_id,keywords,description,content,comments,trashed_p,trashed_by,template_p,templated_p,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created
    set asset_type_id [lindex $attribute_list 2]
    # is asset_id of type hw?
    set return_list [list ]
    if { $asset_type_id eq "hw" } {
        set return_list $attribute_list
        # get, append remaining detail

        #  hf_hardware.instance_id, hw_id, system_name, backup_sys, ni_id, os_id, description, details
        set hw_detail_list [db_list hf_hw_detail_get "select system_name, backup_sys, ni_id, os_id, description, details from hf_hardware where instance_id =:instance_id and hw_id=:hw_id"]
        foreach hw_att_list $hw_detail_list {
            lappend return_list $hw_att_list
        }
    }
    return $return_list
}

ad_proc -private hf_hw_write {
    hw_id
    name
    title
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
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    set new_hw_id ""
    if { $hw_id ne "" } {
        # validate hw_id. If hw_id not an hw or does not exist, set hw_id ""
        if { ![hf_asset_id_exists $hw_id $instance_id "hw"] } {
            set hw_id ""
        }
    }

    if { $hw_id eq "" } {
        # hf_asset_create checks permission to create
        set hw_id_new [hf_asset_create $label $name $asset_type_id $title $content $keywords $description $comments $template_p $templated_p $publish_p $monitor_p $popularity $triage_priority $op_status $ua_id $ns_id $qal_product_id $qal_customer_id $template_id $flags $instance_id $user_id]
    } else {
        # hf_asset_write checks permission to write
        set hw_id_new [hf_asset_write $label $name $title $asset_type_id $content $keywords $description $comments $template_p $templated_p $publish_p $monitor_p $popularity $triage_priority $op_status $ua_id $ns_id $qal_product_id $qal_customer_id $template_id $hw_id $flags $instance_id $user_id]
    }
    if { $hw_id_new ne "" } {
        # insert hw asset hf_hardware
        db_dml hw_asset_create {insert into hf_hardware
            (instance_id, hw_id, system_name, backup_sys, ni_id, os_id, description, details)
            values (:instance_id,:hw_id_new,:hw_system_name,:hw_backup_sys,:hw_ni_id,:hw_os_id,:hw_description,:hw_details) }
    } 
    return $hw_id_new
}

ad_proc -private hf_vm_read {
    vm_id
    {instance_id ""}
} {
    reads full detail of one vm. This is not redundant to hf_vms. This accepts only 1 id and includes all attributes and no summary counts of dependents.
    Returns ordered list: name,title,asset_type_id,keywords,description,content,comments,trashed_p,trashed_by,template_p,templated_p,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created, vm_domain_name, vm_ip_id, vm_ni_id, vm_ns_id, vm_os_id, vm_type_id, vm_resource_path, vm_mount_union, vm_details

} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    # Since the dependency tree is large, no dependencies are checked
    set attribute_list [hf_asset_read $vm_id $instance_id $user_id]
    # Returns asset contents of asset_id. Returns asset as list of attribute values: name,title,asset_type_id,keywords,description,content,comments,trashed_p,trashed_by,template_p,templated_p,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created
    set asset_type_id [lindex $attribute_list 2]
    # is asset_id of type vm?
    set return_list [list ]
    if { $asset_type_id eq "vm" } {
        set return_list $attribute_list
        # get, append remaining detail

        # hf_virtual_machines.instance_id, vm_id, domain_name, ip_id, ni_id, ns_id, type_id, resource_path, mount_union, details
        set vm_detail_list [db_list hf_vm_detail_get "select domain_name, ip_id, ni_id, ns_id, os_id, type_id, resource_path, mount_union, details from hf_virtual_machines where instance_id =:instance_id and vm_id =:vm_id"]
        foreach vm_att_list $vm_detail_list {
            lappend return_list $vm_att_list
        }
    }
    return $return_list
}

ad_proc -private hf_vm_write {
    vm_id
    name
    title
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
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    # hf_assets.instance_id, id, template_id, user_id, last_modified, created, asset_type_id, qal_product_id, qal_customer_id, label, keywords, description, content, coments, templated_p, template_p, time_start, time_stop, ns_id, ua_id, op_status, trashed_p, trashed_by, popularity, flags, publish_p, monitor_p, triage_priority

    set new_vm_id ""
    if { $vm_id ne "" } {
        # validate vm_id. If vm_id not an vm or does not exist, set vm_id ""
        if { ![hf_asset_id_exists $vm_id $instance_id "vm"] } {
            set vm_id ""
        }
    }

    if { $vm_id eq "" } {
        # hf_asset_create checks permission to create
        set vm_id_new [hf_asset_create $label $name $asset_type_id $title $content $keywords $description $comments $template_p $templated_p $publish_p $monitor_p $popularity $triage_priority $op_status $ua_id $ns_id $qal_product_id $qal_customer_id $template_id $flags $instance_id $user_id]
    } else {
        # hf_asset_write checks permission to write
        set vm_id_new [hf_asset_write $label $name $title $asset_type_id $content $keywords $description $comments $template_p $templated_p $publish_p $monitor_p $popularity $triage_priority $op_status $ua_id $ns_id $qal_product_id $qal_customer_id $template_id $vm_id $flags $instance_id $user_id]
    }
    if { $vm_id_new ne "" } {
        # insert vm asset hf_virtual_machines
        # hf_virtual_machines.instance_id, vm_id, domain_name, ip_id, ni_id, ns_id, type_id, resource_path, mount_union, details
        db_dml vm_asset_create {insert into hf_virtual_machines
            (instance_id, vm_id, domain_name, ip_id, ni_id, ns_id, type_id, resource_path, mount_union, details)
            values (:instance_id, :new_vm_id, :vm_domain_name, :vm_ip_id, :vm_ni_id, :vm_ns_id, :vm_type_id, :vm_resource_path, :vm_mount_union, :vm_details) }
    } 
    return $vm_id_new
}

ad_proc -private hf_ss_read {
    ss_id
    {instance_id ""}
} {
    reads full detail of one ss. This is not redundant to hf_sss. This accepts only 1 id and includes all attributes and no summary counts of dependents.
    Returns ordered list: name,title,asset_type_id,keywords,description,content,comments,trashed_p,trashed_by,template_p,templated_p,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created, ss_server_name ss_service_name ss_daemon_ref ss_protocol ss_port ss_ua_id ss_ss_type ss_ss_subtype ss_ss_undersubtype ss_ss_ultrasubtype ss_config_uri ss_memory_bytes ss_details
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    # Since the dependency tree is large, no dependencies are checked
    set attribute_list [hf_asset_read $ss_id $instance_id $user_id]
    # Returns asset contents of asset_id. Returns asset as list of attribute values: name,title,asset_type_id,keywords,description,content,comments,trashed_p,trashed_by,template_p,templated_p,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created
    set asset_type_id [lindex $attribute_list 2]
    # is asset_id of type ss?
    set return_list [list ]
    if { $asset_type_id eq "ss" } {
        set return_list $attribute_list
        # get, append remaining detail
        # hf_services.instance_id ss_id server_name service_name daemon_ref protocol port ua_id ss_type ss_subtype ss_undersubtype ss_ultrasubtype config_uri memory_bytes details
        set ss_detail_list [db_list hf_ss_detail_get "select server_name, service_name, ss_type, ss_subtype, ss_undersubtype, ss_ultrasubtype, daemon_ref, protocol, port, ua_id, config_uri, memory_bytes, details from hf_services where instance_id =:instance_id and ss_id =:ss_id"]
        foreach ss_att_list $ss_detail_list {
            lappend return_list $ss_att_list
        }
    }
    return $return_list
}

ad_proc -private hf_ss_write {
    ss_id
    name
    title
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
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    set new_ss_id ""
    if { $ss_id ne "" } {
        # validate ss_id. If ss_id not an ss or does not exist, set ss_id ""
        if { ![hf_asset_id_exists $ss_id $instance_id "ss"] } {
            set ss_id ""
        }
    }

    if { $ss_id eq "" } {
        # hf_asset_create checks permission to create
        set ss_id_new [hf_asset_create $label $name $asset_type_id $title $content $keywords $description $comments $template_p $templated_p $publish_p $monitor_p $popularity $triage_priority $op_status $ua_id $ns_id $qal_product_id $qal_customer_id $template_id $flags $instance_id $user_id]
    } else {
        # hf_asset_write checks permission to write
        set ss_id_new [hf_asset_write $label $name $title $asset_type_id $content $keywords $description $comments $template_p $templated_p $publish_p $monitor_p $popularity $triage_priority $op_status $ua_id $ns_id $qal_product_id $qal_customer_id $template_id $ss_id $flags $instance_id $user_id]
    }
    if { $ss_id_new ne "" } {
        # insert ss asset hf_services
        db_dml ss_asset_create {insert into hf_services
            (instance_id, ss_id, server_name, service_name, daemon_ref, protocol, port, ua_id, ss_type, ss_subtype, ss_undersubtype, ss_ultrasubtype, config_uri, memory_bytes, details)
            values (:instance_id,:ss_id_new,:ss_server_name,:ss_service_name,:ss_daemon_ref,:ss_protocol,:ss_port,:ss_ua_id,:ss_ss_type,:ss_ss_subtype,:ss_ss_undersubtype,:ss_ss_ultrasubtype,:ss_config_uri,:ss_memory_bytes,:ss_details)}
    } 
    return $ss_id_new
}

# The following are not assets by default. Log changes to a log of the asset the property is assigned to
ad_proc -private hf_ip_read {
    ip_id
    {instance_id ""}
} {
    reads full detail of one ip address: ipv4_addr ipv4_status ipv6_addr ipv6_status. This is not redundant to hf_ips. This accepts only 1 id and includes all attributes (no summary counts)
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    # to check permissions here, would require:
    # get asset_id via a new proc hf_id_of_ip_id, but that would return multiple asset_ids (VMs + machine etc).
    # checking permissions  would require hf_ids_of_ip_id.. and that would be slow for large sets
    # hf_ip_read/write etc should only be called from within a private proc. and is publically available via inet services anyway..

    # get ip data
    set return_list [list ]
    if { [qf_is_natural_number $ip_id ] } {
        set return_list [db_list hf_ip_detail_get "select ipv4_addr, ipv4_status, ipv6_addr, ipv6_status from hf_ip_addresses where instance_id =:instance_id and ip_id =:ip_id"]
    }
    return $return_list
}

ad_proc -private hf_ip_id_exists {
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

ad_proc -private hf_ni_id_exists {
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

ad_proc -private hf_ip_write {
    asset_id
    ip_id
    ipv4_addr
    ipv4_status
    ipv6_addr
    ipv6_status
    {instance_id ""}
} {
    writes or creates an ip asset_type_id. If ip_id is blank, a new one is created, and the new ip_id returned. The ip_id is returned if successful, otherwise 0 is returned. Does not check for address collisions.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    set return_id 0

    # check permissions, get customer_id of asset
    if { [qf_is_natural_number $asset_id] && [qf_is_natural_number $instance_id ] } {
        set customer_id [hf_customer_id_of_asset_id $asset_id]
        set admin_p [hf_permission_p $user_id $customer_id assets admin $instance_id]
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

ad_proc -private hf_ni_read {
    {ni_id ""}
    {instance_id ""}
} {
    reads full detail of one ni. This is not redundant to hf_nis. This accepts only 1 ns_id and includes all attributes (no summary counts):  os_dev_ref, ipv4_addr_range, ipv6_addr_range, bia_mac_address, ul_mac_address
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set return_list [list ]
    if { [qf_is_natural_number $ni_id] } {
       set return_list [db_list hf_network_interfaces_read1 "select os_dev_ref, bia_mac_address, ul_mac_address, ipv4_addr_range, ipv6_addr_range from hf_network_interfaces where instance_id=:instance_id and ni_id =:ni_id"]
    }
    return $return_list
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
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    set return_ni_id 0

    # check permissions, get customer_id of asset
    if { [qf_is_natural_number $asset_id] && [qf_is_natural_number $instance_id ] } {
        set customer_id [hf_customer_id_of_asset_id $asset_id]
        set admin_p [hf_permission_p $user_id $customer_id assets admin $instance_id]
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

ad_proc -private hf_os_read {
    {os_id_list ""}
    {instance_id ""}
} {
    reads full detail of OSes; if os_id_list is blank, returns all records. os_id, label, brand, version, kernel, orphaned_p, requires_upgrade_p, description
} {
    set ost_lists [list ]
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $os_id_list eq "" } {
	set os_lists [db_list_of_lists hf_os_read hf_operating_systems { select os_id, label, brand, version, kernel, orphaned_p, requires_upgrade_p, description, where instance_id =:instance_id } ]
    } else {
	set filtered_ids_list [list ]
	foreach os_id $os_id_list {
	    if { [qf_is_natural_number $os_id] } {
		lappend filtered_ids_list $os_id
	    }
	}
	set os_lists [db_list_of_lists hf_os_read hf_operating_systems "select os_id, label, brand, version, kernel, orphaned_p, requires_upgrade_p, description from hf_operating_systems where instance_id =:instance_id and os_id in ([template_::util::tcl_to_sql_list $filtered_ids_list])" ]
	
    }
    return $os_lists
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
    set success_p 0
    set os_exists_p 0
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { ![qf_is_natural_number $os_id] } {
	set os_id ""
    }
    if { $os_id ne "" } {
	set os_exists_p [db_0or1row check_os_id_exists "select os_id as os_id_db from hf_operating_systems where os_id=:os_id"]
    }
    if { $os_exists_p } {
	# update existing record

    } else {
	# insert new record
    }
	
    ##code
}


ad_proc -private hf_ns_read {
    {vm_id_list ""}
    {instance_id ""}
} {
    reads full detail of one ns. This is not redundant to hf_nss. This accepts only 1 id and includes all attributes (no summary counts)
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    ##code
}

ad_proc -private hf_ns_write {
    args
    {instance_id ""}
} {
    writes or creates an ns_id. If ns_id is blank, a new one is created, and the new ns_id returned. The ns_id is returned if successful, otherwise -1 is returned.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    ##code
}


ad_proc -private hf_vm_quota_read {
    {plan_id_list ""}
    {instance_id ""}
} {
    description
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    ##code
    # hf_vm_quotas.instance_id plan_id description base_storage base_traffic base_memory base_sku over_storage_sku over_traffic_sku over_memory_sku storage_unit traffic_unit memory_unit qemu_memory status_id vm_type max_domain private_vps
}

ad_proc -private hf_vm_quota_write {
    args
    {instance_id ""}
} {
    writes or creates a vm_quota. If id is blank, a new one is created, and the new id returned. id is returned if successful, otherwise -1 is returned.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    ##code
}

ad_proc -private hf_ua_write {
    args
    {instance_id ""}
} {
       writes or creates a ua. If ua_id is blank, a new one is created, and the new id returned. id is returned if successful, otherwise -1 is returned.
} {
    # permissions must be careful here.
    # only admin_p or create_p create new
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    ##code
}

ad_proc -private hf_ua_read {
    args
    {instance_id ""}
} {
       see hf_ua_ck for access credential checking. hf_ua_read is for admin only.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    ##code
}

ad_proc -private hf_up_ck {
    {ua,submitted_up}
    {instance_id ""}
} {
    checks submitted against existing. returns 1 if matches, otherwise returns 0.
} {
    # hf_up_ck takes the place of a standard hf_ua_read
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    ##code
}

ad_proc -private hf_up_write {
    {ua,submitted_up, new}
    {instance_id ""}
} {
    writes or creates a up. If up is blank, a new one is created, and 1 is returned, otherwise returns 0.
} {
    # must have admin_p to create
    # otherwise hf_up_ck must be 1 to update
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    ##code
}


ad_proc -private hf_monitor_configs {
    {asset_id_list ""}
    {instance_id ""}
} {
    description
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    ##code
}

ad_proc -private hf_monitor_logs {
    {asset_id_list ""}
    {instance_id ""}
} {
    description
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    ##code
}

ad_proc -private hf_monitor_status {
    {asset_id_list ""}
    {instance_id ""}
} {
    description
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    ##code
}

ad_proc -private hf_monitor_statistics {
    {monitor_id_list ""}
    {instance_id ""}
} {
    description
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    ##code
}

ad_proc -private hf_monitor_report {
    monitor_id 
    args
    {instance_id ""}
} {
    description
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    ##code
}

