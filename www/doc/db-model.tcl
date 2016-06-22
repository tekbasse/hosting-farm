set title "Hosting Farm Database Model and field definitions"
set context [list [list index "Documentation"] $title]

set type_list [list asset asset_type asset_type_feature sub_asset_map dc hw vm vm_quota vh ss monitor ip ni ns os ua asset_rev_map]
set table_attribute_list [list style "border: 1px;"]
foreach type $type_list {
    # name a variable for html output
    set var hf_${type}_html
    # name a variable for html comments and extras
    set var2 hf_${type}_x_html
    set $var2 ""
    switch -- $type {
        asset {
            set table_name hf_assets
            set keys_list [hf_asset_keys]
            append $var2 "Revisions are managed using table hf_asset_rev_map."
        }
        dc {
            set table_name hf_data_centers
            set keys_list [hf_dc_keys]
        }
        hw {
            set table_name hf_hardware
            set keys_list [hf_hw_keys]
        }
        vm {
            set table_name hf_virtal_machines
            set keys_list [hf_vm_keys]
        }
        vh {
            set table_name hf_vhosts
            set keys_list [hf_vh_keys]
        }
        ss {
            set table_name hf_services
            set keys_list [hf_ss_keys]
        }
        ip {
            set table_name hf_ip_addresses
            set keys_list [hf_ip_keys]
        }
        ni {
            set table_name hf_network_interfaces
            set keys_list [hf_ni_keys]
        }
        ns {
            set table_name hf_ns_records
            set keys_list [hf_ns_keys]
        }
        monitor {
            set table_name hf_monitor_config_n_control
            set keys_list [hf_monitor_configs_keys]
        }
        asset_type {
            set table_name hf_asset_type
            set keys_list [hf_asset_type_keys]
        } 
        asset_feature {
            set table_name hf_asset_type_features
            set keys_list [hf_asset_feature_keys]
        }
        sub_asset_map {
            set table_name hf_sub_asset_map
            set keys_list [hf_sub_asset_map_keys]
            append var2 "This tables manages revisioning for attribute tables.  Attribute types consist of dc, hw, vm, vh, ss, ip, ni, ns, and os."
        }
        vm_quota {
            set table_name hf_vm_quotas
            set keys_list [hf_vm_quota_keys]
        }
        asset_rev_map {
            set table_name hf_asset_rev_map
            set keys_list [list instance_id label f_id asset_id trashed_p]
            append var2 "See also hf_assets"
        }
        ua {
            set table_name hf_ua
            set keys_list [hf_ua_keys]
        }
        os {
            set table_name hf_operating_systems
            set keys_list [hf_os_keys]
        }
    }
    set hidden_keys_list [list ]
    foreach fieldname $keys_list {
        if { [hf_key_hidden_q $fieldname $type] } {
            lappend hidden_keys_list
        }
    }
    set table_lists [list ]
    lappend table_lists [list "#accounts-finance.columns#" "#accounts-finance.title#" "#accounts-finance.description#"]
    foreach column $keys_list {
        set row_list [list $column "#hosting-farm.${column}#" "#hosting-farm.${column}_def#"]
        lappend table_lists $row_list
    }
    set $var [qss_list_of_lists_to_html_table $table_lists $table_attribute_list]
    if { [llength $hidden_keys_list] > 0 } {
        append $var2 "Following are hidden from most user interfacing: [join $user_keys_list ", "]"
    }
}
