# hosting-farm-util-procs.tcl
ad_library {

    general utilities api for Hosting Farm
    @creation-date 11 December 2013
    @Copyright (c) 2014 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl-2.0.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 193, Marylhurst, OR 97036-0193 usa
    @email: tekbasse@yahoo.com
}

ad_proc -private hf_peek_pop_stack {
    ref_list
} {
    Returns the last value in a list, and removes the value from the same referenced list.
} {
    upvar 1 $ref_list the_list
    set last_out [lindex $the_list end]
    set the_list [lrange $the_list 0 end-1]
    return $last_out
}

ad_proc -public hf_lists_filter_by_alphanum {
    user_input_list
} {
    Returns a list of list of items that are alphanumeric from a list of lists.
} {
    set filtered_row_list [list ]
    set filtered_list [list ]
    foreach input_row_unfiltered $user_input_list {
        set filtered_row_list [list ]
        foreach input_unfiltered $input_row_unfiltered {
            # added dash and underscore, because these are often used in alpha/text references
            if { [regsub -all -nocase -- {[^a-z0-9,\.\-\_]+} $input_unfiltered {} input_filtered] } {
                lappend filtered_row_list $input_filtered
            }
        }
        lappend filtered_list $filtered_row_list
    }
    return $filtered_list
}

ad_proc -private hf_key_hidden_q {
    fieldname
    {asset_type_id ""}
} {
    Returns 1 if fieldname should be hidden from end users
    such as in UI forms and views.

    If asset_type_id is included, checks for specific case, otherwise
    only considers the general case.
} {
    set hide_p 0
    set hidden_list [list instance_id ip_id monitor_id ni_id os_id plan_id qal_customer_id qal_product_id report_id role_id ss_id status_id sub_f_id sub_type_id template_id type_id ua_id up_id user_id vh_id vm_id]
    if { $fieldname in $hidden_list } {
        set hide_p 1
    } 
    # There are no special cases for asset_type_id right now.
    # Yet, special cases are expected.
    switch -- $fieldname {
        default {
            # not a special case.
        }
    }
    return $hide_p
}


ad_proc -private hf_privilege_on_key_allowed_q {
    privilege
    fieldname
    {asset_type_id ""}
} {
    Returns 1 if user can perform privilege on fieldname.

    This permits an increasing level of responsibility with increasing privilege.
    Privilege can be create, write.
    such as in UI forms and views.
    Refers to create_p, write_p, admin_p and pkg_admin_p as defined in calling environment.
    Assumes these have been generated using qc_permission_p for assets.


    If asset_type_id is included, checks for specific case, otherwise
    only considers the general case.
} {
    # privilege can be create or write.
    # Is there a use case for admin that exceeds write? If so, it can be added.
    upvar 1 read_p read_p
    upvar 1 create_p create_p
    upvar 1 write_p write_p
    upvar 1 admin_p admin_p
    upvar 1 pkg_admin_p pkg_admin_p
    set allowed_p 0

    if { $read_p } {
        set c_list [list \
                        asset_type_id \
                        domain_name \
                        label \
                        server_name \
                        service_name \
                        ua \
                        up ]
        set w_list [list \
                        name \
                        trashed_p]
        set a_list [list \
                        active_p \
                        alert_by_privilege \
                        alert_by_role \
                        config_uri \
                        health_percentile_trigger \
                        monitor_p \
                        name_record \
                        popularity \
                        port \
                        triage_priority \
                        ua \
                        up ]
        set p_list [list \
                        affix \
                        backup_sys \
                        bia_mac_address \
                        brand \
                        connection_type \
                        description \
                        details \
                        flags \
                        halt_proc \
                        ipv4_addr \
                        ipv4_addr_range \
                        ipv4_status \
                        ipv6_addr \
                        ipv6_addr_range \
                        ipv6_status \
                        kernel \
                        label \
                        mount_union \
                        orphaned_p \
                        os_dev_ref \
                        os_id \
                        requires_upgrade_p \
                        resource_path \
                        start_proc \
                        sub_label \
                        sub_sort_order \
                        system_name \
                        template_p \
                        ul_mac_address \
                        version ]
        if { $create_p && $privilege eq "create" } {
            if { $fieldname in $c_list } {
                set allowed_p 1
            }
        }
        if { $privilege eq "write" } {
            if { $write_p && $fieldname in $w_list } {
                set allowed_p 1
            } elseif { $admin_p } {
                if { $fieldname in $a_list } {
                    set allowed_p 1
                } elseif { $pkg_admin_p && $fieldname in $p_list } {
                    set allowed_p 1
                }
            }
        }

    }
    return $allowed_p
}

ad_proc -private hf_key_sort_for_display {
    names_list
    {unique_p "1"}
} {
    Returns fieldnames in sequence for display or editing. If unique_p, removes duplicate fields.
} {
    set f_lists [list ]
    foreach f $names_list {
        set row_list [list $f [lang::util::localize "#hosting-farm.${f}#" ]] 
        lappend f_lists $row_list
    }
    # using ascii sort, so that capitalized names are first.
    # use dictionary instead to alphabetize all of them.
    if { $unique_p } {
        set f2_lists [lsort -unique -index 1 -ascii -increasing $f_lists]
    } else {
        set f2_lists [lsort -index 1 -ascii -increasing $f_lists]
    }
    set names_list_new [list ]
    foreach row_list $f2_lists {
        lappend names_list_new [lindex $row_list 0]
    }
    return $names_list_new
}
