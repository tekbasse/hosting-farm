# defaults
set title "menu"
set context [list $title]

# User information and top level navigation links
#
set user_id [ad_conn user_id]
set package_id [ad_conn package_id]
set untrusted_user_id [ad_conn untrusted_user_id]
set sw_admin_p 0

if { $untrusted_user_id == 0 } {
    # The browser does NOT claim to represent a user that we know about
    set login_url [ad_get_login_url -return]
    set user_name ""
} else {
    # The browser claims to represent a user that we know about
    set user_name [person::name -person_id $untrusted_user_id]
    set pvt_home_url [ad_pvt_home]
    set pvt_home_name [_ acs-subsite.Your_Account]
    set logout_url [ad_get_logout_url]
    # Site-wide admin link
    set admin_url {}
    set sw_admin_p [acs_user::site_wide_admin_p -user_id $untrusted_user_id]

}

# get status info
#  see as.adp as.tcl for db scenario example

set interval_remaining [expr { int( [random ] * 30 ) } ]

set input_array(s) "-7"
set input_array(p) ""
set input_array(this_start_row) ""

set form_posted [qf_get_inputs_as_array input_array]

set s $input_array(s)
set p $input_array(p)
set this_start_row $input_array(this_start_row)

# s, p, and this_start_row always exist, which simplifies the include tag that is called.

