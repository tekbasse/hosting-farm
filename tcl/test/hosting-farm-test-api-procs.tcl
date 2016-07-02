ad_library {
    Automated tests for hosting-farm
    @creation-date 2015-03-19
}

aa_register_case -cats {api smoke} assets_api_check {
    Test assets and attributes api
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {
            ns_log Notice "aa_register_case.12: Begin test assets_api_check"
            # Use default permissions provided by tcl/hosting-farm-init.tcl
            # Yet, users must have read access permissions or test fails
            # Some tests will fail (predictably) in a hardened system

            set instance_id [ad_conn package_id]
            hf_roles_init $instance_id
            hf_property_init $instance_id
            hf_privilege_init $instance_id
            hf_asset_type_id_init $instance_id
            
            # Identify and test full range of parameters
            set asset_type_ids_list [db_list hf_property_asset_type_ids_get {
                select distinct on (asset_type_id) asset_type_id
                from hf_property } ]
            set asset_type_ids_count [llength $asset_type_ids_list]

            set roles_lists [hf_roles $instance_id]
            set roles_list [list ]
            foreach role_list $roles_lists {
                set role [lindex $role_list 0]
                lappend roles_list $role
                set role_id [hf_role_id_of_label $role $instance_id]
                set role_id_arr(${role}) $role_id
            }
            # keep namespace clean to help prevent bugs in test code
            unset role_id
            unset role
            unset roles_lists

            # A user with sysadmin rights and not customer
            set sysowner_email [ad_system_owner]
            set uid [party::get_by_email -email $sysowner_email]
            set i [string first "@" $sysowner_email]
            if { $i > -1 } {
                set domain [string range $sysowner_email $i+1 end]
            } else {
                set domain [hf_domain_example]
            }


            # put asset and attr records in key value a_larr(z) array
            # 1 element per asset or attr, referenced by z

            # Make two chains of dc hw hw vm vh ss, adding a ua and ns to each.
            # 
            # Then 
            # test against creation data
            # update ua of each
            # verify ua of each
            # update an ns 
            # verify ns
            # 
            # move vm from 1 to 2.
            # verify
            # move vh from 2 to 1
            # verify
            # delete everything below a hw
            # verify

            set z 1
            set randlabel [hf_domain_example]
            array set asset_arr [list \
                                     asset_type_id "dc" \
                                     label $randlabel \
                                     name "${randlabel} test DC $z" \
                                     user_id $sysowner_user_id ]
            set asset_arr(f_id) [hf_asset_create asset_arr ]
            array set asset_arr [list \
                                     affix [enerate_random_string] \
                                     description "DC${z}" \
                                     details "This is for api test"]
            set asset_arr(dc_id) [hf_dc_write asset_arr]
            set a_larr(${z}) [array get asset_arr]
            array unset asset_arr

            incr z
            set randlabel [hf_domain_example]
            array set asset_arr [list \
                                     asset_type_id "dc" \
                                     label $randlabel \
                                     name "${randlabel} test DC $z" \
                                     user_id $sysowner_user_id ]
            set asset_arr(f_id) [hf_asset_create asset_arr ]
            array set asset_arr [list \
                                     affix [enerate_random_string] \
                                     description "DC${z}" \
                                     details "This is for api test"]
            set asset_arr(dc_id) [hf_dc_write asset_arr]
            array unset asset_arr

            incr z
            
        } \
        -teardown_code {
            # 
            #acs_user::delete -user_id $user1_arr(user_id) -permanent

        }
    #aa_true "Test for .." $passed_p
    #aa_equals "Test for .." $test_value $expected_value


}
