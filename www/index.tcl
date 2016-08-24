set title "#hosting-farm.Hosting-Farm#"
set context [list $title]

# adp flags: gt1_customer_p and (role labels_p) site_developer_p for example.

set instance_id [ad_conn package_id]
set user_id [ad_conn user_id]
# min perms is app_read_p
set app_read_p [permission::permission_p -party_id $user_id -object_id $instance_id -privilege read]
if { !$app_read_p } {
    ad_redirect_for_registration
    ad_script_abort
}
set site_developer_p 0

set app_admin_p [permission::permission_p -party_id $user_id -object_id $instance_id -privilege admin]
set customer_id ""
set customer_id_list [hf_customer_ids_for_user $user_id $instance_id]
if { [llength $customer_id_list] > 1 } {

    set gt1_customer_p 1
} else {
    set customer_id [lindex $customer_id_list 0]
    set gt1_customer_p 0
}

set app_roles_list [list ]
set roles_lists [hf_roles $instance_id]
foreach role_list $roles_lists {
    set label [lindex $role_list 0]
    lappend app_roles_list $label
}
if { $app_admin_p } {
    set admin_p 1
    set write_p 1
    set read_p 1
    set create_p 1
    set user_roles_list $app_roles_list
} else {
    set user_roles_list [hf_roles_of_user $user_id $customer_id]
}
if { "site_developer" in $user_roles_list } {
    set site_developer_p 1
} 

ns_log Notice "index.tcl user_roles_list '${user_roles_list}' app_roles_list '${app_roles_list}'"
 
# create more flags for conditional adp content
foreach app_role $app_roles_list {
    if { $app_role in $user_roles_list } {
        set ${app_role}_p 1
    } else {
        set ${app_role}_p 0
    }
}

if { $main_admin_p || $main_manager_p || $main_staff_p } {
    set main_p 1
} else {
    set main_p 0
}

if { $technical_admin_p || $technical_manager_p || $technical_staff_p } {
    set technical_p 1
} else {
    set technical_p 0
}


if { $billing_admin_p || $billing_manager_p || $billing_staff_p } {
    set billing_p 1
} else {
    set billing_p 0
}

#if user can read assets, link to assets with flex sort

#if user can read billing, show billing status, link to billing

#if user can read technical, show highest priority, link to assets by health

#if user can write permissions_*, show link to permissions table (role vs property ie privileges for role property intersect)

#if user is site_developer, show link to assets with flex sort, edit publishable content

#if user can read non_assets, show link to contact records


