# hosting-farm/www/c.tcl
# part of the hosting-farm package 
# This presents a list of users similar to assets.tcl
# When user chooses a customer, customer_id is passed to assets.tcl or monitors.tcl


# depends on OpenACS website toolkit at OpenACS.org
# copyrigh 2016 by Benjamin Brink
# released under GPL license 2 or greater

# This page split into components:
#  Inputs (model/mode), 
#  Actions (controller), and 
#  Outputs (reports/view) sections

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

set create_p 0
set write_p 0
set admin_p 0
set publish_p 0
set pkg_admin_p 0

if { $read_p } {
    set read_p [hf_ui_go_ahead_q read "" "" 0]
    set create_p [hf_ui_go_ahead_q create "" "" 0]
    set write_p [hf_ui_go_ahead_q write "" "" 0]
    set admin_p [hf_ui_go_ahead_q admin "" "" 0]
    if { $admin_p } {
        # check package admin for extras
        set pkg_admin_p [permission::permission_p \
                             -party_id $user_id \
                             -object_id [ad_conn package_id] \
                             -privilege admin]
    }
}
set title "#accounts-ledger.Customers#"
set context [list $title]
set icons_path1 "/resources/acs-subsite/"
set icons_path2 "/resources/ajaxhelper/icons/"
set delete_icon_url [file join $icons_path2 delete.png]
set trash_icon_url [file join $icons_path2 page_delete.png]
set untrash_icon_url [file join $icons_path2 page_add.png]
set radio_checked_url [file join $icons_path1 radiochecked.gif]
set radio_unchecked_url [file join $icons_path1 radio.gif]
set redirect_before_v_p 0
set user_message_list [list ]
set base_url "assets"
set form_html ""
set customer_id ""

#flags
set gt1_customer_p 0


array set input_arr \
    [list \
         customer_id "" \
         interval_remaining "" \
         mode "l" \
         mode_next "" \
         p "" \
         page_title $title \
         reset "" \
         s "" \
         submit "" \
         this_start_row "" \
         top_level_p "0" ]


# INPUTS


set customer_id_list [hf_customer_ids_for_user $user_id $instance_id]
if { [llength $customer_id_list] > 1 } {
     set gt1_customer_p 1
} else {
    set customer_id [lindex $customer_id_list 0]
}

#if gt1_customer_p = 0, just show link to assets and monitors

# Get form inputs if they exist
set form_posted_p [qf_get_inputs_as_array input_arr hash_check 1]
if { !$form_posted_p } {
    # form not posted. Get defaults.
    template::util::array_to_vars input_arr
} else {

    # this is mainly for admins.. or anyone with a long list of customers
}

set doc(title) $title

