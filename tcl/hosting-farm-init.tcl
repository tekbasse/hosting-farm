# hosting-farm/tcl/hosting-farm-init.tcl


# Default initialization?  check at server startup (here)

#    @creation-date 2016-05-05
#    @Copyright (c) 2016 Benjamin Brink
#    @license GNU General Public License 3, see project home or http://www.gnu.org/licenses/gpl-3.0.en.html
#    @project home: http://github.com/tekbasse/hosting-farm
#    @address: po box 20, Marylhurst, OR 97036-0020 usa
#    @email: tekbasse@yahoo.com

set roles_lists_len 0
set db_read_count 0
# This is in a loop so that one db query handles both cases.
while { $roles_lists_len == 0 && $db_read_count < 2 } {
    incr db_read_count
    set roles_lists [db_list_of_lists get_all_roles "select id,label,title,description from hf_role"]
    set roles_lists_len [llength $roles_lists]
    if { [llength $roles_lists] == 0 } {
        # This is the first run of the first instance. Insert defaults
        # here instead of via sql files to minimize permissions files timestamp changes.
        # To help detect any system tampering during operation.
        set roles_defaults_list [list \
                                     [list main_admin "Main Admin" "Primary administrator"] \
                                     [list main_manager "Main Manager" "Primary manager"] \
                                     [list main_staff "Main Staff" "Main monitor"] \
                                     [list technical_admin "Technical Admin" "Primary technical administrator"] \
                                     [list technical_manager "Technical Manager" "Oversees daily technical operations"] \
                                     [list technical_staff "Technical Staff" "Monitors asset performance etc"] \
                                     [list billing_admin "Billing Admin" "Primary billing administrator"] \
                                     [list billing_manager "Billing Manager" "Oversees daily billing operations"] \
                                     [list billing_staff "Billing Staff" "Monitors billing, bookkeeping etc."] ]
        # admin to have admin permissions, manager to have read/write permissions, staff to have read permissions
        foreach def_role_list $roles_defaults_list {
            # No need for instance_id since these are system defaults
            set label [lindex $def_role_list 0]
            set title [lindex $def_role_list 1]
            set description [lindex $def_role_list 2]
            db_dml default_roles_cr {
                insert into hf_role
                (label,title,description)
                values (:label,:title,:description)
            }
        }
    }
}

set props_lists_len 0
set db_read_count 0
# This is in a loop so that one db query handles both cases.
while { $props_lists_len == 0 && $db_read_count < 2 } {
    incr db_read_count
    set props_lists [db_list_of_lists get_all_properties "select asset_type_id,id,title from hf_property"]
    set props_lists_len [llength $props_lists]
    if { $props_lists_len == 0 } {
        # This is the first run of the first instance. 
        set props_defaults_lists [list \
                                      [list main_contact_record "Main Contact Record"] \
                                      [list admin_contact_record "Administrative Contact Record"] \
                                      [list tech_contact_record "Technical Contact Record"] \
                                      [list permissions_properties "Permissions properties"] \
                                      [list permissions_roles "Permissions roles"] \
                                      [list permissions_privileges "Permissions privileges"] \
                                      [list non_assets "non-assets ie customer records etc."] \
                                      [list published "World viewable"] \
                                      [list assets "Assets"] ]
        foreach def_prop_list $props_defaults_lists {
            set asset_type_id [lindex $def_prop_list 0]
            set title [lindex $def_prop_list 1]
            db_dml default_props_cr {
                insert into hf_property
                (asset_type_id,title)
                values (:asset_type_id,:title)
            }
        }
    }
}


set privs_lists_len 0
set db_read_count 0
# This is in a loop so that one db query handles both cases.
while { $privs_lists_len == 0 && $db_read_count < 2 } {
    incr db_read_count
    set privs_lists [db_list_of_lists get_all_privileges "select property_id,role_id,privilege from hf_property_role_privilege_map"]
    set privs_lists_len [llength $privs_lists]
    if { $privs_lists_len == 0 } {
        # This is the first run of the first instance. 
        # In general:
        # admin roles to have admin permissions, manager to have read/write permissions, staff to have read permissions
        # techs to have write privileges on tech stuff, admins to have write privileges on contact stuff
        # write includes trash, admin includes create where appropriate
        set privs_larr(admin) [list "read" "write" "admin"]
        set privs_larr(manager) [list "read" "write"]
        set privs_larr(staff) [list "read"]

        set property_types_list [list tech billing main]
        set props_larr(tech) [list tech_contact_record assets non_assets published]
        set props_larr(billing) [list admin_contact_record non_assets published]
        #set props_larr(main)  is in all general cases, 
        set props_larr(main) [list main_contact_record admin_contact_record non_assets tech_contact_record assets non_assets published]
        # perimissions_* are for special cases where tech admins need access to set special case permissions.
        foreach role_list $roles_lists {
            set role_id [lindex $role_list 0]
            set role_label [lindex $role_list 1]
            set u_idx [string first "-" $role_label]
            incr u_idx
            set priviledge [string range $role_label $u_idx end]
            set role [string range $role_label 0 $u_idx-2]
            foreach prop_list $props_lists {
                set asset_type_id [lindex $prop_list 0]
                set property_id [lindex $prop_list 1]
                # For each role_id and property_id create priviledges
                # Priviledges are base on $privs_larr($role) and props_larr(asset_type_id)
                foreach property_type $property_types_list {
                    if { [lsearch $props_larr($property_type) $asset_type_id ] > -1 } {
                        # This property type has priviledges.
                        # Add privileges for the role_id
                        foreach priv $privs_larr($role) {
                            db_dml default_priviledges_cr {
                                insert into hf_property_role_priviledge_map
                                (property_id,role_id,privilege)
                                values (:property_id,:role_id,:priv)
                            }
                        }
                    }
                }
            }
        }
    }    
}
