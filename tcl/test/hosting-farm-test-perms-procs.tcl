ad_library {
    Automated tests for hosting-farm
    @creation-date 2015-03-19
}

aa_register_case -cats {db smoke} hf_asset_permutations_check {
    tests permutations of each asset and attribute via api
} {
    aa_run_with_teardown \
        -test_code {
            #        -rollback \
                        ns_log Notice "aa_register_case.12: Begin test assets_attr_perms_check"
                        # Use default permissions provided by tcl/hosting-farm-init.tcl
                        # Yet, users must have read access permissions or test fails
                        # Some tests will fail (predictably) in a hardened system

                        set instance_id [ad_conn package_id]
                        # We avoid qc_permission_p by using a sysadmin user

                        # A user with sysadmin rights and not customer
                        set sysowner_email [ad_system_owner]
                        set sysowner_user_id [party::get_by_email -email $sysowner_email]
                        set i [string first "@" $sysowner_email]
                        if { $i > -1 } {
                            set domain [string range $sysowner_email $i+1 end]
                        } else {
                            set domain [hf_domain_example]
                        }
                        
                        # Generate permutations
                        # hf_asset_type_id dc hw vm vh ss ip ni ns ot ua
                        set asset_type_a_list [acc_fin::shuffle_list [hf_asset_type_id_list]]
                        set asset_type_b_list [acc_fin::shuffle_list [hf_asset_type_id_list]]
                        foreach type_id $asset_type_a_list {
                            # create asset record
                            array set asset_arr [list \
                                                     asset_type_id ${type_id} \
                                                     label $domain \
                                                     name "test ${type_id} by hosting-farm-test-perms-procs.tcl" \
                                                     user_id $sysowner_user_id ]
                            set asset_arr(f_id) [hf_asset_create asset_arr ]
                            aa_log "'[string toupper ${type_id}]' asset with f_id '$asset_arr(f_id)' created"
                            ns_log Notice "hosting-farm-test-perms-procs.tcl.43: created asset_arr(f_id) '$asset_arr(f_id)'"
                            array set asset_arr [list \
                                                     sub_label $domain \
                                                     system_name $domain \
                                                     domain_name $domain \
                                                     service_name $domain \
                                                     server_name $domain \
                                                     name_record $asset_arr(name) \
                                                     description $asset_arr(name) \
                                                     ipv4_status 0 \
                                                     ipv6_status 0 \
                                                     details $asset_arr(name) ]
                            foreach sub_type_id $asset_type_b_list {
                                ns_log Notice "hosting-farm-test-perms-procs.tcl.56: trying sub_type_id '${sub_type_id}' attribute on type_id '${type_id}' '$asset_arr(f_id)'"
                                switch -exact $sub_type_id {
                                    dc {
                                        set asset_arr(sub_f_id) [hf_dc_write asset_arr]
                                    }
                                    hw {
                                        set asset_arr(sub_f_id) [hf_hw_write asset_arr]
                                    }
                                    vm {
                                        set asset_arr(sub_f_id) [hf_vm_write asset_arr]
                                    }
                                    vh {
                                        set asset_arr(sub_f_id) [hf_vh_write asset_arr]
                                    }
                                    ss {
                                        set asset_arr(sub_f_id) [hf_ss_write asset_arr]
                                    }
                                    ip {
                                        set asset_arr(sub_f_id) [hf_ip_write asset_arr]
                                    }
                                    ni {
                                        set asset_arr(sub_f_id) [hf_ni_write asset_arr]
                                    }
                                    ns {
                                        set asset_arr(sub_f_id) [hf_ns_write asset_arr]
                                    }
                                    ot {
                                        # hf_dc_write asset_arr
                                        set asset_arr(sub_f_id) ""
                                    }
                                    ua {
                                        #hf_ua_write asset_arr
                                        array set asset_arr [list \
                                                                 ua "user-${type_id}" \
                                                                 up [ad_generate_random_string]]
                                        set asset_arr(sub_f_id) [hf_user_add asset_arr]
                                        if { $type_id eq "ot" } {
                                            ns_log Notice "hosting-farm-test-perms-procs.tcl.93: ot case array get asset_arr '[array get asset_arr]'"
                                        }
                                    }
                                }
                                # end switch
                                if { $sub_type_id in [hf_types_allowed_by $type_id] || ( $sub_type_id eq $type_id && $sub_type_id ni [list ot] ) } {
                                    set allowed_p 1
                                } else {
                                    set allowed_p 0
                                }
                                if { $asset_arr(sub_f_id) ne "" } {
                                    set did_it_p 1
                                } else {
                                    set did_it_p 0
                                }
                                aa_equals "'${type_id}' with attribute '${sub_type_id}' (sub_f_id '$asset_arr(sub_f_id)')" $did_it_p $allowed_p
                                array unset asset_arr sub_f_id
                                ns_log Notice "hosting-farm-test-perms-procs.tcl.107: done trying sub_type_id '${sub_type_id}' attribute on type_id '${type_id}' '$asset_arr(f_id)'"
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

