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
                    set priv_arr(${role},${at_id}) 0
                }
            }
            # Manually add each entry. This is necessary to avoid duplicating 
            # a code/logic error.
            array set rp_map_arr [list \
                                      site_developer,non_assets 7   \
                                      site_developer,published 7   \
                                      billing_staff,admin_contact_record 1   \
                                      billing_staff,non_assets 1   \
                                      billing_staff,published 1   \
                                      billing_manager,admin_contact_record 5   \
                                      billing_manager,non_assets 5   \
                                      billing_manager,published 5   \
                                      billing_admin,admin_contact_record 23   \
                                      billing_admin,non_assets 23   \
                                      billing_admin,published 23   \
                                      technical_staff,assets 1   \
                                      technical_staff,dc 1   \
                                      technical_staff,hw 1   \
                                      technical_staff,non_assets 1   \
                                      technical_staff,ns 1   \
                                      technical_staff,ot 1   \
                                      technical_staff,published 1   \
                                      technical_staff,ss 1   \
                                      technical_staff,tech_contact_record 1   \
                                      technical_staff,vh 1   \
                                      technical_staff,vm 1   \
                                      technical_manager,assets 5   \
                                      technical_manager,dc 5   \
                                      technical_manager,hw 5   \
                                      technical_manager,non_assets 5   \
                                      technical_manager,ns 5   \
                                      technical_manager,ot 5   \
                                      technical_manager,published 5   \
                                      technical_manager,ss 5   \
                                      technical_manager,tech_contact_record 5   \
                                      technical_manager,vh 5   \
                                      technical_manager,vm 5   \
                                      technical_admin,assets 23   \
                                      technical_admin,dc 23   \
                                      technical_admin,hw 23   \
                                      technical_admin,non_assets 23   \
                                      technical_admin,ns 23   \
                                      technical_admin,ot 23   \
                                      technical_admin,published 23   \
                                      technical_admin,ss 23   \
                                      technical_admin,tech_contact_record 23   \
                                      technical_admin,vh 23   \
                                      technical_admin,vm 23   \
                                      main_staff,admin_contact_record 1   \
                                      main_staff,assets 1   \
                                      main_staff,main_contact_record 1   \
                                      main_staff,non_assets 1   \
                                      main_staff,published 1   \
                                      main_staff,tech_contact_record 1   \
                                      main_manager,admin_contact_record 5   \
                                      main_manager,assets 5   \
                                      main_manager,main_contact_record 5   \
                                      main_manager,non_assets 5   \
                                      main_manager,published 5   \
                                      main_manager,tech_contact_record 5   \
                                      main_admin,admin_contact_record 23   \
                                      main_admin,assets 23   \
                                      main_admin,main_contact_record 23   \
                                      main_admin,non_assets 23   \
                                      main_admin,published 23   \
                                      main_admin,tech_contact_record 23 ]
            set i_rp_list [array names rp_map_arr]
            foreach i $i_rp_list {
                set priv_arr(${i}) $rp_map_arr(${i})
            }
            # setup initializations for privilege check
            array set rpv_arr [list read 1 create 2 write 4 delete 8 admin 16]
            set rpn_list [array names rpv_arr]

            # Case 1: A user with sysadmin rights and not customer
            set sysowner_user_id [party::get_by_email -email [ad_system_owner]]
            # Case process
            # Loop through each subcase
            set rp_allowed_p 1
            foreach role $roles_list {
                # at_id = asset_type_id
                foreach at_id $asset_type_ids_list {
                    foreach rpn $rpn_list {
                        set customer_id [randomRange 4]
                        incr customer_id
                        set hp_allowed_p [hf_permission_p $sysowner_user_id $customer_id $at_id $rpn $instance_id]
                        # syaadmin should be 1 for all tests
                        aa_equals "C1 sysadmin ${role} ${at_id} ${rpn} is " $hp_allowed_p $rp_allowed_p
                    }
                }
            }


            # Case 2: A user registered to site and not customer
            set domain hf_domain_example
            array set u_site_arr [auth::create_user -email "test1@${domain}" ]
            if { $u_site_arr(creation_status) ne "ok" } {
                # Could not create user
                error "Could not create test user u_site_arr=[array get u_site_arr]"
            } else {
                set site_user_id $u_site_arr(user_id)
            }
            array set u_site_arr [auth::create_user -email "test1@${domain}" ]
            if { $u_site_arr(creation_status) ne "ok" } {
                # Could not create user
                error "Could not create test user u_site_arr=[array get u_site_arr]"
            } else {
                set site_user_id $u_site_arr(user_id)
            }
            # Case process
            # Loop through each subcase
            set rp_allowed_p 0
            foreach role $roles_list {
                # at_id = asset_type_id
                foreach at_id $asset_type_ids_list {
                    foreach rpn $rpn_list {
                        set hp_allowed_p [hf_permission_p $site_user_id $customer_id $at_id $rpn $instance_id]
                        if { [expr { $rpv_arr(${rpn}) & $priv_arr(${role},${at_id}) } ] > 0 } {
                            set rp_allowed_p 1
                        } else {
                            set rp_allowed_p 0
                        }
                        # site_user should be 0 for all tests
                        # User has no roles.
                        aa_equals "C2 site_user ${role} ${at_id} ${rpn} is " $hp_allowed_p $rp_allowed_p
                    }
                }
            }



            # Case 3: A customer with single user
            array set u_mnp_arr [auth::create_user -email "test1@${domain}" ]
            if { $u_mnp_arr(creation_status) ne "ok" } {
                # Could not create user
                error "Could not create test user u_mnp_arr=[array get u_mnp_arr]"
            } else {
                set mnp_user_id $u_mnp_arr(user_id)
            }
            array set u_mnp_arr [auth::create_user -email "test1@${domain}" ]
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
            # Case process
            # Loop through each subcase
            set rp_allowed_p 1
            foreach role $roles_list {
                # at_id = asset_type_id
                foreach at_id $asset_type_ids_list {
                    foreach rpn $rpn_list {
                        set hp_allowed_p [hf_permission_p $mnp_user_id $customer_id $at_id $rpn $instance_id]
                        # mnp_user should be 1 for all tests
                        # Because user has all roles.
                        aa_equals "C3 mnp_user ${role} ${at_id} ${rpn} is " $hp_allowed_p $rp_allowed_p
                    }
                }
            }




            # Case 4: A customer with desparate user roles
            # Make each user one different role
            set c4_uid_list [list ]
            foreach role $roles_list {
                array set u_${role}_arr [auth::create_user -email "test1@${domain}" ]
                if { $u_${role}_arr(creation_status) ne "ok" } {
                    # Could not create user
                    error "Could not create test user u_${role}_arr=[array get u_${role}_arr]"
                } else {
                    set ${role}_user_id $u_${role}_arr(user_id)
                }
                array set u_${role}_arr [auth::create_user -email "test1@${domain}" ]
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
            # Case process
            # Loop through each subcase
            foreach c4uid $c4_uid_list {
                foreach role $roles_list {
                    # at_id = asset_type_id
                    foreach at_id $asset_type_ids_list {
                        foreach rpn $rpn_list {
                            set hp_allowed_p [hf_permission_p $c4id $customer_id $at_id $rpn $instance_id]
                            if { $c4ui(${role}) eq $c4uid && [expr { $rpv_arr(${rpn}) & $priv_arr(${role},${at_id}) } ] > 0 } {
                                set rp_allowed_p 1
                            } else {
                                set rp_allowed_p 0
                            }
                            # test privilege against role when c4id = crui(role), otherwise 0
                            aa_equals "C4 uid:${c4uid} ${role} ${at_id} ${rpn} is " $hp_allowed_p $rp_allowed_p
                        }
                    }
                }
            }



            # Case 5: A customer with some random duplicates
            set c5_uid_list [list ]
            foreach role $roles_list {
                array set m_${role}_arr [auth::create_user -email "test1@${domain}" ]
                if { $m_${role}_arr(creation_status) ne "ok" } {
                    # Could not create user
                    error "Could not create test user m_${role}_arr=[array get m_${role}_arr]"
                } else {
                    set ${role}_user_id $m_${role}_arr(user_id)
                }
                array set m_${role}_arr [auth::create_user -email "test1@${domain}" ]
                if { $m_${role}_arr(creation_status) ne "ok" } {
                    # Could not create user
                    error "Could not create test user m_${role}_arr=[array get m_${role}_arr]"
                } else {
                    set c5ui(${role}) $m_${role}_arr(user_id)
                    lappend c5_uid_list $u_${role}_arr(usre_id)
                }
            }
            # Create customer records
            set customer_id 5
            set roles_list_len [llength $roles_list_len]
            # uwr_larr = users with role, each key contains list of user_ids assigned role.
            foreach role $roles_list {
                # make sure every role is assigned to a user
                hf_user_role_add $customer_id $c5ui(${role}) [hf_role_id_of_label $role $instance_id] $instance_id
                lappend uwr_larr($role) $c5ui(${role})
                # assign a randome role to same user.
                set u_role [lindex $roles_list [randomRange $roles_list_len]]
                hf_user_role_add $customer_id $c5ui(${role}) [hf_role_id_of_label $u_role $instance_id] $instance_id
                lappend uwr_larr(${role}) $c5ui(${u_role})
            }
            # Case process
            # Loop through each subcase
            foreach c5uid $c5_uid_list {
                foreach role $roles_list {
                    # at_id = asset_type_id
                    foreach at_id $asset_type_ids_list {
                        foreach rpn $rpn_list {
                            set hp_allowed_p [hf_permission_p $c5id $customer_id $at_id $rpn $instance_id]
                            if { $c5uid in $uwr_larr(${role}) && [expr { $rpv_arr(${rpn}) & $priv_arr(${role},${at_id}) } ] > 0 } {
                                set rp_allowed_p 1
                            } else {
                                set rp_allowed_p 0
                            }
                            # test privilege against role when c5id = crui(role), otherwise 0
                            aa_equals "C5 uid:${c5uid} ${role} ${at_id} ${rpn} is " $hp_allowed_p $rp_allowed_p
                        }
                    }
                }
            }

            # Case 6: Case 5 with some random role deletes, so that only one user per role
            set customer_id 5
            foreach role $roles_list {
                set t_list $uwr_larr(${role})
                set t_len [llength $t_list]
                while { $t_len > 1 } {
                    set i [randomRange $t_len]
                    set i_uid [lindex $t_list $i]
                    hf_user_role_delete $customer_id $i_uid [hf_role_id_of_label $role $instance_id] $instance_id
                    set t_list [lreplace $t_list $i $i]
                    incr t_len -1
                }
                set uwr_larr(${role})
            }
            # Case process
            # Loop through each subcase
            foreach c5uid $c5_uid_list {
                foreach role $roles_list {
                    # at_id = asset_type_id
                    foreach at_id $asset_type_ids_list {
                        foreach rpn $rpn_list {
                            set hp_allowed_p [hf_permission_p $c5id $customer_id $at_id $rpn $instance_id]
                            if { $c5uid in $uwr_larr(${role}) && [expr { $rpv_arr(${rpn}) & $priv_arr(${role},${at_id}) } ] > 0 } {
                                set rp_allowed_p 1
                            } else {
                                set rp_allowed_p 0
                            }
                            # test privilege against role when c5id = crui(role), otherwise 0
                            aa_equals "C6 c5uid:${c5uid} ${role} ${at_id} ${rpn} is " $hp_allowed_p $rp_allowed_p
                        }
                    }
                }
            }
            

        } \
        -teardown_code {
            # 
            acs_user::delete -user_id $user1_arr(user_id) -permanent

        }
    #aa_true "Test for .." $passed_p
    #aa_equals "Test for .." $test_value $expected_value


}
