-- hosting-farm-create.sql
--
-- @author Benjamin Brink
-- @ported from Hub.org Hosting's Account Management System (AMS) v2
-- @license GNU GENERAL PUBLIC LICENSE, Version 3
--

-- following tables get munged into monitoring system via 
-- tcl api: memory_detail,memory_summary for now..
--            database_memory_*, storage_detail
--        system_loads,
--            traffic_raw,  traffic_detail, traffic_hourly
--            vm_monitor, vm_status

-- assets use object_id for permissions purposes: db_nextval acs_object_id_seq
-- asset parts use this id_seq

-- Sometimes integer types can be empty strings or null. 
-- To reduce coding requirements for handling type change issues
-- integer type is replaced with more general varchar(19) not null DEFAULT ''.
CREATE SEQUENCE hf_id_seq start 10000;
SELECT nextval ('hf_id_seq');

-- for vm_to_configure, see accounts-receivables shopping-basket


CREATE TABLE hf_asset_type (
   instance_id             integer,
    -- virtual_machine
    -- virtual_host
    -- xref with hf_assets.asset_type
    -- expects dc, hw, vm, vh, hs, ss, ns, ot etc.
   id                      varchar(24),
   -- aka feature.short_name
   label                   varchar(40),
   -- aka one_line_description
   title                   varchar(85),
   -- length of *_proc limited by hf_sched_proc_stack.proc_name
   halt_proc               varchar(40),
   start_proc              varchar(40),
   description             text
);

create index hf_asset_type_instance_id_idx on hf_asset_type (instance_id);
create index hf_asset_type_id_idx on hf_asset_type (id);
create index hf_asset_type_label_idx on hf_asset_type (label);

-- part of database_list
-- a contract applies to an asset that is not a template.

-- Clarification about nomentclature:
-- Naming convention is:    label, name , description
-- This is conistent with OpenACS way.
-- Old way was:             name,  title, description
CREATE TABLE hf_assets (
    instance_id     integer,
    -- asset_id
    id              integer unique not null DEFAULT nextval ( 'hf_id_seq' ),
    -- following 3 fields are similar in use to q-wiki template mapping
    template_id     integer,
    user_id         integer,
    last_modified   timestamptz,
    created         timestamptz,
    -- one of dc data center
    --        hw hardware
    --        vm virtual machine
    --        vh virtual host
    --        hs hosted service etc. (using ss, because hs sounds like hf and looks like ns..)
    --        ss saas/sw as a service
    --        ns custom domain name service records
    --        ot other
    asset_type_id   varchar(24) not null DEFAULT '',
    -- for mapping to ledger and sales attributes, and role-based permissions 
    -- such as pricing, period length, etc
    -- null is same as company_summary.is_exempt=true
    qal_product_id  varchar(19) not null DEFAULT '',
    qal_customer_id varchar(19) not null DEFAULT '',
    -- One word reference aka a name, sku or readable id.
    -- Must be unique within one instance_id.
    -- (was q-wiki.name ie works as url)
    -- Not to be confused with hf_assets.name.
    -- Label might be domain, machine name etc.
    label           varchar(65),
    -- A pretty version of label, spaces allowed etc
    -- (was q-wiki.title ie page title)
    name           varchar(65),
    keywords        varchar(100),
    -- one line description
    -- (was q-wiki.description)
    description     varchar(80),
    -- publishable content. ported from q-wiki for publishing
    content         text,
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
    time_start      timestamptz,
    -- expires/expired on
    time_stop       timestamptz,
    -- DNS record reference
    ns_id           varchar(19) not null DEFAULT '',
    ua_id           varchar(19) not null DEFAULT '',
  -- status aka vm_to_configure, on,off etc.
  -- use with qal_product_id for vm_to_configure.plan_id
  -- and qal_customer_id for vm_to_configure.company_id
    op_status       varchar(20),
    -- for use with monitoring.
    trashed_p       varchar(1),
    -- last trashed by
    trashed_by      varchar(19) not null DEFAULT '',
    -- possible future asset analyzing
    popularity      varchar(19) not null DEFAULT '',
    -- built-in customization flags
    flags       varchar(12),
    -- mainly for promoting clients by linking to their website
    -- was table.advert_link
    publish_p       varchar(1),
    monitor_p       varchar(1),
    -- when monitoring, higher value is higher priority for alerts, alert reponses
    triage_priority varchar(19) not null DEFAULT ''
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
    asset_type_id        varchar(24) not null DEFAULT '',
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

-- domain name records, one per asset_id
CREATE TABLE hf_ns_records (
       instance_id integer,
       -- ns_id
       id          integer not null DEFAULT nextval ( 'hf_id_seq' ),
       -- should be validated before allowed to go live.
       active_p    integer,
       -- DNS records to be added to domain name service
       name_record text
);

create index hf_ns_records_instance_id_idx on hf_ns_records (instance_id);
create index hf_ns_records_id_idx on hf_ns_records (id);
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
    -- network interface id, this is the remote console (primary only, if more than one)
    ni_id       varchar(19) not null DEFAULT '',
    os_id       varchar(19) not null DEFAULT '',
    description varchar(200),
    details     text
);

