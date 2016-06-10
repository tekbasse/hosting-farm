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
             sub_asset_id \
             sub_f_id ]
    # x,y elements in input_arr holds position of image-based submit
    array unset input_arr

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
 mode '${mode} next_mode '${next_mode}' validated_p '${validated_p}'"
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
 ##code
        if { $mode eq "w" } {
            if { $write_p } {
                ns_log Notice "hosting-farm/assets.tcl permission to write the write.."
                set page_contents_quoted $page_contents
                set page_contents [ad_unquotehtml $page_contents]
                set allow_adp_tcl_p [parameter::get -package_id $package_id -parameter AllowADPTCL -default 0]
                set flagged_list [list ]
                
                if { $allow_adp_tcl_p } {
                    ns_log Notice "hosting-farm/assets.tcl(311): adp tags allowed. Fine grain filtering.."
                    # filter page_contents for allowed and banned procs in adp tags
                    set banned_proc_list [split [parameter::get -package_id $package_id -parameter BannedProc]]
                    set allowed_proc_list [split [parameter::get -package_id $package_id -parameter AllowedProc]]
                    
                    set code_block_list [qf_get_contents_from_tags_list "<%" "%>" $page_contents]
                    foreach code_block $code_block_list {
                        # split into lines
                        set code_segments_list [split $code_block \n\r]
                        foreach code_segment $code_segments_list  {
                            # see filters in accounts-finance/tcl/modeling-procs.tcl for inspiration
                            # split at the beginning of each open square bracket
                            set executable_fragment_list [split $code_segment \[]
                            set executable_list [list ]
                            foreach executable_fragment $executable_fragment_list {
                                # right-clip to just the executable for screening purposes
                                set space_idx [string first " " $executable_fragment]
                                if { $space_idx > -1 } {
                                    set end_idx [expr { $space_idx - 1 } ]
                                    set executable [string range $executable_fragment 0 $end_idx]
                                } else {
                                    set executable $executable_fragment
                                }
                                # screen executable
                                if { $executable eq "" } {
                                    # skip an empty executable
                                    # ns_log Notice "hosting-farm/assets.tcl(395): executable is empty. Screening incomplete?"
                                } else {
                                    # see if this proc is allowed
                                    set proc_allowed_p 0
                                    foreach allowed_proc $allowed_proc_list {
                                        if { [string match $allowed_proc $executable] } {
                                            set proc_allowed_p 1
                                        }
                                    }
                                    # see if this proc is banned. Banned takes precedence over allowed.
                                    if { $proc_allowed_p } {
                                        foreach banned_proc $banned_proc_list {
                                            if { [string match $banned_proc $executable] } {
                                                # banned executable found
                                                set proc_allowed_p 0
                                                lappend flagged_list $executable
                                                lappend user_message_list "'$executable' #q-wiki.is_banned_from_use#"
            util_user_message -message [lindex $user_message_list end]
                                            }
                                        }            
                                    } else {
                                        lappend flagged_list $executable
                                        lappend user_message_list "'$executable' #q-wiki.is_not_allowed_at_this_time#"
            util_user_message -message [lindex $user_message_list end]
                                    }
                                }
                            }
                        }
                    }
                    if { [llength $flagged_list] == 0 } {
                        # content passed filters
                        set page_contents_filtered $page_contents
                    } else {
                        set page_contents_filtered $page_contents_quoted
                    }
                } else {
                    # filtering out all adp tags (allow_adp_tcl_p == 0)
                    ns_log Notice "hosting-farm/assets.tcl(358): filtering out adp tags"
                    # ns_log Notice "hosting-farm/assets.tcl(359): range page_contents 0 120: '[string range ${page_contents} 0 120]'"
                    set page_contents_list [qf_remove_tag_contents "<%" "%>" $page_contents]
                    set page_contents_filtered [join $page_contents_list ""]
                    # ns_log Notice "hosting-farm/assets.tcl(427): range page_contents_filtered 0 120: '[string range ${page_contents_filtered} 0 120]'"
                }
                # use $page_contents_filtered, was $page_contents
                set page_contents [ad_quotehtml $page_contents_filtered]
                
                if { [llength $flagged_list ] > 0 } {
                    ns_log Notice "hosting-farm/assets.tcl(369): content flagged, changing to edit mode."
                    set mode e
                } else {
                    # write the data
                    # a different user_id makes new context based on current context, otherwise modifies same context
                    # or create a new context if no context provided.
                    # given:

                    # create or write page
                    if { $asset_id eq "" } {
                        # create page
                        set asset_id [qw_page_create $url $page_name $page_title $page_contents_filtered $keywords $description $page_comments $page_f_id $page_flags $package_id $user_id]
                        if { $asset_id == 0 } {
                            ns_log Warning "q-wiki/hosting-farm/assets.tcl page write error for url '${url}'"
                            lappend user_messag_list "There was an error creating the wiki page at '${url}'."
                        }
                    } else {
                        # write page
                        set asset_id [qw_page_write $page_name $page_title $page_contents_filtered $keywords $description $page_comments $asset_id $page_f_id $page_flags $package_id $user_id]
                        if { $asset_id eq "" } {
                            ns_log Warning "q-wiki/hosting-farm/assets.tcl page write error for url '${url}'"
                            lappend user_messag_list "#q-wiki.There_was_an_error_creating_page# '${url}'."
                        }
                    }

                    # rename existing pages?
                    if { $url ne $page_name } {
                        # rename url, but first post the page
                        if { [qw_page_rename $url $page_name $package_id ] } {
                            # if success, update url and redirect
                            set redirect_before_v_p 1
                            set url $page_name
                            set next_mode "v"
                        }
                    }

                    # switch modes..
                    ns_log Notice "hosting-farm/assets.tcl(396): activating next mode $next_mode"
                    set mode $next_mode
                }
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
    ns_log Warning "hosting-farm/assets.tcl(451): Form not posted. This shouldn't happen via index.vuh."
}


set menu_list [list ]

# OUTPUT / VIEW
# using switch, because there's only one view at a time
ns_log Notice "hosting-farm/assets.tcl(508): OUTPUT mode $mode"
switch -exact -- $mode {
    l {
        #  list...... presents a list of pages  (Branch this off as a procedure and/or lib page fragment to be called by view action)
        if { $read_p } {
            if { $redirect_before_v_p } {
                ns_log Notice "hosting-farm/assets.tcl(587): redirecting to url $url for clean url view"
                ad_returnredirect "$url?mode=l"
                ad_script_abort
            }

            ns_log Notice "hosting-farm/assets.tcl(427): mode = $mode ie. list of pages, index"
            #lappend menu_list [list #q-wiki.edit# "${url}?mode=e" ]

            append title " #q-wiki.index#" 
            # show page
            # sort by f_id, columns
            
            set asset_ids_list [qw_pages $package_id]
            set pages_stats_lists [list ]
            # we get the entire data set, 1 row(list) per page as table pages_stats_lists
            foreach asset_id $asset_ids_list {
                set stats_mod_list [list $asset_id]
                set stats_orig_list [qw_page_stats $asset_id]
                #   a list: name, title, comments, keywords, description, f_id, flags, trashed, popularity, time last_modified, time created, user_id
                foreach stat $stats_orig_list {
                    lappend stats_mod_list $stat
                }
                lappend stats_mod_list [qw_page_url_from_id $asset_id]
                # new: asset_id, name, title, comments, keywords, description, f_id, flags, trashed, popularity, time last_modified, time created, user_id, url
                lappend pages_stats_lists $stats_mod_list
            }
            set pages_stats_lists [lsort -index 2 $pages_stats_lists]
            # build tables (list_of_lists) stats_list and their html filtered versions page_*_lists for display
            set page_scratch_lists [list]
            set page_stats_lists [list ]
            set page_trashed_lists [list ]

            foreach stats_mod_list $pages_stats_lists {
                set stats_list [lrange $stats_mod_list 0 2]
                lappend stats_list [lindex $stats_mod_list 5]
                lappend stats_list [lindex $stats_mod_list 3]

                set asset_id [lindex $stats_mod_list 0]
                set name [lindex $stats_mod_list 1]
                set f_id [lindex $stats_mod_list 6]
                set page_user_id [lindex $stats_mod_list 12]
                set trashed_p [lindex $stats_mod_list 8]
                set page_url [lindex $stats_mod_list 13]

                # convert stats_list for use with html

                # change Name to an active link and add actions if available
                set active_link "<a href=\"${page_url}\">$name</a>"
                set active_link_list [list $active_link]
                set active_link2 ""

                if {  $write_p } {
                    # trash the page
                    if { $trashed_p } {
                        set active_link2 " <a href=\"${page_url}?page_f_id=${f_id}&mode=t&next_mode=l\"><img src=\"${untrash_icon_url}\" alt=\"#acs-tcl.undelete#\" title=\"#acs-tcl.undelete#\" width=\"16\" height=\"16\"></a>"
                    } else {
                        set active_link2 " <a href=\"${page_url}?page_f_id=${f_id}&mode=t&next_mode=l\"><img src=\"${trash_icon_url}\" alt=\"#acs-tcl.delete#\" title=\"#acs-tcl.delete#\" width=\"16\" height=\"16\"></a>"
                    }
                } elseif { $page_user_id == $user_id } {
                    # trash the revision
                    if { $trashed_p } {
                        set active_link2 " <a href=\"${page_url}?asset_id=${asset_id}&mode=t&next_mode=l\"><img src=\"${untrash_icon_url}\" alt=\"#acs-tcl.undelete#\" title=\"#acs-tcl.undelete#\" width=\"16\" height=\"16\"></a>"
                    } else {
                        set active_link2 " <a href=\"${page_url}?asset_id=${asset_id}&mode=t&next_mode=l\"><img src=\"${trash_icon_url}\" alt=\"#acs-tcl.delete#\" title=\"#acs-tcl.delete#\" width=\"16\" height=\"16\"></a>"
                    }
                } 

                set stats_list [lreplace $stats_list 0 0 $active_link]
                set stats_list [lreplace $stats_list 1 1 $active_link2]

                # add stats_list to one of the tables for display
                if { $trashed_p && ( $write_p || $page_user_id eq $user_id ) } {
                    lappend page_trashed_lists $stats_list
                } elseif { $trashed_p } {
                    # ignore this row, but track for errors
                } else {
                    lappend page_stats_lists $stats_list
                }
            }

            # convert table (list_of_lists) to html table
            set page_stats_sorted_lists $page_stats_lists
            set page_stats_sorted_lists [linsert $page_stats_sorted_lists 0 [list "#acs-subsite.Name#" "&nbsp;" "#acs-kernel.common_Title#" "#acs-subsite.Description#" "#acs-subsite.Comment#"] ]
            set page_tag_atts_list [list border 0 cellspacing 0 cellpadding 3]
            set cell_formating_list [list ]
            set page_stats_html [qss_list_of_lists_to_html_table $page_stats_sorted_lists $page_tag_atts_list $cell_formating_list]
            # trashed table
            if { [llength $page_trashed_lists] > 0 } {
                set page_trashed_sorted_lists $page_trashed_lists
                set page_trashed_sorted_lists [linsert $page_trashed_sorted_lists 0 [list "#acs-subsite.Name#" "&nbsp;" "#acs-kernel.common_Title#" "#acs-subsite.Description#" "#acs-subsite.Comment#"] ]
                set page_tag_atts_list [list border 0 cellspacing 0 cellpadding 3]
                
                set page_trashed_html [qss_list_of_lists_to_html_table $page_trashed_sorted_lists $page_tag_atts_list $cell_formating_list]
            }
        } else {
            # does not have permission to read. This should not happen.
            ns_log Warning "hosting-farm/assets.tcl:(465) user did not get expected 404 error when not able to read page."
        }
    }
    r {
        #  revisions...... presents a list of page revisions
            lappend menu_list [list #q-wiki.index# "index?mode=l"]

        if { $write_p } {
            ns_log Notice "hosting-farm/assets.tcl mode = $mode ie. revisions"
            # build menu options
            lappend menu_list [list #q-wiki.edit# "${url}?mode=e" ]
            
            # show page revisions
            # sort by f_id, columns
            set f_id $page_f_id_from_url
            # these should be sorted by last_modified
            set asset_ids_list [qw_pages $package_id $user_id $f_id]

            set pages_stats_lists [list ]
            # we get the entire data set, 1 row(list) per revision as table pages_stats_lists
            # url is same for each
            set asset_id_active [qw_asset_id_from_url $url $package_id]
            foreach list_asset_id $asset_ids_list {
                set stats_mod_list [list $list_asset_id]
                set stats_orig_list [qw_page_stats $list_asset_id]
                set page_list [qw_page_read $list_asset_id]
                #   a list: name, title, comments, keywords, description, f_id, flags, trashed, popularity, time last_modified, time created, user_id
                foreach stat $stats_orig_list {
                    lappend stats_mod_list $stat
                }
                lappend stats_mod_list $url
                lappend stats_mod_list [string length [lindex $page_list 11]]
                lappend stats_mod_list [expr { $list_asset_id == $asset_id_active } ]
                # new: asset_id, name, title, comments, keywords, description, f_id, flags, trashed, popularity, time last_modified, time created, user_id, url, content_length, active_revision
                lappend pages_stats_lists $stats_mod_list
            }
            # build tables (list_of_lists) stats_list and their html filtered versions page_*_lists for display
            set page_stats_lists [list ]

            # stats_list should contain asset_id, user_id, size (string_length) ,last_modified, comments,flags, live_revision_p, trashed? , actions: untrash delete

            set contributor_nbr 0
            set contributor_last_id ""
            set page_name [lindex [lindex $pages_stats_lists 0] 1]
            append title "${page_name} - page revisions"

            foreach stats_mod_list $pages_stats_lists {
                set stats_list [list]
                # create these vars:
                set index_list [list asset_id 0 page_user_id 12 size 14 last_modified 10 created 11 comments 3 flags 7 live_revision_p 15 trashed_p 8]
                foreach {list_item_name list_item_index} $index_list {
                    set list_item_value [lindex $stats_mod_list $list_item_index]
                    set $list_item_name $list_item_value
                    lappend stats_list $list_item_value
                }
                # convert stats_list for use with html

                set active_link "<a href=\"${url}?asset_id=$asset_id&mode=e\">${asset_id}</a>"
                set stats_list [lreplace $stats_list 0 0 $active_link]

                if { $page_user_id ne $contributor_last_id } {
                    set contributor_last_id $page_user_id
                    incr contributor_nbr
                }
                set contributor_title ${contributor_nbr}
                set active_link3 " &nbsp; <a href=\"/shared/community-member?user_id=${page_user_id}\" title=\"page contributor ${contributor_title}\">${contributor_title}</a>"
                set stats_list [lreplace $stats_list 1 1 $active_link3]

                if { $live_revision_p } {
                        # no links or actions. It's live, whatever its status
                    if { $trashed_p } {
                        set stats_list [lreplace $stats_list 7 7 "<img src=\"${radio_unchecked_url}\" alt=\"inactive\" title=\"inactive\" width=\"13\" height=\"13\">"]
                    } else {
                        set stats_list [lreplace $stats_list 7 7 "<img src=\"${radio_checked_url}\" alt=\"active\" title=\"active\" width=\"13\" height=\"13\">"]
                    }
                } else {
                    if { $trashed_p } {
                        set stats_list [lreplace $stats_list 7 7 "&nbsp;"]   
                    } else {
                        # it's untrashed, user can make it live.
                        set stats_list [lreplace $stats_list 7 7 "<a href=\"$url?asset_id=${asset_id}&mode=a&next_mode=r\"><img src=\"${radio_unchecked_url}\" alt=\"activate\" title=\"activate\" width=\"13\" height=\"13\"></a>"]
                    }
                } 

                set active_link_list [list $active_link]
                set active_link2 ""
                if { ( $write_p || $page_user_id == $user_id ) && $trashed_p } {
                    set active_link2 " <a href=\"${url}?asset_id=${asset_id}&mode=t&next_mode=r\"><img src=\"${untrash_icon_url}\" alt=\"#acs-tcl.undelete#\" title=\"#acs-tcl.undelete#\" width=\"16\" height=\"16\"></a>"
                } elseif { $page_user_id == $user_id || $write_p } {
                    set active_link2 " <a href=\"${url}?asset_id=${asset_id}&mode=t&next_mode=r\"><img src=\"${trash_icon_url}\" alt=\"#acs-tcl.delete#\" title=\"#acs-tcl.delete#\" width=\"16\" height=\"16\"></a>"
                } 
                set stats_list [lreplace $stats_list 8 8 $active_link2]



                # if the user can delete or trash this stats_list, display it.
                if { $write_p || $page_user_id eq $user_id } {
                    lappend page_stats_lists $stats_list
                } 
            }

            # convert table (list_of_lists) to html table
            set page_stats_sorted_lists $page_stats_lists
            set page_stats_sorted_lists [linsert $page_stats_sorted_lists 0 [list "#q-wiki.ID#" "#q-wiki.Contributor#" "#q-wiki.Length#" "#q-wiki.Last_Modified#" "#q-wiki.Created#" "#acs-subsite.Comment#" "#q-wiki.Flags#" "#q-wiki.Liveq#" "#acs-subsite.Status#"] ]
            set page_tag_atts_list [list border 0 cellspacing 0 cellpadding 3]
            set cell_formating_list [list ]
            set page_stats_html [qss_list_of_lists_to_html_table $page_stats_sorted_lists $page_tag_atts_list $cell_formating_list]
        } else {
            # does not have permission to read. This should not happen.
            ns_log Warning "hosting-farm/assets.tcl:(465) user did not get expected 404 error when not able to read page."
        }

    }
    e {


        if { $write_p } {
            #  edit...... edit/form mode of current context

            ns_log Notice "hosting-farm/assets.tcl mode = edit"
            set cancel_link_html "<a hrer=\"list?mode=l\">#acs-kernel.common_Cancel#</a>"

            # for existing pages, add f_id
            set conn_package_url [ad_conn package_url]
            set post_url [file join $conn_package_url $url]

            ns_log Notice "hosting-farm/assets.tcl(636): conn_package_url $conn_package_url post_url $post_url"
            if { $asset_id_from_url ne "" && [llength $user_message_list ] == 0 } {

                # get page info
                set page_list [qw_page_read $asset_id_from_url $package_id $user_id ]
                set page_name [lindex $page_list 0]
                set page_title [lindex $page_list 1]
                set keywords [lindex $page_list 2]
                set description [lindex $page_list 3]
                set page_f_id [lindex $page_list 4]
                set page_flags [lindex $page_list 5]
                set page_contents [lindex $page_list 11]
                set page_comments [lindex $page_list 12]

                set cancel_link_html "<a href=\"$page_name\">#acs-kernel.common_Cancel#</a>"
            } 
           
            append title "${page_name} -  #q-wiki.edit#"

            set rows_list [split $page_contents "\n\r"]
            set rows_max [llength $rows_list]
            set columns_max 40
            foreach row $rows_list {
                set col_len [string length $row]
                if { $col_len > $columns_max } {
                    set columns_max $col_len
                }
            }
            if { $rows_max > 200 } {
                set rows_max [expr { int( sqrt( hypot( $columns_max, $rows_max ) ) ) } ]
            }
            set columns_max [f::min 200 $columns_max]
            set rows_max [f::min 800 $rows_max]
            set rows_max [f::max $rows_max 6]

            qf_form action $post_url method post id 20130309 hash_check 1
            qf_input type hidden value w name mode
            qf_input type hidden value v name next_mode
            qf_input type hidden value $page_flags name page_flags
            qf_input type hidden value $page_f_id name page_f_id
            #        qf_input type hidden value $asset_id name asset_id label ""
            qf_append html "<h3>Q-Wiki #acs-templating.Page# #q-wiki.edit#</h3>"
            qf_append html "<div style=\"width: 70%; text-align: right;\">"
            set page_name_unquoted [qf_unquote $page_name]
            qf_input type text value $page_name_unquoted name page_name label "#acs-subsite.Name#:" size 40 maxlength 40
            qf_append html "<br>"
            set page_title_unquoted [qf_unquote $page_title]
            qf_input type text value $page_title_unquoted name page_title label "#acs-kernel.common_Title#:" size 40 maxlength 80
            qf_append html "<br>"
            set description_unquoted [qf_unquote $description]
            qf_textarea value $description_unquoted cols 40 rows 1 name description label "#acs-subsite.Description#:"
            qf_append html "<br>"
            set page_comments_unquoted [qf_unquote $page_comments]
            qf_textarea value $page_comments_unquoted cols 40 rows 3 name page_comments label "#acs-subsite.Comment#:"
            qf_append html "<br>"
            set page_contents_unquoted [qf_unquote $page_contents]
            qf_textarea value $page_contents_unquoted cols $columns_max rows $rows_max name page_contents label "#notifications.Contents#:"
            qf_append html "<br>"
            set keywords_unquoted [qf_unquote $keywords]
            qf_input type text value $keywords_unquoted name keywords label "#q-wiki.Keywords#:" size 40 maxlength 80
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
                ns_log Notice "hosting-farm/assets.tcl(835): redirecting to url $url for clean url view"
                ad_returnredirect $url
                ad_script_abort
            }
            ns_log Notice "hosting-farm/assets.tcl(667): mode = $mode ie. view"

            lappend menu_list [list #q-wiki.index# "index?mode=l"]

            # get page info
            if { $asset_id eq "" } {
                # cannot use previous $asset_id_from_url, because it might be modified from an ACTION
                # Get it again.
                set asset_id_from_url [qw_asset_id_from_url $url $package_id]
                set page_list [qw_page_read $asset_id_from_url $package_id $user_id ]
            } else {
                set page_list [qw_page_read $asset_id $package_id $user_id ]
            }

            if { $create_p } {
                if { $asset_id_from_url ne "" || $asset_id ne "" } {
                    lappend menu_list [list #q-wiki.revisions# "${url}?mode=r"]
                } 
                lappend menu_list [list #q-wiki.edit# "${url}?mode=e" ]
            }
            
            if { [llength $page_list] > 1 } {
                set page_title [lindex $page_list 1]
                set keywords [lindex $page_list 2]
                set description [lindex $page_list 3]
                set page_contents [lindex $page_list 11]
                set trashed_p [lindex $page_list 6]
                set f_id [lindex $page_list 4]
                # trashed pages cannot be viewed by public, but can be viewed with permission
                
                if { $keywords ne "" } {
		    template::head::add_meta -name keywords -content $keywords
                }
                if { $description ne "" } {
                    template::head::add_meta -name description -content $description
                }
                set title $page_title
                # page_contents_filtered
                set page_contents_unquoted [ad_unquotehtml $page_contents]
                set page_main_code [template::adp_compile -string $page_contents_unquoted]
                set page_main_code_html [template::adp_eval page_main_code]
            }
        } else {
            # no permission to read page. This should not happen.
            ns_log Warning "hosting-farm/assets.tcl:(619) user did not get expected 404 error when not able to read page."
        }
    }
    w {
        #  save.....  (write) asset_id 
        # should already have been handled above
        ns_log Warning "hosting-farm/assets.tcl(575): mode = save/write THIS SHOULD NOT BE CALLED."
        # it's called in validation section.
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
set validated_p_exists [info exists validated_p]
if { $validated_p_exists && $validated_p || !$validated_p_exists } {
    foreach item_list $menu_list {
        set menu_label [lindex $item_list 0]
        set menu_url [lindex $item_list 1]
        append menu_html "<a href=\"${menu_url}\" title=\"${menu_label}\">${menu_label}</a> &nbsp; "
    }
} 
set doc(title) $title
set context [list $title]
