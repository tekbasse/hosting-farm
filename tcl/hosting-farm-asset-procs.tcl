#hosting-farm/tcl/hosting-farm-asset-procs.tcl
ad_library {

    API for hosting-farm
    @creation-date 25 May 2013
    @Copyright (c) 2014 Benjamin Brink
    @license GNU General Public License 3, see project home or http://www.gnu.org/licenses/gpl-3.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com

    # Assets can be created, revised, trashed and deleted.
    # Deleted option should only be available if an asset is trashed. 

}

# This was ported from q-wiki, and then completely re-written.
# In q-wiki context, template_id refers to a page with shared revisions of multiple page_id(s).
# hf_asset* uses template in the context of an original from which copies are made.

ad_proc -private hf_asset_type_id_list {
 } {
    Returns list of all asset_type_id
} {
    upvar 1 instance_id instance_id
    #set as_type_list \[list dc hw vm vh ss ot\]
    if { [exists_and_not_null $instance_id] } {
        set as_type_list [db_list hf_asset_type_id_by_i "select distinct id from hf_asset_type where instance_id=:instance_id"]
    } else {
        set as_type_list [db_list hf_asset_type_id_all "select distinct id from hf_asset_type"]
    }
    return $as_type_list
}

ad_proc -public hf_asset_id_exists_q { 
    asset_id
    {asset_type_id ""}
} {
    Returns 1 if asset_id exists, else returns 0

    @param asset_id      The asset_id to check.
    @param asset_type_id If not blank, also verifies that asset is of this type.

    @return  1 if asset_id exists, otherwise 0.
} {
    upvar 1 instance_id instance_id
    set asset_type_id_q $asset_type_id
    set read_p [hf_ui_go_ahead_q read]
    set asset_exists_p 0
    # We can use results hf_ui_go_ahead_q to partially deduce answer
    if { $read_p } {
        if { $asset_type_id ne "" } {
            if { $asset_type_id ne $asset_type_id_q } {
                set asset_exists_p 0
            } else {
                set asset_exists_p 1
            }
        } else {
            set asset_exists_p [db_0or1row hf_asset_get_id {select name from hf_assets where id=:asset_id and instance_id=:instance_id } ]
        }
    }
    return $asset_exists_p
}

ad_proc -public hf_asset_active_q { 
    asset_id
} {
    Returns 1 if asset_id exists, else returns 0

    @param asset_id      The asset_id to check.
    @param asset_type_id If not blank, also verifies that asset is of this type.
    @param instance_id   The context of the implementation.

    @return  1 if asset_id exists, otherwise 0.
} {
    upvar 1 instance_id instance_id
    set active_q 0
    set label [hf_label_from_asset_id $asset_id]
    if { $label ne "" } {
        set active_q 1
    }

    return $asset_exists_p
}

ad_proc -private hf_label_from_asset_id {
    asset_id
} {
    @param asset_id  

    @return label of asset with asset_id, or empty string if not exists or active.
} {
    upvar 1 instance_id instance_id
    set asset_id_active_p [db_0or1row hf_label_from_asset_id { select label from hf_asset_map 
        where asset_id=:asset_id and instance_id=:instance_id } ]
}
##code below here

ad_proc -private hf_change_asset_id_for_label {
    asset_id
    asset_label
    {instance_id ""}
} {
    Changes the active revision of asset with asset_label to asset_id. Returns 1 if successful, otherwise 0.
} {
    set write_p [hf_ui_go_ahead_q write]
    set success_p $write_p
    if { $write_p } {
        # new asset
        hf_asset_stats $asset_id $instance_id $user_id "f_id trashed_p asset_label"
        set asset_label_new [hf_asset_label_from_id $asset_id $instance_id]
        # new and current asset
        if { $asset_label_new ne "" && $asset_label eq $asset_label_new && !$trashed_p } {
            db_dml hf_change_revision { update hf_asset_map
            set asset_id=:asset_id_new where label=:asset_label and instance_id=:instance_id }
            db_dml hf_change_revision_active { update hf_assets
                set last_modified = current_timestamp where id=:asset_id and instance_id=:instance_id }
            set success_p 1
        }
    }
    return $success_p
}