create index hf_hardware_instance_id_idx on hf_hardware (instance_id);
create index hf_hardware_hw_id_idx on hf_hardware (hw_id);


CREATE TABLE hf_virtual_machines (
    instance_id integer,
    vm_id         integer unique not null DEFAULT nextval ( 'hf_id_seq' ),
    domain_name   varchar(300),
    ip_id         varchar(19) not null DEFAULT '',
    -- network interface id. This is duplicate of hf_assets.ni_id. Ideally, see hf_assets only.
    -- If there is more than one ns_id, create an hf_vm_ni_map
    -- Leaving this here for now, because 60+ cases of ni_id in hosting-farm-procs ATM.
    -- It is more important to write to both places the same and get project to first release.
    -- Remove later.
    ni_id         varchar(19) not null DEFAULT '',
    -- DNS record id
    ns_id         varchar(19) not null DEFAULT '',
    os_id         varchar(19) not null DEFAULT '',
    -- from database_server.type_id
    --      server.server_type
    type_id       varchar(19) not null DEFAULT '',
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

create index hf_network_interfaces_instance_id_idx on hf_network_interfaces (instance_id);
create index hf_network_interfaces_ni_id_idx on hf_network_interfaces (ni_id);

CREATE TABLE hf_ip_addresses (
    instance_id  integer,
    ip_id        integer unique not null DEFAULT nextval ( 'hf_id_seq' ),
    ipv4_addr    varchar(15),
    -- 0 down, 1 up
    ipv4_status  integer,
    ipv6_addr    varchar(39), 
    -- 0 down, 1 up
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
    asset_id        integer not null,
    -- from hf_asset_type_features
    feature_id      integer not null
);

create index hf_asset_feature_map_instance_id_idx on hf_asset_feature_map (instance_id);
create index hf_asset_feature_map_asset_id_idx on hf_asset_feature_map (asset_id);
create index hf_asset_feature_map_feature_id_idx on hf_asset_feature_map (feature_id);

CREATE TABLE hf_vm_quotas (
  instance_id        integer,
  plan_id            integer not null,
  description        varchar(40) not null,
  base_storage       integer not null,
  base_traffic       integer not null,
  base_memory        varchar(19) not null DEFAULT '',
  base_sku           varchar(40) not null,
  over_storage_sku   varchar(40) not null,
  over_traffic_sku   varchar(40) not null,
  over_memory_sku    varchar(40),
  -- unit is amount per quantity of one sku
  storage_unit       integer not null,
  traffic_unit       integer not null,
  memory_unit        varchar(19) not null DEFAULT '',
  qemu_memory        varchar(19) not null DEFAULT '',
  status_id          varchar(19) not null DEFAULT '',
  -- shows as 1 or 2 (means?)
  vm_type            varchar(19) not null DEFAULT '',
  -- was vm_group (0 to 3) means?
  max_domain         varchar(19) not null DEFAULT '',
  private_vps        varchar(1)
  -- plan.high_end is ambiguous and isn't differentiated from private_vps, so ignoring.
 );

create index hf_vm_quotas_instance_id_idx on hf_vm_quotas (instance_id);
create index hf_vm_quotas_plan_id_idx on hf_vm_quotas (plan_id);
create index hf_vm_quotas_vm_type_idx on hf_vm_quotas (vm_type);
create index hf_vm_quotas_private_vps_idx on hf_vm_quotas (private_vps);

-- vh might be a domain resolving to ni
CREATE TABLE hf_vhosts (
    instance_id integer,
    vh_id       integer unique not null DEFAULT nextval ( 'hf_id_seq' ),
    ua_id       integer not null,
    ns_id       integer not null,
    domain_name varchar(200),
    details     text
);

create index hf_vhosts_instance_id_idx on hf_vhosts (instance_id); 
create index hf_vhosts_vh_id_idx on hf_vhosts (vh_id);
create index hf_vhosts_ua_id_idx on hf_vhosts (ua_id);
create index hf_vhosts_ns_id_idx on hf_vhosts (ns_id);
create index hf_vhosts_domain_name_idx on hf_vhosts (domain_name);

-- part of database_auth and database_list
-- a service can be mapped to any hf_id via hf_ss_map
--  This mapping helps to alert on asset dependencies etc
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
    ua_id           varchar(19) not null DEFAULT '',
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
    memory_bytes    varchar(19) not null DEFAULT '',
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
    dc_id           integer not null,
    hw_id           integer not null
);

