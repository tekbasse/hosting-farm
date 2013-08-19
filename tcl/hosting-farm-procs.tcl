ad_library {

    misc API for hosting-farm
    @creation-date 5 June 2013

    #user DNS zone editing needs 2 parts. 1:1 vm_id, and 1:1 asset_type
    # need to add name_service table with ns_id to sql/postgresql/hosting-farm-create.sql

    # UI for one click (web-based) installers
      # installers install/update/monitor/activate/de-activate software, ie hosted service (hs) or software as a service (ss)
      # asset_type_id = hh or ss

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
#### TODO: create should not include the same ns_id or ua_id. create a new entry in hf_ua and hf_ns tables.
                #            hf_ua_create
                #            hf_ns_create

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
    set asset_detail_list [hf_assets_w_detail $instance_id $customer_id_list "" 1 "" "" $asset_type_id]
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
                db_1row hf_dc_ni_map_count "select count(ni_id) as ni_id_active_count from hf_dc_ni_map where dc_id =:dc_id and dc_id in ( select id from hf_assets where ( time_stop =null or time_stop < current_timestamp) and trashed_p <> '1' ) "
                db_1row hf_dc_hw_map_count "select count(hw_id) as hw_id_active_count from hf_dc_hw_map where dc_id =:dc_id and dc_id in ( select id from hf_assets where ( time_stop =null or time_stop < current_timestamp) and trashed_p <> '1' ) "
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
    set asset_detail_list [hf_assets_w_detail $instance_id $customer_id_list "" 1 "" "" $asset_type_id]
    # id,user_id,last_modified,created,asset_type_id,qal_product_id, qal_customer_id,label,keywords,templated_p,template_p,time_start,time_stop,trashed_p,trashed_by,flags,publish_p
    set asset_id_list [list ]
    foreach one_asset_detail_list $asset_detail_list {
        lappend asset_id_list [lindex $one_asset_detail_list 0]
    }

    # get dc_id's that have hw associated with it. We do this because we might be filtering by asset_ids, and we want to include subsets.
    set dc_id_list [hf_dcs $instance_id $customer_id_list $asset_id_list]
    #  tables hf_dc_hw_map.instance_id, dc_id, hw_id
    set hw_id_indirect_list [db_list_of_lists hf_dc_get_hw_ids "select hw_id from hf_dc_hw_map where instance_id =:instance_id and dc_id in ([template::util::tcl_to_sql_list $dc_id_list)"]


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
        db_1row hf_dc_ni_map_count "select count(vm_id) as vm_id_active_count from hf_hw_vm_map where hw_id =:hw_id and hw_id in ( select id from hf_assets where ( time_stop =null or time_stop < current_timestamp) and trashed_p <> '1' ) "
        lappend return_list $vm_id_active_count
    return $return_list
}

ad_proc -private hf_nis {
    {instance_id ""}
    {customer_id_list ""}
    {asset_id_list ""}
} {
    returns an ordered list of lists of an asset's direct network interfaces and their properties: 
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
    set asset_detail_lists [hf_assets_w_detail $instance_id $customer_id_list "" 1 "" "" ""]
    set asset_id_list_arr(dc) [list ]
    set asset_id_list_arr(hw) [list ]
    set asset_id_list_arr(vm) [list ]
    foreach asset_list $asset_detail_lists {
        # build asset_ids_list_arr(dc, hw, vm)
        set asset_id [lindex $asset_list 0]
        set asset_type_id [lindex $asset_list 4]
        lappend asset_id_list_arr($asset_type_id) $asset_id
    }
    
    set ni_list [list ]
    # foreach asset__id_type_list, query db 

    if { [llength $asset_id_list_arr(dc)] > 0 } {
        # dc
        #  hf_dc_ni_map.instance_id, dc_id, ni_id
        #  hf_network_interfaces.instance_id, ni_id, os_dev_ref, ipv4_addr_range, ipv6_addr_range, bia_mac_address, ul_mac_address
        set asset_list [db_list_of_lists hf_dc_nis_get "select dc.dc_id, 'dc' as asset_id_type, ni.ni_id, ni.os_dev_ref, ni.ipv4_addr_range, ni.ipv6_addr_range, ni.bia_mac_address, ni.ul_mac_address from hf_dc_ni_map dc, hf_network_interfaces ni where dc.ni_id = ni.ni_id and ni.ni_id in (select ni_id from hf_dc_ni_map where instance_id =:instance_id and dc_id in ([template::util::tcl_to_sql_list $asset_id_list_arr(dc)])"]
        foreach asset_ni_list $asset_lists {
            lappend ni_list $asset_ni_list
        }
    }

    #  hw and vm are 1:1 mapped, so can reference ni_id directly.
  
    if { [llength $asset_id_list(hw)] > 0 } {
        # hw
        #  hf_hardware.instance_id, hw_id, system_name, backup_sys, ni_id, os_id, description, details
        set asset_list [db_list_of_lists hf_hw_nis_get "select hw.hw_id, 'hw' as asset_id_type, ni.ni_id, ni.os_dev_ref, ni.ipv4_addr_range, ni.ipv6_addr_range, ni.bia_mac_address, ni.ul_mac_address from hf_hardware hw, hf_network_interfaces ni where ni.ni_id = hw.ni_id and ni.ni_id in (select ni_id from hf_hardware where instance_id =:instance_id and hw_id in ([template::util::tcl_to_sql_list $asset_id_list_arr(hw)])"]
    }
         
    if { [llength $asset_id_list(vm)] > 0 } {
        # vm
        # hf_virtual_machines instance_id, vm_id, domain_name, ip_id, ni_id, ns_id, type_id, resource_path, mount_union, details
        set asset_list [db_list_of_lists hf_vm_nis_get "select vm.hw_id, 'vm' as asset_id_type, ni.ni_id, ni.os_dev_ref, ni.ipv4_addr_range, ni.ipv6_addr_range, ni.bia_mac_address, ni.ul_mac_address from hf_virtual_machines vm, hf_network_interfaces ni where ni.ni_id = vm.ni_id and ni.ni_id in (select ni_id from hf_virtual_machines where instance_id =:instance_id and vm_id in ([template::util::tcl_to_sql_list $asset_id_list_arr(vm)])"]
    }
    
    return $ni_list
}

