-- hosting-farm-create.sql
--
-- @author Dekka Corp.
-- @ported from Hub.org Hosting ams v2
-- @license GNU GENERAL PUBLIC LICENSE, Version 3
--

--- replace this with stanard nextval object_id
CREATE SEQUENCE hf_id start 10000;
SELECT nextval ('hf_id');

-- for vm_to_configure, see accounts-receivables shopping-basket


-- these roles come from ams.
-- a user can have more than one role
-- and different roles on different customer accounts
-- A role assigns permissions on hf object types.
-- A  role places additional limits
-- on the scope of OpenACS user permissions.
-- A role limits a user_id that is a member of the qal_customer_id set
--   to read, create, and/or write a customer object type
--  Object types (and mapped permissions) include:
--     customer_contracts and billing info  (must be billing, primary, or site_developer via contracts/select, main/select)
--     view detail/create/edit assets (must be technical_contact via main/select)
--     view/edit the contact info of the user roles (support/select)
--     view/create/edit support tickets with categories based on role (support/select)
-- Lots of *_contact specificity in ams
--     view/create/edit services with technical roles
--     view/create/edit service contracts billing/primary/admin roles
CREATE TABLE hf_roles (
    package_id  integer,
    id 		integer,   
--     access_rights.technical_contact
--     access_rights.technical_staff
--     access_rights.billing_contact
--     access_rights.billing_staff
--     access_rights.primary_contact
--     access_rights.site_developer
    label 	varchar(40),
    allow 	varchar(7),
    -- allow can be read, create, or write
    object_type varchar(12),
    -- per types of other hf tables
    description text
);

CREATE TABLE hf_user_roles (
    package_id      integer,
    user_id 	    integer,
    qal_customer_id integer,
    role_id 	    integer
);

CREATE TABLE hf_asset_type_features (
    -- see feature table
    id integer,
    asset_type varchar(12),
    feature_type varchar(12),
    publish_p  varchar(1),
    label varchar(40),
    one_line_description varchar(85),
    descritpion text
);

-- part of database_list
CREATE TABLE hf_assets (
    package_id      integer,
    id 	            integer,
 -- one of dc data center
 --        hw hardware
 --        vm virtual machine
 --	   vh virtual host
 -- 	   hs hosted service etc.
 --        ss saas/sw as a service
 --        ot other
    asset_type      varchar(12),
    -- for mapping to ledger and sales attributes 
    -- such as pricing, period length, etc
    -- null is same as company_summary.is_exempt=true
    qal_product_id  integer,
    qal_customer_id integer,
    label 	    varchar(30),
    description     varchar(80),
    time_start 	    timestamptz,
    time_stop 	    timestamptz,
    ua_id 	    integer,
  -- status aka vm_to_configure, on,off etc.
  -- use with qal_product_id for vm_to_configure.plan_id
  -- and qal_customer_id for vm_to_configure.company_id
    op_status       varchar(20),
    -- for use with monitoring.
    trashed_p 	    varchar(1),
    trashed_by 	    integer,
    -- mainly for promoting clients by linking to their website
    -- was table.advert_link
    publish_p varchar(1),
    monitor_p varchar(1),
    -- when monitoring, higher value is higher priority
    triage_priority integer
 );


CREATE TABLE hf_data_centers (
    dc_id       integer,
    -- was datacenter.short_code
    affix       varchar(20),
    description varchar(80),
    ni_id       integer,
    details     text
);

CREATE TABLE hf_hardware (
    hw_id       integer unique not null,
    ni_id       integer,
    -- following aka backup_config.server_name backup_server
    system_name varchar(200),
    backup_sys  varchar(200),
    description varchar(200),
    details     text
);


CREATE TABLE hf_virtual_machines (
    vm_id       integer unique not null,
    domain_name varchar(300),
    ip_id       integer,
    ni_id       integer,
    -- from database_server.type_id
    type_id      integer,
    details text
);

CREATE TABLE hf_network_interfaces (
  -- see interfaces table
    ni_id integer unique not null,
    -- see interfaces.assigned_interface
    os_dev_ref varchar(20),
    ipv4_addr_range    varchar(20),
    ipv6_addr_range    varchar(50), 
);

CREATE TABLE hf_ip_addresses (
    ip_id        integer,
    ipv4_addr    varchar(15),
    ipv4_status  integer,
    ipv6_addr    varchar(39), 
    ipv6_status  integer
);

CREATE TABLE hf_vm_quota_map (
  plan_id integer not null,
  description varchar(40) not null,
  base_storage integer not null,
  base_traffic integer not null,
  base_memory integer,
  base_sku varchar(40) not null,
  over_storage_sku varchar(40) not null,
  over_traffic_sku varchar(40) not null,
  over_memory_sku varchar(40),
  -- unit is amount per quantity of one sku
  storage_unit integer not null,
  traffic_unit integer not null,
  memory_unit integer,
  qemu_memory integer 
  status_id integer,
  -- shows as 1 or 2 (means?)
  vm_type integer,
  -- was vm_group (0 to 3) means?
  max_domain integer,
  private_vps varchar(1),
  -- plan.high_end is ambiguous and isn't differentiated from private_vps, so ignoring.
 );