create index hf_dc_hw_map_instance_id_idx on hf_dc_hw_map (instance_id);
create index hf_dc_hw_map_dc_id_idx on hf_dc_hw_map (dc_id);
create index hf_dc_hw_map_hw_id_idx on hf_dc_hw_map (hw_id);


CREATE TABLE hf_dc_ni_map (
    instance_id     integer,
    dc_id           integer not null,
    ni_id           integer not null
);

create index hf_dc_ni_map_instance_id_idx on hf_dc_ni_map (instance_id);
create index hf_dc_ni_map_dc_id_idx on hf_dc_ni_map (dc_id);
create index hf_dc_ni_map_ni_id_idx on hf_dc_ni_map (ni_id);

-- hw_ni map is separate fro dc_ni map, because these are inherently 2 different systems
CREATE TABLE hf_hw_ni_map (
    instance_id     integer,
    hw_id           integer not null,
    ni_id           integer not null
);

create index hf_hw_ni_map_instance_id_idx on hf_hw_ni_map (instance_id);
create index hf_hw_ni_map_hw_id_idx on hf_hw_ni_map (hw_id);
create index hf_hw_ni_map_ni_id_idx on hf_hw_ni_map (ni_id);


CREATE TABLE hf_hw_vm_map (
    instance_id     integer,
    hw_id           integer not null,
    vm_id           integer not null
);

create index hf_hw_vm_map_instance_id_idx on hf_hw_vm_map (instance_id);
create index hf_hw_vm_map_hw_id_idx on hf_hw_vm_map (hw_id);
create index hf_hw_vm_map_vnm_id on hf_hw_vm_map (vm_id);

CREATE TABLE hf_vm_vh_map (
    instance_id     integer,
    vm_id           integer not null,
    vh_id           integer not null
);

create index hf_vm_vh_map_instance_id_idx on hf_vm_vh_map (instance_id);
create index hf_vm_vh_map_vm_id_idx on hf_vm_vh_map (vm_id);
create index hf_vm_vh_map_vh_id_idx on hf_vm_vh_map (vh_id);

-- id_ip map is a catch all for ip addresses not assigned to 
-- virtual machines
CREATE TABLE hf_asset_ip_map (
    instance_id     integer,
    asset_id        integer not null,
    ip_id           integer not null
);

create index hf_asset_ip_map_instance_id_idx on hf_asset_ip_map (instance_id);
create index hf_asset_ip_map_asset_id_idx on hf_asset_ip_map (asset_id);
create index hf_asset_ip_map_ip_id_idx on hf_asset_ip_map (ip_id);