ad_proc -public hf_asset_rename {
    asset_label
    asset_name
    {instance_id ""}
} {
    Changes the asset_name where the asset is referenced from asset_label. Returns 1 if successful, otherwise 0.

    @param asset_label  The label of the asset.
    @param asset_name   The new name.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
#    set write_p \[permission::permission_p -party_id $user_id -object_id $instance_id -privilege write\] 
    set customer_id [hf_customer_id_of_asset_id $asset_id $instance_id]
    set write_p [hf_permission_p $user_id $customer_id assets write $instance_id]
    set success_p 0
    if { $write_p && $asset_label ne "" && $asset_name ne "" } {
        set asset_labels_id [hf_asset_id_from_label $asset_label $instance_id]
        set asset_stats_list [hf_asset_stats $asset_labels_id $instance_id]
        set f_id [lindex $asset_stats_list 5]
        # does asset_name already exist? 
        set pn_asset_id  [hf_asset_id_from_label $asset_name $instance_id]

        if { $pn_asset_id ne "" } {
            set pn_stats_list [hf_asset_stats $pn_asset_id $instance_id]
            set pn_f_id [lindex $pn_stats_list 5]
            # just:
            # mv the f_id of asset_label revisions to asset_name revisions f_id
            db_dml hf_name_change_f_id { update hf_assets
                set last_modified = current_timestamp, f_id=:pn_template_id, name=:asset_name where template_id=:template_id and instance_id=:instance_id }
            # get rid of the existing asset_name entry
            db_dml hf_name_change_label_del { delete from hf_asset_label_map
                where label=:asset_label and instance_id=:instance_id }
            
        } else {
            # update hf_asset_label_map.label hf_assets.asset_name to asset_name for template_id, instance_id
            db_dml hf_name_change_assets { update hf_assets
                set last_modified = current_timestamp, name=:asset_name where template_id=:template_id and instance_id=:instance_id }
            db_dml hf_name_change_label { update hf_asset_label_map
                set label=:asset_name where label=:asset_label and instance_id=:instance_id }
        }
        set success_p 1
    }
    return $success_p
}


#
ad_proc -public hf_asset_id_from_label { 
    asset_label
    {instance_id ""}
} {
    Returns asset_id if asset_label exists for instance_id, else returns empty string.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
   # set write_p \[permission::permission_p -party_id $user_id -object_id $instance_id -privilege write\]    
    set customer_id [hf_customer_id_of_asset_id $asset_id $instance_id]
    set write_p [hf_permission_p $user_id $customer_id assets write $instance_id]
    if { $write_p } {
        # okay to return trashed assets
        set asset_exists_p [db_0or1row hf_asset_get_id_from_label {select asset_id from hf_asset_label_map 
            where label=:asset_label and instance_id=:instance_id } ]
    } else {
        set asset_exists_p [db_0or1row hf_asset_get_id_from_label {select asset_id from hf_asset_label_map 
            where label=:asset_label and instance_id=:instance_id and not ( trashed_p = '1' ) } ]
    }
    if { !$asset_exists_p } {
        set asset_id ""
    }
    return $asset_id
}

