-- hosting-farm-create.sql
--
-- @author Benjamin Brink
-- @ported from Hub.org Hosting's Account Management System (AMS) v2
-- @license GNU GENERAL PUBLIC LICENSE, Version 3
--

-- following tables get munged into monitoring system via 
-- tcl api: memory_detail,memory_summary for now..
--            database_memory_*, storage_detail
--	      system_loads,
--            traffic_raw,  traffic_detail, traffic_hourly
--            vm_monitor, vm_status

-- assets use object_id for permissions purposes: db_nextval acs_object_id_seq
-- asset parts use this id_seq
CREATE SEQUENCE hf_id_seq start 10000;
SELECT nextval ('hf_id_seq');

-- for vm_to_configure, see accounts-receivables shopping-basket


CREATE TABLE hf_asset_type (
   instance_id             integer,
    -- virtual_machine
    -- virtual_host
    -- xref with hf_assets.asset_type
   id                      varchar(24),
   -- aka feature.short_name
   label                   varchar(40),
   -- aka one_line_description
   title                   varchar(85),
   description             text
);

create index hf_asset_type_instance_id_idx on hf_asset_type (instance_id);
create index hf_asset_type_id_idx on hf_asset_type (id);
create index hf_asset_type_label_idx on hf_asset_type (label);

-- part of database_list
-- a contract is an asset that is not a template.
CREATE TABLE hf_assets (
    instance_id     integer,
    -- asset_id
    id 	            integer unique not null DEFAULT nextval ( 'hf_id_seq' ),
    -- following 3 fields are similar in use to q-wiki template mapping
    template_id     integer,
    user_id	    integer,
    last_modified   timestamptz,
    created 	    timestamptz,
    -- one of dc data center
    --        hw hardware
    --        vm virtual machine
    --	      vh virtual host
    -- 	      hs hosted service etc. (using ss, because hs sounds like hf and looks like ns..)
    --        ss saas/sw as a service
    --        ns custom domain name service records
    --        ot other
    asset_type_id   varchar(24),
    -- for mapping to ledger and sales attributes, and role-based permissions 
    -- such as pricing, period length, etc
    -- null is same as company_summary.is_exempt=true
    qal_product_id  integer,
    qal_customer_id integer,
    label 	    varchar(30),
    keywords        varchar(100),
    description     varchar(80),
    -- publishable content. ported from q-wiki for publishing
    content	    text,
    -- internal comments. ported from q-wiki for publishing
    comments        text,
    -- see server.templated
    -- set to one if this asset is derived from a template
    -- should only be 1 when template_p eq 0
    templated_p     varchar(1),

    -- replacing vm_template with more general asset templating
    -- template means this is an archetype asset. copy it to create new asset of same type
    template_p      varchar(1),
    -- becomes/became active
    time_start 	    timestamptz,
    -- expires/expired on
    time_stop 	    timestamptz,
    ns_id           integer,
    ua_id 	        integer,
  -- status aka vm_to_configure, on,off etc.
  -- use with qal_product_id for vm_to_configure.plan_id
  -- and qal_customer_id for vm_to_configure.company_id
    op_status       varchar(20),
    -- for use with monitoring.
    trashed_p 	    varchar(1),
    -- last trashed by
    trashed_by 	    integer,
    -- possible future asset analyzing
    popularity      integer,
    -- built-in customization flags
    flags	    varchar(12),
    -- mainly for promoting clients by linking to their website
    -- was table.advert_link
    publish_p       varchar(1),
    monitor_p       varchar(1),
    -- when monitoring, higher value is higher priority
    triage_priority integer
 );

create index hf_assets_id_idx on hf_assets (id);
create index hf_assets_instance_id_idx on hf_assets (instance_id);
create index hf_assets_template_id_idx on hf_assets (template_id);
create index hf_assets_user_id_idx on hf_assets (user_id);
create index hf_assets_trashed_p_idx on hf_assets (trashed_p);
create index hf_assets_asset_type_id_idx on hf_assets (asset_type_id);
create index hf_assets_qal_product_id_idx on hf_assets (qal_product_id);
create index hf_assets_qal_customer_id_idx on hf_assets (qal_customer_id);
create index hf_assets_label_idx on hf_assets (label);

-- following table ported from q-wiki for versioning
CREATE TABLE hf_asset_label_map (
       -- max size must consider label encoding all hf_asset.name characters
       label varchar(903) not null,
       -- should be a value from hf_assets.id
       asset_id integer not null,
       trashed_p varchar(1),
       instance_id integer
);

