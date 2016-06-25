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
set read_p [permission:permission_p \
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
set pkg_admin_p 0
set title "#hosting-farm.Assets#"
set icons_path1 "/resources/acs-subsite/"
set icons_path2 "/resources/ajaxhelper/icons/"
set delete_icon_url [file join $icons_path2 delete.png]
set trash_icon_url [file join $icons_path2 page_delete.png]
set untrash_icon_url [file join $icons_path2 page_add.png]
set radio_checked_url [file join $icons_path1 radiochecked.gif]
set radio_unchecked_url [file join $icons_path1 radio.gif]
set redirect_before_v_p 0
set user_message_list [list ]

array set input_arr \
    [list \
         asset_id "" \
         asset_type_id "" \
         customer_id "" \
         f_id "" \
         mode "v" \
         next_mode "" \
         page_title $title \
         reset "" \
         state "" \
         sub_asset_id "" \
         sub_f_id "" \
         submit "" ]

# INPUTS

# Get form inputs if they exist
set form_posted_p [qf_get_inputs_as_array input_arr hash_check 1]

if { $form_posted_p } {
    if { [qf_is_natural_number $customer_id] } {

    }
    

    # Convert input_array to variables
    qf_array_to_vars input_arr \
        [list \
             asset_id \
             asset_type_id \
             customer_id \
             f_id \
             mode \
             next_mode \
             page_title \
             state \
             sub_asset_id \
             sub_f_id ]
    # x,y elements in input_arr holds position of image-based submit
    array unset input_arr x
    array unset input_arr y

    # Validate input

    # possibilities are: d, t, w, e, v, l, r, "" where "" is invalid input or unreconcilable error condition.
    # options include    d, D, l, r, t, e, "", w, v, a
    if { [string length $mode] != 1 } {
        set mode "v"
        set next_mode ""
    }
    if { [string length $next_mode] > 1 } {
        set next_mode ""
    }
    if { [string first $mode "Ddtwvaelr"] == -1 } {
        set mode "v"

    } elseif { [string first $mode "dt"] > -1 \
                   && [string first $next_mode "lrv"] == -1 } {
        set next_mode "v"
    }

    ns_log Notice "hosting-farm/www/assets.tcl(115): \
 mode '${mode} next_mode ${next_mode}"

    set validated_p 0
    # Cleanse data, verify values for consistency
    # Determine input completeness

    if { [qf_is_natural_number $asset_id] } {
        if { [hf_asset_id_exists_q $asset_id ] } {
            # Probably valid asset_id
        } else {
            set asset_id ""
        }
    } else {
        set asset_id ""
    }
    if { [qf_is_natural_number $sub_asset_id] } {
        if { [hf_asset_id_exists_q $sub_asset_id ] } {
            # Probably valid sub_asset_id
        } else {
            set sub_asset_id ""
        }
    } else {
        set sub_asset_id ""
    }
    if { [qf_is_natural_number $f_id] } {
        if { [hf_asset_id_exists_q $f_id ] } {
            # Probably valid f_id
        } else {
            set f_id ""
        }
    } else {
        set f_id ""
    }
    if { [qf_is_natural_number $sub_f_id] } {
        if { [hf_asset_id_exists_q $sub_f_id ] } {
            # Probably valid sub_f_id
        } else {
            set sub_f_id ""
        }
    } else {
        set sub_f_id ""
    }

    if { $asset_type_id ne "" &&  $asset_type_id ni [hf_asset_type_id_list ] } {
        set asset_type_id ""
    }

    if { $customer_id ne "" && [qf_is_natural_number $customer_id ] } {
        set customer_ids_list [hf_customer_ids_for_user $user_id $instance_id]
        if { $customer_id ni $customer_ids_list } {
            set customer_id ""
        }
    }

    ns_log Notice "hosting-farm/assets.tcl(152): user_id '${user_id}' \
 customer_id '${customer_id}' asset_id '${asset_id}' "
    # special cases require special permissions
    # Re-checking read_p in context of input.
    set read_p [hf_ui_go_ahead_q read "" "" 0]
    set create_p [hf_ui_go_ahead_q create "" "" 0]
    set write_p [hf_ui_go_ahead_q write "" "" 0]
    set admin_p [hf_ui_go_ahead_q admin "" "" 0]
    if { $admin_p } {
        # check package admin for extras
        set pkg_admin_p [permission:permission_p \
                             -party_id $user_id \
                             -object_id $instance_id \
                             -privilege admin]
    }
    ns_log Notice "hosting-farm/assets.tcl(165): read_p '${read_p}' \
 create_p ${create_p} write_p ${write_p} admin_p ${admin_p} \
 pkg_admin_p '${pkg_admin_p}'"

    set referrer_url [get_referrer]
    set http_header_method [ad_conn method]
    # A blank referrer means a direct request
    # otherwise make sure referrer is from same domain when editing.
    if { $referrer_url ne "" } {
        ns_log Notice "hosting-farm/assets.tcl(189): form_posted_p \
 http_header_method ${http_header_method} referrer '${referrer_url}'"
    }
    if { ![string match -nocase "post*" $http_header_method ] } {
        # Make sure there is a clean url, should page be bookmarked etc
        set $redirect_before_v_p 1
    }

    set validated_p 1
    # Validate input for specific modes

    # Modes are views, or one of these compound action/views
    #   d   delete (d x) then view as before (where x = l, r or v)
    #   t   trash (d x) then view as before (where x = l, r or v)
    #   w   write (d x) , then view asset_id (v)
    
    # Actions
    #   d  = delete asset_id or sub_asset_id
    #   D  = delete f_id or sub_f_id 
    #   t  = trash asset_id or sub_asset_id
    #   w  = write asset_id/sub_asset_id asset_type_id
    #   a  = add asset_type_id

    # Views
    #   e  = edit asset_id/sub_asset_id, presents defaults if no prior data
    #   v  = view asset_id or sub_asset_id
    #   l  = list assets
    #   r  = view history (can only delete if pkg admin)
    #   "" = view list of role oriented summaries
    #          such as many customers and assets as possible etc.

    # keeping the logic simple in this section
    # Using IF instead of SWITCH to allow mode to be modified successively
    if { $mode eq "w" } { 
        if { $write_p || $create_p || $admin_p } {
            # allowed
            if { $create_p && !$write_p } {
                # create only. Remove any existing revision references
                set asset_id ""
                set sub_asset_id ""
                set f_id ""
                set sub_f_id ""
            }
        } else {
            set mode ""
            set next_mode ""
            set validated_p 0
            ns_log Warning "hosting-farm/assets.tcl(215): \
 write denied for '${user_id}'."
        }
    }

    if { $mode eq "t" } {
        if { $write_p || $admin_p } {
            # allowed
        } else {
            ns_log Warning "hosting-farm/assets.tcl(222): \
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
            ns_log Warning "hosting-farm/assets.tcl(244): \
 mode '${mode}' denied for '${user_id}'."
            set mode ""
            set validated_p 0
        }
    }

    if { $mode eq "e" } {
        if { $write_p || $admin_p } {
            # allowed
            # copy everything. Only obj keys pass constructor.
            array set ob_arr [array get input_arr]

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
            hf_constructor_a obj_arr
            
        } elseif { $read_p } {
            set mode "v"
        } else {
            set mode "l"
            set validated_p 0
            ns_log Warning "hosting-farm/assets.tcl(258): \
 mode 'e' denied for '${user_id}'."
        }
    }

    if { $mode eq "a" } {
        if { $create_p || $admin_p } {
            # allowed
            if { $state in [list asset_attr attr_only asset_only asset_primary_attr] && $asset_type_id ne "" } {
                hf_constructor_a obj_arr force $state $asset_type_id
            } else {
                ns_log Notice "hosting-farm/assets.tcl.301: incomplete new \
 asset request. state '${state}' asset_type_id '${asset_type_id}'"
                set mode "l"
                set next_mode ""
            }
        } elseif { $read_p } {
            set mode "v"
        } else {
            set mode "l"
            set validated_p 0
            ns_log Warning "hosting-farm/assets.tcl(262): \
 mode 'a' denied for '${user_id}'."
        }
    }

    if { $mode eq "l" } {
        if { $read_p } {
            # allowed
        } else {
            set mode ""
            set next_mode ""
            ns_log Warning "hosting-farm/assets.tcl(268): \
 mode 'l' denied for '${user_id}'."
            set validated_p 0
        }
    }

    if { $mode eq "v" } {
        if { $read_p } {
            # allowed
        } else {
            set mode ""
            set next_mode ""
            set validated 0
            ns_log Warning "hosting-farm/assets.tcl(280): \
 mode 'v' denied for '${user_id}'."
        }
    }
    if { !$validated_p } {
        ns_log Notice "hosting-farm/assets.tcl(287): \
 validated_p '${validated_p}' mode '${mode} next_mode '${next_mode}'"
    }

    # ACTIONS
 
    if { $validated_p } {
        ns_log Notice "hosting-farm/assets.tcl(300): ACTION \
 mode '${mode} next_mode '${next_mode}' validated_p '${validated_p}'"

        # execute process using validated input
        # Using IF instead of SWITCH to allow mode to be modified successively

        if { $mode eq "a" } {

        }

        if { $mode eq "t" } {
            # choose the most specific reference only
            if { $sub_asset_id ne "" } {

            } elseif { $asset_id ne "" } {

            } elseif { $sub_f_id ne "" } {

            } elseif { $f_id ne "" } {
            } else {
                ns_log Warning "hosting-farm/assets.tcl(331): \
 trash requested without an expected reference"
            }
            set mode $next_mode
            set next_mode ""
        }

        if { $mode eq "w" } {
            if { $write_p } {
                # ad-unquotehtml values before posting to db
                set mode $next_mode
                
            } else {
                # does not have permission to write
                lappend user_message_list "#q-wiki.Write_operation_did_not_succeed# #q-wiki.You_don_t_have_permission#"
                util_user_message -message [lindex $user_message_list end]
                ns_log Notice "hosting-farm/assets.tcl(402) User attempting to write content without permission."
                if { $read_p } {
                    set mode "v"
                } else {
                    set mode ""
                }
            }
            # end section of write
            set next_mode ""
        }
    }
} else {
    # form not posted

}


set menu_list [list ]

 ##code

# OUTPUT / VIEW
# using switch, because there's only one view at a time
ns_log Notice "hosting-farm/assets.tcl(508): OUTPUT mode $mode"
# initializations
set include_assets_p 0
set include_attrs_p 0
set include_asset_p 0
set include_attr_p 0
set url "assets"

switch -exact -- $mode {
    l {
        if { $read_p } {
            if { $redirect_before_v_p } {
                ns_log Notice "hosting-farm/assets.tcl(587): redirecting to url ${url} for clean url view"
                ad_returnredirect "${url}?mode=l"
                ad_script_abort
            }
            set include_assets_p 1
            set asset_ids_list [hf_asset_ids_for_user $user_id]
            set assets_lists [hf_assets_read $asset_ids_list]
        } 
    }
    r {
        #  revisions. presents a list of revisions of asset and/or attributes
        if { $admin_p } {
            ns_log Notice "hosting-farm/assets.tcl mode = $mode ie. revisions"
            # sort by date
##code
        }
    }
    e {
        if { $write_p } {
            #  edit...... edit/form mode of current context
            # If context already exists, use most recent/active case
            # for default values.
            ns_log Notice "hosting-farm/assets.tcl mode = edit"

            foreach key [array names obj_arr] {
                set obj_arr(${key}) [qf_unquote $obj_arr(${key}) ]
            }


            set cancel_link_html "<a hrer=\"list?mode=l\">#acs-kernel.common_Cancel#</a>"

            set conn_package_url [ad_conn package_url]
            set post_url [file join $conn_package_url $url]

            append title "${title} -  #q-wiki.edit#"

            qf_form action $post_url method post id 20160616 hash_check 1
            qf_input type hidden value w name mode
            qf_input type hidden value v name next_mode
            qf_append html "<div style=\"width: 70%; text-align: right;\">"

            foreach {key val} [array get obj_arr] {
                if { [hf_key_hidden_q $key] } {
                    qf_input type hidden value $val name $key
                } else {
                    qf_append html "<br>"
                    set val_unquoted [qf_unquote $val]
                    qf_input type text value $val_unquoted name $key label "#hosting-farm.${key}#:" size 40 maxlength 80
                }
            }

            qf_append html "</div>"
            qf_input type submit value "#acs-kernel.common_Save#"
            qf_append html " &nbsp; &nbsp; &nbsp; ${cancel_link_html}"
            qf_close
            set form_html [qf_read]

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
                ns_log Notice "hosting-farm/assets.tcl(835): redirecting to url ${url} for clean url view"
                ad_returnredirect $url
                ad_script_abort
            }
            ns_log Notice "hosting-farm/assets.tcl(667): mode = $mode ie. view"

            lappend menu_list [list #q-wiki.index# "index?mode=l"]

            if { $create_p } {
                if { $admin_p } {
                    lappend menu_list [list #q-wiki.revisions# "${url}?mode=r"]
                } 
                lappend menu_list [list #q-wiki.edit# "${url}?mode=e" ]
            }
            
            set title $page_title
            set include_view_one_p 1

        } else {
            # no permission to read page. This should not happen.
            ns_log Warning "hosting-farm/assets.tcl:(619) user did not get expected 404 error when not able to read page."
        }
    }
    w {
        #  save.....  (write) asset_id 
        # should already have been handled above and switched to another mode.
        ns_log Warning "hosting-farm/assets.tcl(575): mode = save/write THIS SHOULD NOT BE CALLED HERE."
    }
    default {
        # return 404 not found or not validated (permission or other issue)
        # this should use the base from the config.tcl file
        if { [llength $user_message_list ] == 0 } {
            ns_returnnotfound
            #  rp_internal_redirect /www/global/404.adp
            ad_script_abort
        }
    }
}
# end of switches

# using OpenACS built-in util_get_user_messages feature
#set user_message_html ""
#foreach user_message $user_message_list {
#    append user_message_html "<li>${user_message}</li>"
#}

set menu_html ""
if { $form_posted_p && $validated_p || !$form_posted_p } {
    foreach item_list $menu_list {
        set menu_label [lindex $item_list 0]
        set menu_url [lindex $item_list 1]
        append menu_html "<a href=\"${menu_url}\" title=\"${menu_label}\">${menu_label}</a> &nbsp; "
    }
} 
set doc(title) $title
set context [list $title]
