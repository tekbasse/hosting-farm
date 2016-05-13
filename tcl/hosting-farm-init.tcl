# hosting-farm/tcl/hosting-farm-init.tcl


# Default initialization?  check at server startup (here)

#    @creation-date 2016-05-05
#    @Copyright (c) 2016 Benjamin Brink
#    @license GNU General Public License 3, see project home or http://www.gnu.org/licenses/gpl-3.0.en.html
#    @project home: http://github.com/tekbasse/hosting-farm
#    @address: po box 20, Marylhurst, OR 97036-0020 usa
#    @email: tekbasse@yahoo.com
set instance_id 0
if [catch { set instance_id [apm_package_id_from_key hosting-farm] } error_txt } {
    # more than one instance exists
    set instance_id 0
} elseif { $instance_id != 0 } {
    # only one instance of hosting-farm exists.
    # If this is this the first run, add some defaults.

    # to get user_id of systemowner:
    # party::get_by_email -email $email
    set sysowner_email [ad_system_owner]
    set sysowner_user_id [party::get_by_email -email $sysowner_email]


    set roles_lists_len 0
    set db_read_count 0
    # This is in a loop so that one db query handles both cases.
    while { $roles_lists_len == 0 && $db_read_count < 2 } {
        incr db_read_count
        set roles_lists [db_list_of_lists get_all_roles "select id,label,title,description from hf_role"]
        set roles_lists_len [llength $roles_lists]
        if { [llength $roles_lists] == 0 } {
            # This is the first run of the first instance. Insert defaults
            # here instead of via sql files to minimize permissions files timestamp changes.
            # To help detect any system tampering during operation.
            # role is <division>_<role_level> where role_level are privileges.
            set roles_defaults_list [list \
                                         [list main_admin "Main Admin" "Primary administrator"] \
                                         [list main_manager "Main Manager" "Primary manager"] \
                                         [list main_staff "Main Staff" "Main monitor"] \
                                         [list technical_admin "Technical Admin" "Primary technical administrator"] \
                                         [list technical_manager "Technical Manager" "Oversees daily technical operations"] \
                                         [list technical_staff "Technical Staff" "Monitors asset performance etc"] \
                                         [list billing_admin "Billing Admin" "Primary billing administrator"] \
                                         [list billing_manager "Billing Manager" "Oversees daily billing operations"] \
                                         [list billing_staff "Billing Staff" "Monitors billing, bookkeeping etc."] \
                                         [list site_developer "Site Developer" "Builds websites etc"] ]
            
            # admin to have admin permissions, manager to have read/write permissions, staff to have read permissions
            foreach def_role_list $roles_defaults_list {
                # No need for instance_id since these are system defaults
                set label [lindex $def_role_list 0]
                set title [lindex $def_role_list 1]
                set description [lindex $def_role_list 2]
                db_dml default_roles_cr {
                    insert into hf_role
                    (label,title,description)
                    values (:label,:title,:description)
                db_dml default_roles_cr_i {
                    insert into hf_role
                    (label,title,description,instance_id)
                    values (:label,:title,:description,:instance_id)

                }
            }
        }
    }

    set props_lists_len 0
    set db_read_count 0
    # This is in a loop so that one db query handles both cases.
    while { $props_lists_len == 0 && $db_read_count < 2 } {
        incr db_read_count
        set props_lists [db_list_of_lists get_all_properties "select asset_type_id,id,title from hf_property"]
        set props_lists_len [llength $props_lists]
        if { $props_lists_len == 0 } {
            # This is the first run of the first instance. 
            # ns could be an asset or not. For now, it is a property (ie requires an asset besides the ns), but 
            # maybe we give it special permissions or other asset-like qualities for now
            set props_defaults_lists [list \
                                          [list main_contact_record "Main Contact Record"] \
                                          [list admin_contact_record "Administrative Contact Record"] \
                                          [list tech_contact_record "Technical Contact Record"] \
                                          [list permissions_properties "Permissions properties"] \
                                          [list permissions_roles "Permissions roles"] \
                                          [list permissions_privileges "Permissions privileges"] \
                                          [list non_assets "non-assets ie customer records etc."] \
                                          [list published "World viewable"] \
                                          [list assets "Assets"] \
                                          [list ss "Asset: Software as a service"] \
                                          [list dc "Asset: Data center"] \
                                          [list hw "Asset: Hardware"] \
                                          [list vm "Asset: Virtual machine"] \
                                          [list vh "Asset: Virtual host"] \
                                          [list ns "Asset property: Domain name record"] \
                                          [list ot "Asset: other"] ]
            foreach def_prop_list $props_defaults_lists {
                set asset_type_id [lindex $def_prop_list 0]
                set title [lindex $def_prop_list 1]
                db_dml default_props_cr {
                    insert into hf_property
                    (asset_type_id,title)
                    values (:asset_type_id,:title)
                }

                db_dml default_props_cr_i {
                    insert into hf_property
                    (asset_type_id,title,instance_id)
                    values (:asset_type_id,:title,:instance_id)
                }
            }
        }
    }


    set privs_lists_len 0
    set db_read_count 0
    # This is in a loop so that one db query handles both cases.
    while { $privs_lists_len == 0 && $db_read_count < 2 } {
        incr db_read_count
        set privs_lists [db_list_of_lists get_all_privileges "select property_id,role_id,privilege from hf_property_role_privilege_map"]
        set privs_lists_len [llength $privs_lists]
        if { $privs_lists_len == 0 } {
            # This is the first run of the first instance. 
            # In general:
            # admin roles to have admin permissions, manager to have read/write permissions, staff to have read permissions
            # techs to have write privileges on tech stuff, admins to have write privileges on contact stuff
            # write includes trash, admin includes create where appropriate
            set privs_larr(admin) [list "create" "read" "write" "admin"]
            set privs_larr(developer) [list "create" "read" "write"]
            set privs_larr(manager) [list "read" "write"]
            set privs_larr(staff) [list "read"]

            set division_types_list [list tech billing main site]
            set props_larr(tech) [list tech_contact_record assets non_assets published ss dc hw vm vh ns ot]
            set props_larr(billing) [list admin_contact_record non_assets published]
            #set props_larr(main)  is in all general cases, 
            set props_larr(main) [list main_contact_record admin_contact_record non_assets tech_contact_record assets non_assets published]
            set props_larr(site) [list non_assets published]
            # perimissions_* are for special cases where tech admins need access to set special case permissions.

            foreach role_list $roles_lists {
                set role_id [lindex $role_list 0]
                set role_label [lindex $role_list 1]
                set u_idx [string first "_" $role_label]
                incr u_idx
                set role_level [string range $role_label $u_idx end]
                set division [string range $role_label 0 $u_idx-2]
                if { $division eq "technical" } {
                    # division abbreviates technical
                    set division "tech"
                }
                foreach prop_list $props_lists {
                    set asset_type_id [lindex $prop_list 0]
                    set property_id [lindex $prop_list 1]
                    # For each role_id and property_id create privileges
                    # Privileges are base on $privs_larr($role) and props_larr(asset_type_id)
                    # For example,  $privs_larr(manager) = list read write
                    #               $props_larr(billing) = admin_contact_record non_assets published

                    if { [lsearch $props_larr($division) $asset_type_id ] > -1 } {
                        # This division has privileges.
                        # Add privileges for the role_id
                        if { $role_level ne "" } {
                            foreach priv $privs_larr($role_level) {
                                set exists_p [db_0or1row default_privileges_check { select property_id as test from hf_property_role_privilege_map where property_id=:property_id and role_id=:role_id and privilege=:priv } ]
                                if { !$exists_p } {
                                     db_dml default_privileges_cr {
                                        insert into hf_property_role_privilege_map
                                        (property_id,role_id,privilege)
                                        values (:property_id,:role_id,:priv)
                                    }
                                     db_dml default_privileges_cr_i {
                                        insert into hf_property_role_privilege_map
                                        (property_id,role_id,privilege,instance_id)
                                        values (:property_id,:role_id,:priv,:instance_id)
                                    }
                                }
                                ns_log Notice "hosting-farm/tcl/hosting-farm-init.tcl.127: Added privilege '${priv}' to role '${division}' role_id '${role_id}' role_label '${role_label}'"
                            }
                        } else {
                            ns_log Notice "hosting-farm/tcl/hosting-farm-init.tcl.130: No role_level (admin/manager/staff) for role_id '${role_id}' role_label '${role_label}'"
                        }
                    }
                }
            }
        }
    }    

    set as_types_lists_len 0
    set db_read_count 0
    # This is in a loop so that one db query handles both cases.
    while { $as_types_lists_len == 0 && $db_read_count < 2 } {
        incr db_read_count
        set as_types_lists [db_list_of_lists get_all_as_types_defaults "select id,label,title from hf_asset_type limit 2"]
        set as_types_lists_len [llength $as_types_lists]
        if { $as_types_lists_len == 0 } {
            # This is the first run of the first instance. 
            set as_types_defaults_lists [list \
                                             [list ss "#hosting-farm.SAAS#" "#hosting-farm.Software_as_a_service#"] \
                                             [list dc "#hosting-farm.DC#" "#hosting-farm.Data_Center#"] \
                                             [list hw "#hosting-farm.HW#" "#hosting-farm.Hardware#"] \
                                             [list vm "#hosting-farm.VM#" "#hosting-farm.Virtual_Machine#"] \
                                             [list vh "#hosting-farm.VH#" "#hosting-farm.Virtual_Host#"] \
                                             [list ns "#hosting-farm.NS#" "#hosting-farm.Name_Service#"] \
                                             [list ot "#hosting-farm.OT#" "#hosting-farm.Other#"] ]
            foreach def_as_type_list $as_types_defaults_lists {
                set asset_type_id [lindex $def_as_type_list 0]
                set label [lindex $def_as_type_list 1]
                set title [lindex $def_as_type_list 2]
                db_dml default_as_types_cr {
                    insert into hf_asset_type
                    (id,label,title)
                    values (:asset_type_id,:label,:title)
                }
                db_dml default_as_types_cr_i {
                    insert into hf_asset_type
                    (id,label,title,instance_id)
                    values (:asset_type_id,:label,:title,:instance_id)
                }

            }
        }
    }



    set assets_lists_len 0
    set db_read_count 0
    # This is in a loop so that one db query handles both cases.
    while { $assets_lists_len == 0 && $db_read_count < 2 } {
        incr db_read_count
        set assets_lists [db_list_of_lists get_all_assets_defaults "select asset_type_id,label from hf_assets limit 2"]
        set assets_lists_len [llength $assets_lists]
        if { $assets_lists_len == 0 } {
            # This is the first run of the first instance. 
            set assets_defaults_lists [list \
                                           [list ss "HostingFarm"] ]
            foreach def_asset_list $assets_defaults_lists {
                set asset_type_id [lindex $def_asset_list 0]
                set name [lindex $def_asset_list 1]
                set label [string tolower $name]
                # instance name:
                set title [apm_instance_name_from_id $instance_id]
#                db_dml default_assets_cr {
#                    insert into hf_assets
#                    (asset_type_id,label,user_id,instance_id)
#                    values (:asset_type_id,:label,:sysowner_user_id,:instance_id)
#                }
                # use the api
                # Make an example local system profile
                set uname $uname
                set system_type [exec $uname]
                set spc_idx [string first " " $system_type]
                if { $spc_id > -1 } {
                    set system_type2 [string trim [string tolower [string range $system_type 0 $spc_idx]]]
                } else {
                    set system_type2 [string trim [string tolower $system_type]]
                }
                set http_port [ns_config -int nssock port 80]
                set ss_config_file [ns_info config]
                set ss_nsd_file [ns_info nsd]
                set ss_nsd_name [ns_info name]
                set os_id [hf_os_write "" $label $system_type2 $system_type 0 0 "Default example SAAS system" $instance_id]
                set ss_id [hf_ss_write "" $ss_nsd_name $name $ss_nsd_file $asset_type_id "key words" "description" "content" "comments" 0 "" 0 0 0 0 0 0 "" "" "" "" "" $instance_id $user_id "" "" $ss_nsd_name $name $ss_nsd_file "http" $http_port "" "" "" "" "" $ss_config_file "" "" ]
# ss_id name title asset_type_id keywords description content comments trashed_p trashed_by template_p templated_p publish_p monitor_p popularity triage_priority op_status ua_id ns_id qal_product_id qal_customer_id instance_id user_id last_modified created ss_server_name ss_service_name ss_daemon_ref ss_protocol ss_port ss_ua_id ss_ss_type ss_ss_subtype ss_ss_undersubtype ss_ss_ultrasubtype ss_config_uri ss_memory_bytes ss_details 

                hf_asset_create problemvm ProblemVM vm "Problem VM" "" "" "Demo/vm system test case" "" 0 0 0 0 0 0 0 "" "" "" "" "" "" $instance_id $sysowner_user_id ""
                hf_vm_write vm_id name title asset_type_id keywords description content comments trashed_p trashed_by template_p templated_p publish_p monitor_p popularity triage_priority op_status ua_id ns_id qal_product_id qal_customer_id instance_id user_id last_modified created vm_domain_name vm_ip_id vm_ni_id vm_ns_id vm_type_id vm_resource_path vm_mount_union vm_details
# vm_id name title asset_type_id keywords description content comments trashed_p trashed_by template_p templated_p publish_p monitor_p popularity triage_priority op_status ua_id ns_id qal_product_id qal_customer_id instance_id user_id last_modified created vm_domain_name vm_ip_id vm_ni_id vm_ns_id vm_type_id vm_resource_path vm_mount_union vm_details

                hf_asset_create problemhw ProblemHW hw "Problem HW" "" "" "Demo/hw system test case" "" 0 0 0 0 0 0 0 "" "" "" "" "" "" $instance_id $sysowner_user_id ""
                hf_hw_write hw_id name title asset_type_id keywords description content comments trashed_p trashed_by template_p templated_p publish_p monitor_p popularity triage_priority op_status ua_id ns_id qal_product_id qal_customer_id instance_id user_id last_modified created hw_system_name hw_backup_sys hw_ni_id hw_os_id hw_description hw_details 
# hw_id name title asset_type_id keywords description content comments trashed_p trashed_by template_p templated_p publish_p monitor_p popularity triage_priority op_status ua_id ns_id qal_product_id qal_customer_id instance_id user_id last_modified created hw_system_name hw_backup_sys hw_ni_id hw_os_id hw_description hw_details 

                hf_asset_create problemvh ProblemVH vh "Problem VH" "" "" "Demo/vh system test case" "" 0 0 0 0 0 0 0 "" "" "" "" "" "" $instance_id $sysowner_user_id ""

                hf_asset_create problemns ProblemNS ns "Problem NS" "" "" "Demo/ns system test case" "" 0 0 0 0 0 0 0 "" "" "" "" "" "" $instance_id $sysowner_user_id ""
                hf_ns_write ns_id name_record active_p {instance_id ""} 
# ns_id name_record active_p {instance_id ""} 

                hf_asset_create problemdc ProblemDC dc "Problem DC" "" "" "Demo/dc system test case" "" 0 0 0 0 0 0 0 "" "" "" "" "" "" $instance_id $sysowner_user_id ""
                hf_dc_write dc_id name title asset_type_id keywords description content comments trashed_p trashed_by template_p templated_p publish_p monitor_p popularity triage_priority op_status ua_id ns_id qal_product_id qal_customer_id instance_id user_id last_modified created dc_affix dc_description dc_details 
# dc_id name title asset_type_id keywords description content comments trashed_p trashed_by template_p templated_p publish_p monitor_p popularity triage_priority op_status ua_id ns_id qal_product_id qal_customer_id instance_id user_id last_modified created dc_affix dc_description dc_details 
            }
        }
    }

}
