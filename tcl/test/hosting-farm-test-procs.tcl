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

            # create a lookup truth table of permissions
            # hf_asset_type_ids_list vs roles_list
            # with value being 1 read, 2 create, 4 write, 8 delete, 16 admin
            # which results in these values, based on existing assignments:
            # 0,1,3,7,15,31
            # with this table, if user has same role, customer_id, 
            # then pass using bit math: table value & privilege_request_value
            # 
            # initialize table
            foreach role $roles_list {
                # at_id = asset_type_id
                foreach at_id $asset_type_ids_list {
                    # 0 is default, no privilege
                    set priv_arr(${role},${at_id})  0
                }
            }
            # Manually add each entry. This is necessary to avoid duplicating 
            # a code/logic error.
            # asset_type_ids_list:
            #   main_contact_record
            #   admin_contact_record
            #   tech_contact_record
            #   permissions_properties
            #   permissions_roles
            #   permissions_privileges
            #   non_assets
            #   published
            #   assets
            #   ss
            #   dc
            #   hw
            #   vm
            #   vh
            #   ns
            #   ot
            # roles_list
            #   site_developer
            #   billing_staff
            #   billing_manager
            #   billing_admin
            #   technical_staff
            #   technical_manager
            #   technical_admin
            #   main_staff
            #   main_manager
            #   main_admin


            
            # Case 1: A user with sysadmin rights and not customer
            set sysowner_user_id [party::get_by_email -email [ad_system_owner]]



            # Case 2: A user registered to site and not customer
            array set u_site_arr [auth:create_user -email "test1@${domain}" ]
            if { $u_site_arr(creation_status) ne "ok" } {
                # Could not create user
                error "Could not create test user u_site_arr=[array get u_site_arr]"
            } else {
                set site_user_id $u_site_arr(user_id)
            }
            array set u_site_arr [auth:create_user -email "test1@${domain}" ]
            if { $u_site_arr(creation_status) ne "ok" } {
                # Could not create user
                error "Could not create test user u_site_arr=[array get u_site_arr]"
            } else {
                set site_user_id $u_site_arr(user_id)
            }



            # Case 3: A customer with single user
            array set u_mnp_arr [auth:create_user -email "test1@${domain}" ]
            if { $u_mnp_arr(creation_status) ne "ok" } {
                # Could not create user
                error "Could not create test user u_mnp_arr=[array get u_mnp_arr]"
            } else {
                set mnp_user_id $u_mnp_arr(user_id)
            }
            array set u_mnp_arr [auth:create_user -email "test1@${domain}" ]
            if { $u_mnp_arr(creation_status) ne "ok" } {
                # Could not create user
                error "Could not create test user u_mnp_arr=[array get u_mnp_arr]"
            } else {
                set mnp_user_id $u_mnp_arr(user_id)
            }
            # Create customer records
            set customer_id 3
            foreach role $roles_list {
                hf_user_role_add $customer_id $mnp_user_id [hf_role_id_of_label $role $instance_id] $instance_id
            }


            # Case 4: A customer with desparate user roles
            # Make each user one different role
            set c4_uid_list [list ]
            foreach role $roles_list {
                array set u_${role}_arr [auth:create_user -email "test1@${domain}" ]
                if { $u_${role}_arr(creation_status) ne "ok" } {
                    # Could not create user
                    error "Could not create test user u_${role}_arr=[array get u_${role}_arr]"
                } else {
                    set ${role}_user_id $u_${role}_arr(user_id)
                }
                array set u_${role}_arr [auth:create_user -email "test1@${domain}" ]
                if { $u_${role}_arr(creation_status) ne "ok" } {
                    # Could not create user
                    error "Could not create test user u_${role}_arr=[array get u_${role}_arr]"
                } else {
                    set c4ui(${role}) $u_(${role})_arr(user_id)
                    lappend c4_uid_list $c4ui(${role})
                }
            }
            # Create customer records
            set customer_id 4
            foreach role $roles_list {
                hf_user_role_add $customer_id $c4ui(${role}) [hf_role_id_of_label $role $instance_id] $instance_id
            }
            # Check each user against each asset_type_ids_list, 
            # Max of three from each list should be able to admin?
            # Max of six users from each list should be able to write?
            # max of nine users from each list should be able to read?  How many roles? users?


            # Case 5: A customer with some random duplicates
            set c5_uid_list [list ]
            foreach role $roles_list {
                array set m_${role}_arr [auth:create_user -email "test1@${domain}" ]
                if { $m_${role}_arr(creation_status) ne "ok" } {
                    # Could not create user
                    error "Could not create test user m_${role}_arr=[array get m_${role}_arr]"
                } else {
                    set ${role}_user_id $m_${role}_arr(user_id)
                }
                array set m_${role}_arr [auth:create_user -email "test1@${domain}" ]
                if { $m_${role}_arr(creation_status) ne "ok" } {
                    # Could not create user
                    error "Could not create test user m_${role}_arr=[array get m_${role}_arr]"
                } else {
                    set c5ui${role}) $m_${role}_arr(user_id)
                    lappend c5_uid_list $u_${role}_arr(usre_id)
                }

            }
            # Create customer records
            set customer_id 5
            set roles_list_len [llength $roles_list_len]
            foreach role $roles_list {
                hf_user_role_add $customer_id $c5ui${role}) [hf_role_id_of_label $role $instance_id] $instance_id
                set u_role [lindex $roles_list [randomRange $roles_list_len]]
                hf_user_role_add $customer_id $c5ui${role}) [hf_role_id_of_label $u_role $instance_id] $instance_id
            }

            # Case 6: Case 4 with some random role changes.
            set customer_id 4


} \
    -teardown_code {
        # 
        acs_user::delete -user_id $user1_arr(user_id) -permanent

    }
#aa_true "Test for .." $passed_p
#aa_equals "Test for .." $test_value $expected_value


}