ad_proc -public hf_asset_label_from_id { 
    asset_id
    {instance_id ""}
} {
    Returns asset_label if asset_id exists for instance_id, even if asset_id is not the active revision, else returns empty string.
} {
    set asset_label ""
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set user_id [ad_conn user_id]
   # set write_p \[permission::permission_p -party_id $user_id -object_id $instance_id -privilege write\]    
    set customer_id [hf_customer_id_of_asset_id $asset_id $instance_id]
    set write_p [hf_permission_p $user_id $customer_id assets write $instance_id]
    if { $write_p } {
        # okay to return trashed assets
        set asset_exists_p [db_0or1row hf_asset_get_all_label_from_id { select label as asset_label from hf_asset_label_map 
            where asset_id=:asset_id and instance_id=:instance_id } ]
    } else {
        set asset_exists_p [db_0or1row hf_asset_get_untrashed_label_from_id { select label as asset_label from hf_asset_label_map 
            where asset_id=:asset_id and instance_id=:instance_id and not ( trashed_p = '1' ) } ]
    }
    if { !$asset_exists_p } {
        set asset_stat_list [hf_asset_stats $asset_id]
        set template_id [lindex $asset_stat_list 5]
#        ns_log Notice "hf_asset_label_from_id: asset_id '$asset_id' template_id '$template_id'"
        if { $template_id ne "" } {
            # get asset_label from template_id
            db_0or1row hf_asset_get_label_from_ids_template { select label as asset_label from hf_asset_label_map 
                where asset_id in ( select id as asset_id from hf_assets 
                                   where instance_id=:instance_id and template_id=:template_id ) } 
        } 
        if { $asset_label eq "" } {
            # maybe asset_id doesn't exist, but asset_id is a template_id 
            db_0or1row hf_asset_get_label_from_template_id { select label as asset_label from hf_asset_label_map 
                where asset_id in ( select id as asset_id from hf_assets 
                                   where instance_id=:instance_id and template_id=:asset_id ) } 
        }
    }
    return $asset_label
}

ad_proc -public hf_asset_label_id_from_template_id { 
    template_id
    {instance_id ""}
} {
    Returns asset_id that is mapped to the label that is mapped to template_id, else returns empty string.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set asset_id ""
    db_0or1row hf_asset_get_label_from_template_id { select asset_id from hf_asset_label_map 
        where instance_id=:instance_id and asset_id in ( select id as asset_id from hf_assets 
                                                          where instance_id=:instance_id and template_id=:template_id ) }
    return $asset_id
}


ad_proc -public hf_asset_from_label { 
    asset_label
    {instance_id ""}
} {
    Returns asset_id if asset is published (untrashed) for instance_id, else returns empty string.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    set asset_exists_p [db_0or1row hf_asset_get_id_from_label2 {select asset_id from hf_asset_label_map 
        where label=:asset_label and instance_id=:instance_id and not ( trashed_p = '1' ) } ]
    if { !$asset_exists_p } {
        set asset_id ""
    }
    return $asset_id
}

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
#  

ad_proc -public hf_asset_create { 
    label
    name
    asset_type_id
    content
    keywords
    description
    comments
    template_p
    templated_p
    publish_p
    monitor_p
    popularity
    triage_priority
    op_status
    ua_id
    ns_id
    qal_product_id
    qal_customer_id
    {template_id ""}
    {flags ""}
    {instance_id ""}
    {user_id ""}
} {
    Creates hf asset. returns asset_id, or 0 if error. instance_id is usually package_id
} {

    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
        set untrusted_user_id [ad_conn untrusted_user_id]
    }
    set return_asset_id 0
   # set create_p \[permission::permission_p -party_id $user_id -object_id $instance_id -privilege create\]
    set customer_id [hf_customer_id_of_asset_id $asset_id $instance_id]
    set create_p [hf_permission_p $user_id $customer_id assets create_p $instance_id]
    ns_log Notice "hf_asset_create: create_p $create_p"
    if { $create_p } {
        set template_id ""
        set trashed_p 0
        set asset_label_exists_p [db_0or1row hf_label_get_asset_id {select asset_id from hf_asset_label_map where label=:label and instance_id=:instance_id } ]
        if { $asset_label_exists_p } {
            set asset_id_exists_p [db_0or1row hf_label_get_id { select asset_id from hf_asset_label_map where asset_id=:asset_id and instance_id=:instance_id } ]
            if { $asset_id_exists_p } { 
                set asset_id_stats_list [hf_asset_stats $asset_id $instance_id $user_id]
                set template_id [lindex $asset_id_stats_list 5]
            }
        } else {
            set asset_id_exists_p 0
        }
        set asset_id [db_nextval hf_id_seq]
        if { $template_id eq "" } {
            set template_id $asset_id
        }
        db_transaction {
            ns_log Notice "hf_asset_create: hf_asset_create id '$asset_id' template_id '$template_id' name '$name' instance_id '$instance_id' user_id '$user_id'"
            db_dml hf_asset_create { insert into hf_assets
                (id,template_id,label,asset_type_id,name,keywords,description,content,comments,template_p,templated_p,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created,from_template_id)
                values (:asset_id,:template_id,:label,:asset_type_id,:name,:keywords,:description,:content,:comments,:template_p,:templated_p,:publish_p,:monitor_p,:popularity,:triage_priority,:op_status,:ua_id,:ns_id,:qal_product_id,:qal_customer_id,:instance_id,:user_id,current_timestamp,current_timestamp,:from_template_id) }
            
            # Add entry to hf_asset_label_map if new asset, otherwise update existing record.
            # A new record is only when template_id = asset_id
            if { $asset_id eq $template_id } {
                ns_log Notice "hf_asset_create: hf_label_create label '$label' asset_id '$asset_id' trashed_p '$trashed_p' instance_id '$instance_id'"
                db_dml hf_asset_label_create { insert into hf_asset_label_map
                    ( label, asset_id, trashed_p, instance_id )
                    values ( :label, :asset_id, :trashed_p, :instance_id ) }
            } else {
                ns_log Notice "hf_asset_create: hf_label_update label '$label' asset_id '$asset_id' trashed_p '$trashed_p' instance_id '$instance_id'"
                db_dml hf_asset_label_update { update hf_asset_label_map
                    set asset_id=:asset_id where label=:label and instance_id=:instance_id }
            }
            set return_asset_id $asset_id
            
        } on_error {
            set return_asset_id 0
            ns_log Error "hf_asset_create: general psql error during db_dml for label $label"
        }
    }
    return $return_asset_id
}