create index hf_asset_name_map_label_idx on hf_asset_label_map (label);
create index hf_asset_name_map_instance_id_idx on hf_asset_label_map (instance_id);
create index hf_asset_name_map_asset_id_idx on hf_asset_label_map (asset_id);

CREATE TABLE hf_asset_type_features (
    instance_id          integer,
    -- feature.id
    id                   integer unique not null DEFAULT nextval ( 'hf_id_seq' ),
    -- hf_asset_type.id
    asset_type_id        varchar(24),
    -- null
    -- s
    label                varchar(40),
    -- aka feature.short_name
    feature_type         varchar(12),
    publish_p            varchar(1),
    -- aka feature.name or one_line_description
    title                varchar(85),
    description          text
);

create index hf_asset_type_features_instance_id_idx on hf_asset_type_features (instance_id);
create index hf_asset_type_features_id_idx on hf_asset_type_features (id);
create index hf_asset_type_features_asset_type_id_idx on hf_asset_type_features (asset_type_id);
create index hf_asset_type_features_label_idx on hf_asset_type_features (label);

CREATE TABLE hf_ns_records (
       instance_id integer,
       id          integer not null DEFAULT nextval ( 'hf_id_seq' ),
       active_p    integer,
       -- name records to be added to dns
       name_record text
);

create index hf_ns_records_instance_id_idx on hf_ns_records (instance_id);
create index hf_ns_records_id_idx on hf_ns_records (ns_id);
create index hf_ns_records_active_p_idx on hf_ns_records (active_p);

CREATE TABLE hf_data_centers (
    instance_id integer,
    dc_id       integer unique not null DEFAULT nextval ( 'hf_id_seq' ),
    -- was datacenter.short_code
    affix       varchar(20),
    description varchar(80),
    details     text
);

create index hf_data_centers_instance_id_idx on hf_data_centers (instance_id);
create index hf_data_centers_dc_id_idx on hf_data_centers (dc_id);
create index hf_data_centers_affix_idx on hf_data_centers (affix);


CREATE TABLE hf_hardware (
    instance_id integer,
    hw_id       integer unique not null DEFAULT nextval ( 'hf_id_seq' ),
    -- following aka backup_config.server_name backup_server
    system_name varchar(200),
    backup_sys  varchar(200),
    ni_id       integer,
    os_id       integer,
    description varchar(200),
    details     text
);

create index hf_hardware_instance_id_idx on hf_hardware (instance_id);
create index hf_hardware_hw_id_idx on hf_hardware (hw_id);


CREATE TABLE hf_virtual_machines (
    instance_id integer,
    vm_id         integer unique not null DEFAULT nextval ( 'hf_id_seq' ),
    domain_name   varchar(300),
    ip_id         integer,
    ni_id         integer,
    ns_id         integer,
    -- from database_server.type_id
    --      server.server_type
    type_id       integer,
    -- was vm_template.path
    resource_path varchar(300),
    -- was vm_template.mount_union
    mount_union   varchar(1),
    -- vm_feature table goes here if casual, or see hf_asset_feature_map
    details       text
);

create index hf_virtual_machines_vm_instance_id_idx on hf_virtual_machines (instance_id);
create index hf_virtual_machines_vm_id_idx on hf_virtual_machines (vm_id);
create index hf_virtual_machines_domain_name_idx on hf_virtual_machines (domain_name);
create index hf_virtual_machines_ip_id_idx on hf_virtual_machines (ip_id);
create index hf_virtual_machines_ni_id_idx on hf_virtual_machines (ni_id);
create index hf_virtual_machines_ns_id_idx on hf_virtual_machines (ns_id);
create index hf_virtual_machines_type_id_idx on hf_virtual_machines (type_id);

CREATE TABLE hf_network_interfaces (
    instance_id        integer,
  -- see interfaces table
    ni_id              integer unique not null DEFAULT nextval ( 'hf_id_seq' ),
    -- see interfaces.assigned_interface
    os_dev_ref         varchar(20),
    -- burned in address MAC address
    bia_mac_address    varchar(20),
    -- universal/local programmed (non-OUI) MAC address
    ul_mac_address     varchar(20),
    ipv4_addr_range    varchar(20),
    ipv6_addr_range    varchar(50)
);

create index hf_netowrk_interfaces_instance_id_idx on hf_network_interfaces (instance_id);
create index hf_network_interfaces_ni_id_idx on hf_network_interfaces (ni_id);

