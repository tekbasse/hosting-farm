# Initial permissions
set user_id [ad_conn user_id]
set instance_id [qc_set_instance_id]
set read_p [permission::permission_p \
                -party_id $user_id \
                -object_id [ad_conn package_id] \
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


    set non_assets_read_p [hf_ui_go_ahead_q read "" non_assets 0]
    if { $non_assets_read_p } {
        set non_assets_create_p [hf_ui_go_ahead_q create "" non_assets 0]
        set non_assets_write_p [hf_ui_go_ahead_q write "" non_assets 0]
        set non_assets_admin_p [hf_ui_go_ahead_q admin "" non_assets 0]
    }


set pkg_admin_p [permission::permission_p \
                     -party_id $user_id \
                     -object_id $instance_id \
                     -privilege admin]

}

set customer_id ""
set customer_id_list [qc_contact_ids_for_user $user_id $instance_id]
if { [llength $customer_id_list] > 1 } {
    
    set gt1_customer_p 1
} else {
    set customer_id [lindex $customer_id_list 0]
    set gt1_customer_p 0
}



if { $assets_admin_p } {
    # check package admin for extras
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


if { $pkg_admin_p } {
    array set u_arr [list admin 1 doc 1 assets 1 billing 1 c 1]
} else {
    array set u_arr [list admin 0 doc 0 assets $assets_read_p billing $non_assets_read_p c $gt1_customer_p]
}
array set s_arr [list \
                     admin "#accounts-ledger.admin#" \
                     c "#accounts-ledger.Customers#" \
                     doc "Documentation" \
                     assets "#accounts-ledger.Assets#" \
                     billing "#accounts-ledger.Accounts#" ]

if { !$pkg_admin_p && $customer_id eq "" && !$gt1_customer_p } {
    set content_html "<p>Your account is not associated with a hosting account.</p>"
} else {
    set content_html ""
    set arr_names_list [list assets billing c doc admin]
    foreach item $arr_names_list {
        if { $u_arr($item) } {
            set menu_url $item
            set menu_label $s_arr($item)
            append content_html "<a href=\"${menu_url}\" title=\"${menu_label}\">${menu_label}</a> &nbsp; "
        }
    }
}