-- This map connects a service with all assets and subassets it is composed of.
-- For example, 
-- ss may be a server on a vm accepting requests for all or a portion of the vm's vhosts and vm
CREATE TABLE hf_ss_map (
    instance_id     integer,
    ss_id           integer not null,
-- this is hf_id, because it can be an id of a vm, vh another ss ..any asset id
-- this is an hf_id where the ss operates.
    hf_id           integer not null
 );

 create index hf_ss_map_instance_id_idx on hf_ss_map (instance_id);
 create index hf_ss_map_hf_id_idx on hf_ss_map (hf_id);
 create index hf_ss_map_ss_id_idx on hf_ss_map (ss_id);

-- was database_auth
CREATE TABLE hf_ua_up_map (
    instance_id     integer,
    ua_id           integer not null,
    up_id           integer not null
);

create index hf_ua_up_map_instance_map_idx on hf_ua_up_map (instance_id);
create index hf_ua_up_map_ua_id_idx on hf_ua_up_map (ua_id);
create index hf_ua_up_map_up_id_idx on hf_ua_up_map (up_id);

CREATE TABLE hf_monitor_config_n_control (
    instance_id               integer,
    monitor_id                integer unique not null DEFAULT nextval ( 'hf_id_seq' ),
    asset_id                  integer not null,
    label                     varchar(200) not null,
    active_p                  varchar(1) default '0' not null,
    -- log args into hf_beat_stack.proc_args?
    log_args_p                varchar(1) default '0' not null,
    -- number of portions to use in frequency distribution curve
    portions_count            integer not null,
    -- allow some control over how the distribution curves are represented:
    -- Reserved for VM quota calcs, 'T' for traffic 'S' for storage 'M' for memory
    -- A monitor should start with only one of those flags followed by an aniversary date YYYYMMDD.
    calculation_switches      varchar(20),
    -- Following 2 are used to suggest hf_monitor_status.expected_health:
    -- the percentile rank that triggers an alarm
    -- 0% rarely triggers, 100% triggers on most everything.
    health_percentile_trigger numeric,
    -- the health_value matching health_percentile_trigger
    health_threshold          varchar(19) not null DEFAULT '',
    -- If privilege specified, all users with permission of type privilege get notified.
    alert_by_privilege     varchar(12),
    -- If not null, alerts are sent to specified user(s) of specified role
    alert_by_role varchar(300)
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
    report_id            bigint not null,
    -- reported_by provides means to identify/verify reporting source
    reported_by          varchar(120),
    report_time          timestamptz,
    -- 0 dead, down, not normal
    -- 10000 nominal, allows for variable performance issues
    -- Ideal health index should be in range of 0 to 20000.
    -- health = numeric summary indicator determined by hf_procs
    health               varchar(19) not null DEFAULT '',
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
    asset_id                   varchar(19) not null DEFAULT '',
    --  analysis_id at p0
    analysis_id_p0             varchar(19) not null DEFAULT '',
    -- most recent analysis_id ie at p1
    analysis_id_p1             varchar(19) not null DEFAULT '',
    -- health at p0
    health_p0                  varchar(19) not null DEFAULT '',
    -- for calculating differential, p1 is always 1, just as p0 is 0
    -- health at p1
    health_p1                  varchar(19) not null DEFAULT '',
    health_percentile          varchar(19) not null DEFAULT '',
    -- 
    expected_health            varchar(19) not null DEFAULT '',
    expected_percentile        varchar(19) not null DEFAULT ''
);

create index hf_monitor_status_instance_id_idx on hf_monitor_status (instance_id);
create index hf_monitor_status_monitor_id_idx on hf_monitor_status (monitor_id);
create index hf_monitor_status_asset_id_idx on hf_monitor_status (asset_id);
-- to quickly recall most recent prior analysis. id_p0 is prior id_p1
create index hf_monitor_status_analysis_id_p1 on hf_monitor_status (analysis_id_p1);

