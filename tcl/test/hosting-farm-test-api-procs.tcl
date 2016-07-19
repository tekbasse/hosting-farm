ad_library {
    Automated tests for hosting-farm
    @creation-date 2015-03-19
}

aa_register_case -cats {api smoke} assets_sys_lifecycle_api_check {
    Test assets and attributes api through system lifecycle simmulation
} {
    aa_run_with_teardown \
        -test_code {
            #        -rollback
            ns_log Notice "aa_register_case.12: Begin test assets_sys_build_api_check"
            aa_log "0. Build 2 DCs with HW and some attributes"
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

            # + - + - + - # AUDIT CODE # + - + - + - #
            # audit initializations
            set hf_asset_type_id_list [lsort [hf_asset_type_id_list]]
            foreach a_type_id $hf_asset_type_id_list {
                set audit_zero_arr(${a_type_id}) 0
            }
            # db accounting
            array set audit_arm_arr [array get audit_zero_arr]
            array set audit_sam_arr [array get audit_zero_arr]
            array set audit_ast_arr [array get audit_zero_arr]


            # direct accounting
            array set audit_ac_arr [array get audit_zero_arr]
            array set audit_atc_arr [array get audit_zero_arr]

            # get pre-db mod table counts
            # assets (from hf_asset_rev_map)
            db_1row hf_arm_recs_count { select count(*) as hf_arm_count_0 from hf_asset_rev_map where trashed_p!='1' }
            set audit_arm_d_lists [db_list_of_lists hf_audit_asset_type_id_arm0 { select asset_type_id, count(*) as ct from hf_assets where f_id in ( select f_id from hf_asset_rev_map where trashed_p!='1') group by asset_type_id } ]
            set audit_arm_d_list [list ]
            foreach row $audit_arm_d_lists {
                foreach element $row {
                    lappend audit_arm_d_list $element
                }
            }
            array set audit_arm_d_arr [array get audit_zero_arr]
            array set audit_arm_d_arr $audit_arm_d_list
            # asset revisions (from hf_assets)
            db_1row hf_ast_recs_count { select count(*) as hf_ast_count_0 from hf_assets where trashed_p!='1' }
            set audit_ast_d_lists [db_list_of_lists hf_audit_asset_type_id_a0 { select asset_type_id, count(*) as ct from hf_assets group by asset_type_id }]
            set audit_ast_d_list [list ]
            foreach row $audit_ast_d_lists {
                foreach element $row {
                    lappend audit_ast_d_list $element
                }
            }
            array set audit_ast_d_arr [array get audit_zero_arr]
            array set audit_ast_d_arr $audit_ast_d_list
            # attributes (from hf_sub_asset_map)
            db_1row hf_sam_recs_count { select count(*) as hf_sam_count_0 from hf_sub_asset_map where trashed_p!='1' }
            set audit_sam_d_lists [db_list_of_lists hf_audit_asset_type_id_sam0 { select sub_type_id, count(*) as ct from hf_sub_asset_map where trashed_p!='1' and attribute_p!='0' group by sub_type_id }]
            set audit_sam_d_list [list ]
            foreach row $audit_sam_d_lists {
                foreach element $row {
                    lappend audit_sam_d_list $element
                }
            }
            array set audit_sam_d_arr [array get audit_zero_arr]
            array set audit_sam_d_arr $audit_sam_d_list



            # os inits
            set osc 0
            set os_id_list [list ]
            while { $osc < 5 } {
                set randlabel [qal_namelur 1 2 "-"]
                set brand [qal_namelur 1 3 ""]
                set kernel "${brand}-${osc}"
                set title [apm_instance_name_from_id $instance_id]
                set version "${osc}.[randomRange 100].[randomRange 100]"

                # Add an os record
                array set os_arr [list \
                                      instance_id $instance_id \
                                      label $randlabel \
                                      brand $brand \
                                      version $version \
                                      kernel $kernel ]
                set os_arr(os_id) [hf_os_write os_arr]
                lappend os_id_list $os_arr(os_id)

                set os_larr(${osc}) [array get os_arr]
                array unset os_arr
                ns_log Notice "hosting-farm-test-api-procs.tcl.76: osc ${osc}"
                incr osc
            }
            incr osc -1
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

            # ac = asset count
            # audit_atc_arr(dc), atc3, atc4, audit_atc_arr(ua) = attribute counts
            # audit_atc_arr(dc) = dc primary attribute count
            # audit_atc_arr(ip) = ip attribute counts
            # audit_atc_arr(ni) = ni attribute counts
            # audit_atc_arr(ua) = ns + ua attribute counts
            # ss_tc

            set ac 0
            # atc# = attribute counter

            set domain [hf_domain_example]
            set asset_type_id "dc"
            array set asset_arr [list \
                                     asset_type_id ${asset_type_id} \
                                     label $domain \
                                     name "${domain} test ${asset_type_id} $ac" \
                                     user_id $sysowner_user_id ]
            set asset_arr(f_id) [hf_asset_create asset_arr ]
            incr ac
            incr audit_ac_arr(dc)
            set dci(0) $asset_arr(f_id)
            #ns_log Notice "hosting-farm-test-api-procs.tcl.113: asset_arr(label) $asset_arr(label)"
            array set asset_arr [list \
                                     affix [ad_generate_random_string] \
                                     description "[string toupper ${asset_type_id}]${ac}" \
                                     details "This is for api test"]
            #ns_log Notice "hosting-farm-test-api-procs.tcl.119: asset_arr(label) $asset_arr(label)"
            set asset_arr(dc_id) [hf_dc_write asset_arr]
            incr audit_atc_arr(dc)
            array unset asset_arr
            #ns_log Notice "hosting-farm-test-api-procs.tcl.116: dci(0) '$dci(0)'"



            set domain [hf_domain_example]
            set asset_type_id "dc"
            array set asset_arr [list \
                                     asset_type_id ${asset_type_id} \
                                     label $domain \
                                     name "${domain} test ${asset_type_id} $ac" \
                                     user_id $sysowner_user_id ]
            set asset_arr(f_id) [hf_asset_create asset_arr ]
            incr ac
            incr audit_ac_arr(dc)
            set dci(1) $asset_arr(f_id)
            array set asset_arr [list \
                                     affix [ad_generate_random_string] \
                                     description "[string toupper ${asset_type_id}]${ac}" \
                                     details "This is for api test"]
            set asset_arr(dc_id) [hf_dc_write asset_arr]
            incr audit_atc_arr(dc)
            array unset asset_arr
            #ns_log Notice "hosting-farm-test-api-procs.tcl.116: dci(1) '$dci(1)'"


            while { $ac < 15 } {

                # create hw asset
                set backup_sys [qal_namelur 1 2 ""]
                set asset_type_id "hw"
                set randlabel "${asset_type_id}-${backup_sys}-[qal_namelur 1 3 "-"]"
                array set asset_arr [list \
                                         asset_type_id ${asset_type_id} \
                                         label $randlabel \
                                         name "${randlabel} test ${asset_type_id} $ac" \
                                         user_id $sysowner_user_id ]
                set asset_arr(f_id) [hf_asset_create asset_arr ]
                incr ac
                incr audit_ac_arr(hw)


                # Add to dc. hf_asset hierarchy is added manually
                set dc_ref [expr { round( fmod( $ac , 2 ) ) } ]
                set dcn $dci(${dc_ref})
                hf_sub_asset_map_update $dcn dc $randlabel $asset_arr(f_id) hw 0
                #ns_log Notice "hosting-farm-test-api-procs.tcl.182: dc_ref $dc_ref"
                lappend hw_id_larr(${dc_ref}) $asset_arr(f_id)

                # add hw primary attribute
                array set asset_arr [list \
                                         sub_label $asset_arr(label) \
                                         system_name [ad_generate_random_string] \
                                         backup_sys $backup_sys \
                                         os_id [randomRange $osc] \
                                         description "[string toupper ${asset_type_id}]${ac}" \
                                         details "This is for api test"]
                set asset_arr(hw_id) [hf_hw_write asset_arr]
                incr audit_atc_arr(hw)




                # add ip
                set ipv6_suffix [expr { $audit_atc_arr(ip) + 7334 } ]
                array set ip_arr [list \
                                      f_id $asset_arr(f_id) \
                                      sub_label "eth0" \
                                      ip_id "" \
                                      ipv4_addr "198.51.100.$audit_atc_arr(ip)" \
                                      ipv4_status "1" \
                                      ipv6_addr "2001:0db8:85a3:0000:0000:8a2e:0370:${ipv6_suffix}" \
                                      ipv6_status "1"]
                set ip_arr(ip_id) [hf_ip_write ip_arr]
                incr audit_atc_arr(ip)
                # delayed unset ip_arr. See below



                # add ni
                set i_list [list 0 1]
                for {set i 0} {$i < 4} {incr i} {
                    lappend i_list [format %x [randomRange 255]]
                }
                set biamac [join $i_list ":"]
                array set ni_arr [list \
                                      f_id $asset_arr(f_id) \
                                      sub_label "NIC-$audit_atc_arr(ni)" \
                                      os_dev_ref "io1" \
                                      bia_mac_address ${biamac} \
                                      ul_mac_address "" \
                                      ipv4_addr_range "198.51.100.0/24" \
                                      ipv6_addr_range "2001:db8:1234::/48" ]
                set ni_arr(ni_id) [hf_ni_write ni_arr]
                incr audit_atc_arr(ni)
                array unset ni_arr


                # add a ns
                array set ns_arr [list \
                                      f_id $asset_arr(f_id) \
                                      active_p "0" \
                                      name_record "${domain}. A $ip_arr(ipv4_addr)" ]
                set ns_arr(ns_id) [hf_ns_write ns_arr]
                incr audit_atc_arr(ns)
                array unset ns_arr
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
                incr audit_atc_arr(ua)
                array unset ua_arr


                array set ua_arr [list \
                                      f_id $asset_arr(f_id) \
                                      ua "user2" \
                                      connection_type "https" \
                                      ua_id "" \
                                      up "test" ]
                set ua_arr(ua_id) [hf_user_add ua_arr]
                incr audit_atc_arr(ua)
                array unset ua_arr


                #ns_log Notice "hosting-farm-test-api-procs.tcl.237: ac ${ac}"
                array unset asset_arr

            }


            # + - + - + - # AUDIT CODE # + - + - + - #
            # test api info results against creation data
            #
            set dc0_f_id_list [hf_asset_subassets_cascade $dci(0)]
            set dc0_f_id_list_len [llength $dc0_f_id_list]
            set dc1_f_id_list [hf_asset_subassets_cascade $dci(1)]
            set dc1_f_id_list_len [llength $dc1_f_id_list]
            set asset_tot [expr { $dc0_f_id_list_len + $dc1_f_id_list_len } ]
            #ns_log Notice "hosting-farm-test-api-procs.tcl.260: $dc0_f_id_list_len + $dc1_f_id_list_len = $asset_tot"
            #ns_log Notice "hosting-farm-test-api-procs.tcl.261: dc0_f_id_list '${dc0_f_id_list}' dc1_f_id_list '${dc1_f_id_list}'"
            aa_equals "Assets total created" $asset_tot $ac

            #ns_log Notice "hosting-farm-test-api-procs.tcl.311: '[array get audit_assets_0_arr]'"
            #ns_log Notice "hosting-farm-test-api-procs.tcl.312: atc dc $audit_atc_arr(dc) hw $audit_atc_arr(hw) vm $audit_atc_arr(vm) vh $audit_atc_arr(vh) ip $audit_atc_arr(ip) ni $audit_atc_arr(ni) ua $audit_atc_arr(ua) ss $audit_atc_arr(ss) ns $audit_atc_arr(ns)"
            set atcn [expr { $audit_atc_arr(dc) + $audit_atc_arr(hw) + $audit_atc_arr(vh) + $audit_atc_arr(vm) + $audit_atc_arr(ip) + $audit_atc_arr(ni) + $audit_atc_arr(ua) + $audit_atc_arr(ss) + $audit_atc_arr(ns) } ]
            set dc0_sub_f_id_list [hf_asset_attributes_cascade $dci(0)]
            set dc1_sub_f_id_list [hf_asset_attributes_cascade $dci(1)]
            set dc0_sub_f_id_list_len [llength $dc0_sub_f_id_list]
            set dc1_sub_f_id_list_len [llength $dc1_sub_f_id_list]
            set attr_tot 0
            foreach f_id $dc0_f_id_list {
                set f_id_list [hf_asset_attributes_cascade $f_id]
                set f_id_list_len [llength $f_id_list]
                incr attr_tot $f_id_list_len
            }
            foreach f_id $dc1_f_id_list {
                set f_id_list [hf_asset_attributes_cascade $f_id]
                set f_id_list_len [llength $f_id_list]
                incr attr_tot $f_id_list_len
            }
            #ns_log Notice "hosting-farm-test-api-procs.tcl.262: $dc0_sub_f_id_list_len + $dc1_sub_f_id_list_len = $attr_tot"
            #ns_log Notice "hosting-farm-test-api-procs.tcl.263: dc0_sub_f_id_list '${dc0_sub_f_id_list}' dc1_sub_f_id_list '${dc1_sub_f_id_list}'"
            aa_equals "Attributes total created" $attr_tot $atcn


            # + - + - + - # AUDIT CODE # + - + - + - #
            # assets (from hf_asset_rev_map)
            db_1row hf_arm_recs_count { select count(*) as hf_arm_count_0 from hf_asset_rev_map where trashed_p!='1' }
            set audit_arm_0_lists [db_list_of_lists hf_audit_asset_type_id_arm0 { select asset_type_id, count(*) as ct from hf_assets where f_id in ( select f_id from hf_asset_rev_map where trashed_p!='1') group by asset_type_id } ]
            foreach row $audit_arm_0_lists {
                foreach element $row {
                    lappend audit_arm_0_list $element
                }
            }
            array set audit_arm_0_arr [array get audit_zero_arr]
            array set audit_arm_0_arr $audit_arm_0_list
            foreach i $hf_asset_type_id_list {
                set audit_arm_0_arr($i) [expr { $audit_arm_0_arr($i) - $audit_arm_d_arr($i) } ]
                aa_equals "0. Asset revisions $i created" $audit_arm_0_arr($i) $audit_ac_arr($i)
            }
            # asset revisions (from hf_assets)
            db_1row hf_ast_recs_count { select count(*) as hf_ast_count_0 from hf_assets where trashed_p!='1' }
            set audit_ast_0_lists [db_list_of_lists hf_audit_asset_type_id_a0 { select asset_type_id, count(*) as ct from hf_assets group by asset_type_id }]
            foreach row $audit_ast_0_lists {
                foreach element $row {
                    lappend audit_ast_0_list $element
                }
            }
            array set audit_ast_0_arr [array get audit_zero_arr]
            array set audit_ast_0_arr $audit_ast_0_list
            foreach i $hf_asset_type_id_list {
                set audit_ast_0_arr($i) [expr { $audit_ast_0_arr($i) - $audit_ast_d_arr($i) } ]
                aa_equals "0. Assets $i created" $audit_ast_0_arr($i) $audit_ac_arr($i)
            }
            # attributes (from hf_sub_asset_map)
            db_1row hf_sam_recs_count { select count(*) as hf_sam_count_0 from hf_sub_asset_map where trashed_p!='1' }
            set audit_sam_0_lists [db_list_of_lists hf_audit_asset_type_id_sam0 { select sub_type_id, count(*) as ct from hf_sub_asset_map where trashed_p!='1' and attribute_p!='0' group by sub_type_id }]
            foreach row $audit_sam_0_lists {
                foreach element $row {
                    lappend audit_sam_0_list $element
                }
            }
            array set audit_sam_0_arr [array get audit_zero_arr]
            array set audit_sam_0_arr $audit_sam_0_list
            foreach i $hf_asset_type_id_list {
                set audit_sam_0_arr($i) [expr { $audit_sam_0_arr($i) - $audit_sam_d_arr($i) } ]
                aa_equals "0. Attributes $i created" $audit_sam_0_arr($i) $audit_atc_arr($i)
            }



            #
            # populate data
            #

            #ns_log Notice "aa_register_case.327: Begin test assets_sys_populate_api_check"
            aa_log "1. Test populate 2 DCs with HW and some attributes"
            # dc asset_id dci(0) dci(1)
            # dc hardware
            # dc0_f_id_list
            # dc1_f_id_list

            # add  business cases
            # some vm, multiple vh on vm, ss on vh, ss on vm, ua on each
            # ss asset (db, wiki server, asterix for example) with multiple ua
            # vh asset as basic services, ua on each
            # hw asset as co-location,  rasberry pi, linux box,
            set hw_asset_id_list [concat $hw_id_larr(0) $hw_id_larr(1) ]
            foreach hw_asset_id $hw_asset_id_list {
                set dice [randomRange 11]
                ns_log Notice "hosting-farm-test-api-procs.tcl: starting switch '${dice}'"
                switch -glob -- $dice {
                    0 {

                        # add vm asset + ua
                        set domain [hf_domain_example]
                        set asset_type_id "vm"
                        array set asset_arr [list \
                                                 asset_type_id ${asset_type_id} \
                                                 label $domain \
                                                 name "${domain} ${asset_type_id} asset + ua" \
                                                 user_id $sysowner_user_id ]
                        set asset_arr(f_id) [hf_asset_create asset_arr ]
                        if { $asset_arr(f_id) > 0 } {
                            incr ac
                            incr audit_ac_arr(vm)

                            hf_sub_asset_map_update $hw_asset_id hw $asset_arr(label) $asset_arr(f_id) $asset_type_id 0

                            array set asset_arr [list \
                                                     domain_name $domain \
                                                     os_id [randomRange $osc] \
                                                     server_type "standard" \
                                                     resource_path "/var/www/${domain}" \
                                                     mount_union "0" \
                                                     details "generated by hosting-farm-test-api-procs.tcl" ]
                            set asset_arr(vm_id) [hf_vm_write asset_arr]
                            incr audit_atc_arr(vm)

                            array set ua_arr [list \
                                                  f_id $asset_arr(f_id) \
                                                  ua "user1" \
                                                  up [ad_generate_random_string]]
                            set ua_arr(ua_id) [hf_user_add ua_arr]
                            incr audit_atc_arr(ua)
                            array unset ua_arr

                        } else {
                            ns_log Warning "hosting-farm-test-api-procs.tcl dice= 0 failed to create asset."
                        }

                        array unset asset_arr
                    }
                    1 {

                        # add vm asset with multiple vh + ua
                        # add vm asset + ua
                        set domain [hf_domain_example]
                        set asset_type_id "vm"
                        array set asset_arr [list \
                                                 asset_type_id ${asset_type_id} \
                                                 label $domain \
                                                 name "${domain} ${asset_type_id} asset + ua" \
                                                 user_id $sysowner_user_id ]
                        set asset_arr(f_id) [hf_asset_create asset_arr ]
                        if { $asset_arr(f_id) > 0 } {
                            incr ac
                            incr audit_ac_arr(vm)

                            # link asset to hw_id
                            hf_sub_asset_map_update $hw_asset_id hw $asset_arr(label) $asset_arr(f_id) $asset_type_id 0

                            array set asset_arr [list \
                                                     domain_name $domain \
                                                     os_id [randomRange $osc] \
                                                     server_type "standard" \
                                                     resource_path "/var/www/${domain}" \
                                                     mount_union "0" \
                                                     details "generated by hosting-farm-test-api-procs.tcl" ]
                            set asset_arr(vm_id) [hf_vm_write asset_arr]
                            incr audit_atc_arr(vm)

                            set user_count [expr { [randomRange 5] + 1 } ]
                            for { set i 0} {$i < $user_count} {incr i} {
                                array set ua_arr [list \
                                                      f_id $asset_arr(f_id) \
                                                      ua "user${i}" \
                                                      up [ad_generate_random_string]]
                                set ua_arr(ua_id) [hf_user_add ua_arr]
                                incr audit_atc_arr(ua)
                                array unset ua_arr
                            }
                          array unset asset_arr
                        } else {
                            ns_log Warning "hosting-farm-test-api-procs.tcl dice= 1 failed to create asset."
                        }
                    }
                    2 {

                        # add vh asset + ua to a vm attribute + ua
                        set domain [hf_domain_example]
                        set asset_type_id "vm"
                        array set asset_arr [list \
                                                 asset_type_id ${asset_type_id} \
                                                 label $domain \
                                                 name "${domain} ${asset_type_id} asset + ua" \
                                                 user_id $sysowner_user_id ]
                        set asset_arr(f_id) [hf_asset_create asset_arr ]
                        if { $asset_arr(f_id) > 0 } {
                            incr ac
                            incr audit_ac_arr(vm)

                            # link asset to hw_id
                            hf_sub_asset_map_update $hw_asset_id hw $asset_arr(label) $asset_arr(f_id) $asset_type_id 0

                            array set asset_arr [list \
                                                     domain_name $domain \
                                                     os_id [randomRange $osc] \
                                                     server_type "standard" \
                                                     resource_path "/var/www/${domain}" \
                                                     mount_union "1" \
                                                     details "dice= 2, generated by hosting-farm-test-api-procs.tcl" ]
                            set asset_arr(vm_id) [hf_vm_write asset_arr]
                            incr audit_atc_arr(vm)

                            array set ua_arr [list \
                                                  f_id $asset_arr(f_id) \
                                                  ua "user1" \
                                                  up [ad_generate_random_string]]
                            set ua_arr(ua_id) [hf_user_add ua_arr]
                            incr audit_atc_arr(ua)
                            array unset ua_arr

                            # add vh asset + ua
                            # First, create vh asset
                            set randlabel [hf_domain_example]
                            set asset_type_id "vh"
                            array set vh_arr [list \
                                                  asset_type_id ${asset_type_id} \
                                                  label $randlabel \
                                                  name "${randlabel} test ${asset_type_id} $ac" \
                                                  user_id $sysowner_user_id ]
                            set vh_arr(f_id) [hf_asset_create vh_arr ]
                            if { $vh_arr(f_id) > 0 } {
                                incr ac
                                incr audit_ac_arr(vh)

                                array set vh_arr [list \
                                                      domain_name $randlabel \
                                                      details "dice= 2, generated by hosting-farm-test-api-procs.tcl" ]
                                set vh_arr(vh_id) [hf_vh_write vh_arr ]
                                incr audit_atc_arr(vh)

                                # link assets
                                hf_sub_asset_map_update $asset_arr(f_id) vm $vh_arr(label) $vh_arr(f_id) vh 0

                                array set ua_arr [list \
                                                      f_id $vh_arr(f_id) \
                                                      ua "user1" \
                                                      up [ad_generate_random_string]]
                                set ua_arr(ua_id) [hf_user_add ua_arr]
                                incr audit_atc_arr(ua)
                                array unset ua_arr
                            } else {
                                ns_log Warning "hosting-farm-test-api-procs.tcl dice= 2b failed to create asset."
                            }

                          array unset vh_arr

                        } else {
                            ns_log Warning "hosting-farm-test-api-procs.tcl dice= 2 failed to create asset."
                        }
                      array unset asset_arr
                    }
                    3 {

                        # add ss + ua asset to a vh attribute + ua

                        # First, create vh attribute
                        set randlabel [hf_domain_example]
                        set asset_type_id "vh"

                        array set vh_arr [list \
                                              f_id $hw_asset_id \
                                              domain_name $randlabel \
                                              details "dice= 2, generated by hosting-farm-test-api-procs.tcl" ]
                        set vh_arr(vh_id) [hf_vh_write vh_arr ]
                        incr audit_atc_arr(vh)

                        array set ua_arr [list \
                                              f_id $vh_arr(f_id) \
                                              ua "user1" \
                                              up [ad_generate_random_string]]
                        set ua_arr(ua_id) [hf_user_add ua_arr]
                        incr audit_atc_arr(ua)
                        array unset ua_arr

                        # create ss and ua asset
                        array set ss_arr [array get vh_arr]
                        set ss_arr(asset_type_id) "ss"
                        append ss_arr(label) "-gold"
                        set ss_arr(f_id) [hf_asset_create ss_arr]
                        if { $ss_arr(f_id) > 0 } {
                            incr ac
                            incr audit_ac_arr(ss)

                            # link asset to vh_id
                            hf_sub_asset_map_update $vh_arr(vh_id) vh $ss_arr(label) $ss_arr(f_id) ss 0

                            array set ss_arr [list \
                                                  server_name $ss_arr(label) \
                                                  service_name "gold" \
                                                  daemon_ref "au" \
                                                  protocol "http/2" \
                                                  port [randomRange 65535] \
                                                  ss_type "gold type" \
                                                  ss_subtype "198" \
                                                  ss_undersubtype "+1" \
                                                  ss_ultrasubtype "1337K" \
                                                  config_uri "/usr/etc/au.conf" \
                                                  memory_bytes "65535" ]
                            set ss_arr(ss_id) [hf_ss_write ss_arr]
                            incr audit_atc_arr(ss)


                            array set ua_arr [list \
                                                  f_id $ss_arr(ss_id) \
                                                  ua "user1" \
                                                  up [ad_generate_random_string]]
                            set ua_arr(ua_id) [hf_user_add ua_arr]
                            incr audit_atc_arr(ua)

                            array unset ua_arr

                        } else {
                            ns_log Warning "hosting-farm-test-api-procs.tcl dice= 3 failed to create asset."
                        }
                        array unset ss_arr
                        array unset vh_arr
                    }
                    4 {

                        # add ss + ua attribute to a vm
                        set domain [hf_domain_example]
                        set asset_type_id "vm"
                        array set asset_arr [list \
                                                 asset_type_id ${asset_type_id} \
                                                 label $domain \
                                                 name "${domain} ${asset_type_id} asset + ua" \
                                                 user_id $sysowner_user_id ]
                        set asset_arr(f_id) [hf_asset_create asset_arr ]
                        if { $asset_arr(f_id) > 0 } {
                            incr ac
                            incr audit_ac_arr(vm)

                            # link asset to hw_id
                            hf_sub_asset_map_update $hw_asset_id hw $asset_arr(label) $asset_arr(f_id) $asset_type_id 0

                            array set asset_arr [list \
                                                     domain_name $domain \
                                                     os_id [randomRange $osc] \
                                                     server_type "standard" \
                                                     resource_path "/var/www/${domain}" \
                                                     mount_union "0" \
                                                     details "dice= 2, generated by hosting-farm-test-api-procs.tcl" ]
                            set asset_arr(vm_id) [hf_vm_write asset_arr]

                            array set ua_arr [list \
                                                  f_id $asset_arr(vm_id) \
                                                  ua "user1" \
                                                  up [ad_generate_random_string]]
                            set ua_arr(ua_id) [hf_user_add ua_arr]
                            incr audit_atc_arr(ua)
                            array unset ua_arr

                            array set ss_arr [list \
                                                  f_id $asset_arr(vm_id) \
                                                  server_name "db.server.local" \
                                                  service_name "fields" \
                                                  daemon_ref "wc" \
                                                  protocol "xml" \
                                                  port [randomRange 65535] \
                                                  ss_type "comedic" \
                                                  ss_subtype "tragedy" \
                                                  ss_undersubtype "electron" \
                                                  ss_ultrasubtype "proton" \
                                                  config_uri "/usr/etc/db.conf" \
                                                  memory_bytes "4294967295" ]
                            set ss_arr(ss_id) [hf_ss_write ss_arr]
                            incr audit_atc_arr(ss)

                            array set ua_arr [list \
                                                  f_id $ss_arr(ss_id) \
                                                  ua "db_user1" \
                                                  up [ad_generate_random_string]]
                            set ua_arr(ua_id) [hf_user_add ua_arr]

                            array unset ss_arr
                            array unset ua_arr

                        } else {
                            ns_log Warning "hosting-farm-test-api-procs.tcl dice= 4 failed to create asset."
                        }
                        array unset asset_arr
                    }
                    5 {

                        # add ss asset + ua*N (asterix, wiki, db)
                        set randlabel [hf_domain_example]
                        set randtype [lindex [list asterix wiki db crm] [randomRange 3]]
                        append randlabel - $randtype
                        set asset_type_id "ss"
                        array set ss_arr [list \
                                              asset_type_id ${asset_type_id} \
                                              label $randlabel \
                                              name "${randlabel} test ${asset_type_id} $ac" \
                                              user_id $sysowner_user_id ]
                        set ss_arr(f_id) [hf_asset_create ss_arr]
                        if { $ss_arr(f_id) > 0 } {
                            incr ac
                            incr audit_ac_arr(ss)

                            # link asset to hw_id
                            hf_sub_asset_map_update $hw_asset_id hw $ss_arr(label) $ss_arr(f_id) $asset_type_id 0

                            set rand [randomRange 65535]
                            set user_count [randomRange 25]
                            incr user_count 3
                            array set ss_arr [list \
                                                  server_name $ss_arr(label) \
                                                  service_name "club" \
                                                  daemon_ref ${randtype} \
                                                  protocol "http/1" \
                                                  port $rand \
                                                  ss_type "${randtype} type" \
                                                  ss_subtype $rand \
                                                  ss_undersubtype "+${user_count}" \
                                                  ss_ultrasubtype "super8" \
                                                  config_uri "/usr/etc/${randtype}.conf" \
                                                  memory_bytes $rand ]
                            set ss_arr(ss_id) [hf_ss_write ss_arr]
                            incr audit_atc_arr(ss)

                            for {set i 0} {$i < $user_count} {incr i} {
                                array set ua_arr [list \
                                                      f_id $ss_arr(ss_id) \
                                                      ua "user${i}" \
                                                      up [ad_generate_random_string]]
                                set ua_arr(ua_id) [hf_user_add ua_arr]
                                incr audit_atc_arr(ua)
                                array unset ua_arr
                            }

                        } else {
                            ns_log Warning "hosting-farm-test-api-procs.tcl dice= 5 failed to create asset."
                        }
                        array unset ss_arr
                    }
                    6 - 7 - 8 {

                        # add hw asset + ua  as colo unit botbox etc.

                        set randlabel [hf_domain_example]
                        set randtype [lindex [list "botbox" "raspPi" "linuxBox" "BSDbox" "blackbox" "arduino"] [randomRange 5]]
                        append randlabel - $randtype
                        set asset_type_id "hw"
                        array set hw_arr [list \
                                              asset_type_id ${asset_type_id} \
                                              label $randlabel \
                                              name "${randlabel} test ${asset_type_id} $ac" \
                                              user_id $sysowner_user_id ]
                        set hw_arr(f_id) [hf_asset_create hw_arr]
                        if { $hw_arr(f_id) > 0 } {
                            incr ac
                            incr audit_ac_arr(hw)

                            #ns_log Notice "hosting-farm-test-api-procs.tcl.781 hw_arr(f_id) $hw_arr(f_id) hw_arr(label) $hw_arr(label)"
                            # link asset to hw_id
                            hf_sub_asset_map_update $hw_asset_id hw $hw_arr(label) $hw_arr(f_id) hw 0

                            # add hw primary attribute
                            array set hw_arr [list \
                                                  sub_label $hw_arr(label) \
                                                  system_name [ad_generate_random_string] \
                                                  backup_sys "n/a" \
                                                  os_id [randomRange $osc] \
                                                  description "[string toupper ${asset_type_id}]${ac}" \
                                                  details "This is for api test"]
                            set hw_arr(hw_id) [hf_hw_write hw_arr]
                            if { $hw_arr(hw_id) > 0 } {
                                incr audit_atc_arr(hw)
                            } else {
                                ns_log Warning "hosting-farm-test-api-procs.tcl.796: hf_hw_write failed"
                            }

                            # add ip
                            set ipn [expr { int( fmod( $audit_atc_arr(ip), 256) ) } ]
                            set ipn2 [expr { int( $audit_atc_arr(ip) / 256 ) } ]
                            set ipv6_suffix [format %x [expr { int( fmod( $audit_atc_arr(ip), 65535 ) ) } ]]
                            set hwf [format %x $audit_atc_arr(hw)]
                            array set ip_arr [list \
                                                  f_id $hw_arr(hw_id) \
                                                  sub_label "eth0" \
                                                  ip_id "" \
                                                  ipv4_addr "10.0.${ipn2}.${ipn}" \
                                                  ipv4_status "1" \
                                                  ipv6_addr "2001:0db8:85a3:0000:0000:8a2e:${hwf}:${ipv6_suffix}" \
                                                  ipv6_status "1"]
                            set ip_arr(ip_id) [hf_ip_write ip_arr]
                            # delayed unset ip_arr. See below
                            incr audit_atc_arr(ip)


                            # add ni
                            set i_list [list 0 ]
                            for {set i 0} {$i < 5} {incr i} {
                                lappend i_list [format %x [randomRange 255]]
                            }
                            set biamac [join $i_list ":"]

                            array set ni_arr [list \
                                                  f_id $hw_arr(hw_id) \
                                                  sub_label "NIC-$audit_atc_arr(ni)" \
                                                  os_dev_ref "io1" \
                                                  bia_mac_address ${biamac} \
                                                  ul_mac_address "" \
                                                  ipv4_addr_range "10.00.${ipn2}.0/3" \
                                                  ipv6_addr_range "2001:db8:1234::/3" ]
                            set ni_arr(ni_id) [hf_ni_write ni_arr]
                            incr audit_atc_arr(ni)
                            array unset ni_arr


                            # add a ns
                            array set ns_arr [list \
                                                  f_id $hw_arr(hw_id) \
                                                  active_p "0" \
                                                  name_record "${domain}. A $ip_arr(ipv4_addr)" ]
                            set ns_arr(ns_id) [hf_ns_write ns_arr]
                            incr audit_atc_arr(ns)
                            array unset ns_arr


                            # delayed unset ip_arr, so info could be used in ns_arr
                            array unset ip_arr

                            # add two ua
                            array set ua_arr [list \
                                                  f_id $hw_arr(hw_id) \
                                                  ua "user1" \
                                                  connection_type "https" \
                                                  ua_id "" \
                                                  up "test" ]
                            set ua_arr(ua_id) [hf_user_add ua_arr]
                            incr audit_atc_arr(ua)
                            array unset ua_arr


                            array set ua_arr [list \
                                                  f_id $hw_arr(hw_id) \
                                                  ua "user2" \
                                                  connection_type "https" \
                                                  ua_id "" \
                                                  up "test" ]
                            set ua_arr(ua_id) [hf_user_add ua_arr]
                            incr audit_atc_arr(ua)
                            array unset ua_arr

                        } else {
                            ns_log Warning "hosting-farm-test-api-procs.tcl dice= 6,7,8 failed to create asset."
                        }
                        array unset hw_arr
                    }
                    9 {

                        # add ss asset as killer app
                        set randlabel [hf_domain_example]
                        set randtype [lindex [list killer sage web blog ] [randomRange 3]]
                        append randlabel - $randtype
                        set asset_type_id "ss"
                        array set ss_arr [list \
                                              asset_type_id ${asset_type_id} \
                                              label $randlabel \
                                              name "${randlabel} test ${asset_type_id} $ac" \
                                              user_id $sysowner_user_id ]
                        set ss_arr(f_id) [hf_asset_create ss_arr]
                        if { $ss_arr(f_id) > 0 } {
                            incr ac
                            incr audit_ac_arr(ss)

                            # link asset to hw_id
                            hf_sub_asset_map_update $hw_asset_id hw $ss_arr(label) $ss_arr(f_id) $asset_type_id 0

                            set rand [randomRange 65535]
                            set user_count [randomRange 25]

                            array set ss_arr [list \
                                                  server_name $ss_arr(label) \
                                                  service_name "${randtype} app" \
                                                  daemon_ref ${randtype} \
                                                  protocol "http/3" \
                                                  port $rand \
                                                  ss_type "${randtype} type" \
                                                  ss_subtype NAFB \
                                                  ss_undersubtype "ColterStevens" \
                                                  ss_ultrasubtype "sourcecode" \
                                                  config_uri "/usr/etc/${randtype}.conf" \
                                                  memory_bytes "7:40A ORD" ]
                            set ss_arr(ss_id) [hf_ss_write ss_arr]
                            incr audit_atc_arr(ss)
                            array unset ss_arr

                        } else {
                            ns_log Warning "hosting-farm-test-api-procs.tcl dice= 9 failed to create asset."
                        }
                    }
                    10 {

                        # add hw network device to dc attr

                        set randlabel [hf_domain_example]
                        set randtype [lindex [list "dice=" "firewall" "fiber" "satlink" "laser" "cylon"] [randomRange 5]]
                        append randlabel - $randtype
                        set asset_type_id "hw"
                        set label $randtype
                        append randtype - $audit_atc_arr(hw)
                        # add hw primary attribute
                        array set attr_arr [list \
                                                f_id $hw_asset_id \
                                                type_id hw \
                                                sub_label $label \
                                                system_name [ad_generate_random_string] \
                                                backup_sys "n/a" \
                                                os_id [randomRange $osc] \
                                                description "[string toupper ${asset_type_id}]${ac}" \
                                                details "This is for api test"]
                        set attr_arr(f_id) [hf_hw_write attr_arr]
                        incr audit_atc_arr(hw)

                        # add ip
                        set ipn [expr { int( fmod( $audit_atc_arr(ip), 256) ) } ]
                        set ipn2 [expr { int( $audit_atc_arr(ip) / 256 ) } ]
                        set ipv6_suffix [format %x [expr { int( fmod( $audit_atc_arr(ip), 65535 ) ) } ]]
                        set hwf [format %x $audit_atc_arr(hw)]
                        array set ip_arr [list \
                                              f_id $attr_arr(f_id) \
                                              sub_label "eth20" \
                                              ip_id "" \
                                              ipv4_addr "10.0.${ipn2}.${ipn}" \
                                              ipv4_status "1" \
                                              ipv6_addr "2001:0db8:85a3:0000:0000:8a2e:${hwf}:${ipv6_suffix}" \
                                              ipv6_status "0"]
                        set ip_arr(ip_id) [hf_ip_write ip_arr]
                        incr audit_atc_arr(ip)
                        # delayed unset ip_arr. See below

                        # add ni
                        set i_list [list ]
                        for {set i 0} {$i < 6} {incr i} {
                            lappend i_list [format %x [randomRange 255]]
                        }
                        set biamac [join $i_list ":"]
                        array set ni_arr [list \
                                              f_id $attr_arr(f_id) \
                                              sub_label "NIC-$audit_atc_arr(ni)" \
                                              os_dev_ref "io1" \
                                              bia_mac_address ${biamac} \
                                              ul_mac_address "" \
                                              ipv4_addr_range "10.00.${ipn2}.0/3" \
                                              ipv6_addr_range "2001:db8:1234::/3" ]
                        set ni_arr(ni_id) [hf_ni_write ni_arr]
                        incr audit_atc_arr(ni)
                        array unset ni_arr


                        # add a ns
                        array set ns_arr [list \
                                              f_id $attr_arr(f_id) \
                                              active_p "0" \
                                              name_record "${domain}. A $ip_arr(ipv4_addr)" ]
                        set ns_arr(ns_id) [hf_ns_write ns_arr]
                        incr audit_atc_arr(ns)
                        array unset ns_arr


                        # delayed unset ip_arr, so info could be used in ns_arr
                        array unset ip_arr

                        # add two ua
                        array set ua_arr [list \
                                              f_id $attr_arr(f_id) \
                                              ua "user1" \
                                              connection_type "https" \
                                              ua_id "" \
                                              up "test" ]
                        set ua_arr(ua_id) [hf_user_add ua_arr]
                        incr audit_atc_arr(ua)
                        array unset ua_arr

                        array set ua_arr [list \
                                              f_id $attr_arr(f_id) \
                                              ua "user2" \
                                              connection_type "https" \
                                              ua_id "" \
                                              up "test" ]
                        set ua_arr(ua_id) [hf_user_add ua_arr]
                        incr audit_atc_arr(ua)
                        array unset ua_arr

                        array unset attr_arr

                    }
                    11 {

                        # add a vm attr + 1000 ua assets + multiple ns to ua Think domain leasing service
                        set domain [hf_domain_example]
                        set asset_type_id "vm"

                        array set asset_arr [list \
                                                 f_id $hw_asset_id \
                                                 type_id hw \
                                                 domain_name $domain \
                                                 os_id [randomRange $osc] \
                                                 server_type "domainleasing" \
                                                 resource_path "/var/www/${domain}" \
                                                 mount_union "0" \
                                                 details "dice= 11, generated by hosting-farm-test-api-procs.tcl" ]
                        set asset_arr(vm_id) [hf_vm_write asset_arr]

                        incr audit_atc_arr(vm)


                        set asset_type_id "ua"
                        set i_count [randomRange 200]
                        incr $i_count 100
                        for {set i 0} {$i < $i_count} {incr i} {
                            array set ua_arr [list \
                                                  asset_type_id ${asset_type_id} \
                                                  label $randlabel \
                                                  name "${randlabel} test dice= 11 ${asset_type_id} $ac" \
                                                  user_id $sysowner_user_id ]
                            set ua_arr(f_id) [hf_asset_create ua_arr]
                            if { $ua_arr(f_id) > 0 } {
                                incr ac
                                incr audit_ac_arr(ua)

                                # link asset to hw_id
                                #hf_sub_asset_map_update $hw_asset_id hw $ua_arr(label) $ua_arr(f_id) $asset_type_id 0
                                # link asset to vm_id
                                hf_sub_asset_map_update $asset_arr(vm_id) vm $ua_arr(label) $ua_arr(f_id) $asset_type_id 0

                                array set ua_arr [list \
                                                      f_id $ua_arr(f_id) \
                                                      ua "user${i}" \
                                                      up [ad_generate_random_string]]
                                set ua_arr(ua_id) [hf_user_add ua_arr]
                                incr audit_atc_arr(ua)

                                set j_count [randomRange 200]
                                incr $j_count 100
                                for {set j 0} {$j < $j_count} {incr j} {

                                    # add a ns
                                    set domain [hf_domain_example]
                                    set ipn [expr { int( fmod( $audit_atc_arr(ua), 256) ) } ]
                                    set ipn2 [expr { int( $audit_atc_arr(ua) / 256 ) } ]
                                    set ipv4_addr "10.0.${ipn2}.${ipn}"
                                    array set ns_arr [list \
                                                          f_id $ua_arr(f_id) \
                                                          active_p "0" \
                                                          name_record "${domain}. A ${ipv4_addr}" ]
                                    set ns_arr(ns_id) [hf_ns_write ns_arr]
                                    incr audit_atc_arr(ns)
                                    array unset ns_arr
                                    
                                }
                            } else {
                                ns_log Warning "hosting-farm-test-api-procs.tcl dice= 11 failed to create asset."
                            }
                            array unset ua_arr
                        }
                        array unset asset_arr
                    }
                }
                ns_log Notice "hosting-farm-test-api-procs.tcl: end switch '${dice}'"
                #end switch
            }
            # end foreach

            # + - + - + - # AUDIT CODE # + - + - + - #
            # assets (from hf_asset_rev_map)
            db_1row hf_arm_recs_count { select count(*) as hf_arm_count_1 from hf_asset_rev_map where trashed_p!='1' }
            set audit_arm_1_lists [db_list_of_lists hf_audit_asset_type_id_arm0 { select asset_type_id, count(*) as ct from hf_assets where f_id in ( select f_id from hf_asset_rev_map where trashed_p!='1') group by asset_type_id } ]
            foreach row $audit_arm_1_lists {
                foreach element $row {
                    lappend audit_arm_1_list $element
                }
            }
            array set audit_arm_1_arr [array get audit_zero_arr]
            array set audit_arm_1_arr $audit_arm_1_list
            foreach i $hf_asset_type_id_list {
                set audit_arm_1_arr($i) [expr { $audit_arm_1_arr($i) - $audit_arm_d_arr($i) } ]
                aa_equals "1. Asset revisions $i created" $audit_arm_1_arr($i) $audit_ac_arr($i)
            }
            # asset revisions (from hf_assets)
            db_1row hf_ast_recs_count { select count(*) as hf_ast_count_1 from hf_assets where trashed_p!='1' }
            set audit_ast_1_lists [db_list_of_lists hf_audit_asset_type_id_a0 { select asset_type_id, count(*) as ct from hf_assets group by asset_type_id }]
            foreach row $audit_ast_1_lists {
                foreach element $row {
                    lappend audit_ast_1_list $element
                }
            }
            array set audit_ast_1_arr [array get audit_zero_arr]
            array set audit_ast_1_arr $audit_ast_1_list
            foreach i $hf_asset_type_id_list {
                set audit_ast_1_arr($i) [expr { $audit_ast_1_arr($i) - $audit_ast_d_arr($i) } ]
                aa_equals "1. Assets $i created" $audit_ast_1_arr($i) $audit_ac_arr($i)
            }
            # attributes (from hf_sub_asset_map)
            db_1row hf_sam_recs_count { select count(*) as hf_sam_count_1 from hf_sub_asset_map where trashed_p!='1' and attribute_p!='0' }
            set audit_sam_1_lists [db_list_of_lists hf_audit_asset_type_id_sam0 { select sub_type_id, count(*) as ct from hf_sub_asset_map where trashed_p!='1' and attribute_p!='0' group by sub_type_id }]
            foreach row $audit_sam_1_lists {
                foreach element $row {
                    lappend audit_sam_1_list $element
                }
            }
            array set audit_sam_1_arr [array get audit_zero_arr]
            array set audit_sam_1_arr $audit_sam_1_list
            foreach i $hf_asset_type_id_list {
                set audit_sam_1_arr($i) [expr { $audit_sam_1_arr($i) - $audit_sam_d_arr($i) } ]
                aa_equals "1. Attributes $i created" $audit_sam_1_arr($i) $audit_atc_arr($i)
            }




            # evolve data

            ns_log Notice "aa_register_case.327: Begin test assets_sys_evolve_api_check"
            aa_log "2. Test evolve DC assets and attributes"

            # update ua of each
            # verify ua of each
            # update an ns
            # verify ns
            #
            # move vm from 1 to 2.
            # verify
            # move vh from 2 to 1
            # verify

            # + - + - + - # AUDIT CODE # + - + - + - #
            # assets (from hf_asset_rev_map)
            db_1row hf_arm_recs_count { select count(*) as hf_arm_count_2 from hf_asset_rev_map where trashed_p!='1' }
            set audit_arm_2_lists [db_list_of_lists hf_audit_asset_type_id_arm0 { select asset_type_id, count(*) as ct from hf_assets where f_id in ( select f_id from hf_asset_rev_map where trashed_p!='1') group by asset_type_id } ]
            foreach row $audit_arm_2_lists {
                foreach element $row {
                    lappend audit_arm_2_list $element
                }
            }
            array set audit_arm_2_arr [array get audit_zero_arr]
            array set audit_arm_2_arr $audit_arm_2_list
            foreach i $hf_asset_type_id_list {
                set audit_arm_2_arr($i) [expr { $audit_arm_2_arr($i) - $audit_arm_d_arr($i) } ]
                aa_equals "2. Asset revisions $i created" $audit_arm_2_arr($i) $audit_ac_arr($i)
            }
            # asset revisions (from hf_assets)
            db_1row hf_ast_recs_count { select count(*) as hf_ast_count_2 from hf_assets where trashed_p!='1' }
            set audit_ast_2_lists [db_list_of_lists hf_audit_asset_type_id_a0 { select asset_type_id, count(*) as ct from hf_assets group by asset_type_id }]
            foreach row $audit_ast_2_lists {
                foreach element $row {
                    lappend audit_ast_2_list $element
                }
            }
            array set audit_ast_2_arr [array get audit_zero_arr]
            array set audit_ast_2_arr $audit_ast_2_list
            foreach i $hf_asset_type_id_list {
                set audit_ast_2_arr($i) [expr { $audit_ast_2_arr($i) - $audit_ast_d_arr($i) } ]
                aa_equals "2. Assets $i created" $audit_ast_2_arr($i) $audit_ac_arr($i)
            }
            # attributes (from hf_sub_asset_map)
            db_1row hf_sam_recs_count { select count(*) as hf_sam_count_2 from hf_sub_asset_map where trashed_p!='1' and attribute_p!='0' }
            set audit_sam_2_lists [db_list_of_lists hf_audit_asset_type_id_sam0 { select sub_type_id, count(*) as ct from hf_sub_asset_map where trashed_p!='1' and attribute_p!='0' group by sub_type_id }]
            foreach row $audit_sam_2_lists {
                foreach element $row {
                    lappend audit_sam_2_list $element
                }
            }
            array set audit_sam_2_arr [array get audit_zero_arr]
            array set audit_sam_2_arr $audit_sam_2_list
            foreach i $hf_asset_type_id_list {
                set audit_sam_2_arr($i) [expr { $audit_sam_2_arr($i) - $audit_sam_d_arr($i) } ]
                aa_equals "2. Attributes $i created" $audit_sam_2_arr($i) $audit_atc_arr($i)
            }


            # system clear DCs


            ns_log Notice "aa_register_case.327: Begin test assets_sys_clear_api_check"
            aa_log "3. Clear 2 DCs of managed assets and attributes."

            # delete everything below a hw
            # verify

            # + - + - + - # AUDIT CODE # + - + - + - #
            # asset revisions (from hf_assets)
            db_1row hf_arm_recs_count { select count(*) as hf_arm_count_3 from hf_asset_rev_map where trashed_p!='1' }
            set audit_arm_3_lists [db_list_of_lists hf_audit_asset_type_id_arm0 { select asset_type_id, count(*) as ct from hf_assets where f_id in ( select f_id from hf_asset_rev_map where trashed_p!='1') group by asset_type_id } ]
            foreach row $audit_arm_3_lists {
                foreach element $row {
                    lappend audit_arm_3_list $element
                }
            }
            array set audit_arm_3_arr [array get audit_zero_arr]
            array set audit_arm_3_arr $audit_arm_3_list
            foreach i $hf_asset_type_id_list {
                set audit_arm_3_arr($i) [expr { $audit_arm_3_arr($i) - $audit_arm_d_arr($i) } ]
                aa_equals "3. Asset revisions $i created" $audit_arm_3_arr($i) $audit_ac_arr($i)
            }
            # assets (from hf_asset_rev_map)
            db_1row hf_ast_recs_count { select count(*) as hf_ast_count_3 from hf_assets where trashed_p!='1' }
            set audit_ast_3_lists [db_list_of_lists hf_audit_asset_type_id_a0 { select asset_type_id, count(*) as ct from hf_assets group by asset_type_id }]
            foreach row $audit_ast_3_lists {
                foreach element $row {
                    lappend audit_ast_3_list $element
                }
            }
            array set audit_ast_3_arr [array get audit_zero_arr]
            array set audit_ast_3_arr $audit_ast_3_list
            foreach i $hf_asset_type_id_list {
                set audit_ast_3_arr($i) [expr { $audit_ast_3_arr($i) - $audit_ast_d_arr($i) } ]
                aa_equals "3. Assets $i created" $audit_ast_3_arr($i) $audit_ac_arr($i)
            }
            # attributes (from hf_sub_asset_map)
            db_1row hf_sam_recs_count { select count(*) as hf_sam_count_3 from hf_sub_asset_map where trashed_p!='1' and attribute_p!='0' }
            set audit_sam_3_lists [db_list_of_lists hf_audit_asset_type_id_sam0 { select sub_type_id, count(*) as ct from hf_sub_asset_map where trashed_p!='1' and attribute_p!='0' group by sub_type_id }]
            foreach row $audit_sam_3_lists {
                foreach element $row {
                    lappend audit_sam_3_list $element
                }
            }
            array set audit_sam_3_arr [array get audit_zero_arr]
            array set audit_sam_3_arr $audit_sam_3_list
            foreach i $hf_asset_type_id_list {
                set audit_sam_3_arr($i) [expr { $audit_sam_3_arr($i) - $audit_sam_d_arr($i) } ]
                aa_equals "3. Attributes $i created" $audit_sam_3_arr($i) $audit_atc_arr($i)
            }
        }
}