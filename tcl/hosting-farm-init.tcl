# hosting-farm/tcl/hosting-farm-init.tcl


# Default initialization?  check at server startup (here)

#    @creation-date 2016-05-05
#    @Copyright (c) 2016 Benjamin Brink
#    @license GNU General Public License 3, see project home or http://www.gnu.org/licenses/gpl-3.0.en.html
#    @project home: http://github.com/tekbasse/hosting-farm
#    @address: po box 20, Marylhurst, OR 97036-0020 usa
#    @email: tekbasse@yahoo.com

set roles_lists [db_list_of_lists get_all_roles "select id,label,title,description from hf_role"]
if { [llength $roles_lists] == 0 } {
    # This is the first run of the first instance. Insert defaults
    # here instead of via sql files to minimize permissions files timestamp changes.
    # To help detect any system tampering during operation.
    set roles_defaults_list [list \
                           [list technical_admin "Technical Admin" "Primary technical administrator"] \
                           [list technical_manager "Technical Manager" "Oversees daily technical operations"] \
                           [list technical_staff "Technical Staff" "Monitors asset performance etc"] \
                           [list billing_admin "Billing Admin" "Primary billing administrator"] \
                           [list billing_manager "Billing Manager" "Oversees daily billing operations"] \
                           [list billing_staff "Billing Staff" "Monitors billing, bookkeeping etc."] ]
    # admin has admin permissions, manager has read/write permissions, staff has read permissions
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


set props_list [db_list_of_lists get_all_properties "select asset_type_id,id,title from hf_property"]
if { [llength $props_list] == 0 } {
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

set privs_list [db_list_of_lists get_all_privileges "select property_id,role_id,privilege from hf_property_role_privilege_map"]
if { [llength $privs_list] == 0 } {
    # This is the first run of the first instance. 



}
