-- hosting-farm-permissions-drop.sql
--
-- @author Benjamin Brink
-- @license GNU GENERAL PUBLIC LICENSE, Version 3
--

drop index hf_id_object_id_map_object_id_idx;
drop index hf_id_object_id_map_hf_id_idx;

DROP TABLE hf_id_object_id_map;

drop index hf_property_id_permissions_map_role_id_idx;
drop index hf_property_id_permissions_map_property_id_idx;
drop index hf_property_id_permissions_map_instance_id_idx;

DROP TABLE hf_property_id_permissions_map;

drop index hf_user_roles_map_hf_role_id_idx;
drop index hf_user_roles_map_qal_customer_id_idx;
drop index hf_user_roles_map_user_id_idx;
drop index hf_user_roles_map_instance_id_idx;

DROP TABLE hf_user_roles_map;

drop index hf_asset_type_property_label_idx;
drop index hf_asset_type_property_id_idx;
drop index hf_asset_type_property_asset_type_id_idx;
drop index hf_asset_type_property_instance_id_idx;

DROP TABLE hf_asset_type_property;

drop index hf_roles_label_idx;
drop index hf_roles_id_idx;
drop index hf_roles_instance_id_idx;

DROP TABLE hf_roles;

DROP SEQUENCE hf_permissions_id_seq;

