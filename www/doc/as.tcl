set title "DataCenter"
set context [list $title]

# put these in a proc and call it to set local arrays to easily modify all related scenario data.
set asset_key_list [list instance_id id template_id user_id last_modified created asset_type_id qal_product_id qal_customer_id label keywords descrption content comments templated_p template_p time_start time_stop ns_id ua_id op_status trashed_p trashed_by popularity flags publish_p monitor_p triage_priority]
set asset_val_list [list ]

set asset_type_features_key_list [list instance_id id asset_type_id label feature_type publish_p title description]
set asset_type_features_val_list [list ]

set ns_records_key_list [list instance_id id active_p name_record]


set dc_key_list [list instance_id dc_id affix description details]

set hw_key_list [list instance_id hw_id system_name backup_sys ni_id os_id description details]

set vm_key_list [list instance_id vm_id domain_name ip_id ni_id ns_id os_id type_id resource_path mount_union details]

set ni_key_list [list instance_id ni_id os_dev_ref bia_mac_address ul_mac_address ipv4_addr_range ipv6_addr_range]

set ip_addresses_key_list [list instance_id ip_id ipv4_addr ipv4_status ipv6_addr ipv6_status ]

set os_key_list [list instance_id os_id label brand version kernel orphaned_p requires_upgrade_p description ]

set vm_quotas [list instance_id plan_id description base_storage base_traffic base_memory base_sku over_storage_sku over_traffic_sku over_memory_sku storage_unit traffic_unit memory_unit qemu_memory status_id vm_type max_domain private_vps]

set vh_key_list [list instance_id vh_id ua_id ns_id domain_name details ]

set ss_key_list [list instance_id ss_id server_name service_name daemon_ref protocol port ua_id ss_type ss_subtyupe ss_undersubtype ss_ultrasubtuype config_uri memory_bytes details]

set ua_key_list [list instance_id us_id details connection_type]

set monitor_config_n_control_key_list [list instance_id monitor_id asset_id label active_p portions_count calculation_switches health_percentile_trigger health_threashold]

set monitor_log_key_list [list instance_id monitor_id user_id asset_id report_id reported_by report_time health report significant_change]

set monitor_status_key_list [list ]

set monitor_statistics_key_list [list ]

set monitor_freq_dist_curves_key_list [list ]