ad_proc -public hf_asset_stats_keys {
    {separator ""}
} {
    Returns an ordered list of keys that is parallel to the ordered list returned by hf_asset_stats.
    If separator is not "", returns a string joined with separator.
} {
    set keys_list [list \
                       label \
                       name \
                       asset_type_id \
                       keywords \
                       description \
                       template_p \
                       templated_p \
                       trashed_p \
                       trashed_by \
                       publish_p \
                       monitor_p \
                       popularity \
                       triage_priority \
                       op_status \
                       ua_id \
                       ns_id \
                       qal_product_id \
                       qal_customer_id \
                       instance_id \
                       user_id \
                       last_modified \
                       created \
                       flags \
                       template_id\
                       f_id]
    if { $separator ne ""} {
        return [join $keys_list $separator]
    } else {
        return $keys_list
    }
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
            upvar 1 $key [lindex $return_list 
          }
    return $return_list
}

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

ad_proc -public hf_asset_read_keys {
} {
    Returns an ordered list of keys that is parallel to the ordered list returned by hf_asset_read.
} {
    # naming convention is: label, name, description
    # old way: name, title, description
    set keys_list [list \
                       label \
                       name \
                       asset_type_id \
                       keywords \
                       description \
                       content \
                       comments \
                       trashed_p \
                       trashed_by \
                       template_p \
                       templated_p \
                       publish_p \
                       monitor_p \
                       popularity \
                       triage_priority \
                       op_status \
                       ua_id \
                       ns_id \
                       qal_product_id \
                       qal_customer_id \
                       instance_id \
                       user_id \
                       last_modified \
                       created \
                       template_id]
    return $keys_list
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


ad_proc -public hf_asset_write {
    label
    name
    asset_type_id
    content
    keywords
    description
    comments
    template_p
    templated_p
    publish_p
    monitor_p
    popularity
    triage_priority
    op_status
    ua_id
    ns_id
    qal_product_id
    qal_customer_id
    asset_id
    {template_id ""}
    {flags ""}
    {instance_id ""}
    {user_id ""}

} {
    Writes a new revision of an existing asset. asset_id is an existing revision of template_id. returns the new asset_id or a blank asset_id if unsuccessful.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
        set untrusted_user_id [ad_conn untrusted_user_id]
    }
   # set write_p \[permission::permission_p -party_id $user_id -object_id $instance_id -privilege write\]
    set customer_id [hf_customer_id_of_asset_id $asset_id $instance_id]
    set write_p [hf_permission_p $user_id $customer_id assets write $instance_id]
    set new_asset_id ""

    if { $write_p } {
        set asset_exists_p [db_0or1row hf_asset_get_user_id {select user_id as creator_id from hf_assets where id=:asset_id } ]
        if { $asset_exists_p } { 
            set asset_id_stats_list [hf_asset_stats $asset_id $instance_id $user_id]
            set template_id [lindex $asset_id_stats_list 5]
        }

        if { $asset_exists_p } {
            set old_asset_id $asset_id
            set label hf_asset_label_from_id $old_asset_id
            set new_asset_id [db_nextval hf_id_seq]
            ns_log Notice "hf_asset_write: hf_asset_create id '$asset_id' template_id '$template_id' name '$name' instance_id '$instance_id' user_id '$user_id'"
            db_transaction {
                db_dml hf_asset_create { insert into hf_assets
                (id,template_id,label,name,asset_type_id,keywords,description,content,comments,template_p,templated_p,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created)
                values (:asset_id,:template_id,:label,:name,:asset_type_id,:keywords,:description,:content,:comments,:template_p,:templated_p,:publish_p,:monitor_p,:popularity,:triage_priority,:op_status,:ua_id,:ns_id,:qal_product_id,:qal_customer_id,:instance_id,:user_id,current_timestamp,current_timestamp) }
                ns_log Notice "hf_asset_write: hf_asset_id_update asset_id '$new_asset_id' instance_id '$instance_id' old_asset_id '$old_asset_id'"
                db_dml hf_asset_id_update { update hf_asset_label_map
                    set asset_id=:new_asset_id where instance_id=:instance_id and label=:label }
            } on_error {
                set success_p 0
                ns_log Error "hf_asset_write: general db error during db_dml"
            }
        } else {
            set success_p 0
            ns_log Warning "hf_asset_write: no asset exists for asset_id $asset_id"
        }
        set success_p 1
    } else {
        set success_p 0
    }
    return $new_asset_id
}


