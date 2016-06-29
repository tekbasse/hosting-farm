set y [list 1 23 456 7800 ab]
set content ""


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
#                    set priv_arr(${role},${at_id})  0
                    set property_id [hf_property_id $at_id $instance_id]
                    set role_id [hf_role_id_of_label $role $instance_id]
                    set priv_list [db_list test_tcl "select privilege from hf_property_role_privilege_map where instance_id=:instance_id"] 
                    set priv_val 0
                    foreach priv $priv_list {
                        switch -exact -- $priv {
                            read {
                                inr priv_val 1
                            }
                            create {
                                incr priv_val 2
                            }
                            write {
                                incr priv_val 4
                            }
                            delete {
                                incr priv_val 8
                            }
                            admin {
                                incr priv_val 16
                            }
                        }
                    }
                    if { $priv_val > 0 } {
                        append content "${role},${at_id} ${priv_val} \\n"
                    }
                }
            }

