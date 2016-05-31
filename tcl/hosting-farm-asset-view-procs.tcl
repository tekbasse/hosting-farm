#hosting-farm/tcl/hosting-farm-asset-view-procs.tcl
ad_library {

    views and constructors for hosting-farm assets
    @creation-date 25 May 2013
    @Copyright (c) 2014-2016 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl-2.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com

}


# Assets can be created, revised, trashed and deleted.
# Deleted option should only be available if an asset is trashed. 


# This was ported from q-wiki, and then completely re-written.
# In q-wiki context, template_id refers to a page with shared revisions of multiple page_id(s).
# hf uses f_id instead.
# hf_asset* uses template_* in the context of an original from which copies are made.


ad_proc -public hf_asset_read { 
    asset_id
} {
    Returns contents of asset record for asset_id as list of attribute values.
    
    @param asset_id

    @see hf_asset_read_keys

} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set read_p [hf_ui_go_ahead_q read "" "" 0]
    set return_list [list ]
    if { $read_p } {
        set return_list_of_lists [db_list_of_lists hf_asset_get "select [hf_asset_keys ","] from hf_assets where id=:asset_id and instance_id=:instance_id " ] 
        # convert return_lists_of_lists to return_list
        set return_list [lindex $return_list_of_lists 0]
    }
    return $return_list
}


    
ad_proc -public hf_asset_stats { 
    asset_id
    {keys_list ""}
} {
    Returns asset stats as a list. If keys_list not empty, also sets values to variables that are named in keys_list.

    @return stats as a list.
    
    @see hf_asset_stats_keys for order of keys.
} {
    # Asset stats do not include large asset values such as content
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set read_p [hf_ui_go_ahead_q read "" "" 0]
    set return_list [list ]
    if { $read_p } {
        set return_list_of_lists [db_list_of_lists hf_asset_stats "select [hf_asset_stats_keys ","] from hf_assets where id=:asset_id and instance_id=:instance_id" ] 
        # convert return_lists_of_lists to return_list
        set return_list [lindex $return_list_of_lists 0]
    } 
    set all_keys_list [hf_asset_stats_keys]
    foreach key [split $keys_list " ,"] {
        set key_idx [lsearch -exact key $all_keys_list $key]
        if { $key_idx > -1 } {
            upvar 1 $key [lindex $return_list $key_idx]
        }
    }
    return $return_list
}


ad_proc -private hf_assets_w_detail {
    {instance_id ""}
    {customer_ids_list ""}
    {label_match ""}
    {inactives_included_p 0}
    {published_p ""}
    {template_p ""}
    {asset_type_id ""}
} {
    returns asset detail with references (id) and other info via a list of lists, where each list is an ordered tcl list of asset related values: id,user_id,last_modified,created,asset_type_id,qal_product_id, qal_customer_id,label,keywords,templated_p,template_p,time_start,time_stop,trashed_p,trashed_by,flags,publish_p
} {
    # A variation on hf_assets
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    # scope to user_id
    set user_id [ad_conn user_id]
    set all_customer_ids_list [hf_customer_ids_for_user $user_id]
    #    set all_assets_list_of_lists \[db_list_of_lists hf_asset_templates_list {select id,user_id,last_modified,created,asset_type_id,qal_product_id, qal_customer_id,label,keywords,templated_p,time_start,time_stop,ns_id,op_status,trashed_p,trashed_by,popularity,flags,publish_p,monitor_p,triage_priority from hf_assets where template_p =:1 and instance_id =:instance_id} \]
    if { $inactives_included_p } {
        set templates_list_of_lists [db_list_of_lists hf_asset_templates_select_all {select id,user_id,last_modified,created,asset_type_id,qal_product_id, qal_customer_id,label,keywords,templated_p,template_p,time_start,time_stop,trashed_p,trashed_by,flags,publish_p from hf_assets where instance_id =:instance_id and id in ( select asset_id from hf_asset_label_map where instance_id = :instance_id ) order by last_modified desc} ]
    } else {
        set templates_list_of_lists [db_list_of_lists hf_asset_templates_select {select id,user_id,last_modified,created,asset_type_id,qal_product_id, qal_customer_id,label,keywords,templated_p,template_p,time_start,time_stop,trashed_p,trashed_by,flags,publish_p from hf_assets where instance_id =:instance_id and time_stop =null and ( trashed_p is null or trashed_p <> '1' ) and id in ( select asset_id from hf_asset_label_map where instance_id = :instance_id ) order by last_modified desc } ]
    }
    # build list of ids that meet at least one criteria
    set return_list [list ]
    foreach template_list $templates_lists_of_lists {
        # first make sure that user_id has access to asset.
        set customer_id [lindex $template_list 6]
        set insert_p 0
        if { $customer_id eq "" || ( [lsearch -exact $all_customer_ids_list $customer_id] > -1 && [lsearch -exact $customer_ids_list $customer_id] ) } {

            # now check the various requested criteria options. Matching any one or more qualifies.
            # label?
            if { $label_match ne "" && [string match -nocase $label_match [lindex $template_list 7]] } {
                set insert_p 1
            }
            # published_p?
            if { $published_p ne "" } {
                set published_p_val [lindex $template_list 14]
                if { $published_p eq $published_p_val } {
                    set insert_p 1
                }
            }
            if { !$insert_p && $template_p ne "" } {
                set template_p_val [lindex $template_list 10]
                if { $template_p eq $template_p_val } {
                    set insert_p 1
                }
            }
            if { !$insert_p && $asset_type_id ne "" } {
                set asset_type_id_val [lindex $template_list 4]
                if { $asset_type_id eq $asset_type_id_val } {
                    set insert_p 1
                }
            }
            if { $insert_p } {
                set insert_p 0
                # just id's:  lappend return_list \[lindex $template_list 0\]
                lappend return_list $template_list
            }
        }
    }
    return $return_list
}

