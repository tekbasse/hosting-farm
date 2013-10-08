ad_library {

    misc API for hosting-farm
    @creation-date 5 June 2013

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

    # objects can easily be passed to procs via an array and upvar
    #  array references don't work in sql, so these use ordered lists
    ## For dynamically generated objects, a proc should be written
    # to write a series of avariables to an array, and an array to a set of variables equal to the indexes.
    # somthing similar to qf_get_inputs_as_array, or set array but where the pairs are in separate lists
    # for eks: qf_get_inputs_as_array but added to the q-forms help-procs section:
    # qf_vars_from_array, qf_array_from_vars, qf_array_from_ordered_lists $key_list $value_list 

}

# following defined in permissions-procs.tcl
# hf_customer_ids_for_user
# hf_active_asset_ids_for_customer 

ad_proc -private hf_asset_ids_for_user { 
    {instance_id ""}
    {user_id ""}
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
    {instance_id ""}
    asset_id
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
    {instance_id ""}
    customer_id
    asset_id
    asset_label_new
} {
   this should be a proc equivalent to a page that loads template and creates new.. 
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]

    # customer_id of asset_id doesn't matter, because this may a copy of another's asset or template.
    set read_p [hf_permission_p $instance_id $user_id "" published read]
    set create_p [hf_permission_p $instance_id $user_id $customer_id customer_assets create]
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
#### TODO: create should not include the same ns_id or ua_id. create a new entry in hf_ua and hf_ns tables. Delay coding until these procs created:
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
    {instance_id ""}
    asset_label_orig
    asset_label_new
} {
   creates a new asset_label based on an existing asset. Returns 1 if successful, otherwise 0.
} {
  #### TODO code: basically duplicate hf_asset_create_from_asset_template, getting id from hf_asset_id_from_label

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
    {instance_id ""}
    {label_match ""}
    {inactives_included_p 0}
    {published_p ""}
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
        set templates_list_of_lists [db_list_of_lists hf_asset_templates_select {select id,user_id,last_modified,created,asset_type_id,qal_product_id, qal_customer_id,label,keywords,time_start,time_stop,trashed_p,trashed_by,flags,publish_p from hf_assets where template_p =:1 and instance_id =:instance_id and ( time_stop =null or time_stop < current_timestamp ) and trashed_p <> '1' and id in ( select asset_id from hf_asset_label_map where instance_id = :instance_id ) order by last_modified desc } ]
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
        set templates_list_of_lists [db_list_of_lists hf_asset_templates_select {select id,user_id,last_modified,created,asset_type_id,qal_product_id, qal_customer_id,label,keywords,templated_p,template_p,time_start,time_stop,trashed_p,trashed_by,flags,publish_p from hf_assets where instance_id =:instance_id and time_stop =null and trashed_p <> '1' and id in ( select asset_id from hf_asset_label_map where instance_id = :instance_id ) order by last_modified desc } ]
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
                db_1row hf_dc_ni_map_count "select count(ni_id) as ni_id_active_count from hf_dc_ni_map where instance_id =:instance_id and dc_id =:dc_id and dc_id in ( select id from hf_assets where ( time_stop =null or time_stop < current_timestamp) and trashed_p <> '1' ) "
                db_1row hf_dc_hw_map_count "select count(hw_id) as hw_id_active_count from hf_dc_hw_map where instance_id =:instance_id and dc_id =:dc_id and dc_id in ( select id from hf_assets where ( time_stop =null or time_stop < current_timestamp) and trashed_p <> '1' ) "
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
        db_1row hf_dc_ni_map_count "select count(vm_id) as vm_id_active_count from hf_hw_vm_map where instance_id =:instance_id and hw_id =:hw_id and hw_id in ( select id from hf_assets where ( time_stop =null or time_stop < current_timestamp) and trashed_p <> '1' ) "
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
    asset_id, asset_id_type, ni_id, os_dev_ref, ipv4_addr_range, ipv6_addr_range, bia_mac_address, ul_mac_address
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    # asset_id can be dc, vm, or  hw
    # by limiting ni to direct connections helps keep context with ui

    # use hf_assets_w_detail to get valid asset_id, asset_id_type
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
    # foreach asset_id_type_list, query db 

    if { [llength $asset_id_list_arr(dc)] > 0 } {
        # dc
        #  hf_dc_ni_map.instance_id, dc_id, ni_id
        #  hf_network_interfaces.instance_id, ni_id, os_dev_ref, ipv4_addr_range, ipv6_addr_range, bia_mac_address, ul_mac_address
        set asset_lists [db_list_of_lists hf_dc_nis_get "select dc.dc_id, 'dc' as asset_id_type, ni.ni_id, ni.os_dev_ref, ni.ipv4_addr_range, ni.ipv6_addr_range, ni.bia_mac_address, ni.ul_mac_address from hf_dc_ni_map dc, hf_network_interfaces ni where dc.instance_id = ni.instance_id and dc.instance_id =:instance_id and dc.ni_id = ni.ni_id and ni.ni_id in (select ni_id from hf_dc_ni_map where instance_id =:instance_id and dc_id in ([template::util::tcl_to_sql_list $asset_id_list_arr(dc)])"]
        foreach asset_ni_list $asset_lists {
            lappend ni_detail_lists $asset_ni_list
        }
    }

    if { [llength $asset_id_list(hw)] > 0 } {
        #  hf_hw_ni_map.instance_id, hw_id, ni_id
        #  hf_hardware.instance_id, hw_id, system_name, backup_sys, ni_id, os_id, description, details
        set asset_lists [db_list_of_lists hf_hw_nis_get "select hw.hw_id, 'hw' as asset_id_type, ni.ni_id, ni.os_dev_ref, ni.ipv4_addr_range, ni.ipv6_addr_range, ni.bia_mac_address, ni.ul_mac_address from hf_hw_ni_map hw, hf_network_interfaces ni where hw.instance_id = ni.instance_id and hw.instance_id =:instance_id and hw.ni_id = ni.ni_id and ni.ni_id in (select ni_id from hf_hw_ni_map where instance_id =:instance_id and hw_id in ([template::util::tcl_to_sql_list $asset_id_list_arr(hw)])"]
        foreach asset_ni_list $asset_lists {
            lappend ni_detail_lists $asset_ni_list
        }
    }

    # vm are 1:1 mapped, so can reference ni_id directly.         
    if { [llength $asset_id_list(vm)] > 0 } {
        # vm
        # hf_virtual_machines instance_id, vm_id, domain_name, ip_id, ni_id, ns_id, type_id, resource_path, mount_union, details
        set asset_lists [db_list_of_lists hf_vm_nis_get "select vm.hw_id, 'vm' as asset_id_type, ni.ni_id, ni.os_dev_ref, ni.ipv4_addr_range, ni.ipv6_addr_range, ni.bia_mac_address, ni.ul_mac_address from hf_virtual_machines vm, hf_network_interfaces ni where ni.ni_id = vm.ni_id and ni.ni_id in (select ni_id from hf_virtual_machines where instance_id =:instance_id and vm_id in ([template::util::tcl_to_sql_list $asset_id_list_arr(vm)])"]
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
        # vm is an asset_id_type, so direct vm's are in: asset_id_list_arr(vm) 
        
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
        # vm is an asset_id_type, so direct vm's are in: asset_id_list_arr(vm)
        
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
        append sql_extra " and orphaned_p <> '1'"
    }
    if { $requires_upgrade_p ne 1 } {
        set requires_upgrade_p 0
        append sql_extra " and requires_upgrade_p <> '1'"
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
        set insert_p 0
        # scope to filter
        foreach as_id $as_ids_list {
            if { [lsearch -exact $asset_id_list $as_id ] > -1 } {
                set insert_p 1
            }
            if { $insert_p } {
                set insert_p 0
                lappend filtered_ids_list $as_id
            }
        }
    } else {
        set filtered_ids_list $as_ids_list
    }

    # filter to ss, but also include cases where ss is indirectly referenced, such as via vm or vh types
    # hf_ss_map.instance_id, ss_id, hf_id (where hf_id is vm_id or vh_id etc)
    set ss_set_list [db_list_of_lists hf_ss_ua_get2 "select distinct hf_id, ss_id from hf_ss_map where instance_id =:instance_id and ( hf_id in ([template::util::tcl_to_sql_list $filtered_ids_list]) or ss_id in ([template::util::tcl_to_sql_list $filtered_ids_list]) )"]
    ## How to handle cases where ids in ss_set_list are not in as_ids_list?
    ## Log them; but also include a subset of the data in the return list --enough to identify, but not act on a service

    ## build primary asset table from asset_detail_lists that match ss_set_list 

    ## Then add hf_services detail
    # hf_services.instance_id ss_id server_name service_name daemon_ref protocol port ua_id ss_type ss_subtype ss_undersubtype ss_ultrasubtype config_uri memory_bytes details

    # return ss_detail_list
}




