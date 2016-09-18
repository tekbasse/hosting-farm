# hosting-farm/www/assets.tcl
# part of the hosting-farm package 
# depends on OpenACS website toolkit at OpenACS.org
# copyrigh 2016 by Benjamin Brink
# released under GPL license 2 or greater

# This page split into components:
#  Inputs (model/mode), 
#  Actions (controller), and 
#  Outputs (reports/view) sections

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

set create_p 0
set write_p 0
set admin_p 0
set publish_p 0
if { $read_p } {
    set read_p [hf_ui_go_ahead_q read "" "" 0]
    set create_p [hf_ui_go_ahead_q create "" "" 0]
    set write_p [hf_ui_go_ahead_q write "" "" 0]
    set admin_p [hf_ui_go_ahead_q admin "" "" 0]
    if { $admin_p } {
        # check package admin for extras
        set pkg_admin_p [permission::permission_p \
                             -party_id $user_id \
                             -object_id $instance_id \
                             -privilege admin]
    }
}
set title "#hosting-farm.Assets#"
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
#flags
set include_view_assets_p 0
set include_view_one_p 0
set include_view_attrs_p 0
set include_view_sub_assets_p 0
set include_edit_one_p 0
set include_add_one_p 0
set keep_user_input_p 0
array set input_arr \
    [list \
         asset_id "" \
         asset_type "" \
         asset_type_id "" \
         customer_id "" \
         f_id "" \
         interval_remaining "" \
         mapped_asset_id "" \
         mapped_f_id "" \
         mode "l" \
         mode_next "" \
         name "" \
         p "" \
         page_title $title \
         reset "" \
         s "" \
         state "" \
         sub_asset_id "" \
         sub_f_id "" \
         sub_type_id "" \
         submit "" \
         this_start_row "" \
         top_level_p "0" \
         type_id "" ]

# INPUTS


# Get form inputs if they exist
set form_posted_p [qf_get_inputs_as_array input_arr hash_check 1]

