ad_library {

    misc API for hosting-farm
    @creation-date 5 June 2013

    user DNS zone editing
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
    Returns asset_ids available to user_id as list of lists (each list represents ids by  one customer)
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
        if { [llength $assets_list > 0 ] } {
            lappend asset_ids_list $assets_list
        }
    }
    return $asset_ids_list
}


ad_proc -private hf_asset_create_from_asset_template {
    {instance_id ""}
    asset_id 
    args
} {
   this should be a proc equivalent to a page that loads template and creates new.. 
} {
#     hf_asset_read instance_id asset_id
#     hf_asset_create new_label
}

ad_proc -private hf_asset_create_from_asset_label {
    {instance_id ""}
    asset_label
    args
} {
   this should be a proc equivalent to a page that loads asset_label and creates new.
} {
    # code
}

ad_proc -private hf_asset_templates_active {
    {instance_id ""}
    {label_match "*"}
} {
    returns active template references
} {
    # code
}

ad_proc -private hf_asset_templates_all {
    {instance_id ""}
    {label_match "*"}
} {
    returns all templates references (active and inactive)
} {
    # code
}

# API for various asset types:
#   in each case, add ecds-pagination bar when displaying. defaults to all allowed by user permissions

# asset mapped procs
#   direct:
ad_proc -private hf_nis_dc {
    {dc_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_vhs_vh {
    {vh_list ""}
} {
    description
} {
    #code
}


ad_proc -private hf_hws_dc {
    {dc_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_vms_hw {
    {hw_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_vhs_vm {
    {vm_list ""}
} {
    description
} {
    #code
}

#   indirect, practical:
ad_proc -private hf_nis_hw {
    {hw_list ""} 
} {
    description
} {
    #code
}

ad_proc -private hf_ips_ni {
    {ni_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_ips_vm {
    {vm_list ""}
} {
    description
} {
    #code
}


# info tables: 
ad_proc -private hf_dcs {
    {customer_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_hws {
    {customer_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_vms {
    {customer_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_nis {
    {customer_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_ips {
    {customer_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_oses {
    {customer_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_vhs {
    {customer_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_uas {
    {customer_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_sss {
    {customer_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_assets_active {
    {customer_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_assets_archive {
    {customer_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_assets_all {
    {customer_id_list ""}
} {
    description
} {
    #code
}


ad_proc -private hf_asset_templates_active {
    {asset_type_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_asset_features {
    {asset_type_id_list ""}
} {
    description
} {
    #code
}


# basic API
# With each change, call hf_monitor_log_create {
#    asset_id, reported_by, user_id .. monitor_id=0}
ad_proc -private hf_dc_create {
    args
} {
    description
} {
    #code
}

ad_proc -private hf_dc_deactivate {
    {dc_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_dc_read {
    {dc_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_dc_write {
    args
} {
    description
} {
    #code
}

ad_proc -private hf_hw_create {
    args
} {
    description
} {
    #code
}

ad_proc -private hf_hw_deactivate {
    {hw_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_hw_read {
    {hw_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_hw_write {
    args
} {
    description
} {
    #code
}

ad_proc -private hf_ip_create {
    args
} {
    description
} {
    #code
}

ad_proc -private hf_ip_deactivate {
    {ip_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_ip_read {
    {ip_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_ip_write {
    args
} {
    description
} {
    #code
}

ad_proc -private hf_ni_create {
    args
} {
    description
} {
    #code
}

ad_proc -private hf_ni_deactivate {
    {ni_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_ni_read {
    {ni_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_ni_write {
    args
} {
    description
} {
    #code
}

ad_proc -private hf_os_create {
    args
} {
    description
} {
    #code
}

ad_proc -private hf_os_deactivate {
    {os_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_os_read {
    {os_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_os_write {
    args
} {
    description
} {
    #code
}

ad_proc -private hf_ss_create {
    args
} {
    description
} {
    #code
}

ad_proc -private hf_ss_deactivate {
    {ss_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_ss_read {
    {ss_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_ss_write {
    args
} {
    description
} {
    #code
}

ad_proc -private hf_vm_create {
    args
} {
    description
} {
    #code
}

ad_proc -private hf_vm_deactivate {
    {vm_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_vm_read {
    {vm_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_vm_write {
    args
} {
    description
} {
    #code
}

ad_proc -private hf_vm_quota_create {
    args
} {
    description
} {
    #code
}

ad_proc -private hf_vm_quota_deactivate {
    {plan_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_vm_quota_read {
    {plan_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_vm_quota_write {
    args
} {
    description
} {
    #code
}

ad_proc -private hf_ua_create {
    args
} {
    description
} {
    #code
}

ad_proc -private hf_ua_deactivate {
    args
} {
    description
} {
    #code
}

ad_proc -private hf_up_ck {
    {ua,submitted_up}
} {
    description
} {
    #code
}

ad_proc -private hf_up_delta {
    {ua,submitted_up, new}
} {
    description
} {
    #code
}


ad_proc -private hf_monitor_configs {
    {asset_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_monitor_logs {
    {asset_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_monitor_statuss {
    {asset_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_monitor_statistics {
    {monitor_id_list ""}
} {
    description
} {
    #code
}

ad_proc -private hf_monitor_report monitor_id {
    args
} {
    description
} {
    #code
}

