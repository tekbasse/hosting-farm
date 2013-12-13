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

set current_dt [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
#set t1 [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
set t1 [clock seconds]
set year_1 [expr { 3600 * 24 * 31 * 12 } ]
set interval_rand [expr { int( [random ] * $year_1 * 3 ) } ]
#set interval_rand [expr { round( 3600 * 24 * 31 * 12 * 2.94 ) } ]
set t2 [expr { $t1 + $interval_rand } ]
set t2_string [clock format $t2 -format "%Y-%m-%d"]

# these messages show up as alerts
# util_user_message -message "This is alert 1"
# util_user_message -message "This is alert 2"
if { $interval_rand < $year_1 } {
    util_user_message -html -message "Account expires on ${t2_string} <a href=\"order\" class=\"btn-big\">Replenish Account</a>"
}
# build menus

set menu_list [list \
                   [list account Account 0] \
                   [list affiliates Reseller 7] \
                   [list assets Assets 3] \
                   [list billing Billing 2] \
                   [list feedback Feedback 8] \
                   [list forums Forums 3] \
                   [list news News 1] \
                   [list plans Contracts 3] \
                   [list support Help 2] \
                   [list ticket-tracker "Direct Support" 5] \
                   [list user-settings "User Settings" 4] \
                   [list wiki Documentation 4] \
                   ]
foreach m_list $menu_list {
    set index [lindex $m_list 0]
    set menu_title_arr($index) [lindex $m_list 1]
}
set menu_1_list [list news support assets account affiliates feedback]
# support includes: forums, file-storage, wiki, tickets/customer-service
set menu_2_list [list support forums wiki ticket-tracker feedback]
set menu_3_list [list account billing plans user-settings affiliates feedback]

#
# build html
# 
set wrap_arr(1,0) {<div>
}
set wrap_arr(1,1) {</div>
}
set wrap_arr(2,0) $wrap_arr(1,0)
set wrap_arr(3,0) $wrap_arr(1,0)
set wrap_arr(2,1) $wrap_arr(1,1)
set wrap_arr(3,1) $wrap_arr(1,1)

set class_html "btn grid-whole padded-sides"

set menu_1_html ""
foreach menu_item $menu_1_list {
    append menu_1_html $wrap_arr(1,0) "<a class=\"${class_html}\" href=\"$menu_item\">$menu_title_arr($menu_item)</a>" $wrap_arr(1,1)
}
set menu_2_html ""
foreach menu_item $menu_2_list {
    append menu_2_html $wrap_arr(2,0) "<a class=\"${class_html}\" href=\"$menu_item\">$menu_title_arr($menu_item)</a>" $wrap_arr(2,1)
}
set menu_3_html ""
foreach menu_item $menu_3_list {
    append menu_3_html $wrap_arr(3,0) "<a class=\"${class_html}\" href=\"$menu_item\">$menu_title_arr($menu_item)</a>" $wrap_arr(3,1)
}

# pass to adp
set list_html ""
append list_html $menu_1_html $menu_2_html $menu_3_html


