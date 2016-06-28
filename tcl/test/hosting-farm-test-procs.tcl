ad_library {
    Automated tests for hosting-farm
    @creation-date 2015-03-19
}

aa_register_case -cats {api smoke} permissions_check {
    Test hf_permissions_p proc for all cases
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {
            
            ns_log Notice "aa_register_case.13: Begin test permissions_check"
            # Use default permissions provided by tcl/hosting-farm-init.tcl
            # Yet, users must have read access permissions or test fails
            # Some tests will fail (predictably) in a hardened system

            set instance_id [ad_con package_id]
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
                append roles_list $role
                set role_id [hf_role_id_of_label $role "" $instance_id]
                set role_id_arr(${role}) $role_id
            }
            # keep namespace clean to help prevent bugs in test code
            unset role_id
            unset role
            unset roles_lists
            
            # Case 1: A user with sysadmin rights
            set sysowner_user_id [party::get_by_email -email [ad_system_owner]]



            # Case 2: A user registered to site, but not customer
            array set u_site_arr [auth:create_user -email "test1@${domain}" ]
            if { $u_site_arr(creation_status) ne "ok" } {
                # Could not create user
                error "Could not create test user with u_site_arr=[array get u_site_arr]"
            } else {
                set site_user_id $u_site_arr(user_id)
            }
            array set u_site_arr [auth:create_user -email "test1@${domain}" ]
            if { $u_site_arr(creation_status) ne "ok" } {
                # Could not create user
                error "Could not create test user with u_site_arr=[array get u_site_arr]"
            } else {
                set site_user_id $u_site_arr(user_id)
            }



            # Case 3: A customer with single user
            array set u_mnp_arr [auth:create_user -email "test1@${domain}" ]
            if { $u_mnp_arr(creation_status) ne "ok" } {
                # Could not create user
                error "Could not create test user with u_mnp_arr=[array get u_mnp_arr]"
            } else {
                set mnp_user_id $u_mnp_arr(user_id)
            }
            array set u_mnp_arr [auth:create_user -email "test1@${domain}" ]
            if { $u_mnp_arr(creation_status) ne "ok" } {
                # Could not create user
                error "Could not create test user with u_mnp_arr=[array get u_mnp_arr]"
            } else {
                set mnp_user_id $u_mnp_arr(user_id)
            }



            # Case 4: A customer with desparate user roles
            # Make each user with one different role
            foreach role $roles_list {
                array set u_${role}_arr [auth:create_user -email "test1@${domain}" ]
                if { $u_${role}_arr(creation_status) ne "ok" } {
                    # Could not create user
                    error "Could not create test user with u_${role}_arr=[array get u_${role}_arr]"
                } else {
                    set ${role}_user_id $u_${role}_arr(user_id)
                }
                array set u_${role}_arr [auth:create_user -email "test1@${domain}" ]
                if { $u_${role}_arr(creation_status) ne "ok" } {
                    # Could not create user
                    error "Could not create test user with u_${role}_arr=[array get u_${role}_arr]"
                } else {
                    set u_${role}_user_id $u_${role}_arr(user_id)
                }

            }
            # Create customer record



            # Case 5: A customer with duplicate and changing user roles
            foreach role $roles_list {
                array set m_${role}_arr [auth:create_user -email "test1@${domain}" ]
                if { $m_${role}_arr(creation_status) ne "ok" } {
                    # Could not create user
                    error "Could not create test user with m_${role}_arr=[array get m_${role}_arr]"
                } else {
                    set ${role}_user_id $m_${role}_arr(user_id)
                }
                array set m_${role}_arr [auth:create_user -email "test1@${domain}" ]
                if { $m_${role}_arr(creation_status) ne "ok" } {
                    # Could not create user
                    error "Could not create test user with m_${role}_arr=[array get m_${role}_arr]"
                } else {
                    set m_${role}_user_id $m_${role}_arr(user_id)
                }

            }
            # Create customer record



        } \
        -teardown_code {
            # 
            acs_user::delete -user_id $user1_arr(user_id) -permanent

        }
            #aa_true "Test for .." $passed_p
            #aa_equals "Test for .." $test_value $expected_value
            

}
