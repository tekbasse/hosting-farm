set title "#acs-subsite.Permissions#"
set context [list $title]

# Initial permissions
set user_id [ad_conn user_id]
set instance_id [ad_conn package_id]

set pkg_admin_p 0
# Check for read_p against minimum case, so all appropriate users see something
set read_p [hf_ui_go_ahead_q read "" non_assets 0]
if { !$read_p } {
    ad_redirect_for_registration
    ad_script_abort
}
# Check for admin_p against assets
## If this could edit permissions, check permissions_properties permissions_roles or permissions_privileges
set admin_p [hf_ui_go_ahead_q admin "" assets 0]
if { $admin_p } {
    # check package admin for extras
    set pkg_admin_p [permission::permission_p \
                         -party_id $user_id \
                         -object_id $instance_id \
                         -privilege admin]
}


set permissions_table_html ""





# if query_customer_id exists 
# table showing roles assigned for each user of customer_id

# if query_user_id exists
# roles for user for each customer_id
# 

# if admin_p:

# table showing privileges 
#
# role vs property_label, 
# otherwise 
# if query_user_id exists limit roles to only those of user_id split by customer_id


