set title "Hosting farm demo install"
set context [list $title]
qc_pkg_admin_required

ns_log Notice "demo install begin, based on: aa_register_case.12: Begin test assets_sys_build_api_check"
#aa_log "0. Build 2 DCs with HW and some attributes"
# Use default permissions provided by tcl/hosting-farm-init.tcl
# Yet, users must have read access permissions or test fails
# Some tests will fail (predictably) in a hardened system

set instance_id [qc_set_instance_id]
# We avoid qf_permission_p by using a sysadmin user
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
set prior_asset_ids_list [hf_asset_ids_for_user $sysowner_user_id]
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
    ns_log Notice "hosting-farm/www/admin/demo-install.tcl.76: osc ${osc}"
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
#ns_log Notice "hosting-farm/www/admin/demo-install.tcl.113: asset_arr(label) $asset_arr(label)"
array set asset_arr [list \
                         affix [ad_generate_random_string] \
                         description "[string toupper ${asset_type_id}]${ac}" \
                         details "This is for api test"]
#ns_log Notice "hosting-farm/www/admin/demo-install.tcl.119: asset_arr(label) $asset_arr(label)"
set asset_arr(dc_id) [hf_dc_write asset_arr]
incr audit_atc_arr(dc)
array unset asset_arr
#ns_log Notice "hosting-farm/www/admin/demo-install.tcl.116: dci(0) '$dci(0)'"



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
#ns_log Notice "hosting-farm/www/admin/demo-install.tcl.116: dci(1) '$dci(1)'"


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
    #ns_log Notice "hosting-farm/www/admin/demo-install.tcl.182: dc_ref $dc_ref"
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


    #ns_log Notice "hosting-farm/www/admin/demo-install.tcl.237: ac ${ac}"
    array unset asset_arr

}





#
# populate data
#

#ns_log Notice "aa_register_case.327: Begin test assets_sys_populate_api_check"
#aa_log "1. Test populate 2 DCs with HW and some attributes"
# dc asset_id dci(0) dci(1)
# dc hardware
# dc0_f_id_list
# dc1_f_id_list

