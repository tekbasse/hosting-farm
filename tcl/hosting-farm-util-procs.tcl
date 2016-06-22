# hosting-farm-util-procs.tcl
ad_library {

    General utilities for hosting farm procs
    @creation-date 11 December 2013
    @Copyright (c) 2014 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl-2.0.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com
}

ad_proc -private hf_peek_pop_stack {
    ref_list
} {
    returns the first value in a list, and removes the value from the same referenced list.
} {
    upvar 1 $ref_list the_list
    set last_out [lindex $the_list end]
    set the_list [lrange $the_list 0 end-1]
    return $last_out
}

ad_proc -private hf_keys_by {
    keys_list
    separator
} {
    if { $separator ne ""} {
        set keys ""
        if { $separator eq ",:" } {
            # for db
            set keys ":"
        }
        append keys [join $keys_list $separator]
    } else {
        set keys $keys_list
    }
    return $keys
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

ad_proc -public hf_list_filter_by_alphanum {
    user_input_list
} {
    Returns a list of alphanumeric items from user_input_list
} {
    set filtered_list [list ]
    foreach input_unfiltered $user_input_list {
        # added dash and underscore, because these are often used in alpha/text references
        if { [regsub -all -nocase -- {[^a-z0-9,\.\-\_]+} $input_unfiltered {} input_filtered ] } {
            lappend filtered_list $input_filtered
        }
    }
    return $filtered_list
}

ad_proc -public hf_list_filter_by_decimal {
    user_input_list
} {
    set filtered_list [list ]
    foreach input_unfiltered $user_input_list {
        if { [qf_is_decimal $input_unfiltered] } {
            lappend filtered_list $input_unfiltered
        }
    }
    return $filtered_list
}

ad_proc -public hf_list_filter_by_natural_number {
    user_input_list
} {
    set filtered_list [list ]
    foreach input_unfiltered $user_input_list {
        if { [qf_is_natural_number $input_unfiltered] } {
            lappend filtered_list $input_unfiltered
        }
    }
    return $filtered_list
}

ad_proc -private hf_natural_number_list_validate {
    natural_number_list
} {
    Retuns 1 if list only contains natural numbers, otherwise returns 0
} {
    set nn_list [hf_list_filter_by_natural_number $natural_number_list]
    if { [llength $nn_list] != [llength $natural_number_list] } {
        set natnums_p 0
    } else {
        set natnums_p 1
    }
    return $natnums_p
}

ad_proc -private hf_are_visible_characters_q {
    user_input
} {
    if { [regexp -- {^[[:graph:]]+$} $user_input scratch ] } {
        set visible_p 1
    } else {
        set visible_p 0
    }
    return $visible_p
}

ad_proc -private hf_list_filter_by_visible {
    user_input_list
} {
    set filtered_list [list ]
    foreach input_unfiltered $user_input_list {
        if { [hf_are_visible_characters_q $input_unfiltered] } {
            lappend filtered_list $input_unfiltered
        }
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
