set title "Hosting farm privilege map"
set context [list $title]

qc_pkg_admin_required

set content ""
set instance_id [qc_set_instance_id]

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
append content "<table>"
append content "<th>#hosting-farm.role#</th><th>#hosting-farm.property#</th><th>#hosting-farm.privilege#</th>\n"
set role_prev ""
foreach role $roles_list {
    # at_id = asset_type_id
    foreach at_id $asset_type_ids_list {
        # 0 is default, no privilege
        #                    set priv_arr(${role},${at_id})  0
        set property_id [hf_property_id $at_id $instance_id]
        set role_id [hf_role_id_of_label $role $instance_id]
        set priv_list [db_list test_tcl "select privilege from hf_property_role_privilege_map where property_id=:property_id and role_id=:role_id and instance_id=:instance_id"] 
        set priv_val 0
        foreach priv $priv_list {
            switch -exact -- $priv {
                read {
                    incr priv_val 1
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
            #append content "${role},${at_id} ${priv_val} \ <br>"
            if { $role eq $role_prev } {
                append content "<tr><td>&nbsp;</td><td>${at_id}</td><td>[join $priv_list ","]</td></tr>"
            } else {
                append content "<tr><td>${role}</td><td>${at_id}</td><td>[join $priv_list ","]</td></tr>"
            }
            set role_prev $role
        }
    }



}

append content "</table>"
