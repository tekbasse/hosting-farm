-- hosting-farm-permissions-create.sql
--
-- @author Benjamin Brink
-- @ported from Hub.org Hosting's Account Management System (AMS) v2
-- @license GNU GENERAL PUBLIC LICENSE, Version 3
--

-- PERMISSIONS
-- A role places additional limits on the scope of OpenACS user permissions.
-- OpenACS user permissions answer this question:
--       WHO can do WHAT on which OBJECT (context).
-- from:  http://openacs.org/doc/permissions-tediously-explained.html

-- Translated to ams permissions:
-- A role is a party or group of user_ids (WHO) 
-- can create/read/write/delete/admin (WHAT) ie privilege
-- on an asset_type property (OBJECT)

-- for example
-- a technical_contact or technical_staff can modify customer controlled, technical parts of an hf_asset

-- In OpenACS, these could be handled using Parties/permissions relationships. However,
-- this is going to be a more direct/literal translation from AMS to avoid too many context jumps that foster mistakes
-- In Openacs, a  permissions call is like this:  write_p = permissions_call(object_id,user_id,write)

-- WHO: hf_roles.role_id
-- WHAT: hf_property_id_permissions_map.privilege
-- OBJECT: hf_asset_type_property.property_id

-- assigned roles for a user are hf_user_roles_map.hf_role_id  Given: user_id 
-- assigned roles for a customer are hf_user_roles_map.hf_role_id  Given: qal_customer_id
-- assigned roles for a user of a customer are hf_user_roles_map.hf_role_id  Given: qal_customer_id and qal_customer_id
-- available roles: hf_user_roles_map.hf_role_id  

-- each role may have a privilege on a property_id, no role means no privilege (cannot read)

-- these roles come from ams:
-- 1. a user can have more than one role
--    default: all roles for first user_id assigned to hf_asset
--             no roles to all others assigned to hf_asset
-- 2. a user can have different roles on different customer accounts and same account
--

-- mapped permissions include:
--     customer_contracts and billing info  (must be billing, primary, or site_developer via contracts/select, main/select)
--     view detail/create/edit hf_assets (must be technical_contact via main/select)
--     view/edit the contact info of the user roles (support/select)
--     view/create/edit support tickets with categories based on role (support/select)
-- Lots of *_contact specificity in ams
--     view/create/edit services with technical roles
--     view/create/edit service contracts billing/primary/admin roles


-- asset_type_id 1:0..* property_id
-- asset_type_id 1:0..* asset_id

-- qal_customer_id 1..*:1..* user_id 1..*:1..* role_id

CREATE SEQUENCE hf_permissions_id_seq start 100;
SELECT nextval ('hf_permissions_id_seq');


CREATE TABLE hf_roles (
    -- qal_customer_id and user_id distill to a role_id(s) list
    instance_id  integer,
    -- hf_role.id
    id 		integer unique not null DEFAULT nextval ( 'hf_permissions_id_seq' ),
    --     access_rights.technical_contact
    --     access_rights.technical_staff
    --     access_rights.billing_contact
    --     access_rights.billing_staff
    --     access_rights.primary_contact
    --     access_rights.site_developer
    label 	varchar(300) unique not null,
    description text
);

create index hf_roles_instance_id_idx on hf_roles (instance_id);
create index hf_roles_id_idx on hf_roles (id);
create index hf_roles_label_idx on hf_roles (label);

CREATE TABLE hf_asset_type_property (
   -- distills a (property.label or property.id) + asset_type_id to a property_id
   -- there may be 5 or 6 property_id(s) per asset_type 
   -- for example, billing, technical, administrative differences per property
   instance_id     integer,
   -- hf_asset_type.id
   asset_type_id   varchar(24),
   -- property_id
   -- property might be administrator contact record for an asset_type, for example
   id              integer  unique not null DEFAULT nextval ( 'hf_permissions_id_seq' ),
   label varchar(40)
);

create index hf_asset_type_property_instance_id_idx on hf_asset_type_property (instance_id);
create index hf_asset_type_property_asset_type_id_idx on hf_asset_type_property (asset_type_id);
create index hf_asset_type_property_id_idx on hf_asset_type_property (id);
create index hf_asset_type_property_label_idx on hf_asset_type_property (label);

CREATE TABLE hf_user_roles_map (
    -- Permission for user_id to perform af hs_roles.allow on qal_customer_id hf_assets
    -- This is where roles for qal_customer_id are assigned to user_id
    instance_id     integer,
    user_id 	    integer,
    qal_customer_id integer,
    -- hf_role.id
    hf_role_id 	    integer
);

create index hf_user_roles_map_instance_id_idx on hf_user_roles_map (instance_id);
create index hf_user_roles_map_user_id_idx on hf_user_roles_map (user_id);
create index hf_user_roles_map_qal_customer_id_idx on hf_user_roles_map (qal_customer_id);
create index hf_user_roles_map_hf_role_id_idx on hf_user_roles_map (hf_role_id);

CREATE TABLE hf_property_id_permissions_map (
-- only one combination of property_id and role_id per privilege
    instance_id integer,
    property_id integer,
    role_id integer,
    -- privilege can be read, create, write (includes trash), delete, or admin
    privilege 	varchar(12)
    -- priviledge_level integer
    -- allows priviledges to be sorted for maximizing priviledge speed via query?
    -- This is done in the API tcl level for speed by referencing preset values by arr($priviledge)
    -- and using f::max
    -- Consisent with OpenACS permissions: admin > delete > write > create > read.
);

create index hf_property_id_permissions_map_instance_id_idx on hf_property_id_permissions_map (instance_id);
create index hf_property_id_permissions_map_property_id_idx on hf_property_id_permissions_map (property_id);
create index hf_property_id_permissions_map_role_id_idx on hf_property_id_permissions_map (role_id);



-- use this table to assign an object_id to an hf_asset or part-asset.
-- each purchased asset might have an object_id assigned to it..
-- and if not, defaults to instance_id for example.
CREATE TABLE hf_id_object_id_map (
       hf_id integer,
       object_id integer
);

create index hf_id_object_id_map_hf_id_idx on hf_id_object_id_map (hf_id);
create index hf_id_object_id_map_object_id_idx on hf_id_object_id_map (object_id);