ad_proc -private hf_asset_features {
    {instance_id ""}
    {asset_type_id_list ""}
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
    # hf_asset_type_features.instance_id feature_id asset_type_id label feature_type publish_p title description
    # hf_asset_feature_map.instance_id asset_id feature_id

}


# basic API
# With each change, call hf_monitor_log_create {
#    asset_id, reported_by, user_id .. monitor_id=0}
ad_proc -private hf_asset_type_create {
    {instance_id ""}
    label
    title
    description
} {
    creates asset type, returns id of new asset type, or ""
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    set admin_p [hf_permission_p $instance_id $user_id "" technical admin]
    set asset_type_id ""
    if { $admin_p } {
        set asset_type_id [db_nextval hf_id_seq]
        db_dml asset_type_create {insert into hf_asset_type
            (instance_id,id,label,title,description)
            values (:instance_id,:asset_type_id,:label,:title,:description) }
    }
    return $asset_type_id
}

ad_proc -private hf_asset_type_write {
    {instance_id ""}
    id
    label
    title
    description
} {
    writes to an existing asset type, returns 1 if successful
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
    set admin_p [hf_permission_p $instance_id $user_id "" technical admin]
    if { $admin_p } {
        db_dml asset_type_write {update hf_asset_type
            set label =:label, title =:title, description=:description where instance_id =:instance_id and id=:id}
    }
    return $admin_p
}