ad_proc -private hf_vms {
    {instance_id ""}
    {customer_id_list ""}
    {asset_id_list ""}
} {
    returns an ordered list of lists of an asset's virtual machines and their direct properties. A hardware id is an asset_id.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    ##code
    # get all available asset_ids to user (ie. customers of user) (even ones that might be listed as a different type)

    #get all available hw_ids to user
    # get all vm's mapped to those hw_ids
    # hf_hw_vm_map.instance_id, hw_id, vm_id

    # get all direct vm's available to user
    # vm = asset_id_type

    # build list of list using collected vm_id's
    # hf_virtual_machines.instance_id, vm_id, domain_name, ip_id, ni_id, ns_id, type_id, resource_path, mount_union, details

    # hf_vm_vh_map.instance_id, vm_id, vh_id (include count(vh_id) per vm_id )
}


ad_proc -private hf_ips {
    {instance_id ""}
    {customer_id_list ""}
    {asset_id_list ""}
} {
    returns an ordered list of lists of ip references and their direct properties
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    #code
}

ad_proc -private hf_oses {
    {customer_id_list ""}
    {asset_id_list ""}
} {
    returns an ordered list of lists of operating systems and their direct properties
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    #code
}

ad_proc -private hf_vhs {
    {customer_id_list ""}
    {asset_id_list ""}
} {
    returns an ordered lists of lists of virtual hosts and their direct properties
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    #code
}

ad_proc -private hf_uas {
    {customer_id_list ""}
    {asset_id_list ""}
} {
    returns an ordered lists of lists of user accounts and their direct properties
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    #code
}

ad_proc -private hf_sss {
    {customer_id_list ""}
    {asset_id_list ""}
} {
    returns an ordered list of lists of software as services and their direct properties
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    #code
}




ad_proc -private hf_asset_features {
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
    #code
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
    returns an existing asset type in a list of lists: {label1, title1, description1} {labelN, titleN, descriptionN} or blank list if none found. Bad id's are ignored.
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
    #code
}

ad_proc -private hf_dc_read {
    {dc_id_list ""}
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
    #code
}

ad_proc -private hf_dc_write {
    args
} {
    writes or creates a dc asset_type_id. If asset_id is blank, a new one is created, and the new asset_id returned. The asset_id is returned if successful, otherwise -1 is returned.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    #code
}


ad_proc -private hf_hw_read {
    {hw_id_list ""}
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
    #code
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
    #code
}


ad_proc -private hf_ip_read {
    {ip_id_list ""}
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
    #code
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
    #code
}

ad_proc -private hf_ni_read {
    {ni_id_list ""}
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
    #code
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
    #code
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
    #code
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
    #code
}

ad_proc -private hf_ss_read {
    {ss_id_list ""}
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
    #code
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
    #code
}

ad_proc -private hf_vm_read {
    {vm_id_list ""}
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
    #code
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
    #code
}


ad_proc -private hf_ns_read {
    {vm_id_list ""}
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
    #code
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
    #code
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
    #code
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
    #code
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
    #code
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
    #code
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
    #code
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
    #code
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
    #code
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
    #code
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
    #code
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
    #code
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
    #code
}

