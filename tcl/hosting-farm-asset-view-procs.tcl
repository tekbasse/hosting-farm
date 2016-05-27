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
# hf_asset* uses template_* in the context of an original from which copies are made.


# asset_create/write param number vs. all hf_assets fields.
# 0 is ignored for hf_asset_create
#
#  21 instance_id
#  0  asset_id
#  19 template_id
#  22 user_id
#     last_modified
#     created
#  3  asset_type_id
#  17 qal_product_id
#  18 qal_customer_id
#  1  label
#  2  name
#  5  keywords
#  6  description
#  4  content
#  7  comments
#  9  templated_p
#  8  template_p
#     time_start
#     time_stop
#  16 ns_id
#  15 ua_id
#  14 op_status
#     trashed_p
#     trashed_by
#  12 popularity
#  20 flags
#  10 publish_p
#  11 monitor_p
#  13 triage_priority
#     f_id  

##code

ad_proc -public hf_assets { 
    {instance_id ""}
    {user_id ""}
    {template_id ""}
} {
    Returns a list of asset_ids. If template_id is included, the results are scoped to assets with same template (aka revisions).
    If user_id is included, the results are scoped to the user. If nothing found, returns an empty list.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set party_id [ad_conn user_id]
        set untrusted_user_id [ad_conn untrusted_user_id]
    } else {
        set party_id $user_id
    }
   # set read_p [permission::permission_p -party_id $party_id -object_id $instance_id -privilege read]
    set customer_id [hf_customer_id_of_asset_id $asset_id $instance_id]
    set read_p [hf_permission_p $user_id $customer_id assets read $instance_id]
    if { $read_p } {
        if { $template_id eq "" } {
            if { $user_id ne "" } {
                # get a list of asset_ids that are mapped to a label for instance_id and where the current revision was created by user_id
                set return_list [db_list hf_assets_user_list { select id from hf_assets where instance_id=:instance_id and user_id=:user_id and id in ( select asset_id from hf_asset_label_map where instance_id=:instance_id ) order by last_modified desc } ]
            } else {
                # get a list of all asset_ids mapped to a label for instance_id.
                set return_list [db_list hf_assets_list { select id as asset_id from hf_assets where id in ( select asset_id from hf_asset_label_map where instance_id=:instance_id ) order by last_modified desc } ]
            }
        } else {
            # is the template_id valid?
            set has_template [db_0or1row hf_asset_template { select template_id as db_template_id from hf_assets where template_id=:template_id limit 1 } ]
            if { $has_template && [info exists db_template_id] && $template_id > 0 } {
                if { $user_id ne "" } {
                    # get a list of all asset_ids of the revisions of asset (template_id) that user_id created.
                    set return_list [db_list hf_assets_t_u_list { select id from hf_assets where instance_id=:instance_id and user_id=:user_id and template_id=:template_id order by last_modified desc } ]
                } else {
                    # get a list of all asset_ids of the revisions of asset (template_id) 
                    set return_list [db_list hf_assets_list { select id from hf_assets where instance_id=:instance_id and template_id=:template_id order by last_modified } ]
                }
            } else {
                set return_list [list ]
            }
        }
    } else {
        set return_list [list ]
    }
    return $return_list
} 


ad_proc -public hf_asset_read { 
    asset_id
    {instance_id ""}
    {user_id ""}
} {
    Returns asset contents of asset_id. Returns asset as list of attribute values: label,name,asset_type_id,keywords,description,content,comments,trashed_p,trashed_by,template_p,templated_p,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created,template_id

} {
    
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
        set untrusted_user_id [ad_conn untrusted_user_id]
    }
   # set read_p \[permission::permission_p -party_id $user_id -object_id $instance_id -privilege read\]
    set customer_id [hf_customer_id_of_asset_id $asset_id $instance_id]
    set read_p [hf_permission_p $user_id $customer_id assets read $instance_id]
    set return_list [list ]
    if { $read_p } {
        set return_list_of_lists [db_list_of_lists hf_asset_get { select label, name, asset_type_id, keywords, description, content, comments, trashed_p, trashed_by, template_p, templated_p, publish_p, monitor_p, popularity, triage_priority, op_status, ua_id,ns_id, qal_product_id, qal_customer_id, instance_id, user_id, last_modified, created, template_id from hf_assets where id=:asset_id and instance_id=:instance_id } ] 
        # convert return_lists_of_lists to return_list
        set return_list [lindex $return_list_of_lists 0]
        # convert null/empty values to logical 0 for these index numbers:
        # trashed_p, template_p, templated_p, publish_p, monitor_p
        set field_idx_list [list 6 8 9 10 11]
        foreach field_idx $field_idx_list {
            if { [llength $return_list] > 1 && [lindex $return_list $field_idx] eq "" } {
                set return_list [lreplace $return_list $field_idx $field_idx 0]
            }
        }
    }
    return $return_list
}


    
ad_proc -public hf_asset_stats { 
    asset_id
    {instance_id ""}
    {user_id ""}
    {keys_list ""}
} {
    Returns asset stats as a list.
    
    @see hf_asset_stats_keys
} {
    # Asset stats doesn't include large asset values such as content
    set read_p [hf_ui_go_ahead_q read]
    if { $read_p } {
        set return_list_of_lists [db_list_of_lists hf_asset_stats "select [hf_asset_stats_keys ","] from hf_assets where id=:asset_id and instance_id=:instance_id" ] 
        # convert return_lists_of_lists to return_list
        set return_list [lindex $return_list_of_lists 0]
        # convert trash null/empty value to logical 0
        if { [llength $return_list] > 1 && [lindex $return_list 7] eq "" } {
            set return_list [lreplace $return_list 7 7 0]
        }
    } else {
        set return_list [list ]
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