if { !$form_posted_p } {
    # form not posted. Get defaults.
    template::util::array_to_vars input_arr
} else {

    # Given permutations of asset_types:
    #  A. asset_only
    #  B. asset_primary_attr
    #  C. attr_only 
    #  D. asset_attr 
    # and that D is a case of A-C,
    # and that C is dependent on A (or B).
    # These permutations must be considered for form input, 
    # where focus for change/addition is on the right most (lower) member.
    # and permissions are derived from asset_id associated with an A or B.
    # Here, '=' means 'reduces to'
    # A
    # B (expected to be common)
    # A-C (expected to be common, where A is part of a B )
    # A-B = B
    # A-A = A
    # B-A = A
    # B-B = B (expected to be common)
    # B-C (expected to be common)
    # A-A-A = A 
    # A-A-B = B
    # A-A-C = A-C
    # A-B-A = A
    # A-B-B = B
    # A-B-C = B-C
    # A-C-A = A
    # A-C-B = B
    # A-C-C *
    # B-A-A = A
    # B-A-B = B
    # B-A-C = A-C
    # B-B-A = A
    # B-B-B = B
    # B-B-C = B-C
    # B-C-A = A
    # B-C-B = B
    # B-C-C *
    # * References must consider that an attribute may be dependent of other attribute
    # and ultimately to an asset; Because an attribute requires an asset.

    # In summary, these literal asset_type combos:
    #  A
    #  B = A+C
    #  A-C *
    #  B-C *
    #  A-C-C * 
    #  B-C-C * = A-C-C-C * 
    #  A-C-..C *
    #  B-C-..C * = A-C-C..C *
    #  * only the last C is in focus (edited/added).

    #  C view requires:
    #           sub_f_id
    #  C edit requires:
    #           mapped_asset_id,
    #           sub_f_id
    #  C add requires:
    #           mapped_asset_id, 
    #           mapped_f_id (which is f_id in sub map, sub_f_id is empty)
    #           sub_type_id
    #  A view requries:
    #           asset_id
    #  A add requires:
    #           mapped_asset_id if any, 
    #           asset_type_id
    #  A edit requires:
    #           asset_id
    #  B view requires:
    #           asset_id
    #  B edit requires:
    #           asset_id
    #  B add requires:
    #           mapped_asset_id if any,
    #           asset_type_id = sub_type_id
    #           (sub_type_id)

    # Modes are views, or one of these compound action/views
    #   d   delete (d x) then view as before (where x = l, r or v)
    #   t   trash (d x) then view as before (where x = l, r or v)
    #   w   write (d x) , then view asset_id (v)
    
    # Actions
    #   d  = delete asset_id or sub_asset_id
    #   D  = delete f_id or sub_f_id 
    #   t  = trash asset_id or sub_asset_id
    #   T  = untrash asset_id
    #   c  = create asset/attr asset_type_id
    #           Requires:
    #              asset_type
    #              mapped_f_id  (for permissions and mapping)
    #              asset_type_id
    #   w  = write asset_id/sub_asset_id asset_type_id
    #               asset_type
    #           Requires for asset:
    #               asset_id
    #               f_id (found via asset_id)
    #           Requires for asset_attr:
    #               asset_id
    #               sub_f_id
    #               f_id (found via asset_id)
    #           Requires for attr:
    #               mapped_asset_id (for permissions)
    #               sub_f_id
    #               f_id  (for mapping, found via sub_f_id)
    #   s  = publish
    #   S  = Unpublish

    # Views
    #   a  = add asset/attribute (this allows more control over adding than using edit form allows)
    #        An add button is presented in context of a view
    #   e  = edit asset_id/sub_asset_id or attribute, presents defaults if no prior data
    #        An edit is preceded by view, in order to collected relevant input requirements.
    #   v  = view asset_id or sub_asset_id (attribute_id or asset_id)
    #   l  = list assets
    #   r  = view revision history (can only delete if pkg admin)
    #   "" = view list of role oriented summaries
    #          such as many customers and assets as possible etc.


    # Convert input_array to variables
    qf_array_to_vars input_arr \
        [list \
             asset_id \
             asset_type \
             asset_type_id \
             customer_id \
             f_id \
             interval_remaining \
             mapped_asset_id \
             mapped_f_id \
             mode \
             mode_next \
             p \
             page_title \
             s \
             state \
             sub_asset_id \
             sub_f_id \
             sub_type_id \
             this_start_row \
             top_level_p \
             type_id ]
    # x,y elements in input_arr holds position of image-based submit
    array unset input_arr x
    array unset input_arr y
    ns_log Notice "hosting-farm/assets.tcl.125. Values posted as: \
 asset_id '${asset_id}' sub_asset_id '${sub_asset_id}' f_id '${f_id}' \
 sub_f_id '${sub_f_id}' asset_type_id '${asset_type_id}' sub_type_id '${sub_type_id}' \
 asset_type '${asset_type}' state '${state}' mode '${mode}' mode_next '${mode_next}'"

    # following is part of dynamic menu processing using form tags instead of url/GET
    # key,value is passed as a single name, with first letter z for asset_id or Z for sub_f_id.
    set input_arr_idx_list [array names input_arr]
    # add required defaults not passed by form


    ##code update this regexp?
    set modes_idx [lsearch -regexp $input_arr_idx_list {[Zz][avpsSrnwctTdel][ivcrl][0-9]*} ]
    if { $modes_idx > -1 && $mode eq "p" } {
        set modes [lindex $input_arr_idx_list $modes_idx]
        set test [string range $modes 0 3]
        if { [string match "z*" $test] } {
            # all asset_type except attr_only
            if { [string match {za*} $test] } {
                set mapped_f_id [string range $modes 3 end]
                ns_log Notice "hosting-farm/www/assets.tcl.139: mapped_f_id '${mapped_f_id}'"
            } elseif { [string match {zl*} $test] } {
                set this_start_row [string range $modes 3 end]
                ns_log Notice "hosting-farm/www/assets.tcl.145: this_start_row '${this_start_row}'"
            } else {
                set asset_id [string range $modes 3 end]
                set f_id [hf_f_id_of_asset_id $asset_id]
                ns_log Notice "hosting-farm/www/assets.tcl.141: asset_id '${asset_id}'"
            }
        }
        if { [string match "Z*" $test] } {
            # attr_only
            set asset_type "attr_only"
            if { [string match {Z[vewtTdl]*} $test] } {
                set sub_f_id [string range $modes 3 end]
                #  asset_id required for permissions, and make rest of map record available. sub_type_id etc.
                if { $sub_f_id > 0 } {
                    set sam_list [hf_sub_asset $sub_f_id]
                    qf_lists_to_array sam_arr $sam_list [hf_sub_asset_map_keys]
                    set sub_type_id $sam_arr(sub_type_id)
                    set f_id $sam_arr(f_id)
                    set mapped_f_id $f_id
                }
            } elseif { [string match "Za*" $test] } {
                set mapped_f_id [string range $modes 3 end]
            }
            set mapped_f_id_of_asset_id [hf_asset_f_id_of_sub_f_id $mapped_f_id]
            set mapped_asset_id [hf_asset_id_of_f_id_if_untrashed $mapped_f_id_of_asset_id]

            ns_log Notice "hosting-farm/www/assets.tcl.149: f_id '${f_id}' sub_f_id '${sub_f_id}' mapped_asset_id '${mapped_asset_id}'"
        }
        
        # modes 0 0 is z or Z
        set mode [string range $modes 1 1]
        set mode_next [string range $modes 2 2]

    }

    # Validate input for specific modes
    # Validate input
    set validated_p 0

    if { [string length $mode] != 1 } {
        set mode "v"
        set mode_next ""
    }
    if { [string length $mode_next] > 1 } {
        set mode_next ""
    }
    if { [string first $mode "dDtT"] > -1 \
             && [string first $mode_next "lrv"] == -1 } {
        set mode_next "v"
    }

    ns_log Notice "hosting-farm/www/assets.tcl.182: \
 mode '${mode}' mode_next ${mode_next}"
    ns_log Notice "hosting-farm/assets.tcl.186: user_id '${user_id}' \
 customer_id '${customer_id}' asset_id '${asset_id}' "

    # Cleanse data, verify values for consistency
    # Determine input completeness

    if { $asset_id ne "" } {
        if { [hf_asset_id_exists_q $asset_id ] } {
            # Probably valid asset_id
        } else {
            ns_log Warning "hosting-farm/assets.tcl.225: asset_id '${asset_id}' not valid. Set to ''"
            set asset_id ""
        }
    }

    if { $sub_asset_id ne "" } {
        if { [hf_asset_id_exists_q $sub_asset_id ] } {
            # Probably valid sub_asset_id
        } else {
            ns_log Warning "hosting-farm/assets.tcl.230: sub_asset_id '${sub_asset_id}' not valid. Set to ''"
            set sub_asset_id ""
        }
    } 

    if { $f_id ne "" } {
        if { [hf_f_id_exists_q $f_id ] || [hf_sub_f_id_exists_q $f_id] } {
            # Probably valid f_id
        } else {
            ns_log Warning "hosting-farm/assets.tcl.235: f_id '${f_id}' not valid. Set to ''"
            set f_id ""
        }
    } 

    if { $sub_f_id ne "" } {
        if { [hf_sub_f_id_exists_q $sub_f_id ] } {
            # Probably valid sub_f_id
        } else {
            ns_log Warning "hosting-farm/assets.tcl.240: sub_f_id '${sub_f_id}' not valid. Set to ''"
            set sub_f_id ""
        }
    }

    if { $asset_type_id ne "" &&  $asset_type_id ni [hf_asset_type_id_list ] } {
        ns_log Notice "hosting-farm/assets.tcl.265: asset_type_id '${asset_type_id}' not in hf_asset_type_id_list. Setting to ''."
        set asset_type_id ""
    }

    if { $sub_type_id ne "" &&  $sub_type_id ni [hf_asset_type_id_list ] } {
        ns_log Notice "hosting-farm/assets.tcl.270: sub_type_id '${sub_type_id}' not in hf_asset_type_id_list. Setting to ''."
        set sub_type_id ""
    }

    if { $asset_type ni [list "" asset_primary_attr asset_attr attr_only asset_only] } {
        ns_log Notice "hosting-farm/assets.tcl.275: asset_type '${asset_type}' not recognized. Setting to ''."
        set asset_type ""
    }         

    # blank out any invalid inputs from above at the source, if they exist.
    foreach key [list asset_id sub_asset_id f_id sub_f_id asset_type_id sub_type_id asset_type] {
        if { ![info exists $key] } {
            if { $input_arr(${key}) ne "" } {
                ns_log Notice "hosting-farm/assets.tcl.277: key '${key}' is blank. Subsequently blanked out input_arr(${key}) '$input_arr(${key})'"
                set input_arr(${key}) ""
            }
        }
    }

    # special cases require special permissions
    # Re-checking permissions in context of input.

    set asset_id_varnam [qal_first_nonempty_in_list [list $asset_id $mapped_asset_id]]
    set ati_varnam [qal_first_nonempty_in_list [list $sub_type_id $type_id $asset_type_id ]]

    set read_p [hf_ui_go_ahead_q read $asset_id_varnam $ati_varnam 0]
    set create_p [hf_ui_go_ahead_q create $asset_id_varnam $ati_varnam 0]
    set write_p [hf_ui_go_ahead_q write $asset_id_varnam $ati_varnam 0]
    set admin_p [hf_ui_go_ahead_q admin $asset_id_varnam $ati_varnam 0]

    

    if { $customer_id ne "" && [qf_is_natural_number $customer_id ] } {
        set customer_ids_list [hf_customer_ids_for_user $user_id $instance_id]
        if { $customer_id ni $customer_ids_list && !$pkg_admin_p } {
            ns_log Warning "hosting-farm/assets.tcl.243: customer_id '${customer_id}' not permitted. Set to ''"
            set customer_id ""
        }
    }
    ns_log Notice "hosting-farm/assets.tcl.247: user_id '${user_id}' \
 customer_id '${customer_id}' asset_id '${asset_id}' "

    ns_log Notice "hosting-farm/assets.tcl.250: read_p '${read_p}' \
 create_p ${create_p} write_p ${write_p} admin_p ${admin_p} \
 pkg_admin_p '${pkg_admin_p}'"

    ns_log Notice "hosting-farm/assets.tcl.256. Validated as: \
 asset_id '${asset_id}' sub_asset_id '${sub_asset_id}' f_id '${f_id}' \
 sub_f_id '${sub_f_id}' asset_type_id '${asset_type_id}' sub_type_id '${sub_type_id}' \
 asset_type '${asset_type}' state '${state}' mode '${mode}' mode_next '${mode_next}'"

    set referrer_url [get_referrer]
    set http_header_method [ad_conn method]
    # A blank referrer means a direct request
    # otherwise make sure referrer is from same domain when editing.
    # Referrer originates from browser.
    if { $referrer_url ne "" } {
        ns_log Notice "hosting-farm/assets.tcl.260: form_posted_p '${form_posted_p}' \
 http_header_method ${http_header_method} referrer '${referrer_url}'"
    }
    if { ![string match -nocase "post*" $http_header_method ] } {
        # Make sure there is a clean url, should page be bookmarked etc
        set $redirect_before_v_p 1
    }

    set validated_p 1

    # keeping the logic simple in this section
    # Using IF instead of SWITCH to allow mode to be modified successively
    if { $mode eq "c" } { 
        if { $create_p || $admin_p } {
            # validate data input
            set v_asset_input_p 1
            set v_attr_input_p 1
            if { [string match "*asset*" $asset_type] } {
                foreach key [hf_asset_keys] {
                    set obj_arr(${key}) $input_arr(${key})
                }
                set v_asset_input_p [hfl_asset_field_validation obj_arr]
            }
            if { [string match "*attr*" $asset_type] && $v_asset_input_p } {
### code 
                foreach key [concat hf_$_keys] {
                    set obj_arr(${key}) $input_arr(${key})
                }
                set v_attr_input_p [hfl_attribute_field_validation obj_arr]
            }
            set valid_input_p [expr { $v_asset_input_p && $v_attr_input_p} ]
            if { !$valid_input_p } {
                set mode_next "a"
                ns_log Notice "hosting-farm/assets.tcl.300: \
 asset/attr input validation issues. \
 state '${state}' state '${state}' \
 asset_type_id '${asset_type_id}'. set mode_next '${mode_next}'"
            }
        } else {
            # does not have permission to create
            ns_log Warning "hosting-farm/assets.tcl.311: \
 write denied for '${user_id}'."
            lappend user_message_list "#q-wiki.Write_operation_did_not_succeed# #q-wiki.You_don_t_have_permission#"
            util_user_message -message [lindex $user_message_list end]
            set mode_next ""
            if { $read_p } {
                set mode "v"
            } else {
                set mode ""
            }
            set validated_p 0
        }
    }
    if { $mode eq "w" } { 
        if { $write_p || $admin_p } {
            # allowed
            array set obj_arr [array get input_arr]
            # validate data input
            set valid_input_p 0
            set v_asset_input_p 1
            set v_attr_input_p 1
            if { [string match "*asset*" $asset_type] } {
                set v_asset_input_p [hfl_asset_field_validation obj_arr]
            }
            if { [string match "*attr*" $asset_type] && $valid_input_p } {
                set v_attr_input_p [hfl_attribute_field_validation obj_arr]
            }
            set valid_input_p [expr { $v_asset_input_p && $v_attr_input_p} ]
            if { !$valid_input_p } {
                set mode_next "e"
                set keep_user_input_p 1
                ns_log Notice "hosting-farm/assets.tcl.432: \
 asset/attr input validation issues. \
 state '${state}' asset_type '${asset_type}' \
 asset_type_id '${asset_type_id}'. set mode_next '${mode_next}'"
            }
        } else {
            # does not have permission to write
            ns_log Warning "hosting-farm/assets.tcl.319: \
 write denied for '${user_id}'."
            lappend user_message_list "#q-wiki.Write_operation_did_not_succeed# #q-wiki.You_don_t_have_permission#"
            util_user_message -message [lindex $user_message_list end]
            set mode_next ""
            if { $read_p } {
                set mode "v"
            } else {
                set mode ""
            }
            set validated_p 0
        }
    }

    if { $mode eq "t" || $mode eq "T" } {
        # (t)rash un(T)rash
        if { $write_p || $admin_p } {
            # allowed
        } else {
            ns_log Warning "hosting-farm/assets.tcl.321: \
 trash denied for '${user_id}'."
            set validated_p 0
            if { $read_p } {
                set mode "l"
            } else {
                set mode ""
            }
        }
    }

    if { $mode eq "d" || $mode eq "D" } {
        if { $pkg_admin_p } {
            # allowed
        } else {
            ns_log Warning "hosting-farm/assets.tcl.336: \
 mode '${mode}' denied for '${user_id}'."
            set mode ""
            set validated_p 0
        }
    }

    if { $mode eq "e" } {
        if { $write_p || $admin_p } {
            # allowed
            
        } elseif { $read_p } {
            set mode "v"
        } else {
            set mode "l"
            set validated_p 0
            ns_log Warning "hosting-farm/assets.tcl.352: \
 mode 'e' denied for '${user_id}'."
        }
    }

    if { $mode eq "a" } {
        if { $create_p || $admin_p } {
            if { ( $asset_type in [list asset_attr asset_only asset_primary_attr] && $asset_type_id ne "") || ( $asset_type eq "attr_only" && $sub_type_id ne "" ) } {
                # allowed
            } else {
                ns_log Notice "hosting-farm/assets.tcl.367: incomplete new \
 asset or attribute request. asset_type '${asset_type}' asset_type_id '${asset_type_id}'"
                set mode "l"
                set mode_next ""
            }
        } elseif { $read_p } {
            set mode "v"
        } else {
            set mode "l"
            set validated_p 0
            ns_log Warning "hosting-farm/assets.tcl.377: \
 mode 'a' denied for '${user_id}'."
        }
    }

    if { $mode eq "l" } {
        if { $read_p } {
            # allowed
        } else {
            set mode ""
            set mode_next ""
            ns_log Warning "hosting-farm/assets.tcl.388: \
 mode 'l' denied for '${user_id}'."
            set validated_p 0
        }
    }

    if { $mode eq "v" } {
        if { $read_p } {
            # allowed
        } else {
            set mode ""
            set mode_next ""
            set validated 0
            ns_log Warning "hosting-farm/assets.tcl.401: \
 mode 'v' denied for '${user_id}'."
        }
    }
    if { !$validated_p } {
        ns_log Notice "hosting-farm/assets.tcl.406: \
 validated_p '${validated_p}' mode '${mode} mode_next '${mode_next}'"
    }

    # ACTIONS
    
    if { $validated_p } {
        ns_log Notice "hosting-farm/assets.tcl.413: ACTION \
 mode '${mode}' mode_next '${mode_next}' validated_p '${validated_p}'"

        # execute process using validated input
        # Using IF instead of SWITCH to allow mode to be modified successively

        if { [string match -nocase "t" $mode] } {
            set processed_p 0
            if { $asset_type eq "" } {
                array set obj_arr [array get input_arr]
                set asset_type [hf_constructor_a obj_arr]
            }
            if { $mode eq "T" } {
                if { [string match "*asset*" $asset_type] && $asset_id ne "" } {
                    set processed_p [hf_asset_untrash $asset_id]
                }
                if { [string match "*attr*" $asset_type] && $sub_f_id ne "" } {
                    ##code
                    set processed_p [hf_attribute_untrash $sub_f_id]
                }
            } else {
                # mode t
                if { [string match "*asset*" $asset_type] && $asset_id ne "" } {
                    set processed_p [hf_asset_trash $asset_id]
                }
                if { [string match "*attr*" $asset_type] && $sub_f_id ne "" } {
                    set processed_p [hf_attribute_trash $sub_f_id]
                }
            }
            if { !$processed_p } {
                ns_log Warning "hosting-farm/assets.tcl.443: \
 trash mode '${mode}'. Unsuccessful or incomplete request"
            }
            set mode $mode_next
            set mode_next ""
        }
        if { $mode eq "c" } {
            if { $create_p } {
                # create only. 
                if { $valid_input_p } {
                    if { [string match "*asset*" $asset_type ] } {
                        # first asset_id is f_id
                        set asset_id [hf_asset_create obj_arr]
                        set obj_arr(f_id) $asset_id
                        if { $mapped_f_id ne "" } {
                            # link asset to asset
                            hf_sub_asset_map_update $mapped_f_id $obj_arr(type_id) $obj_arr(label) $asset_id $obj_arr(asset_type_id) 0
                        }
                    }
                    if { [string match "*attr*" $asset_type ] } {
                        set sub_type_id $obj_arr(sub_type_id)
                        #if { $asset_type eq "attr_only" } {
                        # attr_only
                        #    set obj_arr(f_id) \[qal_first_nonempty_in_list \[list $obj_arr(f_id) $mapped_f_id\]\]
                        #    set obj_arr(sub_type_id) \[qal_first_nonempty_in_list \[list $obj_arr(sub_type_id)  $mapped_type_id\]\]
                        #    set sub_type_id $mapped_type_id
                        #}
                        #set sub_f_id ""
                        if { $sub_type_id ne "" } {
                            set sub_f_id [hf_${sub_type_id}_write obj_arr]
                            set obj_arr(sub_f_id) $sub_f_id
                        } else {
                            ns_log Warning "hosting-farm/assets.tcl.455 sub_type_id ''"
                        }
                        if { $sub_f_id eq "" } {
                            ns_log Warning "hosting-farm/assets.tcl.462: attribute not created. sub_f_id '' array get obj_arr '[array get obj_arr]'"
                        }
                    } else {
                        ns_log Warning "hosting-farm/assets.tcl.465: attribute not created. obj_arr(f_id) '$obj_arr(f_id)' mapped_type_id '${mapped_type_id}'  array get obj_arr '[array get obj_arr]'"
                    }
                }
                set mode $mode_next
            } else {
                ns_log Warning "hosting-farm/assets.tcl.468: mode c, create_p 0 should not happen"
            }
        }

        if { $mode eq "w" } {
            if { $write_p || $admin_p } {
                if { $f_id eq "" } {
                    set f_id_of_asset_id [hf_f_id_of_asset_id $asset_id]
                    set f_id [qal_first_nonempty_in_list [list $mapped_f_id $f_id_of_asset_id]]
                              ns_log Warning "hosting-farm/assets.tcl.470: f_id is ''. Changed to '${f_id}. mapped_f_id '${mapped_f_id}' f_id_of_asst_id '${f_id_of_asset_id}'"
                }
                if { $asset_type_id ne "" || $sub_type_id ne "" } {
                    if { [string match "*asset*" $asset_type] } {
                        set asset_id_old $asset_id
                        set asset_id [hf_asset_write obj_arr]
                        if { $asset_id ne "" } {
                            set obj_arr(asset_id) $asset_id
                            set asset_type_id $obj_arr(asset_type_id)
                        } else {
                            ns_log Warning "hosting-farm/assets.tcl.473: hf_asset_write returned '' for asset_id '${asset_id_old}' array get obj_arr '[array get obj_arr]'"
                        }
                    }
                    if { [string match "*attr*" $asset_type] } {
                        #set sub_type_id $obj_arr(sub_type_id)
                        set sub_f_id_old $sub_f_id
                        set sub_f_id [hf_${sub_type_id}_write obj_arr]
                        if { $sub_f_id ne "" } {
                            set obj_arr(sub_f_id) $sub_f_id
                            set type_id $obj_arr(type_id)
                            set f_id $obj_arr(f_id)
                        } else {
                            ns_log Warning "hosting-farm/assets.tcl.483: hf_${sub_type_id}_write returned '' for sub_f_id '${sub_f_id_old}' array get obj_arr '[array get obj_arr]'"
                        }
                    }
                    set mode $mode_next
                } else {
                    set mode ""
                    ns_log Warning "hosting-farm/assets.tcl.570: asset_type_id '${asset_type_id}'. form input ignored. array get obj_arr '[array get obj_arr]'"
                } 
                # end section of write
                set mode_next ""
            }
        }
    }
}


