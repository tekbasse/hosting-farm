-- hosting-farm-permissions-drop.sql
--
-- @author Benjamin Brink
-- @ported from Hub.org Hosting's Account Management System (AMS) v2
-- @license GNU GENERAL PUBLIC LICENSE, Version 3
--

drop index hf_id_object_id_map_object_id_idx;
drop index hf_id_object_id_map_hf_id_idx;

DROP TABLE hf_id_object_id_map;

drop index hf_property_role_privilege_map_role_id_idx;
drop index hf_property_role_privilege_map_property_id_idx;
drop index hf_property_role_privilege_map_instance_id_idx;

DROP TABLE hf_property_role_privilege_map;

drop index hf_user_roles_map_hf_role_id_idx;
drop index hf_user_roles_map_qal_customer_id_idx;
drop index hf_user_roles_map_user_id_idx;
drop index hf_user_roles_map_instance_id_idx;

DROP TABLE hf_user_roles_map;

drop index hf_property_title_idx;
drop index hf_property_id_idx;
drop index hf_property_asset_type_id_idx;
drop index hf_property_instance_id_idx;

DROP TABLE hf_property;

drop index hf_role_label_idx;
drop index hf_role_id_idx;
drop index hf_role_instance_id_idx;

DROP TABLE hf_role;

DROP SEQUENCE hf_permissions_id_seq;

