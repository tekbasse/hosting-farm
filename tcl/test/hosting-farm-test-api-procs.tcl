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
            # We avoid hf_permission_p by using a sysadmin user
            # hf_roles_init $instance_id
            # hf_property_init $instance_id
            # hf_privilege_init $instance_id
            # hf_asset_type_id_init $instance_id
            
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
            #unset role_id
            #unset role
            #unset roles_lists

            # A user with sysadmin rights and not customer
            set sysowner_email [ad_system_owner]
            set sysowner_user_id [party::get_by_email -email $sysowner_email]
            set i [string first "@" $sysowner_email]
            if { $i > -1 } {
                set domain [string range $sysowner_email $i+1 end]
            } else {
                set domain [hf_domain_example]
            }
            

            # os inits
            set z2 0
            set os_id_list [list ]
            while { $z2 < 5 } {
                set randlabel [qal_namelur 1 2 "-"]
                set brand [qal_namelur 1 3 ""]
                set kernel "${brand}-${z2}"
                set title [apm_instance_name_from_id $instance_id]
                set version "${z2}.[randomRange 100].[randomRange 100]"
                
                # Add an os record
                array set os_arr [list \
                                      instance_id $instance_id \
                                      label $randlabel \
                                      brand $brand \
                                      version $version \
                                      kernel $kernel ]
                set os_arr(os_id) [hf_os_write os_arr]
                lappend os_id_list $os_arr(os_id)

                set b_larr(${z2}) [array get os_arr]
                array unset os_arr
                ns_log Notice "hosting-farm-test-api-procs.tcl.76: z2 ${z2}"
                incr z2
            }
            incr z2 -1
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

            set z 0

            set domain [hf_domain_example]
            set asset_type_id "dc"
            array set asset_arr [list \
                                     asset_type_id ${asset_type_id} \
                                     label $domain \
                                     name "${domain} test ${asset_type_id} $z" \
                                     user_id $sysowner_user_id ]
            set asset_arr(f_id) [hf_asset_create asset_arr ]
            array set asset_arr [list \
                                     affix [ad_generate_random_string] \
                                     description "[string toupper ${asset_type_id}]${z}" \
                                     details "This is for api test"]
            set asset_arr(${asset_type_id}_id) [hf_dc_write asset_arr]
            lappend type_larr(${asset_type_id}) $z
            set a_larr(${z}) [array get asset_arr]
            set dci(0) $asset_arr(f_id)
            ns_log Notice "hosting-farm-test-api-procs.tcl.116: dci(0) '$dci(0)'"
            array unset asset_arr
            incr z

            set domain [hf_domain_example]
            set asset_type_id "dc"
            array set asset_arr [list \
                                     asset_type_id ${asset_type_id} \
                                     label $domain \
                                     name "${domain} test ${asset_type_id} $z" \
                                     user_id $sysowner_user_id ]
            set asset_arr(f_id) [hf_asset_create asset_arr ]
            array set asset_arr [list \
                                     affix [ad_generate_random_string] \
                                     description "[string toupper ${asset_type_id}]${z}" \
                                     details "This is for api test"]
            set asset_arr(${asset_type_id}_id) [hf_dc_write asset_arr]
            lappend type_larr(${asset_type_id}) $z
            set a_larr(${z}) [array get asset_arr]
            set dci(1) $asset_arr(f_id)
            ns_log Notice "hosting-farm-test-api-procs.tcl.116: dci(0) '$dci(1)'"
            array unset asset_arr
            incr z
            set z3 0
            set z4 0
            set z5 0

            while { $z < 15 } {
                              

                set backup_sys [qal_namelur 1 2 ""]
                set randlabel "${backup_sys}-[qal_namelur 1 3 "-"]"
                set asset_type_id "hw"
                array set asset_arr [list \
                                         asset_type_id ${asset_type_id} \
                                         label $randlabel \
                                         name "${randlabel} test ${asset_type_id} $z" \
                                         user_id $sysowner_user_id ]
                set asset_arr(f_id) [hf_asset_create asset_arr ]
                # Add to dc. hf_asset hierarchy is added manually
                set dc_ref [expr { round( fmod( $z , 2 ) ) } ]
                hf_sub_asset_map_update $dci(${dc_ref}) dc $randlabel $asset_arr(f_id) hw 0
                array set asset_arr [list \
                                         system_name [ad_generate_random_string] \
                                         backup_sys $backup_sys \
                                         os_id [randomRange $z2] \
                                         description "[string toupper ${asset_type_id}]${z}" \
                                         details "This is for api test"]
                set asset_arr(${asset_type_id}_id) [hf_hw_write asset_arr]
                lappend type_larr(${asset_type_id}) $z
                set a_larr(${z}) [array get asset_arr]

                # add ip
                set ipv6_suffix [expr { $z3 + 7334 } ]
                array set ip_arr [list \
                                      f_id $asset_arr(f_id) \
                                      label "eth0" \
                                      ip_id "" \
                                      ipv4_addr "198.51.100.${z3}" \
                                      ipv4_status "1" \
                                      ipv6_addr "2001:0db8:85a3:0000:0000:8a2e:0370:${ipv6_suffix}" \
                                      ipv6_status "1"]
                set ip_arr(ip_id) [hf_ip_write ip_arr]
                lappend ip_id_list $ip_arr(ip_id)

                set c_larr(${z3}) [array get ip_arr]

                incr z3

                # add ni
                array set ni_arr [list \
                                      f_id $asset_arr(f_id) \
                                      label "NIC-${z3}" \
                                      os_dev_ref "io1" \
                                      bia_mac_address "00:1e:52:c6:3e:7a" \
                                      ul_mac_address "" \
                                      ipv4_addr_range "198.51.100.0/24" \
                                      ipv6_addr_range "2001:db8:1234::/48" ]
                set ni_arr(ni_id) [hf_ni_write ni_arr]
                lappend ni_id_list $ni_arr(ni_id)
                
                set c_larr(${z4}) [array get ni_arr]
                array unset ni_arr
                incr z4

                # add a ns
                array set ns_arr [list \
                                      f_id $asset_arr(f_id) \
                                      active_p "0" \
                                      name_record "${domain}. A $ip_arr(ipv4_addr)" ]
                set ns_arr(ns_id) [hf_ns_write ns_arr]
                lappend ns_id_list $ns_arr(ns_id)
                
                set c_larr(${z5}) [array get ns_arr]
                array unset ns_arr
                incr z5
                # delayed unset ip_arr, so info could be used in ns_arr
                array unset ip_arr

                # add two ua
                array set ua_arr [list \
                                      f_id $asset_arr(f_id) \
                                      ua "user1" \
                                      connection_type "https" \
                                      ua_id "" \
                                      up "test" ]
                set ua_arr(ua_id) [hf_user_add ua_arr]
                set d_larr(${z5}) [array get ua_arr]
                incr z5
                lappend ua_larr(${z}) $ua_arr(ua_id)

                array set ua_arr [list \
                                      f_id $asset_arr(f_id) \
                                      ua "user2" \
                                      connection_type "https" \
                                      ua_id "" \
                                      up "test" ]
                set ua_arr(ua_id) [hf_user_add ua_arr]
                set d_larr(${z5}) [array get ua_arr]
                lappend ua_larr(${z}) $ua_arr(ua_id)
                incr z5
                ns_log Notice "hosting-farm-test-api-procs.tcl.237: z ${z}"
                array unset asset_arr
                incr z


            }

            set dc0_f_id_list [hf_asset_subassets_cascade $dci(0)]
            set dc0_f_id_list_len [llength $dc0_f_id_list]
            set dc1_f_id_list [hf_asset_subassets_cascade $dci(1)]
            set dc1_f_id_list_len [llength $dc1_f_id_list]
            set asset_tot [expr { $dc0_f_id_list_len + $dc1_f_id_list_len } ]
            aa_equals "Assets total created" $z $asset_tot

            set zn [expr { $z3 + $z4 + $z5 } ]
            set dc0_sub_f_id_list [hf_asset_attributes_cascade $dci(0)]
            set dc0_sub_f_id_list_len [llength $dc0_f_id_list]
            set dc1_sub_f_id_list [hf_asset_attributes_cascade $dci(1)]
            set dc1_sub_f_id_list_len [llength $dc1_f_id_list]
            set attr_tot [expr { $dc0_sub_f_id_list_len + $dc1_sub_f_id_list_len } ]
            aa_equals "Attributes total created" $zn $attr_tot

            
        } \
        -teardown_code {
            # 
            #acs_user::delete -user_id $user1_arr(user_id) -permanent

        }
    #aa_true "Test for .." $passed_p
    #aa_equals "Test for .." $test_value $expected_value


}
