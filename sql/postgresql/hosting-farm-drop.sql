-- hosting-farm-drop.sql
--
-- @author Benjamin Brink
-- @license GNU GENERAL PUBLIC LICENSE, Version 2 or greater
--
\i hosting-farm-cron-drop.sql
\i hosting-farm-mon-drop.sql
\i hosting-farm-permissions-drop.sql


drop index hf_calls_instance_id_idx;
drop index hf_calls_proc_name;
drop index hf_calls_asset_type_id;
drop index hf_calls_asset_templ_id;
drop index hf_calls_asset_id;

DROP TABLE hf_calls;

drop index hf_call_role_map_role_id_idx;
drop index hf_call_role_map_call_id_idx;
drop index hf_call_role_map_instance_id_idx;

DROP TABLE hf_call_role_map;

drop index hf_monitor_freq_dist_curves_analysis_id_idx; 
drop index hf_monitor_freq_dist_curves_monitor_id_idx;
drop index hf_monitor_freq_dist_curves_instance_id_idx;

DROP TABLE hf_monitor_freq_dist_curves;

drop index hf_monitor_statistics_analysis_id_idx;
drop index hf_monitor_statistics_monitor_id_idx;
drop index hf_monitor_statistics_instance_id_idx;

DROP TABLE hf_monitor_statistics;

drop index hf_monitor_status_analysis_id_p1;
drop index hf_monitor_status_asset_id_idx;
drop index hf_monitor_status_monitor_id_idx;
drop index hf_monitor_status_instance_id_idx;

DROP TABLE hf_monitor_status;

drop index hf_monitor_log_sig_change_id_idx;
drop index hf_monitor_log_report_id_idx;
drop index hf_monitor_log_asset_id_idx;
drop index hf_monitor_log_monitor_id_idx;
drop index hf_monitor_log_instance_id_idx;

DROP TABLE hf_monitor_log;

drop index hf_monitor_config_n_control_active_p_idx;
drop index hf_monitor_config_n_control_asset_id_idx;
drop index hf_monitor_config_n_control_monitor_id_idx;
drop index hf_monitor_config_n_control_instance_id_idx;

DROP TABLE hf_monitor_config_n_control;

drop index hf_ua_up_map_up_id_idx;
drop index hf_ua_up_map_ua_id_idx;
drop index hf_ua_up_map_instance_map_idx;

DROP TABLE hf_ua_up_map;

drop index hf_sub_asset_map_f_id_idx;
drop index hf_sub_asset_map_sub_f_id_idx;
drop index hf_sub_asset_map_instance_id_idx;
drop index hf_sub_asset_map_type_id_idx;
drop index hf_sub_asset_map_sub_type_id_idx;
drop index hf_sub_asset_map_trashed_p_idx;

DROP TABLE hf_sub_asset_map;

drop index hf_up_up_id_idx;
drop index hf_up_instance_id_idx;

DROP TABLE hf_up;

drop index hf_ua_ua_id_idx;
drop index hf_ua_instance_id_idx;

DROP TABLE hf_ua;

-- drop index hf_services_ua_id_idx;
drop index hf_services_port_idx;
drop index hf_services_protocol_idx;
drop index hf_services_daemon_ref_idx;
drop index hf_services_server_name_idx;
drop index hf_services_ss_id_idx;
drop index hf_services_instance_id_idx;

DROP TABLE hf_services;

drop index hf_vhosts_domain_name_idx;
-- drop index hf_vhosts_ns_id_idx;
-- drop index hf_vhosts_ua_id_idx;
drop index hf_vhosts_vh_id_idx;
drop index hf_vhosts_instance_id_idx;

DROP TABLE hf_vhosts;

drop index hf_vm_quotas_private_vps_idx;
drop index hf_vm_quotas_vm_type_idx;
drop index hf_vm_quotas_plan_id_idx;
drop index hf_vm_quotas_instance_id_idx;

DROP TABLE hf_vm_quotas;


drop index hf_asset_feature_map_feature_id_idx;
drop index hf_asset_feature_map_asset_id_idx;
drop index hf_asset_feature_map_instance_id_idx;

DROP TABLE hf_asset_feature_map;

drop index hf_operating_systems_requires_upgrade_p_idx;
drop index hf_operating_systems_os_id_idx;
drop index hf_operating_systems_instance_id_idx;

DROP TABLE hf_operating_systems;

drop index hf_ip_addresses_ipv6_addr_idx;
drop index hf_ip_addresses_ipv4_addr_idx;
drop index hf_ip_addresses_ip_id_idx;
drop index hf_ip_addresses_instance_id_idx;

DROP TABLE hf_ip_addresses;

drop index hf_network_interfaces_ni_id_idx;
drop index hf_network_interfaces_instance_id_idx;

DROP TABLE hf_network_interfaces;

drop index hf_virtual_machines_server_type_idx;
-- drop index hf_virtual_machines_ns_id_idx;
-- drop index hf_virtual_machines_ni_id_idx;
-- drop index hf_virtual_machines_ip_id_idx;
drop index hf_virtual_machines_domain_name_idx;
drop index hf_virtual_machines_vm_id_idx;
drop index hf_virtual_machines_vm_instance_id_idx;

DROP TABLE hf_virtual_machines;

drop index hf_hardware_hw_id_idx;
drop index hf_hardware_instance_id_idx;

DROP TABLE hf_hardware;

drop index hf_data_centers_affix_idx;
drop index hf_data_centers_dc_id_idx;
drop index hf_data_centers_instance_id_idx;

DROP TABLE hf_data_centers;

drop index hf_ns_records_active_p_idx;
drop index hf_ns_records_ns_id_idx;
drop index hf_ns_records_instance_id_idx;

DROP TABLE hf_ns_records;

drop index hf_asset_type_features_label_idx;
drop index hf_asset_type_features_asset_type_id_idx;
drop index hf_asset_type_features_id_idx;
drop index hf_asset_type_features_instance_id_idx;

DROP TABLE hf_asset_type_features;


drop index hf_asset_rev_map_asset_id_idx;
drop index hf_asset_rev_map_instance_id_idx;
drop index hf_asset_rev_map_label_idx;

DROP TABLE hf_asset_rev_map;

drop index hf_assets_label_idx;
drop index hf_assets_qal_customer_id_idx;
drop index hf_assets_qal_product_id_idx;
drop index hf_assets_asset_type_id_idx;
drop index hf_assets_trashed_p_idx;
drop index hf_assets_user_id_idx;
drop index hf_assets_template_id_idx;
drop index hf_assets_instance_id_idx;
drop index hf_assets_f_id_idx;
drop index hf_assets_asset_id_idx;

DROP TABLE hf_assets;

drop index hf_asset_type_label_idx;
drop index hf_asset_type_id_idx;
drop index hf_asset_type_instance_id_idx;

DROP TABLE hf_asset_type;

DROP SEQUENCE hf_id_seq;