CREATE TABLE hf_ip_addresses (
    instance_id  integer,
    ip_id        integer unique not null DEFAULT nextval ( 'hf_id_seq' ),
    ipv4_addr    varchar(15),
    ipv4_status  integer,
    ipv6_addr    varchar(39), 
    ipv6_status  integer
);

create index hf_ip_addresses_instance_id_idx on hf_ip_addresses (instance_id);
create index hf_ip_addresses_ip_id_idx on hf_ip_addresses (ip_id);
create index hf_ip_addresses_ipv4_addr_idx on hf_ip_addresses (ipv4_addr);
create index hf_ip_addresses_ipv6_addr_idx on hf_ip_addresses (ipv6_addr);

CREATE TABLE hf_operating_systems (
    instance_id         integer,
    os_id               integer unique not null DEFAULT nextval ( 'hf_id_seq' ),
    -- server.fsys
    label               varchar(20),
    brand               varchar(80),
    version             varchar(300),
    kernel              varchar(300),
    orphaned_p          varchar(1),
    requires_upgrade_p  varchar(1),
    description         text
);

create index hf_operating_systems_instance_id_idx on hf_operating_systems (instance_id);
create index hf_operating_systems_os_id_idx on hf_operating_systems (os_id);
create index hf_operating_systems_requires_upgrade_p_idx on hf_operating_systems (requires_upgrade_p);

CREATE TABLE hf_asset_feature_map (
    instance_id     integer,
    asset_id        integer,
    -- from hf_asset_type_features
    feature_id      integer
);

create index hf_asset_feature_map_instance_id_idx on hf_asset_feature_map (instance_id);
create index hf_asset_feature_map_asset_id_idx on hf_asset_feature_map (asset_id);
create index hf_asset_feature_map_feature_id_idx on hf_asset_feature_map (feature_id);

CREATE TABLE hf_dc_ni_map (
    instance_id     integer,
    dc_id           integer,
    ni_id           integer
);

create index hf_dc_ni_map_instance_id_idx on hf_dc_ni_map (instance_id);
create index hf_dc_ni_map_dc_id_idx on hf_dc_ni_map (dc_id);
create index hf_dc_ni_map_ni_id_idx on hf_dc_ni_map (ni_id);

CREATE TABLE hf_vm_quota_map (
  instance_id        integer,
  plan_id            integer not null,
  description        varchar(40) not null,
  base_storage       integer not null,
  base_traffic       integer not null,
  base_memory        integer,
  base_sku           varchar(40) not null,
  over_storage_sku   varchar(40) not null,
  over_traffic_sku   varchar(40) not null,
  over_memory_sku    varchar(40),
  -- unit is amount per quantity of one sku
  storage_unit       integer not null,
  traffic_unit       integer not null,
  memory_unit        integer,
  qemu_memory        integer,
  status_id          integer,
  -- shows as 1 or 2 (means?)
  vm_type            integer,
  -- was vm_group (0 to 3) means?
  max_domain         integer,
  private_vps        varchar(1)
  -- plan.high_end is ambiguous and isn't differentiated from private_vps, so ignoring.
 );

create index hf_vm_quota_map_instance_id_idx on hf_vm_quota_map (instance_id);
create index hf_vm_quota_map_plan_id_idx on hf_vm_quota_map (plan_id);
create index hf_vm_quota_map_vm_type_idx on hf_vm_quota_map (vm_type);
create index hf_vm_quota_map_private_vps_idx on hf_vm_quota_map (private_vps);

-- vh might be a domain resolving to ni
CREATE TABLE hf_vhosts (
    instance_id integer,
    vh_id       integer unique not null DEFAULT nextval ( 'hf_id_seq' ),
    ua_id       integer,
    ns_id       integer,
    domain_name varchar(200),
    details     text
);

create index hf_vhosts_instance_id_idx on hf_vhosts (instance_id); 
create index hf_vhosts_vh_id_idx on hf_vhosts (vh_id);
create index hf_vhosts_ua_id_idx on hf_vhosts (ua_id);
create index hf_vhosts_ns_id_idx on hf_vhosts (ns_id);
create index hf_vhosts_domain_name_idx on hf_vhosts (domain_name);