ad_proc -private hf_asset_type_read {
    {instance_id ""}
    id_list
} {
    returns an existing asset_type in a list of lists: {label1, title1, description1} {labelN, titleN, descriptionN} or blank list if none found. Bad id's are ignored.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set return_list_of_lists [db_list_of_lists hf_asset_type_read "select id, label, title, description from hf_asset_type where instance_id =:instance_id and id in ([template::util::tcl_to_sql_list $id_list])" ]
    }
    return $return_list_of_lists
}

ad_proc -private hf_asset_types {
    {instance_id ""}
    {label_match ""}
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


ad_proc -private hf_asset_halt {
    {asset_id_list ""}
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

ad_proc -private hf_dc_read {
    {dc_id_list ""}
} {
    reads full detail of one dc. This is not redundant to hf_dcs. This accepts only 1 id and includes all attributes (no summary counts)
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

ad_proc -private hf_dc_write {
    args
} {
    writes or creates a dc asset_type_id. If asset_id is blank, a new one is created, and the new asset_id returned. The asset_id is returned if successful, otherwise -1 is returned.
} {
    # hf_data_centers.instance_id, dc_id, affix, description, details
    # hf_assets.instance_id, id, template_id, user_id, last_modified, created, asset_type_id, qal_product_id, qal_customer_id, label, keywords, description, content, coments, templated_p, template_p, time_start, time_stop, ns_id, ua_id, op_status, trashed_p, trashed_by, popularity, flags, publish_p, monitor_p, triage_priority

    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    ##code
}


ad_proc -private hf_hw_read {
    {hw_id_list ""}
} {
    reads full detail of one hw. This is not redundant to hf_hws. This accepts only 1 id and includes all attributes (no summary counts)
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

ad_proc -private hf_hw_write {
    args
} {
    writes or creates a hw asset_type_id. If asset_id is blank, a new one is created, and the new asset_id returned. The asset_id is returned if successful, otherwise -1 is returned.
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


ad_proc -private hf_ip_read {
    {ip_id_list ""}
} {
    reads full detail of one ip. This is not redundant to hf_ips. This accepts only 1 id and includes all attributes (no summary counts)
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

ad_proc -private hf_ip_write {
    args
} {
    writes or creates an ip asset_type_id. If asset_id is blank, a new one is created, and the new asset_id returned. The asset_id is returned if successful, otherwise -1 is returned.
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

ad_proc -private hf_ni_read {
    {ni_id_list ""}
} {
    reads full detail of one ni. This is not redundant to hf_nis. This accepts only 1 id and includes all attributes (no summary counts)
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

ad_proc -private hf_ni_write {
    args
} {
    writes or creates an ip asset_type_id. If asset_id is blank, a new one is created, and the new asset_id returned. The asset_id is returned if successful, otherwise -1 is returned.
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

ad_proc -private hf_os_read {
    {os_id_list ""}
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

ad_proc -private hf_os_write {
    args
} {
    writes or creates an os asset_type_id. If asset_id is blank, a new one is created, and the new asset_id returned. The asset_id is returned if successful, otherwise -1 is returned.
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

ad_proc -private hf_ss_read {
    {ss_id_list ""}
} {
    reads full detail of one ss. This is not redundant to hf_sss. This accepts only 1 id and includes all attributes (no summary counts)
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

ad_proc -private hf_ss_write {
    args
} {
    writes or creates an ss asset_type_id. If asset_id is blank, a new one is created, and the new asset_id returned. The asset_id is returned if successful, otherwise -1 is returned.
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

ad_proc -private hf_vm_read {
    {vm_id_list ""}
} {
    reads full detail of one vm. This is not redundant to hf_vms. This accepts only 1 id and includes all attributes (no summary counts)
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

ad_proc -private hf_vm_write {
    args
} {
    writes or creates a vm asset_type_id. If asset_id is blank, a new one is created, and the new asset_id returned. The asset_id is returned if successful, otherwise -1 is returned.
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


ad_proc -private hf_ns_read {
    {vm_id_list ""}
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

ad_proc -private hf_monitor_report monitor_id {
    args
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