ad_proc -public hf_asset_delete {
    {asset_id ""}
    {template_id ""}
    {instance_id ""}
    {user_id ""}
} {
    Deletes all revisions of template_id if not null, or if asset_id not null, deletes asset_id.
    Returns 1 if deleted. Returns 0 if there were any issues.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    #set delete_p \[permission::permission_p -party_id $user_id -object_id $instance_id -privilege delete\]
    set customer_id [hf_customer_id_of_asset_id $asset_id $instance_id]
    set delete_p [hf_permission_p $user_id $customer_id assets delete $instance_id]
    set success_p 0
    set asset_id_active_p 0
    ns_log Notice "hf_asset_delete: delete_p '$delete_p' asset_id '$asset_id' template_id '$template_id'"
    if { $delete_p } {
        
        if { $asset_id ne "" } {
            set template_id [lindex [hf_asset_stats $asset_id $instance_id] 5]
            # delete a revision
            db_dml hf_asset_delete { delete from hf_assets 
                where id=:asset_id and instance_id=:instance_id and trashed_p = '1' }
            # is asset_id the active revision for template_id?
            set asset_id_active_p [db_0or1row hf_label_from_asset_id { select label from hf_asset_label_map 
                where asset_id=:asset_id and instance_id=:instance_id } ]
        } elseif { $template_id ne "" } {
            # delete all revisions of template_id and the label_mapped to it
            # get active asset_id for reference later
            set asset_id [hf_asset_label_id_from_template_id $template_id $instance_id]
            # delete all revisions
            db_dml hf_template_delete { delete from hf_assets 
                where template_id=:template_id and instance_id=:instance_id and trashed_p = '1' }
            set asset_id_active_p 1
        }

    } else {

        # a user can only delete their own creations
        if { $asset_id ne "" } {
            set template_id [lindex [hf_asset_stats $asset_id $instance_id] 5]
            # delete a revision
            db_dml hf_asset_delete_u { delete from hf_assets 
                where id=:asset_id and instance_id=:instance_id and user_id=:user_id and trashed_p = '1' }
            # is asset_id the active revision for template_id?
            set asset_id_active_p [db_0or1row hf_label_from_asset_id { select label from hf_asset_label_map 
                where asset_id=:asset_id and instance_id=:instance_id } ]
            set success_p 1
        } elseif { $template_id ne "" } {
            # delete all revisions of template_id and the label_mapped to it
            # get active asset_id for reference later
            set asset_id [hf_asset_label_id_from_template_id $template_id $instance_id]
            # delete all revisions
            db_dml hf_template_delete_u { delete from hf_assets 
                where template_id=:template_id and instance_id=:instance_id and user_id=:user_id and trashed_p = '1' }
            set asset_id_active_p 1
        }
        
    }

    if { $asset_id_active_p } {
        # change the asset_id mapped to the label, or delete it if no alternates exist
        # find the most recent untrashed revision
        set new_untrashed_id_exists_p [db_0or1row hf_previous_asset_id { select id as new_asset_id from hf_assets 
            where template_id=:template_id and instance_id=:instance_id and not ( trashed_p = '1') and not ( id=:asset_id ) order by created desc limit 1 } ]
        if { $new_untrashed_id_exists_p } {
            #  point to the most recent untrashed revision
            db_dml hf_asset_id_update { update hf_asset_label_map set asset_id=:new_asset_id 
                where instance_id=:instance_id and asset_id=:asset_id }
        } else {
            # point to the most recent trashed revision, and trash the mapped label status for consistency
            set new_trashed_id_exists_p [db_0or1row hf_previous_asset_id2 { select id as new_asset_id from hf_assets 
                where template_id=:template_id and instance_id=:instance_id and not ( id=:asset_id ) order by created desc limit 1 } ]
            if { $new_trashed_id_exists_p } {
                db_dml hf_asset_id_update_trashed { update hf_asset_label_map
                    set asset_id=:new_asset_id, trashed_p = '1'
                    where instance_id=:instance_id and asset_id=:asset_id }
            } else {
                # the revision being deleted is the last revision, delete the mapped label entry
                set label [hf_asset_label_from_id $template_id]
                db_dml hf_asset_label_delete { delete from hf_asset_label_map
                    where label=:label and instance_id=:instance_id }
            }
        }
    }
    return 1
}