-- vh might be a domain resolving to ni
CREATE TABLE hf_vhosts (
    vh_id integer,
    ua_id integer,
    domain_name varchar(200),
    details text
);

-- part of database_auth and database_list
CREATE TABLE hf_services (
  -- was database_id
    hs_id integer,
  -- was database_user_id
    ua_id integer,
    -- from database_server.type_id 
    -- type can be: db, protocol, generic daemon etc.    port integer,
    hs_type varchar(12),
    -- see database_server.db_type (pgsql, mysql etc.)    
    hs_subtype varchar(12),
    -- see dbs.database_type_id
    hs_undersubtype varchar(12),
    -- if needed in future: 
    hs_ultrasubtype varchar(12),
    server_name varchar(40),
    service_name varchar(300),
    daemon_ref varchar(40),
    protocol   varchar(40),
    port       varchar(40),
    config_uri varchar(300),
    -- following from database_memory_detail
    memory_bytes bigint,
    --runtime is part of hf_assets start or monitor_log

    
    details text
);


CREATE TABLE hf_ua (
    ua_id              integer,
    -- bruger kontonavn
    details            text
    -- following was database_auth.secure_authentication bool
    connection_type varcar(12)
);

CREATE TABLE hf_up (
    up_id integer,
    --ie. adgangs kode
    details text
);

CREATE TABLE hf_dc_hw_map (
    package_id integer,
    dc_id integer,
    hw_id integer
);

CREATE TABLE hf_hw_vm_map (
    package_id integer,
    hw_id integer,
    vm_id integer
);

CREATE TABLE hf_vm_vh_map (
    package_id integer,
    vm_id integer,
    vh_id integer
);

CREATE TABLE hf_vh_map (
    package_id integer,
    vh_id integer,
    hs_id integer
);

-- was database_auth
CREATE TABLE hf_ua_up_map (
    package_id integer,
    ua_id integer,
    up_id integer
);

CREATE TABLE hf_monitor_config_n_control (
    monitor_id integer not null,
    asset_id integer not null,
    label varchar(200) not null,
    active_p varchar(1) not null,
    -- number of portions to use in frequency distribution curve
    portions_count integer not null,
    -- allow some control over how the distribution curves are represented:
    calculation_switches varchar(20)
    -- Following 2 are used to suggest hf_monitor_status.expected_health:
    -- the percentile rank that triggers an alarm
    -- 0% rarely triggers, 100% triggers on most everything.
    health_percentile_trigger numeric,
    -- the health_value matching health_percentile_trigger
    health_threshold integer
);

CREATE TABLE hf_monitor_log (
    monitor_id integer not null,
    asset_id  integer not null,
    -- increases by 1 for each monitor_id's report of asset_id
    report_id integer not null,
    -- reported_by provides means to identify/verify reporting source
    reported_by varchar(120),
    report_time timestamptz,
    -- 0 dead, down, not normal
    -- 10000 nominal, allows for variable performance issues
    -- health = numeric summary indicator determined by hf_procs
    health integer,
    -- latest report from monitoring
    report text
    -- sysadmins can log significant changes to asset, such as sw updates
    -- with health=null and/or:
    significant_change varchar(1),
    -- Changes mark boundaries for data samples
);

CREATE TABLE hf_monitor_status (
    monitor_id integer unique not null,
    asset_id integer,
    -- most recent report_id:
    report_id integer,
    health_p0 integer,
    -- for calculating differential, p1 is always 1
    health_p1 integer,
    expected_health integer,
);

CREATE TABLE hf_monitor_statistics (
    -- only most recent status statistics are reported here 
    -- A hf_monitor_log.significant_change flags boundary
    monitor_id integer not null,
    analysis_id integer not null,
    sample_count integer,
    -- range_min is minimum value of report_id
    range_min integer,
    range_max integer,
    health_max integer,
    health_min integer,
    health_average numeric,
    health_median numeric,
); 

-- Curves are normalized to 1.0
-- Percents are represented decimally 0.01 is one percent
-- Maybe one day "Per mil" notation should be used instead of percent.
-- http://en.wikipedia.org/wiki/Permille
-- curve resolution is count of points
-- This model keeps old curves, to help with long-term performance insights
-- see accounts-finance  qaf_discrete_dist_report {
CREATE TABLE hf_monitor_freq_dist_curves (
    monitor_id integer not null,
    analysis_id integer not null,
    -- position x is a sequential position below curve
    -- median is where cumulative_pct = 0.50 
    -- x_pos may not be evenly distributed
    x_pos integer not null,
    -- cumulative_pct increases to 1.0 (from 0 to 100 percentile)
    cumulative_pct not null,
    -- sum of the delta_x equals 1.0
    -- delta_x values might be equal, or not,
    -- depending on how distribution is calculated/represented
    delta_x_pct not null
);