CREATE TABLE hf_monitor_statistics (
    instance_id     integer,
    -- only most recent status statistics are reported here 
    -- A hf_monitor_log.significant_change flags boundary
    monitor_id      integer not null,
    -- same as hf_monitor_status.analysis_id_p1
    analysis_id     bigint not null,
    sample_count    varchar(19) not null DEFAULT '',
    -- range_min is minimum value of hf_monitor_log.report_id used.
    range_min       varchar(19) not null DEFAULT '',
    -- range_max is current hf_monitor_log.report_id
    range_max       varchar(19) not null DEFAULT '',
    health_max      varchar(19) not null DEFAULT '',
    health_min      varchar(19) not null DEFAULT '',
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
-- see accounts-finance  qaf_discrete_dist_report
-- On 20160201 it became clear that much of these records between analysis_id
-- of the same monitor_id will be consistent --execpt for the last value.
-- anaysis_id would be for just the new point, and hf_monitor_statisics
-- would need an analysis_id_min, analysis_id_max to reference the points
-- specific to the analysis_id.  There is little benefit of increasing storage efficiency
-- versus the additional complexity in code for completing first release.
-- ADMIN: consider harmonizing hf_monitor_freq_dist_curves at some point if looking
-- to decrease storage footprint.
CREATE TABLE hf_monitor_freq_dist_curves (
    instance_id      integer,
    monitor_id       integer not null,
    -- analysis_id might contribute 1 or a few points to a distribution
    -- This provides a way to drill back into the logs to get more specific info.
    -- This is the same as hf_monitor_status.analysis_id_p1
    analysis_id      bigint not null,
    -- distribution_id represents a distribution between
    -- hf_monitor_log.significant_change flags
    -- because this is a static distribution -no new points can be added.
    distribution_id  integer not null,
    -- position x is a sequential position below curve
    -- median is where cumulative_pct = 0.50 
    -- x_pos is unlikely to be sampled from intervals of exact same size.
    -- initial cases assume x_pos is a system time in seconds.
    x_pos            bigint not null,
    -- The sum of all delta_x_pct from 0 to this x_pos.
    -- cumulative_pct increases to 1.0 (from 0 to 100 percentile)
    cumulative_pct   numeric,
    -- Sum of all delta_x_pct equals 1.0
    -- delta_x_pct may have some values near low limits of 
    -- digitial representation, so only delta_x values are stored.
    -- delta_x values might be equal, or not,
    -- Depends on how distribution is obtained.
    -- Initial use assumes delta_x is in seconds.
    delta_x      numeric not null,
    -- Duplicate of hf_monitor_log.health.
    -- Avoids excessive table joins and provides a clearer
    -- boundary between admin and user accessible table queries.
    monitor_y        numeric not null
);

create index hf_monitor_freq_dist_curves_instance_id_idx on hf_monitor_freq_dist_curves (instance_id);
create index hf_monitor_freq_dist_curves_monitor_id_idx on hf_monitor_freq_dist_curves (monitor_id);
create index hf_monitor_freq_dist_curves_analysis_id_idx on hf_monitor_freq_dist_curves (analysis_id);

CREATE TABLE hf_calls (
    instance_id integer,
    id integer not null,
    -- system api call name
    -- the api grabs asset specific values, then updates db and makes systems calls as needed
    proc_name varchar(40) not null,
    -- in order of increasing specificity to allow for system-wide exceptions
    -- of calling another proc for a more specific asset
    asset_type_id varchar(24) not null DEFAULT '',
    asset_template_id varchar(19) not null DEFAULT '',
    asset_id varchar(19) not null DEFAULT ''
    -- permissions always uses asset_id
);

create index hf_calls_instance_id_idx on hf_calls (instance_id);
create index hf_calls_proc_name on hf_calls (proc_name);
create index hf_calls_asset_type_id on hf_calls (asset_type_id);
create index hf_calls_asset_templ_id on hf_calls (asset_template_id);
create index hf_calls_asset_id on hf_calls (asset_id);

-- Assigns a role permission to make a call, and
-- answers question: what roles are allowed to make call?
-- If the combination of role_id and call_id doesn't exist, then no permission.
CREATE TABLE hf_call_role_map (
       instance_id integer,
       -- hf_calls.proc_id
       call_id integer not null,
       role_id integer not null
);

create index hf_call_role_map_instance_id_idx on hf_call_role_map (instance_id);
create index hf_call_role_map_call_id_idx on hf_call_role_map (call_id);
create index hf_call_role_map_role_id_idx on hf_call_role_map (role_id);

\i hosting-farm-cron-create.sql
\i hosting-farm-mon-create.sql
\i hosting-farm-permissions-create.sql
