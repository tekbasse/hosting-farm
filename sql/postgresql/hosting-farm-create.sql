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
);

CREATE TABLE hf_monitor_status (
    monitor_id integer unique not null,
    asset_id integer,
    expected_health integer,
    -- most recent report_id:
    report_id integer,
    health_p0 integer,
    -- for calculating differential, p1 is always 1
    health_p1 integer,
    -- status statistics are reported here instead of in hf_monitor_status_statistics
    -- if number of points < hf_monitor_extended_config.p_count
    -- http://en.wikipedia.org/wiki/Ordinary_least_squares
    sample_p_count integer,
    range_min integer,
    range_max integer,
    -- x is really t for time..
    health_max integer,
    health_min integer,
    health_average numeric,
    health_median numeric,
    sum_x numeric,
    sum_xx numeric,
    delta_x_seconds numeric,
    sum_xy numeric,
    -- The further away a point is, the less 
    -- frequently its reference needs updating.
    -- For example p10 might go from 500ct ago to 511ct ago over 12 status updates.
    -- To lessen burden on updating the calcs.
);

CREATE TABLE hf_monitor_status_statistics (
    monitor_id integer not null,
    analysis_id integer not null,
    -- p_number is sequential count of points reported
    -- where current is p0, ie hf_monitor_status.report_id - p_report_id
    -- report_id range
    sample_p_count integer,
    range_min integer,
    range_max integer,
    -- x is really t for time..
    health_max integer,
    health_min integer,
    health_average numeric,
    health_median numeric,
    sum_x numeric,
    sum_xx numeric,
    delta_x_seconds numeric,
    sum_xy numeric,
); 

CREATE TABLE hf_monitor_extended_config (
    monitor_id integer not null,
    p_interval integer,
    -- number of reports between summaries
    p_count
    -- number of points reported
); 

CREATE TABLE hf_data_centers (
    dc_id       integer,
    description varchar(80),
    details     text
);

CREATE TABLE hf_hardware (
    hw_id       integer,
    description varchar(200),
    details     text
);

-- vm might be a network interface (ni)
CREATE TABLE hf_virtual_machines (
    vm_id       integer,
    domain_name varchar(200),
    ipv4_addr    varchar(15),
    ipv6_addr    varchar(39), 
    details text
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


CREATE TABLE hf_services (
    hs_id integer,
    ua_id integer,
    hs_type varchar(12),
    -- type can be: db, protocol, generic daemon etc.
    port integer,
    config_uri varchar(300),
    details text
);


CREATE TABLE hf_ua (
    ua_id integer,
    -- bruger kontonavn
    details text
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

CREATE TABLE hf_vh_hs_map (
    package_id integer,
    vh_id integer,
    hs_id integer
);

CREATE TABLE hf_ua_up_map (
    package_id integer,
    ua_id integer,
    up_id integer
);

