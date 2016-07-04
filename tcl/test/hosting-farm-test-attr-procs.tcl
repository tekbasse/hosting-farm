ad_library {
    Automated tests for hosting-farm
    @creation-date 2015-03-19
}

aa_register_case -cats {db smoke} assets_attr_check {
    Test assets and attributes api
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {
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
            
            # add two ua
            array set ua1_arr [list \
                                  f_id $hw_arr(f_id) \
                                  ua "user1" \
                                  connection_type "https" \
                                  ua_id "" \
                                  up "test" ]
            set ua1_arr(ua_id) [hf_user_add ua1_arr]



            array set ua2_arr [list \
                                  f_id $hw_arr(f_id) \
                                  ua "user2" \
                                  connection_type "https" \
                                  ua_id "" \
                                  up "test" ]
            set ua2_arr(ua_id) [hf_user_add ua2_arr]


            

            set dc_f_id_list [hf_asset_subassets_cascade $dc_arr(dc_id)]
            set dc_f_id_list_len [llength $dc_f_id_list]
            aa_equals "Assets total created" $dc_f_id_list_len 2 

            set dc_sub_f_id_list [hf_asset_attributes_cascade $dc_arr(dc_id)]
            set dc_sub_f_id_list_len [llength $dc_f_id_list]
            aa_equals "Attributes total created" $dc_sub_f_id_list_len 2 

            
        } \
        -teardown_code {
            # 
            #acs_user::delete -user_id $user1_arr(user_id) -permanent

        }
    #aa_true "Test for .." $passed_p
    #aa_equals "Test for .." $test_value $expected_value


}
