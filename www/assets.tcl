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
set pkg_admin_p 0
set publish_p 0
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
set include_view_attr_p 0
set include_view_attrs_p 0
set include_view_sub_assets_p 0
set include_edit_one_p 0
set include_edit_attr_p 0
array set input_arr \
    [list \
         asset_id "" \
         asset_type "" \
         asset_type_id "" \
         customer_id "" \
         f_id "" \
         name "" \
         mode "l" \
         mode_next "" \
         page_title $title \
         reset "" \
         state "" \
         sub_asset_id "" \
         sub_f_id "" \
         submit "" \
         s "" \
         p "" \
         this_start_row "" \
         interval_remaining "" \
         top_level_p "0"]

# INPUTS


# Get form inputs if they exist
set form_posted_p [qf_get_inputs_as_array input_arr hash_check 1]

if { !$form_posted_p } {
    # form not posted. Get defaults.
    template::util::array_to_vars input_arr
} else {

    # Convert input_array to variables
    qf_array_to_vars input_arr \
        [list \
             asset_id \
             asset_type_id \
             customer_id \
             f_id \
             mode \
             mode_next \
             page_title \
             state \
             sub_asset_id \
             s \
             p \
             this_start_row \
             top_level_p \
             interval_remaining \
             sub_f_id ]
    # x,y elements in input_arr holds position of image-based submit
    array unset input_arr x
    array unset input_arr y


    # following is part of dynamic menu processing using form tags instead of url/GET
    # key,value is passed as a single name, with first letter z for asset_id or Z for sub_f_id.
    set input_arr_idx_list [array names input_arr]
    # add required defaults not passed by form
    set asset_type ""


    ##code update this regexp?
    set modes_idx [lsearch -regexp $input_arr_idx_list {[Zz][vpsSrnwctTdel][ivcrl][1-9][0-9]*}]
    if { $modes_idx > -1 && $mode eq "p" } {
        set modes [lindex $input_arr_idx_list $modes_idx]
        set test [string range $modes 0 3]
        if { [string match {z[ev]*} $test] } {
            set asset_id [string range $modes 3 end]
            ns_log Notice "hosting-farm/www/assets.tcl.110: asset_id '${asset_id}'"
        }
        if { [string match "zl*" $test] } {
            set this_start_row [string range $modes 3 end]
            ns_log Notice "hosting-farm/www/assets.tcl.114: this_start_row '${this_start_row}'"
        }
        if { [string match "Zv*" $test] } {
            set sub_f_id [string range $modes 3 end]
            ns_log Notice "hosting-farm/www/assets.tcl.121: sub_f_id '${sub_f_id}'"
            # set asset_id for permissions, and make rest of map record available. sub_type_id etc.
            set sam_list [hf_sub_asset $sub_f_id]
            qf_lists_to_array sam_arr $sam_list [hf_sub_asset_map_keys]
            set f_id [hf_asset_f_id_of_sub_f_id $sam_arr(f_id)]
            set asset_id [hf_asset_id_current_of_f_id $f_id]
            set asset_type "attr_only"
            set sub_type_id $sam_arr(sub_type_id)
        }


        # modes 0 0 is z
        set mode [string range $modes 1 1]
        set next_mode [string range $modes 2 2]

    }

    # Validate input

    # possibilities are: d, t, w, e, v, l, r, "" where "" is invalid input or unreconcilable error condition.
    # options include    d, D, l, r, t, e, "", w, v, a
    if { [string length $mode] != 1 } {
        set mode "v"
        set mode_next ""
    }
    if { [string length $mode_next] > 1 } {
        set mode_next ""
    }
    if { [string first $mode "dt"] > -1 \
                   && [string first $mode_next "lrv"] == -1 } {
        set mode_next "v"
    }

    ns_log Notice "hosting-farm/www/assets.tcl(115): \
 mode '${mode}' mode_next ${mode_next}"

    set validated_p 0
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
        set pkg_admin_p [permission::permission_p \
                             -party_id $user_id \
                             -object_id $instance_id \
                             -privilege admin]
    }


    # Cleanse data, verify values for consistency
    # Determine input completeness

    if { [qf_is_natural_number $asset_id] } {
        if { [hf_asset_id_exists_q $asset_id ] || $asset_type eq "attr_only" } {
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
        if { [hf_asset_id_exists_q $f_id ] || $asset_type eq "attr_only" } {
            # Probably valid f_id
        } else {
            set f_id ""
        }
    } else {
        set f_id ""
    }
    if { [qf_is_natural_number $sub_f_id] } {
        if { [hf_sub_f_id_exists_q $sub_f_id ] } {
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
        if { $customer_id ni $customer_ids_list && !$pkg_admin_p } {
            set customer_id ""
        }
    }
    ns_log Notice "hosting-farm/assets.tcl(214): user_id '${user_id}' \
 customer_id '${customer_id}' asset_id '${asset_id}' "

    ns_log Notice "hosting-farm/assets.tcl(165): read_p '${read_p}' \
 create_p ${create_p} write_p ${write_p} admin_p ${admin_p} \
 pkg_admin_p '${pkg_admin_p}'"

    set referrer_url [get_referrer]
    set http_header_method [ad_conn method]
    # A blank referrer means a direct request
    # otherwise make sure referrer is from same domain when editing.
    if { $referrer_url ne "" } {
        ns_log Notice "hosting-farm/assets.tcl(189): form_posted_p '${form_posted_p}' \
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
    #   T  = untrash asset_id
    #   w  = write asset_id/sub_asset_id asset_type_id
    #   a  = add asset_type_id
    #   s  = publish
    #   S  = Unpublish

    # Views
    #   e  = edit asset_id/sub_asset_id or attribute, presents defaults if no prior data
    #   v  = view asset_id or sub_asset_id (attribute_id or asset_id)
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
            set mode_next ""
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
                set mode_next ""
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
            set mode_next ""
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
            set mode_next ""
            set validated 0
            ns_log Warning "hosting-farm/assets.tcl(280): \
 mode 'v' denied for '${user_id}'."
        }
    }
    if { !$validated_p } {
        ns_log Notice "hosting-farm/assets.tcl(287): \
 validated_p '${validated_p}' mode '${mode} mode_next '${mode_next}'"
    }

    # ACTIONS
 
    if { $validated_p } {
        ns_log Notice "hosting-farm/assets.tcl(300): ACTION \
 mode '${mode}' mode_next '${mode_next}' validated_p '${validated_p}'"

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
            set mode $mode_next
            set mode_next ""
        }

        if { $mode eq "w" } {
            if { $write_p } {
                # ad-unquotehtml values before posting to db
                set mode $mode_next
                
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
            set mode_next ""
        }
    }
}


