set title "#acs-subsite.Administration#"
set context [list ]


qc_pkg_admin_required

set window_content ""
set user_id [ad_conn user_id]
set instance_id [qc_set_instance_id]
# For admins, this is the total asset count:
set id_list [hf_asset_ids_for_user $user_id]
set id_count [llength $id_list]
if { $id_count > 2 } {
    set offer_demo_p 0
} else {
    set offer_demo_p 1
}

set contents "hf_domain_example [hf_domain_example]"

