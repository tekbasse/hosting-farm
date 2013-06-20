-- hosting-farm-permissions-create.sql
--
-- @author Benjamin Brink
-- @ported from Hub.org Hosting's Account Management System (AMS) v2
-- @license GNU GENERAL PUBLIC LICENSE, Version 3
--

-- PERMISSIONS

-- In OpenACS, permissions would be handled using Parties/permissions relationships. 

-- OpenACS user permissions answer this question:
--       WHO can do WHAT on which OBJECT (context).
--       WHAT: read/write/create/delete/admin
--       WHO: user_id
--	 OBJECT: object_id
-- from:  http://openacs.org/doc/permissions-tediously-explained.html

-- In Openacs, a  permissions check is like this:  write_p       = permissions_call(object_id,user_id,write)
--                                                 allowed_p = permissions_call(OBJECT, WHO, WHAT)

-- AMS3 PERMISSIONS

-- AMS3 uses a more direct/literal translation from AMS to avoid too many context jumps that foster mistakes.

-- AMS3 permissions limit the scope of OpenACS user permissions.
-- In other words, permission for both (AND) is required for an operation to be allowed.

-- The operating paradigm is: SUBJECT ACTION OBJECT. 

-- SUBJECT is a function of user_id and customer_id
-- ACTION  must be the rudimentary read/write/create/delete/admin used in computer resource management
--         after passing through the complexity of roles.
-- OBJECT  is an asset_id, screened via customer_id

--In order of operation (and dependencies):
-- WHO/SUBJECT: user_id is checked against customer_id (if not admin_p per OpenACS).
-- 		role_id(s) is/are determined from customer_id and user_id
-- OBJECT:      property_id mapped from hard coded label or asset_type
-- WHAT/ACTION: read/write/create/delete/admin is determined from referencing a table of property_id and role_id (a type of role: admin,tech,owner etc ie property_id -> role_id)

-- these roles come from ams:
-- 1. a user can have more than one role
--    default: all roles for first user_id assigned to hf_asset
--             no roles to all others assigned to hf_asset
-- 2. a user can have different roles on different customer accounts and same account

-- Permissions are pre-mapped to scale processes while allowing dynamic changes to role-level permissions.

-- mapped permissions include:
--     customer_contracts and billing info must have billing, primary, or site_developer roles (via contracts/select, main/select)
--     view detail/create/edit hf_assets must have technical_contact role (via main/select)
--     view/edit the contact info of user roles must have support role (via support/select)
--     view/create/edit support tickets with categories based on role must have specific role type (via support/select)
-- Lots of *_contact specificity in ams
--     view/create/edit services with technical roles
--     view/create/edit service contracts billing/primary/admin roles

-- for example
-- a technical_contact or technical_staff can modify customer controlled, technical parts of an hf_asset

------------------------------------------------------------------- saving following notes until transistion complete
-- asset_type_id 1:0..* property_id
-- asset_type_id 1:0..* asset_id
-- qal_customer_id 1..*:1..* user_id 1..*:1..* role_id
-- WHO: hf_role.role_id (as a function of user_id and customer_id)
-- WHAT: hf_property_id_permissions_map.privilege (as a function of role and asset type)
-- OBJECT: hf_asset_type_property.property_id
-- assigned roles for a user are hf_user_roles_map.hf_role_id  Given: user_id 
-- assigned roles for a customer are hf_user_roles_map.hf_role_id  Given: qal_customer_id
-- assigned roles for a user of a customer are hf_user_roles_map.hf_role_id  Given: qal_customer_id and qal_customer_id
-- available roles: hf_user_roles_map.hf_role_id  
-- each role may have a privilege on a property_id, no role means no privilege (cannot read)
----------------------------------------------------------------------------------------------------------------------

CREATE SEQUENCE hf_permissions_id_seq start 100;
SELECT nextval ('hf_permissions_id_seq');


CREATE TABLE hf_role (
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
    title	varchar(40),
    description text
);

create index hf_role_instance_id_idx on hf_role (instance_id);
create index hf_role_id_idx on hf_role (id);
create index hf_role_label_idx on hf_role (label);

CREATE TABLE hf_property (
   -- for example, billing, technical, administrative differences per property
   instance_id     integer,
   -- hf_asset_type.id or hard-coded label, such as main_contact_record,admin_contact_record,tech_contact_record etc.
   asset_type_id   varchar(24),
   -- property_id
   id              integer  unique not null DEFAULT nextval ( 'hf_permissions_id_seq' ),
   -- human readable reference for asset_type_id
   title varchar(40)
);

create index hf_property_instance_id_idx on hf_property (instance_id);
create index hf_property_asset_type_id_idx on hf_property (asset_type_id);
create index hf_property_id_idx on hf_property (id);
create index hf_property_title_idx on hf_property (title);

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

CREATE TABLE hf_property_role_privilege_map (
-- only one combination of property_id and role_id per privilege
    instance_id integer,
    property_id integer,
    role_id integer,
    -- privilege can be read, create, write (includes trash), delete, or admin
    privilege 	varchar(12)
    -- If privilege exists, then assumes permission, otherwise not allowed.
    -- To use, db_0or1row select privilege from hf_property_role_privilege where property_id = :property_id, role_id = :role_id
    -- If db_0or1row returns 1, permission granted, else 0 not granted.
    -- Consisent with OpenACS permissions: admin > delete > write > create > read, with added flexibility
);

create index hf_property_role_privilege_map_instance_id_idx on hf_property_role_privilege_map (instance_id);
create index hf_property_role_privilege_map_property_id_idx on hf_property_role_privilege_map (property_id);
create index hf_property_role_privilege_map_role_id_idx on hf_property_role_privilege_map (role_id);


-- For custom permissions not handled by the role paradigm,
-- use this table to assign an object_id to an hf_asset or part-asset.
-- each purchased asset might have an object_id assigned to it..
-- and if not, defaults to instance_id for example.
CREATE TABLE hf_id_object_id_map (
       hf_id integer,
       object_id integer
);

create index hf_id_object_id_map_hf_id_idx on hf_id_object_id_map (hf_id);
create index hf_id_object_id_map_object_id_idx on hf_id_object_id_map (object_id);