ad_proc -public hf_asset_trash {
    {asset_id ""}
    {trash_p "1"}
    {template_id ""}
    {instance_id ""}
    {user_id ""}
} {
    Trashes/untrashes asset_id or template_id (subject to permission check).
    set trash_p to 1 (default) to trash asset. Set trash_p to '0' to untrash. 
    Returns 1 if successful, otherwise returns 0
} {
    # asset_id can be unpublished revision or the published revision, trashed or untrashed
    set label ""

    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
        set untrusted_user_id [ad_conn untrusted_user_id]
    }
    #set write_p \[permission::permission_p -party_id $user_id -object_id $instance_id -privilege write\]
    set customer_id [hf_customer_id_of_asset_id $asset_id $instance_id]
    set write_p [hf_permission_p $user_id $customer_id assets write $instance_id]
    set asset_id_active_p 0

    # if write_p, don't need to scope to user_id == asset_user_id
    if { $write_p } {

        if { $asset_id ne "" } {
            # trash revision
            set template_id [lindex [hf_asset_stats $asset_id $instance_id] 5]
            set label [hf_asset_label_from_id $template_id]
            # wtr = write privilege trash revision
            db_dml hf_asset_trash_wtr { update hf_assets set trashed_p=:trash_p, last_modified = current_timestamp
                where id=:asset_id and instance_id=:instance_id }
            # is asset_id associated with a label ie published?
            set asset_id_active_p [db_0or1row hf_label_from_asset_id { select label from hf_asset_label_map 
                where asset_id=:asset_id and instance_id=:instance_id } ]

        } elseif { $template_id ne "" } {
            set label [hf_asset_label_from_id $template_id]
            # template_id affects all revisions. 
            # asset_id is blank. set asset_id to asset label's asset_id
            set asset_id [hf_asset_id_from_label $label]
            # wtp = write privilege trash asset ie bulk trashing revisions
            db_dml hf_asset_trash_wtp { update hf_assets set trashed_p=:trash_p, last_modified = current_timestamp
                where template_id=:template_id and instance_id=:instance_id }
            set asset_id_trash_p 1
        }

    } else {

        # a user can only un/trash their own entries
        # the user_id scope is applied in the query
        if { $asset_id ne "" } {
            # trash one revision
            set template_id [lindex [hf_asset_stats $asset_id $instance_id] 5]            
            set label [hf_asset_label_from_id $template_id]
            # utr = user privilege trash revision
            db_dml hf_asset_trash_utr { update hf_assets set trashed_p=:trash_p, last_modified = current_timestamp
                where id=:asset_id and instance_id=:instance_id and user_id=:user_id }
            # is asset_id associated with a label ie published?
            set asset_id_active_p [db_0or1row hf_label_from_asset_id { select label from hf_asset_label_map 
                where asset_id=:asset_id and instance_id=:instance_id } ]
            
        } elseif { $template_id ne "" 0 } {
            # trash for all revisions possible for same template_id
            set label [hf_asset_label_from_id $template_id]
            set asset_id [hf_asset_id_from_label $label]
            
            # utp = user privilege trash asset (as many revisions as they created)
            db_dml hf_asset_trash_utp { update hf_assets set trashed_p=:trash_p, last_modified = current_timestamp
                where template_id=:template_id and instance_id=:instance_id and user_id=:user_id }            
            set asset_id_active_p 1
        }
        
    }