-- part of database_auth and database_list
CREATE TABLE hf_services (
    instance_id     integer,
  -- was database_id
    ss_id           integer unique not null DEFAULT nextval ( 'hf_id_seq' ),
    server_name     varchar(40),
    service_name    varchar(300),
    daemon_ref      varchar(40),
    protocol        varchar(40),
    port            varchar(40),
  -- was database_user_id
    ua_id           integer,
    -- from database_server.type_id 
    -- type can be: db, protocol, generic daemon etc.    port integer,
    ss_type         varchar(24),
    -- see database_server.db_type (pgsql, mysql etc.)    
    ss_subtype      varchar(24),
    -- see dbs.database_type_id
    ss_undersubtype varchar(24),
    -- if needed in future: 
    ss_ultrasubtype varchar(24),
    config_uri      varchar(300),
    -- following from database_memory_detail
    memory_bytes    bigint,
    --runtime is part of hf_assets start or monitor_log
    details         text
);

create index hf_services_instance_id_idx on hf_services (instance_id);
create index hf_services_ss_id_idx on hf_services (ss_id);
create index hf_services_server_name_idx on hf_services (server_name);
create index hf_services_daemon_ref_idx on hf_services (daemon_ref);
create index hf_services_protocol_idx on hf_services (protocol);
create index hf_services_port_idx on hf_services (port);
create index hf_services_ua_id_idx on hf_services (ua_id);

CREATE TABLE hf_ua (
    instance_id     integer,
    ua_id           integer unique not null DEFAULT nextval ( 'hf_id_seq' ),
    -- bruger kontonavn
    details         text,
    -- following was database_auth.secure_authentication bool
    connection_type varchar(24)
);

create index hf_ua_instance_id_idx on hf_ua (instance_id);
create index hf_ua_ua_id_idx on hf_ua (ua_id);

CREATE TABLE hf_up (
    instance_id     integer,
    up_id           integer unique not null DEFAULT nextval ( 'hf_id_seq' ),
    --ie. adgangs kode
    details         text
);

create index hf_up_instance_id_idx on hf_up (instance_id);
create index hf_up_up_id_idx on hf_up (up_id);

CREATE TABLE hf_dc_hw_map (
    instance_id     integer,
    dc_id           integer,
    hw_id           integer
);

create index hf_dc_hw_map_instance_id_idx on hf_dc_hw_map (instance_id);
create index hf_dc_hw_map_dc_id_idx on hf_dc_hw_map (dc_id);
create index hf_dc_hw_map_hw_id_idx on hf_dc_hw_map (hw_id);

CREATE TABLE hf_hw_vm_map (
    instance_id     integer,
    hw_id           integer,
    vm_id           integer
);

create index hf_hw_vm_map_instance_id_idx on hf_hw_vm_map (instance_id);
create index hf_hw_vm_map_hw_id_idx on hf_hw_vm_map (hw_id);
create index hf_hw_vm_map_vnm_id on hf_hw_vm_map (vm_id);

CREATE TABLE hf_vm_vh_map (
    instance_id     integer,
    vm_id           integer,
    vh_id           integer
);

create index hf_vm_vh_map_instance_id_idx on hf_vm_vh_map (instance_id);
create index hf_vm_vh_map_vm_id_idx on hf_vm_vh_map (vm_id);
create index hf_vm_vh_map_vh_id_idx on hf_vm_vh_map (vh_id);

CREATE TABLE hf_vh_map (
    instance_id     integer,
    vh_id           integer,
    ss_id           integer
);

create index hf_vh_map_instance_id_idx on hf_vh_map (instance_id);
create index hf_vh_map_vh_id_idx on hf_vh_map (vh_id);
create index hf_vh_map_ss_id_idx on hf_vh_map (ss_id);

-- was database_auth
CREATE TABLE hf_ua_up_map (
    instance_id     integer,
    ua_id           integer,
    up_id           integer
);

create index hf_ua_up_map_instance_map_idx on hf_ua_up_map (instance_id);
create index hf_ua_up_map_ua_id_idx on hf_ua_up_map (ua_id);
create index hf_ua_up_map_up_id_idx on hf_ua_up_map (up_id);

CREATE TABLE hf_monitor_config_n_control (
    instance_id               integer,
    monitor_id                integer unique not null DEFAULT nextval ( 'hf_id_seq' ),
    asset_id                  integer not null,
    label                     varchar(200) not null,
    active_p                  varchar(1) not null,
    -- number of portions to use in frequency distribution curve
    portions_count            integer not null,
    -- allow some control over how the distribution curves are represented:
    calculation_switches      varchar(20),
    -- Following 2 are used to suggest hf_monitor_status.expected_health:
    -- the percentile rank that triggers an alarm
    -- 0% rarely triggers, 100% triggers on most everything.
    health_percentile_trigger numeric,
    -- the health_value matching health_percentile_trigger
    health_threshold          integer
);