set menu_list [list ]


# OUTPUT / VIEW
# using switch, because there's only one view at a time
ns_log Notice "hosting-farm/assets.tcl.578: OUTPUT mode ${mode}"
# initializations
set include_assets_p 0
set include_attrs_p 0
set include_asset_p 0

set url "assets"

switch -exact -- $mode {
    l {
        if { $read_p } {
            if { $redirect_before_v_p } {
                ns_log Notice "hosting-farm/assets.tcl.590: redirecting to url ${url} for clean url view"
                ad_returnredirect "${url}?mode=l"
                ad_script_abort
            }
            set asset_ids_list [hf_asset_ids_for_user $user_id $top_level_p]
            set assets_lists [hf_assets_read $asset_ids_list]
            set include_view_assets_p 1
            # pass asset_arr perms_arr for buttons etc.
            array set perms_arr [list read_p $read_p create_p $create_p write_p $write_p admin_p $admin_p pkg_admin_p $pkg_admin_p publish_p $publish_p ]


        } 
    }
    r {
        #  revisions. presents a list of revisions of asset and/or attributes
        if { $admin_p } {
            ns_log Notice "hosting-farm/assets.tcl.606: mode = ${mode} ie. revisions"
            # sort by date
            ##code later, in /www/admin
        }
    }
    a {
        if { $create_p } {
            #  add...... add/form mode of current context
            # If context already exists, use most recent/active case
            # for default values.
            ns_log Notice "hosting-farm/assets.tcl.616: mode = add"
            
            if { $asset_type eq "attr_only" } {
                set asset_type [hf_constructor_a obj_arr force $asset_type $sub_type_id]
                array set obj_arr [array get sam_arr]
                set obj_arr(f_id) $f_id
                ns_log Notice "hosting-farm/assets.tcl.627: array get obj_arr [array get obj_arr]"
                set include_add_one_p 1
                append title " #hosting-farm.Attribute#"
            } elseif { $asset_type ne "" } {
                set asset_type [ hf_constructor_a obj_arr force $asset_type $asset_type_id]
                set include_add_one_p 1
                set publish_p [hf_ui_go_ahead_q write "" published 0]
                append title " #hosting-farm.Asset#"
                ns_log Notice "hosting-farm/assets.tcl.635: publish_p '${publish_p}' asset_id '${asset_id}'"
            }
            array set perms_arr [list read_p $read_p create_p $create_p write_p $write_p admin_p $admin_p pkg_admin_p $pkg_admin_p publish_p $publish_p ]
            # pass asset_arr perms_arr
            set detail_p $pkg_admin_p
            set tech_p $admin_p

            # adjust page context

            if { [exists_and_not_null obj_arr(name)] } {
                set sub_title $obj_arr(name)
            } elseif { [exists_and_not_null obj_arr(label)] } {
                set sub_title $obj_arr(label)
            } elseif { [exists_and_not_null obj_arr(sub_label)] } {
                set sub_title $obj_arr(sub_label)
            } elseif { [exists_and_not_null obj_arr(asset_type_id)] } {
                set sub_title $obj_arr(asset_type_id)
            } else {
                set sub_title $obj_arr(sub_type_id)
            }
            append title " ${sub_title} - #acs-subsite.create#"
            set context [list [list assets #hosting-farm.Assets#] "${sub_title} - #acs-subsite.create#"]  

            if { ![exists_and_not_null asset_type] } {
                ns_log Warning "hosting-farm/assets.tcl.659: asset_type not defined."
            }

            ##code



        } else {
            lappend user_message_list "#q-wiki.Edit_operation_did_not_succeed# #q-wiki.You_don_t_have_permission#"
            util_user_message -message [lindex $user_message_list end]
        }
    }
    e {
        if { $write_p } {
            #  edit...... edit/form mode of current context
            # If context already exists, use most recent/active case
            # for default values.
            ns_log Notice "hosting-farm/assets.tcl.676: mode = edit"

            # 0. asset_type_id:
            #    New combo asset and primary attribute of asset_type_id
            
            # 1. asset_id/f_id:
            #    Edit asset
            
            # 2. asset_id/f_id,primary sub_asset_id/f_id:
            #    Edit combo existing asset and attribute 
            
            # 3. sub_asset_id/sub_f_id
            #    Edit attribute
            
            # 4. asset_id/f_id and asset_type_id
            #    New attribute of asset_id
            # If asset and non primary attribute exist, just
            # edit the attribute.
            # set include_view_one_p 1
            if { $asset_type eq "attr_only" } {
                if { !$keep_user_input_p } {
                    array set obj_arr [array get sam_arr]
                    if { $sub_type_id in [hf_asset_type_id_list] } {
                        set obj_arr(sub_type_id) $sub_type_id
                        set sub_asset_list [hf_${sub_type_id}_read $sub_f_id]
                        qf_lists_to_array obj_arr $sub_asset_list [hf_${sub_type_id}_keys]
                        ns_log Notice "hosting-farm/assets.tcl.700: array get obj_arr [array get obj_arr]"
                    }
                }
                set include_edit_one_p 1
                
            } else {
                if { $keep_user_input_p } {
                    set asset_type [hf_constructor_a obj_arr]
                } else {
                    set asset_type [hf_constructor_b obj_arr]
                }
                set include_edit_one_p 1
                set publish_p [hf_ui_go_ahead_q write "" published 0]
                ns_log Notice "hosting-farm/assets.tcl.710 publish_p '${publish_p}' asset_id '${asset_id}'"
            }
            array set perms_arr [list read_p $read_p create_p $create_p write_p $write_p admin_p $admin_p pkg_admin_p $pkg_admin_p publish_p $publish_p ]
            # pass asset_arr perms_arr
            set detail_p $pkg_admin_p
            set tech_p $admin_p

            # adjust page context
            append title " -  #q-wiki.edit#"
            if { [info exists obj_arr(name)] } {
                set context [list [list assets #hosting-farm.Assets#] "$obj_arr(name) - #q-wiki.edit#"]
            } elseif { [info exists obj_arr(label)] } {
                set context [list [list assets #hosting-farm.Assets#] "$obj_arr(label) - #q-wiki.edit#"]
            } elseif { [info exists obj_arr(sub_label)] } {
                set context [list [list assets #hosting-farm.Assets#] "$obj_arr(sub_label) - #q-wiki.edit#"]
            }

            if { ![exists_and_not_null asset_type] } {
                ns_log Warning "hosting-farm/assets.tcl.726: asset_type not defined."
            }

            ##code



        } else {
            lappend user_message_list "#q-wiki.Edit_operation_did_not_succeed# #q-wiki.You_don_t_have_permission#"
            util_user_message -message [lindex $user_message_list end]
        }
    }
    v {
        #  view page(s) (standard, html page document/report)
        if { $read_p } {
            # if $url is different than ad_conn url stem, 303/305 redirect to asset_id's primary url
            if { $redirect_before_v_p } {
                ns_log Notice "hosting-farm/assets.tcl.743: redirecting to url ${url} for clean url view"
                ad_returnredirect $url
                ad_script_abort
            }
            ns_log Notice "hosting-farm/assets.tcl.750: view mode '${mode}' asset_id '${asset_id}' sub_f_id '${sub_f_id}' asset_type '${asset_type}'"

            set title "#hosting-farm.Asset#"

            # ignore inputs from forms
            # retrieve data from db
            if { $asset_type eq "attr_only" } {
                if { $sub_type_id in [hf_asset_type_id_list] } {
                    set sub_asset_list [hf_${sub_type_id}_read $sub_f_id]
                    qf_lists_to_array obj_arr $sub_asset_list [hf_${sub_type_id}_keys]
                    if { [array exists sam_arr] } {
                        array set obj_arr [array get sam_arr]
                    } else {
                        set sam_list [hf_sub_asset $sub_f_id]
                        qf_lists_to_array obj_arr $sam_list [hf_sub_asset_map_keys]
                    }
                    ns_log Notice "hosting-farm/assets.tcl.760: array get obj_arr [array get obj_arr]"
                }
                set include_view_one_p 1
            } else {
                set asset_type [hf_constructor_b obj_arr]
                set include_view_one_p 1
                set publish_p [hf_ui_go_ahead_q write "" published 0]
            }
            ns_log Notice "hosting-farm/assets.tcl.790: publish_p '${publish_p}' asset_id '${asset_id}'"
            array set perms_arr [list read_p $read_p create_p $create_p write_p $write_p admin_p $admin_p pkg_admin_p $pkg_admin_p publish_p $publish_p ]
            # pass asset_arr perms_arr
            set detail_p $pkg_admin_p
            set tech_p $admin_p
            
            # adjust page context
            if { [info exists obj_arr(name)] } {
                set context [list [list assets #hosting-farm.Assets#] $obj_arr(name)]
            } elseif { [info exists obj_arr(label)] } {
                set context [list [list assets #hosting-farm.Assets#] $obj_arr(label)]
            } elseif { [info exists obj_arr(sub_label)] } {
                set context [list [list assets #hosting-farm.Assets#] $obj_arr(sub_label) ]
            }

        } else {
            # no permission to read page. This should not happen.
            ns_log Warning "hosting-farm/assets.tcl.805: user did not get expected 404 error when not able to read page."
        }
    }
    w {
        #  save.....  (write) asset_id 
        # should already have been handled above and switched to another mode.
        ns_log Warning "hosting-farm/assets.tcl.820: mode = save/write THIS SHOULD NOT BE CALLED HERE."
    }
    default {
        # return 404 not found or not validated (permission or other issue)
        # this should use the base from the config.tcl file
        if { [llength $user_message_list ] == 0 } {
            ns_returnnotfound
            #  rp_internal_redirect /www/global/404.adp
            ad_script_abort
        }
        ns_log Warning "hosting-farm/assets.tcl.833: mode '${mode}' mode_next '${mode_next}' THIS SHOULD NOT BE CALLED HERE."
    }
}
# end of switches

# using OpenACS built-in util_get_user_messages feature
set user_message_html ""
#util_get_user_messages -multirow user_message_list
#foreach user_message $user_message_list {
#    append user_message_html "<li>${user_message}</li>"
#    ns_log Notice "hosting-farm/assets.tcl.842: user_message '${user_message}'"
#}

# for buttons as multiple form submits within one form, example of a submit:
# from accounts-finance: input type="submit" value="Sort by Y ascending" name="zy" class="btn"

set menu_html ""
if { $form_posted_p && $validated_p || !$form_posted_p } {
    foreach item_list $menu_list {
        set menu_label [lindex $item_list 0]
        set menu_url [lindex $item_list 1]
        append menu_html "<a href=\"${menu_url}\" title=\"${menu_label}\">${menu_label}</a> &nbsp; "
    }
} 
set doc(title) $title

