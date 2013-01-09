-- hosting-farm-create.sql
--
-- @author Dekka Corp.
-- @ported from Hub.org Hosting ams v2
-- @license GNU GENERAL PUBLIC LICENSE, Version 3
--

--- replace this with stanard nextval object_id
CREATE SEQUENCE hf_id start 10000;
SELECT nextval ('hf_id');

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
    label 	    varchar(30),
    description     varchar(80),
    time_start 	    timestamptz,
    time_stop 	    timestamptz,
    trashed_p 	    varchar(1),
    trashed_by 	    integer,
    -- mainly for promoting clients by linking to their website
    -- was table.advert_link
    publish_asset_p varchar(1),
    -- latest report from monitoring
    monitor_reports text
    monitor_updated timestamptz
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