# add  business cases
# some vm, multiple vh on vm, ss on vh, ss on vm, ua on each
# ss asset (db, wiki server, asterix for example) with multiple ua
# vh asset as basic services, ua on each
# hw asset as co-location,  rasberry pi, linux box,
set dice -1
set hw_asset_id_list [concat $hw_id_larr(0) $hw_id_larr(1) ]
set switch_options_count 12
# randomize a list of all switch references instead of maybe randomly missing one or two.
for {set i 0} {$i < $switch_options_count } {incr i} {
    set dice [expr { int( fmod( $dice + 1 , $switch_options_count ) ) } ]
    lappend dice_list $dice
}
set dice_list [acc_fin::shuffle_list $dice_list]
foreach hw_asset_id $hw_asset_id_list {
    set dice [hf_peek_pop_stack dice_list]
    ns_log Notice "hosting-farm/www/admin/demo-install.tcl: starting switch '${dice}'"
    switch -glob -- $dice {
        0 {
            set sh_id [hfdt_vm_create $hw_asset_id]
            if { $sh_id eq "" } {
                ns_log Warning "hosting-farm/www/admin/demo-install.tcl dice= 0 failed to create asset."
            }

        }
        1 {
            # create shared host base
            # add a few shared hosting clients
            set sh_id [hfdt_vm_base_create $hw_asset_id]
            if { $sh_id ne "" } {
                set user_count [expr { [randomRange 5] + 1 } ]
                for { set i 0} {$i < $user_count} {incr i} {
                    hfdt_shared_hosting_client_create $sh_id
                }
            } else {
                ns_log Warning "hosting-farm/www/admin/demo-install.tcl dice= 1 failed to create asset."
            }
        }
        2 {
            # add vh asset + ua to a vm attribute + ua
            set sh_id [hfdt_vm_attr_create $hw_asset_id]
            if { $sh_id ne "" } {
                hfdt_shared_hosting_client_create $sh_id
            } else {
                ns_log Warning "hosting-farm/www/admin/demo-install.tcl dice= 2 failed to create vm attribute."
            }
        }
        3 {

            # add ss + ua asset to a vh attribute + ua

            # First, create vh attribute
            set vh_id [hfdt_vh_base_create $hw_asset_id]
            if { $vh_id ne "" } {
                # create ss and ua asset
                hfdt_ss_base_create $vh_id
            } else {
                ns_log Warning "hosting-farm/www/admin/demo-install.tcl dice= 3 failed to create asset."
            }
        }
        4 {

            # create vm
            set vm_id [hfdt_vm_base_create $hw_asset_id]
            if { $vm_id ne "" } {
                # add ss + ua attribute to a vm
                hfdt_ss_attr_create $vm_id
            } else {
                ns_log Warning "hosting-farm/www/admin/demo-install.tcl dice= 4 failed to create asset."
            }
        }
        5 {

            # add ss asset + ua*N (asterix, wiki, db)
            set f_id [hfdt_ss_base_create $hw_asset_id]
            if { $f_id ne "" } {
                set user_count [randomRange 25]
                for {set i 0} {$i < $user_count} {incr i} {
                    hfdt_ua_asset_create $f_id
                }
            } else {
                ns_log Warning "hosting-farm/www/admin/demo-install.tcl dice= 5 failed to create asset."
            }
        }
        6 - 
        7 - 
        8 {
            # Add a rack or shelf of equipment
            set f_id [hfdt_hw_base_create $hw_asset_id]
            if { $f_id ne "" } {

                # add hw asset + ua  as 1u unit botbox etc.
                set box_id [hfdt_hw_1u_create $f_id]
                if { $box_id ne "" } {
                    set c [randomRange 8]
                    incr c 5
                    for {set i 0} {$i < $c } {incr i} {
                        # add hw asset + ua  as colo unit botbox etc.
                        set box_id [hfdt_hw_1u_create $f_id]
                    }
                } else {
                    ns_log Warning "hosting-farm/www/admin/demo-install.tcl dice= 6,7,8 failed to create colo assets."
                }
            } else {
                ns_log Warning "hosting-farm/www/admin/demo-install.tcl dice= 6,7,8 failed to create asset."
            }
        }
        9 {
            
            # add ss asset as killer app
            set f_id [hfdt_ss_base_create $hw_asset_id]
            if { $f_id eq "" } {
                ns_log Warning "hosting-farm/www/admin/demo-install.tcl dice= 9 failed to create asset."
            }
        }
        10 {

            # add hw network device to dc attr
            set f_id [hfdt_hw_base_create $hw_asset_id]
            if { $f_id eq "" } {
                ns_log Warning "hosting-farm/www/admin/demo-install.tcl dice= 10 failed to create asset."
            }
        }
        11 {

            # add a vm attr + 100+ ua assets with multiple ns to ua Think domain leasing service
            set f_id [hfdt_vm_attr_create $hw_asset_id]

            if { $f_id ne "" } {
                set i_count [randomRange 30]
                incr i_count
                for {set i 0} {$i < $i_count} {incr i} {
                    set ua_id [hfdt_ua_asset_create $f_id]
                    if { $ua_id ne "" } {
                        set ipn [expr { int( fmod( $audit_atc_arr(ua), 256) ) } ]
                        set ipn2 [expr { int( $audit_atc_arr(ua) / 256 ) } ]
                        
                        set j_count [randomRange 30]
                        
                        for {set j 0} {$j < $j_count} {incr j} {
                            
                            # add a ns
                            set domain [hf_domain_example]
                            set ipv4_addr "10.0.${ipn2}.${ipn}"
                            array set ns_arr [list \
                                                  f_id ${ua_id} \
                                                  active_p "0" \
                                                  name_record "${domain}. A ${ipv4_addr}" ]
                            set ns_arr(ns_id) [hf_ns_write ns_arr]
                            if { $ns_arr(ns_id) ne "" } {
                                incr audit_atc_arr(ns)
                            }
                            array unset ns_arr
                        }
                    } else {
                        ns_log Warning "hosting-farm/www/admin/demo-install.tcl dice= 11 failed hfdt_ua_asset_create"
                    }
                }
            } else {
                ns_log Warning "hosting-farm/www/admin/demo-install.tcl dice= 11 failed to create vm attr."
            }
        }
    }
    ns_log Notice "hosting-farm/www/admin/demo-install.tcl: end switch '${dice}'"
    #end switch
}
# end foreach



