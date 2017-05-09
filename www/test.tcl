
#
#oacs-dev=# select * from hf_hardware;
# instance_id | hw_id | system_name | backup_sys | os_id | description |       details        | time_trashed |      time_created      
#-------------+-------+-------------+------------+-------+-------------+----------------------+--------------+------------------------
#         147 | 10805 | 7D92764B2   | Dn         |       | HW0         | This is for api test |              | 2016-07-05 05:50:44-04
#(1 row)
#
#oacs-dev=# select * from hf_asset_rev_map;
# instance_id |  label   | f_id  | asset_id | trashed_p 
#-------------+----------+-------+----------+-----------
#         147 | or97.net | 10802 |    10802 | 0
#         147 | Dn-D-d   | 10804 |    10804 | 0
#(2 rows)
#
#oacs-dev=# select * from hf_sub_asset_map;
# instance_id | f_id  | type_id | sub_f_id | sub_type_id | sub_sort_order | sub_label | attribute_p | trashed_p 
#-------------+-------+---------+----------+-------------+----------------+-----------+-------------+-----------
#         147 | 10802 | dc      |    10803 | dc          |             20 | 1         | 1           | 0
#         147 | 10804 | hw      |    10806 | ua          |             20 |           | 1           | 0
#         147 | 10804 | hw      |    10806 | ua          |             20 |           | 1           | 0
#         147 | 10804 | hw      |    10806 | hw          |             20 | 1         | 1           | 0
#(4 rows)
#
#oacs-dev=# select * from hf_data_centers;
# instance_id | dc_id |   affix   | description |       details        | time_trashed |      time_created      
#-------------+-------+-----------+-------------+----------------------+--------------+------------------------
#         147 | 10803 | C7A7D9B7E | DC0         | This is for api test |              | 2016-07-05 05:50:44-04
#(1 row)
#
#oacs-dev=# select * from hf_assets;
#oacs-dev=# select * from hf_assets;
#oacs-dev=# select label,asset_id,f_id,asset_type_id,name from hf_assets;
#  label   | asset_id | f_id  | asset_type_id |        name        
#----------+----------+-------+---------------+--------------------
# or97.net |    10802 | 10802 | dc            | or97.net test dc 0
# Dn-D-d   |    10804 | 10804 | hw            | Dn-D-d test hw 0
#(2 rows)
set asset_id 33683
set asset_list [hf_asset_read $asset_id]
set hf_asset_keys_list [hf_asset_keys]
set result_list [qf_lists_to_array obj_arr $asset_list $hf_asset_keys_list]

set content "
asset_list: $asset_list
hf_asset_keys_list: $hf_asset_keys_list
[array get obj_arr]"
set content "<pre>
$content
</pre>"
#db_list_of_lists hf_test1 "select [hf_hw_keys ","] from hf_hardware"
#db_list_of_lists hf_test2 "select instance_id,asset_id,f_id,label,trashed_p from hf_asset_rev_map"
#db_list_of_lists hf_test3 "select [hf_dc_keys ","] from hf_data_centers"
#db_list_of_lists hf_test4 "select instance_id,asset_id,f_id,asset_type_id,label,name from hf_assets"
#db_list_of_lists hf_test5 "select [hf_sub_asset_map_keys ","] from hf_sub_asset_map"
