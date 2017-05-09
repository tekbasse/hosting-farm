set title "#acs-subsite.Administration#"
set context [list ]



set user_id [ad_conn user_id]
set instance_id [ad_conn package_id]
qc_pkg_admin_required



set package_key [ad_conn package_key]
set input_arr(input_text) "some text for $package_key"
set form_posted_p [qf_get_inputs_as_array input_arr hash_check 1]
set content "<pre>\n"
if { !$form_posted_p } {
   append content "form not posted."
} else {
    append content "form posted.

values:\n\n"
    foreach key [array names input_arr] {
        append content "${key}: '$input_arr(${key})' \n"
    }
    #set content $input_arr(a)
    # flush old forms
}
append content "
</pre>"

set input_text $input_arr(input_text)
qf_form action test3 method post id 20160904 hash_check 1
qf_bypass_nv_list [list name1 val1 name2 val2 name3 3 name4 4 name5 -5.14 -name6 -6.268]
qf_bypass name qf_bypass_name value qf_bypass_value
qf_input type text value $input_text name "input_text" label "input text" size 40 maxlength 80
qf_input type hidden name blank1 value ""
qf_bypass name blank2 value ""
qf_bypass value qf_value2 name qf_name2
qf_bypass_nv_list [list n1 v1 n2 v2 n3 3 n4 4 n5 -5 -n6 6 blank3 ""]
qf_input type submit value "#acs-kernel.common_Save#"
qf_append html " &nbsp; &nbsp; &nbsp; <a href=\"test3\">test3</a>"
qf_close
append content [qf_read]

append content "\n\n"
append content [time { set instance_id [ad_conn package_id] } ]

append content [time {
    set override_id [parameter::get -package_id $instance_id -parameter overrideId -default "package_id"]
} ]

append content [time {
    if { [qf_is_natural_number $override_id] } {
        set instance_id $override_id
    } else {
        set instance_id [ad_conn $override_id]
    }
} ]
append content "instance $instance_id"
