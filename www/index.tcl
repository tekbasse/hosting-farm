# Initial permissions
set user_id [ad_conn user_id]
set instance_id [ad_conn package_id]
set read_p [permission::permission_p \
                -party_id $user_id \
                -object_id $instance_id \
                -privilege read]
if { !$read_p } {
    ad_redirect_for_registration
    ad_script_abort
}

# Initializations

set assets_create_p 0
set assets_write_p 0
set assets_admin_p 0
set assets_publish_p 0
set nonassets_create_p 0
set nonassets_write_p 0
set nonassets_admin_p 0
set nonassets_publish_p 0
set pkg_admin_p 0

if { $read_p } {
    set assets_read_p [hf_ui_go_ahead_q read "" assets 0]
    if { $assets_read_p } {
        set assets_create_p [hf_ui_go_ahead_q create "" assets 0]
        set assets_write_p [hf_ui_go_ahead_q write "" assets 0]
        set assets_admin_p [hf_ui_go_ahead_q admin "" assets 0]
    }
}
if { $read_p } {
    set non_assets_read_p [hf_ui_go_ahead_q read "" non_assets 0]
    if { $non_assets_read_p } {
        set non_assets_create_p [hf_ui_go_ahead_q create "" non_assets 0]
        set non_assets_write_p [hf_ui_go_ahead_q write "" non_assets 0]
        set non_assets_admin_p [hf_ui_go_ahead_q admin "" non_assets 0]
    }
}


set customer_id ""
set customer_id_list [hf_customer_ids_for_user $user_id $instance_id]
if { [llength $customer_id_list] > 1 } {
    
    set gt1_customer_p 1
} else {
    set customer_id [lindex $customer_id_list 0]
    set gt1_customer_p 0
}



if { $assets_admin_p } {
    # check package admin for extras
    set pkg_admin_p [permission::permission_p \
                         -party_id $user_id \
                         -object_id $instance_id \
                         -privilege admin]
}

set title "#hosting-farm.Hosting_Farm#"
set context [list $title]


# example 1st page plan:

#if user can read assets, link to assets with flex sort

#if user can read billing, show billing status, link to billing

#if user can read technical, show highest priority, link to assets by health

#if user can write permissions_*, show link to permissions table (role vs property ie privileges for role property intersect)

#if user is site_developer, show link to assets with flex sort, edit publishable content

#if user can read non_assets, show link to contact records


