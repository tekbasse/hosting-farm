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