create index hf_monitor_config_n_control_instance_id_idx on hf_monitor_config_n_control (instance_id);
create index hf_monitor_config_n_control_monitor_id_idx on hf_monitor_config_n_control (monitor_id);
create index hf_monitor_config_n_control_asset_id_idx on hf_monitor_config_n_control (asset_id);
create index hf_monitor_config_n_control_active_p_idx on hf_monitor_config_n_control (active_p);

CREATE TABLE hf_monitor_log (
    instance_id          integer,
    monitor_id           integer not null,
    -- if monitor_id is 0 such as when adding activity note, user_id should not be 0
    user_id              integer not null,
    asset_id             integer not null,
    -- increases by 1 for each monitor_id's report of asset_id
    report_id            integer not null,
    -- reported_by provides means to identify/verify reporting source
    reported_by          varchar(120),
    report_time          timestamptz,
    -- 0 dead, down, not normal
    -- 10000 nominal, allows for variable performance issues
    -- health = numeric summary indicator determined by hf_procs
    health               integer,
    -- latest report from monitoring
    report text,
    -- sysadmins can log significant changes to asset, such as sw updates
    -- with health=null and/or:
    significant_change   varchar(1)
    -- Changes mark boundaries for data samples
);

create index hf_monitor_log_instance_id_idx on hf_monitor_log (instance_id);
create index hf_monitor_log_monitor_id_idx on hf_monitor_log (monitor_id);
create index hf_monitor_log_asset_id_idx on hf_monitor_log (asset_id);
create index hf_monitor_log_report_id_idx on hf_monitor_log (report_id);
create index hf_monitor_log_sig_change_id_idx on hf_monitor_log (significant_change);

CREATE TABLE hf_monitor_status (
    instance_id                integer,
    monitor_id                 integer unique not null,
    asset_id                   integer,
    -- most recent report_id:
    report_id                  integer,
    health_p0                  integer,
    -- for calculating differential, p1 is always 1, just as p0 is 0
    health_p1                  integer,
    expected_health            integer
);

create index hf_monitor_status_instance_id_idx on hf_monitor_status (instance_id);
create index hf_monitor_status_monitor_id_idx on hf_monitor_status (monitor_id);
create index hf_monitor_status_asset_id_idx on hf_monitor_status (asset_id);
create index hf_monitor_status_report_id_idx on hf_monitor_status (report_id);

CREATE TABLE hf_monitor_statistics (
    instance_id     integer,
    -- only most recent status statistics are reported here 
    -- A hf_monitor_log.significant_change flags boundary
    monitor_id      integer not null,
    analysis_id     integer not null,
    sample_count    integer,
    -- range_min is minimum value of report_id
    range_min       integer,
    range_max       integer,
    health_max      integer,
    health_min      integer,
    health_average  numeric,
    health_median   numeric
); 

create index hf_monitor_statistics_instance_id_idx on hf_monitor_statistics (instance_id);
create index hf_monitor_statistics_monitor_id_idx on hf_monitor_statistics (monitor_id);
create index hf_monitor_statistics_analysis_id_idx on hf_monitor_statistics (analysis_id);

-- Curves are normalized to 1.0
-- Percents are represented decimally 0.01 is one percent
-- Maybe one day "Per mil" notation should be used instead of percent.
-- http://en.wikipedia.org/wiki/Permille
-- curve resolution is count of points
-- This model keeps old curves, to help with long-term performance insights
-- see accounts-finance  qaf_discrete_dist_report {
CREATE TABLE hf_monitor_freq_dist_curves (
    instance_id      integer,
    monitor_id       integer not null,
    analysis_id      integer not null,
    -- position x is a sequential position below curve
    -- median is where cumulative_pct = 0.50 
    -- x_pos may not be evenly distributed
    x_pos            integer not null,
    -- cumulative_pct increases to 1.0 (from 0 to 100 percentile)
    cumulative_pct   numeric not null,
    -- sum of the delta_x equals 1.0
    -- delta_x values might be equal, or not,
    -- depending on how distribution is calculated/represented
    delta_x_pct      numeric not null
);

create index hf_monitor_freq_dist_curves_instance_id_idx on hf_monitor_freq_dist_curves (instance_id);
create index hf_monitor_freq_dist_curves_monitor_id_idx on hf_monitor_freq_dist_curves (monitor_id);
create index hf_monitor_freq_dist_curves_analysis_id_idx on hf_monitor_freq_dist_curves (analysis_id);