#    ns_log Notice "hf_asset_trash: asset_id_active_p '$asset_id_active_p' trash_p '$trash_p'"

    if { $asset_id_active_p && $trash_p } {
        #  need to choose an alternate asset_id if available, since this asset_id is trashed
        ns_log Notice "hf_asset_trash(529). need to change asset_id"
        # asset_id is old_asset_id  
        # select most recent, available new_asset_id
        set new_asset_id_exists [db_0or1row hf_available_asset_id { select id as new_asset_id from hf_assets 
            where template_id=:template_id and instance_id=:instance_id and not (trashed_p = '1') and not ( id=:asset_id ) order by created desc limit 1 } ]
        if { $new_asset_id_exists } {
            ns_log Notice "hf_asset_trash(583): new_asset_id $new_asset_id"
            #  point to the most recent untrashed revision
            if { $asset_id ne $new_asset_id } {
                ns_log Notice "hf_asset_trash: changing active asset_id from $asset_id to $new_asset_id"
                db_dml hf_asset_label_id_update { update hf_asset_label_map set asset_id=:new_asset_id 
                    where instance_id=:instance_id and asset_id=:asset_id }
                # we avoided having to update trashed status for label_map
                set $asset_id_active_p 0
            }
        } 
    }

    if { !$trash_p } {
        # if asset_id of label_map is trashed, untrash it.

        db_0or1row hf_asset_label_trashed_p { select trashed_p as label_trashed_p from hf_asset_label_map
            where label=:label and instance_id=:instance_id }
        set label_trashed_p_exists_p [info exists label_trashed_p]
        if { !$label_trashed_p_exists_p || ( $label_trashed_p_exists_p && $label_trashed_p ne "1" ) } {
            set label_trashed_p 0
        }
        if { $label_trashed_p } {
            set label_asset_id [hf_asset_id_from_label $label $instance_id]
 #           ns_log Notice "hf_asset_trash(603): updating trash and asset_id '$label_asset_id' for label '$label' to asset_id '$asset_id' untrashed"
            db_dml hf_asset_label_map_update2 { update hf_asset_label_map set asset_id=:asset_id, trashed_p=:trash_p
                    where instance_id=:instance_id and asset_id=:label_asset_id }
            set asset_id_active_p 0
        }
        # untrash the label
    }

    # if asset_id active or untrashing asset_id and asset_label trashed
    if { $asset_id_active_p } {
        # published asset_id is affected, set mapped asset trash also.
        ns_log Notice "hf_asset_trash: updating hf_asset_label_map asset_id '$asset_id' instance_id '$instance_id'"
        db_dml hf_asset_label_trash_update { update hf_asset_label_map set trashed_p=:trash_p 
            where asset_id=:asset_id and instance_id=:instance_id }
    }
    return 1
}
