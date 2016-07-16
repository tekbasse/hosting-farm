ad_library {
    Automated tests for hosting-farm
    @creation-date 2015-03-19
}

aa_register_case -cats {api smoke} assets_sys_lifecycle_api_check {
    Test assets and attributes api through system lifecycle simmulation
} {
    aa_run_with_teardown \
        -test_code {
#        -rollback \
            ns_log Notice "aa_register_case.12: Begin test assets_sys_build_api_check"
            aa_log "Build 2 DCs with HW and some attributes"
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
            # dc_atc, atc3, atc4, ua_atc = attribute counts
            # dc_atc = dc primary attribute count
            # ip_atc = ip attribute counts
            # ni_atc = ni attribute counts
            # ua_atc = ns + ua attribute counts
            # ss_tc 

            set ac 0
            # atc# = attribute counter
            set dc_atc 0
            set hw_atc 0
            set vh_atc 0
            set vm_atc 0
            set ip_atc 0
            set ni_atc 0
            set ua_atc 0
            set ss_atc 0
            set ns_atc 0



            set domain [hf_domain_example]
            set asset_type_id "dc"
            array set asset_arr [list \
                                     asset_type_id ${asset_type_id} \
                                     label $domain \
                                     name "${domain} test ${asset_type_id} $ac" \
                                     user_id $sysowner_user_id ]
            set asset_arr(f_id) [hf_asset_create asset_arr ]
            set dci(0) $asset_arr(f_id)
ns_log Notice "hosting-farm-test-api-procs.tcl.113: asset_arr(label) $asset_arr(label)"
            array set asset_arr [list \
                                     affix [ad_generate_random_string] \
                                     description "[string toupper ${asset_type_id}]${ac}" \
                                     details "This is for api test"]
ns_log Notice "hosting-farm-test-api-procs.tcl.119: asset_arr(label) $asset_arr(label)"
            set asset_arr(${asset_type_id}_id) [hf_dc_write asset_arr]
            incr dc_atc
            set a_larr(${ac}) [array get asset_arr]
            ns_log Notice "hosting-farm-test-api-procs.tcl.116: dci(0) '$dci(0)'"
            array unset asset_arr
            incr ac

            set domain [hf_domain_example]
            set asset_type_id "dc"
            array set asset_arr [list \
                                     asset_type_id ${asset_type_id} \
                                     label $domain \
                                     name "${domain} test ${asset_type_id} $ac" \
                                     user_id $sysowner_user_id ]
            set asset_arr(f_id) [hf_asset_create asset_arr ]
            set dci(1) $asset_arr(f_id)
            array set asset_arr [list \
                                     affix [ad_generate_random_string] \
                                     description "[string toupper ${asset_type_id}]${ac}" \
                                     details "This is for api test"]
            set asset_arr(${asset_type_id}_id) [hf_dc_write asset_arr]
            incr dc_atc
            set a_larr(${ac}) [array get asset_arr]

            ns_log Notice "hosting-farm-test-api-procs.tcl.116: dci(1) '$dci(1)'"
            array unset asset_arr
            incr ac

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


                # Add to dc. hf_asset hierarchy is added manually
                set dc_ref [expr { round( fmod( $ac , 2 ) ) } ]
                set dcn $dci(${dc_ref})
                hf_sub_asset_map_update $dcn dc $randlabel $asset_arr(f_id) hw 0
                ns_log Notice "hosting-farm-test-api-procs.tcl.182: dc_ref $dc_ref"
                lappend hw_id_larr(${dc_ref}) $asset_arr(f_id)

                # add hw primary attribute
                array set asset_arr [list \
                                         sub_label $asset_arr(label) \
                                         system_name [ad_generate_random_string] \
                                         backup_sys $backup_sys \
                                         os_id [randomRange $osc] \
                                         description "[string toupper ${asset_type_id}]${ac}" \
                                         details "This is for api test"]
                set asset_arr(${asset_type_id}_id) [hf_hw_write asset_arr]
                incr hw_atc

                set a_larr(${ac}) [array get asset_arr]


                # add ip
                set ipv6_suffix [expr { $ip_atc + 7334 } ]
                array set ip_arr [list \
                                      f_id $asset_arr(f_id) \
                                      sub_label "eth0" \
                                      ip_id "" \
                                      ipv4_addr "198.51.100.${ip_atc}" \
                                      ipv4_status "1" \
                                      ipv6_addr "2001:0db8:85a3:0000:0000:8a2e:0370:${ipv6_suffix}" \
                                      ipv6_status "1"]
                set ip_arr(ip_id) [hf_ip_write ip_arr]
                lappend ip_id_list $ip_arr(ip_id)

                set ip_larr(${ip_atc}) [array get ip_arr]

                # delayed unset ip_arr. See below
                incr ip_atc


                # add ni
                set i_list [list 0 1]
                for {set i 0} {$i < 4} {incr i} {
                    lappend i_list [format %x [randomRange 255]]
                }
                set biamac [join $i_list ":"]

                array set ni_arr [list \
                                      f_id $asset_arr(f_id) \
                                      sub_label "NIC-${ni_atc}" \
                                      os_dev_ref "io1" \
                                      bia_mac_address ${biamac} \
                                      ul_mac_address "" \
                                      ipv4_addr_range "198.51.100.0/24" \
                                      ipv6_addr_range "2001:db8:1234::/48" ]
                set ni_arr(ni_id) [hf_ni_write ni_arr]
                lappend ni_id_list $ni_arr(ni_id)
                
                set ni_larr(${ni_atc}) [array get ni_arr]

                array unset ni_arr
                incr ni_atc

                # add a ns
                array set ns_arr [list \
                                      f_id $asset_arr(f_id) \
                                      active_p "0" \
                                      name_record "${domain}. A $ip_arr(ipv4_addr)" ]
                set ns_arr(ns_id) [hf_ns_write ns_arr]
                lappend ns_id_list $ns_arr(ns_id)
                
                set ns_larr(${ns_atc}) [array get ns_arr]

                array unset ns_arr
                incr ns_atc

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

                lappend ua_larr(${ua_atc}) [array get ua_arr]

                array unset ua_arr
                incr ua_atc

                array set ua_arr [list \
                                      f_id $asset_arr(f_id) \
                                      ua "user2" \
                                      connection_type "https" \
                                      ua_id "" \
                                      up "test" ]
                set ua_arr(ua_id) [hf_user_add ua_arr]

                lappend ua_larr(${ua_atc}) [array get ua_arr]

                array unset ua_arr
                incr ua_atc

                ns_log Notice "hosting-farm-test-api-procs.tcl.237: ac ${ac}"
                array unset asset_arr
                incr ac


            }


            #
            # test api results against creation data

            set dc0_f_id_list [hf_asset_subassets_cascade $dci(0)]
            set dc0_f_id_list_len [llength $dc0_f_id_list]
            set dc1_f_id_list [hf_asset_subassets_cascade $dci(1)]
            set dc1_f_id_list_len [llength $dc1_f_id_list]
            set asset_tot [expr { $dc0_f_id_list_len + $dc1_f_id_list_len } ]
            #ns_log Notice "hosting-farm-test-api-procs.tcl.260: $dc0_f_id_list_len + $dc1_f_id_list_len = $asset_tot"
            #ns_log Notice "hosting-farm-test-api-procs.tcl.261: dc0_f_id_list '${dc0_f_id_list}' dc1_f_id_list '${dc1_f_id_list}'"
            aa_equals "Assets total created" $asset_tot $ac 

            set atcn [expr { $dc_atc + $hw_atc + $vh_atc + $vm_atc + $ip_atc + $ni_atc + $ua_atc + $ss_atc + $ns_atc } ]
            ns_log Notice "hosting-farm-test-api-procs.tcl.261: atc dc $dc_atc hw $hw_atc vm $vm_atc vh $vh_atc ip $ip_atc ni $ni_atc ua $ua_atc ss $ss_atc ns $ns_atc"
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

            ns_log Notice "hosting-farm-test-api-procs.tcl.262: $dc0_sub_f_id_list_len + $dc1_sub_f_id_list_len = $attr_tot"
            ns_log Notice "hosting-farm-test-api-procs.tcl.263: dc0_sub_f_id_list '${dc0_sub_f_id_list}' dc1_sub_f_id_list '${dc1_sub_f_id_list}'"


            aa_equals "Attributes total created" $attr_tot $atcn 

# populate

            ns_log Notice "aa_register_case.327: Begin test assets_sys_populate_api_check"
             aa_log "Test populate 2 DCs with HW and some attributes"
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
            foreach hf_asset_id $hw_asset_id_list {
                set dice [randomRange 11]
                switch -exact $dice {
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
                        hf_sub_asset_map_update $hf_asset_id hw $asset_arr(f_id) $asset_type_id 0
                        array set asset_arr [list \
                                                 domain_name $domain \
                                                 os_id [randomRange $osc] \
                                                 server_type "standard" \
                                                 resource_path "/var/www/${domain}" \
                                                 mount_union "0" \
                                                 details "generated by hosting-farm-test-api-procs.tcl" ]
                        set asset_arr(vm_id) [hf_vm_write asset_arr]
                        set a_larr(${ac}) [array get asset_arr]

                        
                        array set ua_arr [list \
                                              f_id $asset_arr(f_id) \
                                              ua "user1" \
                                              up [ad_generate_random_string]]
                        set ua_arr(ua_id) [hf_user_add ua_arr]
                        
                        lappend ua_larr(${ua_atc}) [array get ua_arr]

                        array unset ua_arr
                        incr ua_atc

                        incr ac
                        incr vm_atc
                        unset asset_arr
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
                        # link asset to hw_id
                        hf_sub_asset_map_update $hf_asset_id hw $asset_arr(f_id) $asset_type_id 0

                        array set asset_arr [list \
                                                 domain_name $domain \
                                                 os_id [randomRange $osc] \
                                                 server_type "standard" \
                                                 resource_path "/var/www/${domain}" \
                                                 mount_union "0" \
                                                 details "generated by hosting-farm-test-api-procs.tcl" ]
                        set asset_arr(vm_id) [hf_vm_write asset_arr]
                        set a_larr(${ac}) [array get asset_arr]

                        set user_count [expr { [randomRange 5] + 1 } ]
                        for { set i 0} {$i < $user_count} {incr i} {
                            array set ua_arr [list \
                                                  f_id $asset_arr(f_id) \
                                                  ua "user${i}" \
                                                  up [ad_generate_random_string]]
                            set ua_arr(ua_id) [hf_user_add ua_arr]
                            
                            lappend ua_larr(${ua_atc}) [array get ua_arr]
                            
                            array unset ua_arr
                            incr ua_atc
                        }

                        incr ac
                        incr vm_atc
                        unset asset_arr
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
                        # link asset to hw_id
                        hf_sub_asset_map_update $hf_asset_id hw $asset_arr(f_id) $asset_type_id 0

                        array set asset_arr [list \
                                                 domain_name $domain \
                                                 os_id [randomRange $osc] \
                                                 server_type "standard" \
                                                 resource_path "/var/www/${domain}" \
                                                 mount_union "1" \
                                                 details "switch 2, generated by hosting-farm-test-api-procs.tcl" ]
                        set asset_arr(vm_id) [hf_vm_write asset_arr]
                        set a_larr(${ac}) [array get asset_arr]

                        
                        array set ua_arr [list \
                                              f_id $asset_arr(f_id) \
                                              ua "user1" \
                                              up [ad_generate_random_string]]
                        set ua_arr(ua_id) [hf_user_add ua_arr]
                        
                        lappend ua_larr(${ua_atc}) [array get ua_arr]

                        array unset ua_arr
                        incr ua_atc

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
                        array set vh_arr [list \
                                              domain_name $randlabel \
                                              details "switch 2, generated by hosting-farm-test-api-procs.tcl" ]
                        set vh_arr(vh_id) [hf_vh_write vh_arr ]
                        set a_larr(${ac}) [array get asset_arr]
                        incr ac

                        # link assets
                        hf_sub_asset_map_update $asset_arr(f_id) vm $vh_arr(f_id) vh 0


                        array set ua_arr [list \
                                              f_id $vh_arr(f_id) \
                                              ua "user1" \
                                              up [ad_generate_random_string]]
                        set ua_arr(ua_id) [hf_user_add ua_arr]
                        
                        lappend ua_larr(${ua_atc}) [array get ua_arr]

                        array unset ua_arr
                        incr ua_atc


                        unset vh_arr
                        incr vm_atc
                        unset asset_arr
                        incr ac

                    }
                    3 {
                        # add ss + ua asset to a vh attribute + ua
                        
                        # First, create vh asset
                        set randlabel [hf_domain_example]
                        set asset_type_id "vh"

                        array set vh_arr [list \
                                              f_id $hf_asset_id \
                                              domain_name $randlabel \
                                              details "switch 2, generated by hosting-farm-test-api-procs.tcl" ]
                        set vh_arr(vh_id) [hf_vh_write vh_arr ]
                        set a_larr(${ac}) [array get vh_arr]
                        incr vh_atc

                        array set ua_arr [list \
                                              f_id $vh_arr(f_id) \
                                              ua "user1" \
                                              up [ad_generate_random_string]]
                        set ua_arr(ua_id) [hf_user_add ua_arr]
                        
                        lappend ua_larr(${ua_atc}) [array get ua_arr]

                        array unset ua_arr
                        incr ua_atc

                        # create ss and ua asset

                        array set ss_arr [array get vh_arr]
                        set ss_arr(asset_type_id) "ss"
                        append ss_arr(label) "-gold"
                        set ss_arr(f_id) [hf_asset_create ss_arr]

                        # link asset to vh_id
                        hf_sub_asset_map_update $vh_arr(vh_id) vh $ss_arr(f_id) ss 0

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
                        set a_larr(${ac}) [array get ss_arr]


                        array set ua_arr [list \
                                              f_id $ss_arr(f_id) \
                                              ua "user1" \
                                              up [ad_generate_random_string]]
                        set ua_arr(ua_id) [hf_user_add ua_arr]
                        
                        lappend ua_larr(${ua_atc}) [array get ua_arr]

                        array unset ua_arr
                        incr ua_atc



                        unset ss_arr
                        unset vh_arr
                        incr ss_atc
                        incr ac                                          
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
                        # link asset to hw_id
                        hf_sub_asset_map_update $hf_asset_id hw $asset_arr(f_id) $asset_type_id 0

                        array set asset_arr [list \
                                                 domain_name $domain \
                                                 os_id [randomRange $osc] \
                                                 server_type "standard" \
                                                 resource_path "/var/www/${domain}" \
                                                 mount_union "0" \
                                                 details "switch 2, generated by hosting-farm-test-api-procs.tcl" ]
                        set asset_arr(vm_id) [hf_vm_write asset_arr]
                        set a_larr(${ac}) [array get asset_arr]

                        
                        array set ua_arr [list \
                                              f_id $asset_arr(f_id) \
                                              ua "user1" \
                                              up [ad_generate_random_string]]
                        set ua_arr(ua_id) [hf_user_add ua_arr]
                        
                        lappend ua_larr(${ua_atc}) [array get ua_arr]

                        array unset ua_arr
                        incr ua_atc


                        array set ss_arr [list \
                                              f_id $asset_arr(f_id) \
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
                        set a_larr(${ac}) [array get ss_arr]
                        

                        array set ua_arr [list \
                                              f_id $ss_arr(f_id) \
                                              ua "db_user1" \
                                              up [ad_generate_random_string]]
                        set ua_arr(ua_id) [hf_user_add ua_arr]
                        
                        lappend ua_larr(${ua_atc}) [array get ua_arr]

                        array unset ss_arr
                        incr ss_atc
                        array unset ua_arr
                        incr ua_atc

                        array unset asset_arr
                        
                        incr ac
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
                        # link asset to hw_id
                        hf_sub_asset_map_update $hf_asset_id hw $ss_arr(f_id) $asset_type_id 0

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
                        set a_larr(${ac}) [array get ss_arr]

                        for {set i 0} {$i < $user_count} {incr i} {
                            array set ua_arr [list \
                                                  f_id $ss_arr(f_id) \
                                                  ua "user${i}" \
                                                  up [ad_generate_random_string]]
                            set ua_arr(ua_id) [hf_user_add ua_arr]
                        
                            lappend ua_larr(${ua_atc}) [array get ua_arr]

                            array unset ua_arr
                            incr ua_atc
                        }

                        unset ss_arr
                        incr ss_atc
                        incr ac

                    }
                    6,7,8 {
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
                        # link asset to hw_id
                        hf_sub_asset_map_update $hf_asset_id hw $hw_arr(f_id) $asset_type_id 0
                        
                        # add hw primary attribute
                        array set hw_arr [list \
                                                 sub_label $hw_arr(label) \
                                                 system_name [ad_generate_random_string] \
                                                 backup_sys "n/a" \
                                                 os_id [randomRange $osc] \
                                                 description "[string toupper ${asset_type_id}]${ac}" \
                                                 details "This is for api test"]
                        set hw_arr(${asset_type_id}_id) [hf_hw_write asset_arr]
                        incr hw_atc

                        set a_larr(${ac}) [array get hw_arr]


                        # add ip
                        set ipn [expr { int( fmod( $ip_atc, 256) ) } ]
                        set ipn2 [expr { int( $ip_atc / 256 ) } ]
                        set ipv6_suffix [format %x [expr { int( fmod( $ip_atc, 65535 ) ) } ]]
                        set hw_atc_f [format %x $hw_atc]
                        array set ip_arr [list \
                                              f_id $hw_arr(f_id) \
                                              sub_label "eth0" \
                                              ip_id "" \
                                              ipv4_addr "10.0.${ipn2}.${ipn}" \
                                              ipv4_status "1" \
                                              ipv6_addr "2001:0db8:85a3:0000:0000:8a2e:${hw_atc_f}:${ipv6_suffix}" \
                                              ipv6_status "1"]
                        set ip_arr(ip_id) [hf_ip_write ip_arr]
                        lappend ip_id_list $ip_arr(ip_id)

                        set ip_larr(${ip_atc}) [array get ip_arr]

                        # delayed unset ip_arr. See below
                        incr ip_atc


                        # add ni
                        set i_list [list 0 ]
                        for {set i 0} {$i < 5} {incr i} {
                            lappend i_list [format %x [randomRange 255]]
                        }
                        set biamac [join $i_list ":"]

                        array set ni_arr [list \
                                              f_id $hw_arr(f_id) \
                                              sub_label "NIC-${ni_atc}" \
                                              os_dev_ref "io1" \
                                              bia_mac_address ${biamac} \
                                              ul_mac_address "" \
                                              ipv4_addr_range "10.00.${ipn2}.0/3" \
                                              ipv6_addr_range "2001:db8:1234::/3" ]
                        set ni_arr(ni_id) [hf_ni_write ni_arr]
                        lappend ni_id_list $ni_arr(ni_id)
                        
                        set ni_larr(${ni_atc}) [array get ni_arr]

                        array unset ni_arr
                        incr ni_atc

                        # add a ns
                        array set ns_arr [list \
                                              f_id $hw_arr(f_id) \
                                              active_p "0" \
                                              name_record "${domain}. A $ip_arr(ipv4_addr)" ]
                        set ns_arr(ns_id) [hf_ns_write ns_arr]
                        lappend ns_id_list $ns_arr(ns_id)
                        
                        set ns_larr(${ns_atc}) [array get ns_arr]

                        array unset ns_arr
                        incr ns_atc

                        # delayed unset ip_arr, so info could be used in ns_arr
                        array unset ip_arr

                        # add two ua
                        array set ua_arr [list \
                                              f_id $hw_arr(f_id) \
                                              ua "user1" \
                                              connection_type "https" \
                                              ua_id "" \
                                              up "test" ]
                        set ua_arr(ua_id) [hf_user_add ua_arr]

                        lappend ua_larr(${ua_atc}) [array get ua_arr]

                        array unset ua_arr
                        incr ua_atc

                        array set ua_arr [list \
                                              f_id $hw_arr(f_id) \
                                              ua "user2" \
                                              connection_type "https" \
                                              ua_id "" \
                                              up "test" ]
                        set ua_arr(ua_id) [hf_user_add ua_arr]

                        lappend ua_larr(${ua_atc}) [array get ua_arr]

                        array unset ua_arr
                        incr ua_atc


                        array unset hw_arr
                        incr ac


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
                        # link asset to hw_id
                        hf_sub_asset_map_update $hf_asset_id hw $ss_arr(f_id) $asset_type_id 0

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
                        set a_larr(${ac}) [array get ss_arr]


                        unset ss_arr
                        incr ss_atc
                        incr ac

                    }
                    10 {
                        # add hw network device to dc attr

                        set randlabel [hf_domain_example]
                        set randtype [lindex [list "switch" "firewall" "fiber" "satlink" "laser" "cylon"] [randomRange 5]]
                        append randlabel - $randtype
                        set asset_type_id "hw"
                        set label $randtype
                        append randtype - $hw_atc
                        # add hw primary attribute
                        array set attr_arr [list \
                                                f_id $hf_asset_id \
                                                type_id hw \
                                                sub_label $label \
                                                system_name [ad_generate_random_string] \
                                                backup_sys "n/a" \
                                                 os_id [randomRange $osc] \
                                                description "[string toupper ${asset_type_id}]${ac}" \
                                                details "This is for api test"]
                        set attr_arr(f_id) [hf_hw_write attr_arr]
                        incr hw_atc
                        
                        set a_larr(${ac}) [array get attr_arr]
                        
                        
                        # add ip
                        set ipn [expr { int( fmod( $ip_atc, 256) ) } ]
                        set ipn2 [expr { int( $ip_atc / 256 ) } ]
                        set ipv6_suffix [format %x [expr { int( fmod( $ip_atc, 65535 ) ) } ]]
                        set hw_atc_f [format %x $hw_atc]
                        array set ip_arr [list \
                                              f_id $attr_arr(f_id) \
                                              sub_label "eth20" \
                                              ip_id "" \
                                              ipv4_addr "10.0.${ipn2}.${ipn}" \
                                              ipv4_status "1" \
                                              ipv6_addr "2001:0db8:85a3:0000:0000:8a2e:${hw_atc_f}:${ipv6_suffix}" \
                                              ipv6_status "0"]
                        set ip_arr(ip_id) [hf_ip_write ip_arr]
                        lappend ip_id_list $ip_arr(ip_id)

                        set ip_larr(${ip_atc}) [array get ip_arr]

                        # delayed unset ip_arr. See below
                        incr ip_atc


                        # add ni
                        set i_list [list ]
                        for {set i 0} {$i < 6} {incr i} {
                            lappend i_list [format %x [randomRange 255]]
                        }
                        set biamac [join $i_list ":"]
                        array set ni_arr [list \
                                              f_id $attr_arr(f_id) \
                                              sub_label "NIC-${ni_atc}" \
                                              os_dev_ref "io1" \
                                              bia_mac_address ${biamac} \
                                              ul_mac_address "" \
                                              ipv4_addr_range "10.00.${ipn2}.0/3" \
                                              ipv6_addr_range "2001:db8:1234::/3" ]
                        set ni_arr(ni_id) [hf_ni_write ni_arr]
                        lappend ni_id_list $ni_arr(ni_id)
                        
                        set ni_larr(${ni_atc}) [array get ni_arr]

                        array unset ni_arr
                        incr ni_atc

                        # add a ns
                        array set ns_arr [list \
                                              f_id $attr_arr(f_id) \
                                              active_p "0" \
                                              name_record "${domain}. A $ip_arr(ipv4_addr)" ]
                        set ns_arr(ns_id) [hf_ns_write ns_arr]
                        lappend ns_id_list $ns_arr(ns_id)
                        
                        set ns_larr(${ns_atc}) [array get ns_arr]

                        array unset ns_arr
                        incr ns_atc

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

                        lappend ua_larr(${ua_atc}) [array get ua_arr]

                        array unset ua_arr
                        incr ua_atc

                        array set ua_arr [list \
                                              f_id $attr_arr(f_id) \
                                              ua "user2" \
                                              connection_type "https" \
                                              ua_id "" \
                                              up "test" ]
                        set ua_arr(ua_id) [hf_user_add ua_arr]

                        lappend ua_larr(${ua_atc}) [array get ua_arr]

                        array unset ua_arr
                        incr ua_atc


                        array unset attr_arr
                        incr ac


                    }
                    11 {
                        # add a vm attr + 1000 ua assets + multiple ns to ua Think domain leasing service
                        set domain [hf_domain_example]
                        set asset_type_id "vm"

                        array set asset_arr [list \
                                                 f_id $hf_asset_id \
                                                 type_id hw \
                                                 domain_name $domain \
                                                 os_id [randomRange $osc] \
                                                 server_type "domainleasing" \
                                                 resource_path "/var/www/${domain}" \
                                                 mount_union "0" \
                                                 details "switch 11, generated by hosting-farm-test-api-procs.tcl" ]
                        set asset_arr(vm_id) [hf_vm_write asset_arr]
                        set a_larr(${ac}) [array get asset_arr]
                        incr vm_atc
                        

                        set asset_type_id "ua"
                        set i_count [randomRange 200]
                        incr $i_count 100
                        for {set i 0} {$i < $i_count} {incr i} {
                            array set ua_arr [list \
                                                  asset_type_id ${asset_type_id} \
                                                  label $randlabel \
                                                  name "${randlabel} test switch 11 ${asset_type_id} $ac" \
                                                  user_id $sysowner_user_id ]
                            set ua_arr(f_id) [hf_asset_create ua_arr]
                            # link asset to hw_id
                            hf_sub_asset_map_update $hf_asset_id hw $ua_arr(f_id) $asset_type_id 0
                            array set ua_arr [list \
                                                  f_id $ua_arr(f_id) \
                                                  ua "user${i}" \
                                                  up [ad_generate_random_string]]
                            set ua_arr(ua_id) [hf_user_add ua_arr]
                        
                            lappend ua_larr(${ua_atc}) [array get ua_arr]
                            
                            array unset ua_arr
                            incr ua_atc
                            incr ac
                        }
                        
                    }

                }
                
            }

            # evolve data

            ns_log Notice "aa_register_case.327: Begin test assets_sys_evolve_api_check"
            aa_log "Test evolve DC assets and attributes"

            # update ua of each
            # verify ua of each
            # update an ns 
            # verify ns
            # 
            # move vm from 1 to 2.
            # verify
            # move vh from 2 to 1
            # verify


            # system clear DCs


            ns_log Notice "aa_register_case.327: Begin test assets_sys_clear_api_check"
            aa_log "Clear 2 DCs of managed assets and attributes."

            # delete everything below a hw
            # verify


        }
}
