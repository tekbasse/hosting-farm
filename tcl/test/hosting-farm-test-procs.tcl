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

            ns_log Notice "hosting-farm-test-procs.tcl.60: roles_list '${roles_list}'"
            ns_log Notice "hosting-farm-test-procs.tcl.61: rpn_list '${rpn_list}'"
            ns_log Notice "hosting-farm-test-procs.tcl.61: asset_type_ids_list '${asset_type_ids_list}'"

            # Case 1: A user with sysadmin rights and not customer
            set sysowner_email [ad_system_owner]
            set sysowner_user_id [party::get_by_email -email $sysowner_email]
            set i [string first "@" $sysowner_email]
            if { $i > -1 } {
                set domain [string range $sysowner_email $i+1 end]
            } else {
                set domain [hf_domain_example]
            }

            # Case 2: A user registered to read package and not customer
            set z [clock seconds]
            set email "test${z}@${domain}"
            array set u_site_arr [auth::create_user -first_names [join [qal_namelur] " "] -last_name [qal_namelur 1] -email $email ]
            if { $u_site_arr(creation_status) ne "ok" } {
                # Could not create user
                ns_log Warning "Could not create test user u_site_arr=[array get u_site_arr]"
            } else {
                set site_user_id $u_site_arr(user_id)
                permission::grant -party_id $site_user_id -object_id $instance_id -privilege read
            }


            # Case 3: A customer with single user
            incr z
            set email "test${z}@${domain}"
            array set u_mnp_arr [auth::create_user -first_names [join [qal_namelur] " "] -last_name [qal_namelur 1] -email $email ]
            if { $u_mnp_arr(creation_status) ne "ok" } {
                # Could not create user
                ns_log Warning "Could not create test user u_mnp_arr=[array get u_mnp_arr]"
            } else {
                set mnp_user_id $u_mnp_arr(user_id)
                permission::grant -party_id $mnp_user_id -object_id $instance_id -privilege read
            }
            incr z
            # Create customer records
            set customer_id 3
            foreach role $roles_list {
                hf_user_role_add $customer_id $mnp_user_id $role_id_arr(${role}) $instance_id
            }

            # Case 4: A customer with desparate user roles
            # Make each user one different role
            set c4_uid_list [list ]
            foreach role $roles_list {
                incr z
                set email "test${z}@${domain}"
                set arr1_name u1_${role}_arr
                array set $arr1_name [auth::create_user -first_names [join [qal_namelur] " "] -last_name [qal_namelur 1] -email $email ]
                if { [lindex [array get $arr1_name creation_status] 1] ne "ok" } {
                    # Could not create user
                    ns_log Warning "Could not create test user u_${role}_arr=[array get u_${role}_arr]"
                } else {
                    set uid [set u1_${role}_arr(user_id) ]
                    set c4ui(${role}) $uid
                    set c4urole(${uid}) $role
                    lappend c4_uid_list $uid
                    permission::grant -party_id $uid -object_id $instance_id -privilege read
                }
            }
            # Create customer records
            set customer_id 4
            foreach role $roles_list {
                hf_user_role_add $customer_id $c4ui(${role}) $role_id_arr(${role}) $instance_id
                ns_log Notice "hosting-farm-test-procs.tcl.200: added customer_id ${customer_id} user_id $uid role $role"
            }


            # Case 5: A customer with some random duplicates
            set c5_uid_list [list ]
            foreach role $roles_list {
                incr z
                set email "test${z}@${domain}"
                set arrm_name m_${role}_arr
                array set $arrm_name [auth::create_user -first_names [join [qal_namelur] " "] -last_name [qal_namelur 1] -email $email ]
                if { [lindex [array get $arrm_name creation_status] 1] ne "ok" } {
                    # Could not create user
                    ns_log Warning "Could not create test user m_${role}_arr=[array get m_${role}_arr]"
                } else {
                    set uid [set m_${role}_arr(user_id) ]
                    lappend c5ui_arr(${role}) $uid
                    lappend c5_uid_list $uid
                    permission::grant -party_id $uid -object_id $instance_id -privilege read
                }
            }
            # Create customer records
            set customer_id 5
            set roles_list_len_1 [llength $roles_list]
            incr roles_list_len_1 -1
            # c5uwr_larr = users with role, each key contains list of user_ids assigned role.
            foreach role $roles_list {
                set uid $c5ui_arr(${role})
                # make sure every role is assigned to a user
                hf_user_role_add $customer_id $uid $role_id_arr(${role}) $instance_id
                ns_log Notice "hosting-farm-test-procs.tcl.230: added customer_id ${customer_id} user_id $uid role $role"
                lappend c5uwr_larr(${uid}) $role
                # assign a random role to same user.
                set r [randomRange $roles_list_len_1]
                set u_role [lindex $roles_list $r]
                if { $u_role ne "" } {
                    ns_log Notice "hosting-farm-test-procs.tcl.310. u_role '${u_role}'"
                    hf_user_role_add $customer_id $uid $role_id_arr(${u_role}) $instance_id
                    ns_log Notice "hosting-farm-test-procs.tcl.238: added customer_id ${customer_id} user_id $uid role $u_role"
                    lappend c5uwr_larr(${uid}) $u_role
                } else {
                    ns_log Warning "hosting-farm-test-procs.tcl.316: u_role blank. r '${r}' roles_list_len_1 ${roles_list_len_1}"
                }
            }



            # Case 1 process
            # Loop through each subcase
            set rp_allowed_p 1
            set customer_id ""
            foreach role $roles_list {
                # at_id = asset_type_id
                foreach at_id $asset_type_ids_list {
                    foreach rpn $rpn_list {
                        set customer_id [randomRange 4]
                        incr customer_id
                        set hp_allowed_p [hf_permission_p $sysowner_user_id $customer_id $at_id $rpn $instance_id]
                        # syaadmin should be 1 for all tests
                        aa_equals "C1 sysadmin ${role} ${at_id} ${rpn}" $hp_allowed_p $rp_allowed_p
                    }
                }
            }


            # Case 2 process
            # Loop through each subcase
            set rp_allowed_p 0
            set c 0
            # at_id = asset_type_id
            foreach at_id $asset_type_ids_list {
                #check against existing customers and non existent customers.
                incr c
                if { $c > 5 } {
                    set customer_id ""
                    set c 1
                }
                foreach rpn $rpn_list {
                    
                    set hp_allowed_p [hf_permission_p $site_user_id $customer_id $at_id $rpn $instance_id]
                    # site_user should be 0 for all tests except read published
                    # User has no roles.
                    if { $rpn eq "read" && $at_id eq "published" } {
                        set rp_allowed_p 1
                    } else {
                        set rp_allowed_p 0
                    }
                    aa_equals "C2 site uid:${site_user_id} customer:${customer_id} ${at_id} ${rpn}" $hp_allowed_p $rp_allowed_p
                }
            }




            # Case 3 process
            # Loop through each subcase
            set customer_id 3
            # at_id = asset_type_id
            set c3_role_ids_list [qc_roles_of_user_contact_id $nmp_user_id $customer_id $instance_id]
            ns_log Notice "hosting-farm-test-procs.tcl.303 c3_role_ids_list '${c3_role_ids_list}'"
            foreach at_id $asset_type_ids_list {
                foreach rpn $rpn_list {
                    set hp_allowed_p [hf_permission_p $mnp_user_id $customer_id $at_id $rpn $instance_id]
                    # mnp_user should be 1 for all tests except delete
                    # Because user has all roles.
                    if { $rpn eq "delete" || [string match "permission*" $at_id] } {
                        set rp_allowed_p 0
                    } else {
                        set rp_allowed_p 1
                    }
                         aa_equals "C3 1customer-user:${mnp_user_id} customer:${customer_id} ${at_id} ${rpn}" $hp_allowed_p $rp_allowed_p
                }
            }




            # Check each user against each asset_type_ids_list, 
            # Case 4 process
            set customer_id 4
            # Loop through each subcase
            foreach c4uid $c4_uid_list {
                # at_id = asset_type_id
                foreach at_id $asset_type_ids_list {
                    foreach rpn $rpn_list {
                        set hp_allowed_p [hf_permission_p $c4uid $customer_id $at_id $rpn $instance_id]
                        set role $c4urole(${c4uid})
                        if { $c4ui(${role}) eq $c4uid && [expr { $rpv_arr(${rpn}) & $priv_arr(${role},${at_id}) } ] > 0 } {
                            set rp_allowed_p 1
                        } else {
                            set rp_allowed_p 0
                        }
                        # these have not been assigned to anyone
                        if { $rpn eq "delete" || [string match "permission*" $at_id] } {
                            set rp_allowed_p 0
                        }
                        # permissions defaults for all registered users with read priv.
                        if { $rpn eq "read" && $at_id eq "published" } {
                            set rp_allowed_p 1
                        }
                        # test privilege against role when c4uid = crui(role), otherwise 0
                        aa_equals "C4 1role/uid uid:${c4uid} ${role} ${at_id} ${rpn}" $hp_allowed_p $rp_allowed_p
                    }
                }
            }



            # Case 5 process
            set customer_id 5
            # Loop through each subcase
            foreach c5uid $c5_uid_list {
                # at_id = asset_type_id
                foreach at_id $asset_type_ids_list {
                    foreach rpn $rpn_list {
                        set hp_allowed_p [hf_permission_p $c5uid $customer_id $at_id $rpn $instance_id]
                        set rp_allowed_p 0
                        foreach role $c5uwr_larr(${c5uid}) {
                            if { [expr { $rpv_arr(${rpn}) & $priv_arr(${role},${at_id}) } ] > 0 } {
                                set rp_allowed_p 1
                            } 
                        }
                        # these have not been assigned to anyone
                        if { $rpn eq "delete" || [string match "permission*" $at_id] } {
                            set rp_allowed_p 0
                        }
                        # permissions defaults for all registered users with read priv.
                        if { $rpn eq "read" && $at_id eq "published" } {
                            set rp_allowed_p 1
                        }
                        # test privilege against role when c5uid = crui(role), otherwise 0
                        aa_equals "C5 uid:${c5uid} ${role} ${at_id} ${rpn}" $hp_allowed_p $rp_allowed_p
                    }
                }
                
            }
            



            # Case 6: Case 5 with some random role deletes, so that only one user per role, but maybe differnt user than c5..
            set customer_id 5
            foreach c5cuid $c5_uid_list {
                set t_list $c5uwr_larr(${c5uid})
                set t_len [llength $t_list]
                while { $t_len > 1 } {
                    incr t_len -1
                    set i [randomRange $t_len]
                    set role [lindex $t_list $i]
                    hf_user_role_delete $customer_id $c5uid $role_id_arr(${role}) $instance_id
                    ns_log Notice "hosting-farm-test-procs.tcl.255: delet customer_id ${customer_id} user_id $c5uid role $role"
                    set t_list [lreplace $t_list $i $i]
                }
                set c5uwr_larr(${c5uid}) $t_list
            }




            # Case 6 process
            set customer_id 5
            # Loop through each subcase
            foreach c5uid $c5_uid_list {
                # at_id = asset_type_id
                foreach at_id $asset_type_ids_list {
                    foreach rpn $rpn_list {
                        set hp_allowed_p [hf_permission_p $c5uid $customer_id $at_id $rpn $instance_id]
                        set rp_allowed_p 0
                        foreach role $c5uwr_larr(${c5uid}) {
                            if { [expr { $rpv_arr(${rpn}) & $priv_arr(${role},${at_id}) } ] > 0 } {
                                set rp_allowed_p 1
                            } 
                        }
                        # these have not been assigned to anyone
                        if { $rpn eq "delete" || [string match "permission*" $at_id] } {
                            set rp_allowed_p 0
                        }
                        # permissions defaults for all registered users with read priv.
                        if { $rpn eq "read" && $at_id eq "published" } {
                            set rp_allowed_p 1
                        }
                        # test privilege against role when c5uid = crui(role), otherwise 0
                        aa_equals "C6 c5uid:${c5uid} [join $c5uwr_larr(${c5uid}) ","] ${at_id} ${rpn}" $hp_allowed_p $rp_allowed_p
                    }
                }
                
            }
            

        } \
        -teardown_code {
            # 
            #acs_user::delete -user_id $user1_arr(user_id) -permanent

        }
    #aa_true "Test for .." $passed_p
    #aa_equals "Test for .." $test_value $expected_value


}
