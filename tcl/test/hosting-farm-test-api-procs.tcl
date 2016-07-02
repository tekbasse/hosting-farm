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
            
            

            # os inits
            set z2 1
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
            set os_id [hf_os_write os_arr]

            # Add another os record
            incr z2
            set randlabel [qal_namelur 1 2 "-"]
            set brand [qal_namelur 1 3 ""]
            set kernel "${brand}-${z2}"
            set title [apm_instance_name_from_id $instance_id]
            set version "${z2}.[randomRange 100].[randomRange 100]"
            set randlabel [qal_namelur 1 2 "-"]

            array set os_arr [list \
                                  instance_id $instance_id \
                                  label $randlabel \
                                  brand $brand \
                                  version $version \
                                  kernel $kernel ]
            set os_id [hf_os_write os_arr]

            # Add another os record
            incr z2
            set randlabel [qal_namelur 1 2 "-"]
            set brand [qal_namelur 1 3 ""]
            set kernel "${brand}-${z2}"
            set title [apm_instance_name_from_id $instance_id]
            set version "${z2}.[randomRange 100].[randomRange 100]"
            set randlabel [qal_namelur 1 2 "-"]

            array set os_arr [list \
                                  instance_id $instance_id \
                                  label $randlabel \
                                  brand $brand \
                                  version $version \
                                  kernel $kernel ]
            set os_id [hf_os_write os_arr]
            
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

            set randlabel [hf_domain_example]
            set asset_type_id "dc"
            array set asset_arr [list \
                                     asset_type_id ${asset_type_id} \
                                     label $randlabel \
                                     name "${randlabel} test ${asset_type_id} $z" \
                                     user_id $sysowner_user_id ]
            set asset_arr(f_id) [hf_asset_create asset_arr ]
            array set asset_arr [list \
                                     affix [generate_random_string] \
                                     description "[string toupper ${asset_type_id}]${z}" \
                                     details "This is for api test"]
            set asset_arr(${asset_type_id}_id) [hf_dc_write asset_arr]

            set a_larr(${z}) [array get asset_arr]
            array unset asset_arr
            incr z

            set randlabel [hf_domain_example]
            set asset_type_id "dc"
            array set asset_arr [list \
                                     asset_type_id ${asset_type_id} \
                                     label $randlabel \
                                     name "${randlabel} test ${asset_type_id} $z" \
                                     user_id $sysowner_user_id ]
            set asset_arr(f_id) [hf_asset_create asset_arr ]
            array set asset_arr [list \
                                     affix [generate_random_string] \
                                     description "[string toupper ${asset_type_id}]${z}" \
                                     details "This is for api test"]
            set asset_arr(${asset_type_id}_id) [hf_dc_write asset_arr]

            set a_larr(${z}) [array get asset_arr]
            array unset asset_arr
            incr z

            set randlabel [qal_namelur 1 5 "-"]
            set asset_type_id hw
            array set asset_arr [list \
                                     asset_type_id ${asset_type_id} \
                                     label $randlabel \
                                     name "${randlabel} test ${asset_type_id} $z" \
                                     user_id $sysowner_user_id ]
            set asset_arr(f_id) [hf_asset_create asset_arr ]
            array set asset_arr [list \
                                     system_name [generate_random_string] \
                                     backup_sys "c3p0" \
                                     os_id "" \
                                     affix  \
                                     description "[string toupper ${asset_type_id}]${z}" \
                                     details "This is for api test"]
            set asset_arr(${asset_type_id}_id) [hf_dc_write asset_arr]

            set a_larr(${z}) [array get asset_arr]
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