# evolve data

ns_log Notice "aa_register_case.327: Begin test assets_sys_evolve_api_check"
#aa_log "2. Test evolve DC assets and attributes"

# update ua of each
# verify ua of each
# update an ns
# verify ns
#
# move vm from 1 to 2.
# verify
# move vh from 2 to 1
# verify
# etc
set op_status_list [list \
                        active \
                        inactive \
                        terminated \
                        suspended \
                        wip \
                        suspended-active \
                        suspended-config \
                        suspended-inactive \
                        config-active \
                        wip-inactive \
                        wip-active ]
set op_status_list_len [llength $op_status_list]

set update_list [lrepeat 4 "update"]
set cycle_count [expr { round( pow($switch_options_count,2) ) } ]
for {set cycle_nbr 0} {$cycle_nbr < $cycle_count} {incr cycle_nbr} {
    set t [expr { $cycle_nbr * 360. / $cycle_count } ]
    # balance of creates to trashes ie creates - trashes. This simmulates a life cycle..
    set td [expr { round( [acc_fin::pos_sine_cycle_rate $t] * 10 + 11. ) } ]
    set tr_count [expr { 22 - $td } ]
    set create_list [lrepeat $td "create"]
    set trash_list [lrepeat $tr_count "trash"]
    set op_type_list [concat $update_list $create_list $trash_list]
    set op_type_list_len [llength $op_type_list]
    incr op_type_list_len -1
    set hw_asset_id_list [acc_fin::shuffle_list $hw_asset_id_list]
    ns_log Notice "hosting-farm/www/admin/demo-install.tcl: starting evolve cycle_nbr '${cycle_nbr}' of '${cycle_count}'"
    foreach hw_asset_id $hw_asset_id_list {
        # Choose operations and target type
        set op_type [lindex $op_type_list [randomRange $op_type_list_len]]
        set target [lindex [list asset attribute] [randomRange 1]]
        # Choose primary target
        set sub_assets_list [hf_asset_subassets_cascade $hw_asset_id]
        set sub_assets_list [lrange $sub_assets_list 1 end]
        set sub_assets_count [llength $sub_assets_list ]
        incr sub_assets_count -1
        if { $sub_assets_count > 0 } {
            set sub_asset_id [lindex $sub_assets_list [randomRange $sub_assets_count]]
        } else {
            set sub_asset_id [lindex $sub_assets_list 0]
        }
        if { $target eq "asset" } {
            if { $sub_asset_id eq "" } {
                set op_type "create"
            }

            if { $op_type eq "trash" } {
                hf_asset_stats $sub_asset_id [list trashed_p asset_type_id]
                if { $trashed_p eq "" } {
                    ns_log Warning "hosting-farm/www/admin/demo-install.tcl: sub_asset_id '${sub_asset_id}' trashed_p '${trashed_p}'"
                    set op_type "create"
                }
            }

            ns_log Notice "hosting-farm/www/admin/demo-install.tcl: starting evolve op_type '${op_type}' on sub_asset_id '${sub_asset_id}'"
            switch -exact -- $op_type {
                trash {
                    if { $trashed_p } { 
                        if { [hf_asset_untrash $sub_asset_id] } {
                            incr audit_ac_arr(${asset_type_id})
                        } else {
                            ns_log Warning "hosting-farm/www/admin/demo-install.tcl: failed hf_asset_untrash sub_asset_id '${sub_asset_id}' trashed_p '${trashed_p}'"
                        }
                    } else {
                        if { [hf_asset_trash $sub_asset_id] } {
                            incr audit_ac_arr(${asset_type_id}) -1
                        } else {
                            ns_log Warning "hosting-farm/www/admin/demo-install.tcl: failed hf_asset_trash sub_asset_id '${sub_asset_id}' trashed_p '${trashed_p}'"
                        }
                    }
                }
                create {
                    set sub_asset_type_id [hf_asset_type_id_of_asset_id $sub_asset_id]
                    if { $sub_asset_type_id eq "vm" && [random] > .5 } {
                        hfdt_shared_hosting_client_create $sub_asset_id
                    } else {
                        set r [randomRange 9]
                        switch -exact -- $r {
                            0 { hfdt_vh_attr_create $sub_asset_id }
                            1 { hfdt_ss_attr_create $sub_asset_id }
                            2 { hfdt_ss_base_create $sub_asset_id }
                            3 { hfdt_vm_create $hw_asset_id }
                            4 { hfdt_vm_base_create $sub_asset_id }
                            5 { hfdt_vm_attr_create $sub_asset_id }
                            6 { hfdt_hw_1u_create $sub_asset_id }
                            7 { hfdt_vh_base_create $sub_asset_id }
                            8 { hfdt_hw_base_create $sub_asset_id }
                            9 { hfdt_ua_asset_create $sub_asset_id }
                        }
                    }
                }
                update {
                    # change label, active / inactive, monitor_p on or off
                    set k [randomRange 3]
                    switch $k { 
                        0 { hf_asset_label_change $sub_asset_id [hf_domain_example] }
                        1 { 
                            set op_status [lindex $op_status_list [randomRange $op_status_list_len]]
                            hf_asset_op_status_change $sub_asset_id $op_status
                        }
                        2 {
                            # Switch monitor on or off
                            hf_asset_monitor $sub_asset_id [randomRange 1]
                        }
                        3 {
                            # switch publish on /off
                            hf_asset_publish $sub_asset_id [randomRange 1]
                        }
                    }
                }
            }
        } else {
            # Target is an attribute of sub_asset_id
            # Choose an attribute
            set attr_id_list [hf_asset_attributes_cascade $sub_asset_id]
            set attr_id_count [llength $attr_id_list]
            incr attr_id_count -1
            if { $attr_id_count > 0 } {
                set attr_id [lindex $attr_id_list [randomRange $attr_id_count]]
            } else {
                set attr_id [lindex $attr_id_list 0]
            }
            set sam_list [hf_sub_asset $attr_id]
            qf_lists_to_vars $sam_list [hf_sub_asset_map_keys] [list sub_type_id trashed_p]
            if { $attr_id eq "" || $trashed_p eq "" } {
                set op_type "create"
                if { $trashed_p eq "" } {
                    ns_log Notice "hosting-farm/www/admin/demo-install.tcl: attr_id '${attr_id}' trashed_p '${trashed_p}'"
                }
            }
            
            if { $attr_id ne "" } {
                ns_log Notice "hosting-farm/www/admin/demo-install.tcl: starting evolve op_type '${op_type}' on attr_id '${attr_id}'"
                switch -exact -- $op_type {
                    trash {
                        if { !$trashed_p } {
                            if { [hf_attribute_trash $attr_id ] } {
                                incr audit_atc_arr(${sub_type_id}) -1
                            }
                        }
                    }
                    create {
                        # add attribute below it.
                        hfdt_ua_asset_create $attr_id
                    }
                    update {
                        # change label?
                        hf_attribute_sub_label_update $attr_id [ad_generate_random_string]
                    }
                }
            }
        }
        #end if asset/attr
    }
    # end foreach
}
# end cycle_nbr loop

ns_log Notice "demo install end, based on: hosting-farm-test-api-procs.tcl assets_sys_build_api_check"