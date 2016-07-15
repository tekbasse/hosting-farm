ad_library {
    Automated tests for hosting-farm
    @creation-date 2015-03-19
}

aa_register_case -cats {db smoke} assets_attr_check {
    Simple detailed test and diagnostics of asset and attribute api
} {
    aa_run_with_teardown \
        -test_code {
            #        -rollback \
            ns_log Notice "aa_register_case.12: Begin test assets_attr_check"
            # Use default permissions provided by tcl/hosting-farm-init.tcl
            # Yet, users must have read access permissions or test fails
            # Some tests will fail (predictably) in a hardened system

            set instance_id [ad_conn package_id]
            # We avoid hf_permission_p by using a sysadmin user

            # A user with sysadmin rights and not customer
            set sysowner_email [ad_system_owner]
            set sysowner_user_id [party::get_by_email -email $sysowner_email]
            set i [string first "@" $sysowner_email]
            if { $i > -1 } {
                set domain [string range $sysowner_email $i+1 end]
            } else {
                set domain [hf_domain_example]
            }
            

            set asset_type_id "dc"
            array set dc_arr [list \
                                     asset_type_id ${asset_type_id} \
                                     label $domain \
                                     name "${domain} test ${asset_type_id} 0" \
                                     user_id $sysowner_user_id ]
            set dc_arr(f_id) [hf_asset_create dc_arr ]
            array set dc_arr [list \
                                     affix [ad_generate_random_string] \
                                     description "[string toupper ${asset_type_id}]0" \
                                     details "This is for api test"]
            set dc_arr(dc_id) [hf_dc_write dc_arr]

            ns_log Notice "hosting-farm-test-api-procs.tcl.116: dc array get dc_arr [array get dc_arr]"
            ns_log Notice "hosting-farm-test-api-procs.tcl.117: hf_asset_read $dc_arr(f_id) [hf_asset_read $dc_arr(f_id)]"

            set q1 "instance_id,label,f_id,asset_id,trashed_p"
            set q1_list [db_list_of_lists hf_test_hf_asset_rev_map_1 "select $q1 from hf_asset_rev_map "]
            ns_log Notice "hosting-farm-test-api-procs.tcl.118: hf_asset_rev_map $q1 $q1_list"

            set q2 "instance_id,f_id,type_id,sub_f_id,sub_type_id,sub_sort_order,sub_label,attribute_p,trashed_p"
            set q2_list [db_list_of_lists hf_test_hf_sub_asset_map_1 "select $q2 from hf_sub_asset_map" ]
            ns_log Notice "hosting-farm-test-api-procs.tcl.119: hf_sub_asset_map $q2 $q2_list"

            # hw
            set backup_sys [qal_namelur 1 2 ""]
            set randlabel "${backup_sys}-[qal_namelur 1 3 "-"]"
            set asset_type_id "hw"
            array set hw_arr [list \
                                     asset_type_id ${asset_type_id} \
                                     label $randlabel \
                                     name "${randlabel} test ${asset_type_id} 0" \
                                     user_id $sysowner_user_id ]
            set hw_arr(f_id) [hf_asset_create hw_arr ]


            hf_sub_asset_map_update $dc_arr(dc_id) dc $randlabel $hw_arr(f_id) hw 0
            array set hw_arr [list \
                                     system_name [ad_generate_random_string] \
                                     backup_sys $backup_sys \
                                     description "[string toupper ${asset_type_id}]0" \
                                     details "This is for api test"]
            set hw_arr(hw_id) [hf_hw_write hw_arr]

            ns_log Notice "hosting-farm-test-api-procs.tcl.126: hw array get hw_arr [array get hw_arr]"
            ns_log Notice "hosting-farm-test-api-procs.tcl.127: hf_asset_read $hw_arr(f_id) [hf_asset_read $hw_arr(f_id)]"

            set q1 "instance_id,label,f_id,asset_id,trashed_p"
            set q1_list [db_list_of_lists hf_test_hf_asset_rev_map_1 "select $q1 from hf_asset_rev_map "]
            ns_log Notice "hosting-farm-test-api-procs.tcl.128: hf_asset_rev_map $q1 $q1_list"

            set q2 "instance_id,f_id,type_id,sub_f_id,sub_type_id,sub_sort_order,sub_label,attribute_p,trashed_p"
            set q2_list [db_list_of_lists hf_test_hf_sub_asset_map_1 "select $q2 from hf_sub_asset_map" ]
            ns_log Notice "hosting-farm-test-api-procs.tcl.129: hf_sub_asset_map $q2 $q2_list"
            
            # add two ua
            array set ua1_arr [list \
                                  f_id $hw_arr(f_id) \
                                  ua "user1" \
                                  connection_type "https" \
                                  ua_id "" \
                                  up "test" ]
            set ua1_arr(ua_id) [hf_user_add ua1_arr]

            set q2 "instance_id,f_id,type_id,sub_f_id,sub_type_id,sub_sort_order,sub_label,attribute_p,trashed_p"
            set q2_list [db_list_of_lists hf_test_hf_sub_asset_map_1 "select $q2 from hf_sub_asset_map" ]
            ns_log Notice "hosting-farm-test-api-procs.tcl.139: hf_sub_asset_map $q2 $q2_list"
            set q3 "instance_id,ua_id,up_id"
            set q3_list [db_list_of_lists hf_test_hf_ua_up_map_1 "select $q3 from hf_ua_up_map" ]
            ns_log Notice "hosting-farm-test-api-procs.tcl.133: hf_ua_up_map $q3 $q3_list"
            set q4 "instance_id,ua_id,details,connection_type"
            set q4_list [db_list_of_lists hf_test_hf_ua_1 "select $q4 from hf_ua" ]
            ns_log Notice "hosting-farm-test-api-procs.tcl.134: hf_ua $q4 $q4_list"
            set q5 "instance_id,up_id,details"
            set q5_list [db_list_of_lists hf_test_hf_up_1 "select $q5 from hf_up" ]
            ns_log Notice "hosting-farm-test-api-procs.tcl.135: hf_up $q5 $q5_list"


            array set ua2_arr [list \
                                  f_id $hw_arr(f_id) \
                                  ua "user2" \
                                  connection_type "https" \
                                  ua_id "" \
                                  up "test" ]
            set ua2_arr(ua_id) [hf_user_add ua2_arr]

            set q2 "instance_id,f_id,type_id,sub_f_id,sub_type_id,sub_sort_order,sub_label,attribute_p,trashed_p"
            set q2_list [db_list_of_lists hf_test_hf_sub_asset_map_1 "select $q2 from hf_sub_asset_map" ]
            ns_log Notice "hosting-farm-test-api-procs.tcl.149: hf_sub_asset_map $q1 $q1_list"
            set q2 "instance_id,f_id,type_id,sub_f_id,sub_type_id,sub_sort_order,sub_label,attribute_p,trashed_p"
            set q2_list [db_list_of_lists hf_test_hf_sub_asset_map_1 "select $q2 from hf_sub_asset_map" ]
            ns_log Notice "hosting-farm-test-api-procs.tcl.139: hf_sub_asset_map $q1 $q1_list"
            set q3 "instance_id,ua_id,up_id"
            set q3_list [db_list_of_lists hf_test_hf_ua_up_map_1 "select $q3 from hf_ua_up_map" ]
            ns_log Notice "hosting-farm-test-api-procs.tcl.133: hf_ua_up_map $q3 $q3_list"
            set q4 "instance_id,ua_id,details,connection_type"
            set q4_list [db_list_of_lists hf_test_hf_ua_1 "select $q4 from hf_ua" ]
            ns_log Notice "hosting-farm-test-api-procs.tcl.134: hf_ua $q4 $q4_list"
            set q5 "instance_id,up_id,details"
            set q5_list [db_list_of_lists hf_test_hf_up_1 "select $q5 from hf_up" ]
            ns_log Notice "hosting-farm-test-api-procs.tcl.135: hf_up $q5 $q5_list"


            # add network interface
            array set ni1_arr [list \
                                   f_id $hw_arr(f_id) \
                                   sub_label "NIC-1" \
                                   os_dev_ref "io1" \
                                   bia_mac_address "00:1e:52:c6:3e:7a" \
                                   ul_mac_address "" \
                                   ipv4_addr_range "198.51.100.0/24" \
                                   ipv6_addr_range "2001:db8:1234::/48" ]
            set ni1_arr(ni_id) [hf_ni_write ni1_arr]

            set q2 "instance_id,f_id,type_id,sub_f_id,sub_type_id,sub_sort_order,sub_label,attribute_p,trashed_p"
            set q2_list [db_list_of_lists hf_test_hf_sub_asset_map_1 "select $q2 from hf_sub_asset_map" ]
            ns_log Notice "hosting-farm-test-api-procs.tcl.139: hf_sub_asset_map $q2 $q2_list"
            set q4 "instance_id,ni_id,os_dev_ref,bia_mac_address,ul_mac_address,ipv4_addr_range,ipv6_addr_range,time_trashed,time_created"
            set q4_list [db_list_of_lists hf_test_hf_ni_1 "select $q4 from hf_network_interfaces" ]
            ns_log Notice "hosting-farm-test-api-procs.tcl.134: hf_ni $q4 $q4_list"

            

            set dc_f_id_list [hf_asset_subassets_cascade $dc_arr(f_id)]
            set dc_f_id_list_len [llength $dc_f_id_list]
            ns_log Notice "hosting-farm-test-api-procs.tcl.201: dc_f_id_list '${dc_f_id_list}'"
            aa_equals "DC Assets total created" $dc_f_id_list_len 1

            set dc_sub_f_id_list [hf_asset_attributes_cascade $dc_arr(f_id)]
            ns_log Notice "hosting-farm-test-api-procs.tcl.205: dc_sub_f_id_list '${dc_sub_f_id_list}'"
            set dc_sub_f_id_list_len [llength $dc_f_id_list]
            aa_equals "DC Attributes total created" $dc_sub_f_id_list_len 1 


            set hw_f_id_list [hf_asset_subassets_cascade $hw_arr(f_id)]
            set hw_f_id_list_len [llength $hw_f_id_list]
            ns_log Notice "hosting-farm-test-api-procs.tcl.201: hw_f_id_list '${hw_f_id_list}'"
            aa_equals "HW Assets total created" $hw_f_id_list_len 1

            set hw_sub_f_id_list [hf_asset_attributes_cascade $hw_arr(f_id)]
            ns_log Notice "hosting-farm-test-api-procs.tcl.205: hw_sub_f_id_list '${hw_sub_f_id_list}'"
            set hw_sub_f_id_list_len [llength $hw_sub_f_id_list]
            aa_equals "HW Attributes total created" $hw_sub_f_id_list_len 4

            
        } \
        -teardown_code {
            # 
            #acs_user::delete -user_id $user1_arr(user_id) -permanent

        }
    #aa_true "Test for .." $passed_p
    #aa_equals "Test for .." $test_value $expected_value


}