set menu_list [list ]


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
            set asset_ids_list [hf_asset_ids_for_user $user_id $top_level_p]
            set assets_lists [hf_assets_read $asset_ids_list]
            set include_view_assets_p 1

        } 
    }
    r {
        #  revisions. presents a list of revisions of asset and/or attributes
        if { $admin_p } {
            ns_log Notice "hosting-farm/assets.tcl mode = $mode ie. revisions"
            # sort by date
            ##code later, in /www/admin
        }
    }
    e {
        if { $write_p } {
            #  edit...... edit/form mode of current context
            # If context already exists, use most recent/active case
            # for default values.
            ns_log Notice "hosting-farm/assets.tcl mode = edit"

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
                array set obj_arr [array get sam_arr]
                if { $sub_type_id in [hf_asset_type_id_list] } {
                    set sub_asset_list [hf_${sub_type_id}_read $sub_f_id]
                    qf_lists_to_array obj_arr $sub_asset_list [hf_${sub_type_id}_keys]
                }
                set include_edit_attr_p 1
            } else {
                set asset_type [hf_constructor_b obj_arr]
                set include_edit_one_p 1
                set publish_p [hf_ui_go_ahead_q write "" published 0]
                ns_log Notice "assets.tcl.490 publish_p '${publish_p}' asset_id '${asset_id}'"
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
                ns_log Warning "assets.tcl.507: asset_type not defined."
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
                ns_log Notice "hosting-farm/assets.tcl(835): redirecting to url ${url} for clean url view"
                ad_returnredirect $url
                ad_script_abort
            }
            ns_log Notice "hosting-farm/assets.tcl(667): view mode '${mode}' asset_id '${asset_id}' sub_f_id '${sub_f_id}' asset_type '${asset_type}'"

            set title "#hosting-farm.Asset#"
            # add default, to convert attr_only to include asset?
            #set asset_type \[hf_constructor_a asset_arr default asset_attr\]
            if { $asset_type eq "attr_only" } {
                array set obj_arr [array get sam_arr]
                if { $sub_type_id in [hf_asset_type_id_list] } {
                    set sub_asset_list [hf_${sub_type_id}_read $sub_f_id]
                    qf_lists_to_array obj_arr $sub_asset_list [hf_${sub_type_id}_keys]
                    ns_log Notice "hosting-farm/assets.tcl(669): array get obj_arr [array get obj_arr]"
                }

                set include_view_attr_p 1
                set attrs_list [hf_asset_attributes $sub_f_id]
                if { [llength $attrs_list ] > 0 } {
                    set include_view_attrs_p 1
                }
                
                set asset_ids_list [hf_asset_subassets $sub_f_id]
                if { [llength $asset_ids_list ] > 0 } {
                    set assets_lists [hf_assets_read $asset_ids_list]
                    set include_view_sub_assets_p 1
                }
            } else {
                set asset_type [hf_constructor_b obj_arr]
                set include_view_one_p 1
                set publish_p [hf_ui_go_ahead_q write "" published 0]
                if { $f_id ne "" } {
                    set attrs_list [hf_asset_attributes $f_id]
                    if { [llength $attrs_list ] > 0 } {
                        set include_view_attrs_p 1
                    }
                    
                    set asset_ids_list [hf_asset_subassets $f_id]
                    if { [llength $asset_ids_list ] > 0 } {
                        set assets_lists [hf_assets_read $asset_ids_list]
                        set include_view_sub_assets_p 1
                    }
                }
            }
            ns_log Notice "assets.tcl.539 publish_p '${publish_p}' asset_id '${asset_id}'"
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

