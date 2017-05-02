#hosting-farm/tcl/hosting-farm-asset-view-procs.tcl
ad_library {

    Asset views and constructors for Hosting Farm
    @creation-date 25 May 2013
    @Copyright (c) 2014-2016 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl-2.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 193, Marylhurst, OR 97036-0193 usa
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
    Returns an asset record as a list. See hf_asset_keys

    @param asset_id

    @see hf_asset_keys for key order
} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set return_list [hf_assets_read [list $asset_id]]
    set return_list [lindex $return_list 0]
    return $return_list
}


ad_proc -public hf_assets_read { 
    asset_id_list
} {
    Returns list of lists; Each list is an asset record for each asset_id in asset_id_list as a list of attribute values.
    
    @param asset_id_list

    @see hf_asset_keys for key order

} {
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set asset_ids_list [hf_list_filter_by_natural_number $asset_id_list]
    set return_lists [list ]
    foreach asset_id $asset_ids_list {
        set read_p [hf_ui_go_ahead_q read "" "" 0]
        if { $read_p } {
            set rows_lists [db_list_of_lists hf_asset_get "select [hf_asset_keys ","] from hf_assets where asset_id=:asset_id and instance_id=:instance_id " ]
            # should return only 1 row max
            set row_list [lindex $rows_lists 0]
            if { [llength $row_list] > 0 } {
                lappend return_lists $row_list
            }
        } else {
            ns_log Notice "hf_assets_read.66: read_p '${read_p}' for user_id '${user_id}' instance_id '${instance_id}' asset_id '${asset_id}'"
        }
    }
    return $return_lists
}


    
ad_proc -public hf_asset_stats { 
    asset_id
    {keys_list ""}
} {
    Returns asset stats as a list. If keys_list not empty, also sets values to variables that are named in keys_list.

    @return stats as a list.
    
    @see hf_asset_keys for order of keys.
} {
    # Asset stats do not include large asset values such as content
    upvar 1 instance_id instance_id
    upvar 1 user_id user_id
    set read_p [hf_ui_go_ahead_q read "" "" 0]
    set return_list [list ]
    if { $read_p } {
        set return_list_of_lists [db_list_of_lists hf_asset_stats "select [hf_asset_keys ","] from hf_assets where asset_id=:asset_id and instance_id=:instance_id" ] 
        # convert return_lists_of_lists to return_list
        set return_list [lindex $return_list_of_lists 0]
        set all_keys_list [hf_asset_keys]
        foreach key [split $keys_list " ,"] {
            set key_idx [lsearch -exact $all_keys_list $key]
            if { $key_idx > -1 } {
                upvar 1 $key $key 
                set $key [lindex $return_list $key_idx]
            }
        }
    } 
    return $return_list
}


ad_proc -public hf_active_asset_ids_of_customer {
    customer_id
    {top_level_p "0"}
} {
    Returns a list of active asset_ids (contracts) for customer_id

    @param customer_id Checks for this customer.
    @top_level_p

    @return Returns asset_id numbers in a list.

} {
    upvar instance_id instance_id
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [qc_set_instance_id]
    }
    set user_id [ad_conn user_id]
    set read_p [qc_permission_p $user_id $customer_id assets read $instance_id]
    set asset_ids_list [list ]
    if { $read_p } {
        set f_id_list [db_list f_ids_for_customer_get { select f_id from hf_assets 
            where instance_id=:instance_id 
            and qal_customer_id=:customer_id
            and trashed_p!='1'} ]
        if { [qf_is_true $top_level_p] } {
            # This is trickier than for sys admins, because top level may
            # very well be dependent on a system asset or asset
            # of another customer
            set asset_tla_list [db_list asset_ids_for_customer_get_tla_f_id "
                select f_id from hf_sub_asset_map
                where instance_id=:instance_id
                and trashed_p!='1'
                and f_id in ( [template::util::tcl_to_sql_list $f_id_list] )
                and f_id not in ( select sub_f_id from hf_sub_asset_map
                                  where sub_f_id in [template::util::tcl_to_sql_list $f_id_list] ) " ]
            set asset_ids_list [db_list asset_ids_for_customer_get_tla_id "select asset_id
                from hf_asset_rev_map
                where instance_id=:instance_id
                and trashed_p!='1'
                and f_id in ( [template::util::tcl_to_sql_list $asset_tla_list] )" ]
        } else {
            set asset_ids_list [db_list asset_ids_for_customer_get "select asset_id from hf_asset_rev_map where instance_id=:instance_id and trashed_p!='1' and f_id in ( [template::util::tcl_to_sql_list $f_id_list] )"]
        }
    }
    return $asset_ids_list
}

