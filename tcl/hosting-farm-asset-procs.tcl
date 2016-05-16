#hosting-farm/tcl/hosting-farm-asset-procs.tcl
ad_library {

    API for hosting-farm
    @creation-date 25 May 2013
    @Copyright (c) 2014 Benjamin Brink
    @license GNU General Public License 3, see project home or http://www.gnu.org/licenses/gpl-3.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com

    # this is ported from q-wiki.
    # in this context, template_id refers to a page with shared revisions of multiple page_id(s).
    # hf_assets uses template in the context of an original from which copies are made.

    # to do: 
    # make q-wiki.tcl work for hf_asset procs
    #  convert the tcl in the hf-asset.tcl to modular procs for multiple uses with
    # subsets of assets ie dedicated custom 1 page apps.

    # Assets can be created, revised, trashed and deleted.
    # Deleted option should only be available if an asset is not referenced.. 
    # TODO: add reference checking for hf_asset_delete
    #   asset_type_id

    # temporary map showing qw_ vs. hf_ fields.
    template_id
    id
    label (was q-wiki.url)
    name  (pretty label)
    title          title (was one_line_description)
    content        # publishable content
    keywords       # publishable search
    description
    comments       # internal comments
    trashed_p
    trashed_by
    # wherever keywords are referenced, add these fields:
    time_start     # becomes/became active
    time_stop      # expires/expired
    #flags   (see lower in list)
    template_p
    templated_p  # this value should only be 1 when template_p eq 0
    publish_p
    monitor_p
    popularity
    triage_priority
    flags
    op_status
    ua_id # burger kontonavn, see hf_ua
    ns_id # name service, custom record
    qal_product_id 
    qal_customer_id
    instance_id
    user_id
}

ad_proc -public hf_asset_id_exists { 
    asset_id
    {asset_type_id ""}
    {instance_id ""}
} {
    Returns 1 if asset_id exists for instance_id, else returns 0
} {
    if { $instance_id eq "" } {
        # set instance_id subsite_id
        set instance_id [ad_conn subsite_id]
    }
    if { $asset_type_id eq "" } {
        set asset_filter_p 0
    } else {
        regsub -nocase -all -- {[^a-z0-9]} $asset_type_id {} filtered_as_type_id
        if { $filtered_as_type_id eq "" || [string length $filtered_as_type_id] > 24 } {
            set asset_filter_p 0
        } else {
            set asset_filter_p 1
        }
    }
    if { $asset_filter_p } {
        set asset_exists_p [db_0or1row hf_asset_get_id {select name from hf_assets where id = :asset_id and instance_id = :instance_id and asset_type_id =:filtered_as_type_id } ]
    } else {
        set asset_exists_p [db_0or1row hf_asset_get_id {select name from hf_assets where id = :asset_id and instance_id = :instance_id } ]
    }
    return $asset_exists_p
}

ad_proc -public hf_change_asset_id_for_label {
    asset_id_new
    asset_label
    {instance_id ""}
} {
    Changes the active revision (asset_id) for asset_label. Returns 1 if successful, otherwise 0.
} {
    if { $instance_id eq "" } {
        # set instance_id subsite_id
        set instance_id [ad_conn subsite_id]
    }
    set user_id [ad_conn user_id]
#    set write_p \[permission::permission_p -party_id $user_id -object_id $instance_id -privilege write\] 
    set write_p [hf_permission_p $user_id "" assets write $instance_id]
    set success_p 0
    if { $write_p } {
        # new asset
        set asset_new_stats_list [hf_asset_stats $asset_id_new $instance_id]
        set template_id_new [lindex $asset_new_stats_list 5]
        set trashed_p_new [lindex $asset_new_stats_list 7]
        set asset_label_new [hf_asset_label_from_id $asset_id_new $instance_id]
        # new and current asset
        if { $asset_label_new ne "" && $asset_label eq $asset_label_new && !$trashed_p_new } {
            db_dml hf_change_revision { update hf_asset_label_map
            set asset_id = :asset_id_new where label = :asset_label and instance_id = :instance_id }
            db_dml hf_change_revision_active { update hf_assets
                set last_modified = current_timestamp where id = :asset_id_new and instance_id = :instance_id }
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
    Changes the asset_label where the asset is referenced from asset_label to asset_name. Returns 1 if successful, otherwise 0.
} {
    if { $instance_id eq "" } {
        # set instance_id subsite_id
        set instance_id [ad_conn subsite_id]
    }
    set user_id [ad_conn user_id]
#    set write_p \[permission::permission_p -party_id $user_id -object_id $instance_id -privilege write\] 
    set write_p [hf_permission_p $user_id "" assets write $instance_id]
    set success_p 0
    if { $write_p && $asset_label ne "" && $asset_name ne "" } {
        set asset_labels_id [hf_asset_id_from_label $asset_label $instance_id]
        set asset_stats_list [hf_asset_stats $asset_labels_id $instance_id]
        set template_id [lindex $asset_stats_list 5]
        # does asset_name already exist? 
        set pn_asset_id  [hf_asset_id_from_label $asset_name $instance_id]

        if { $pn_asset_id ne "" } {
            set pn_stats_list [hf_asset_stats $pn_asset_id $instance_id]
            set pn_template_id [lindex $pn_stats_list 5]
            # just:
            # mv the template_id of asset_label revisions to asset_name revisions template_id
            db_dml hf_name_change_template_id { update hf_assets
                set last_modified = current_timestamp, template_id =:pn_template_id, name =:asset_name where template_id = :template_id and instance_id = :instance_id }
            # get rid of the existing asset_name entry
            db_dml hf_name_change_label_del { delete from hf_asset_label_map
                where label = :asset_label and instance_id = :instance_id }
            
        } else {
            # update hf_asset_label_map.label hf_assets.asset_name to asset_name for template_id, instance_id
            db_dml hf_name_change_assets { update hf_assets
                set last_modified = current_timestamp, name = :asset_name where template_id = :template_id and instance_id = :instance_id }
            db_dml hf_name_change_label { update hf_asset_label_map
                set label = :asset_name where label = :asset_label and instance_id = :instance_id }
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
        # set instance_id subsite_id
        set instance_id [ad_conn subsite_id]
    }
    set user_id [ad_conn user_id]
   # set write_p \[permission::permission_p -party_id $user_id -object_id $instance_id -privilege write\]    
    set write_p [hf_permission_p $user_id "" assets write $instance_id]
    if { $write_p } {
        # okay to return trashed assets
        set asset_exists_p [db_0or1row hf_asset_get_id_from_label {select asset_id from hf_asset_label_map 
            where label = :asset_label and instance_id = :instance_id } ]
    } else {
        set asset_exists_p [db_0or1row hf_asset_get_id_from_label {select asset_id from hf_asset_label_map 
            where label = :asset_label and instance_id = :instance_id and not ( trashed_p = '1' ) } ]
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
        # set instance_id subsite_id
        set instance_id [ad_conn subsite_id]
    }
    set user_id [ad_conn user_id]
   # set write_p \[permission::permission_p -party_id $user_id -object_id $instance_id -privilege write\]    
    set write_p [hf_permission_p $user_id "" assets write $instance_id]
    if { $write_p } {
        # okay to return trashed assets
        set asset_exists_p [db_0or1row hf_asset_get_all_label_from_id { select label as asset_label from hf_asset_label_map 
            where asset_id = :asset_id and instance_id = :instance_id } ]
    } else {
        set asset_exists_p [db_0or1row hf_asset_get_untrashed_label_from_id { select label as asset_label from hf_asset_label_map 
            where asset_id = :asset_id and instance_id = :instance_id and not ( trashed_p = '1' ) } ]
    }
    if { !$asset_exists_p } {
        set asset_stat_list [hf_asset_stats $asset_id]
        set template_id [lindex $asset_stat_list 5]
#        ns_log Notice "hf_asset_label_from_id: asset_id '$asset_id' template_id '$template_id'"
        if { $template_id ne "" } {
            # get asset_label from template_id
            db_0or1row hf_asset_get_label_from_ids_template { select label as asset_label from hf_asset_label_map 
                where asset_id in ( select id as asset_id from hf_assets 
                                   where instance_id = :instance_id and template_id = :template_id ) } 
        } 
        if { $asset_label eq "" } {
            # maybe asset_id doesn't exist, but asset_id is a template_id 
            db_0or1row hf_asset_get_label_from_template_id { select label as asset_label from hf_asset_label_map 
                where asset_id in ( select id as asset_id from hf_assets 
                                   where instance_id = :instance_id and template_id = :asset_id ) } 
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
        # set instance_id subsite_id
        set instance_id [ad_conn subsite_id]
    }
    set asset_id ""
    db_0or1row hf_asset_get_label_from_template_id { select asset_id from hf_asset_label_map 
        where instance_id = :instance_id and asset_id in ( select id as asset_id from hf_assets 
                                                          where instance_id = :instance_id and template_id = :template_id ) }
    return $asset_id
}


ad_proc -public hf_asset_from_label { 
    asset_label
    {instance_id ""}
} {
    Returns asset_id if asset is published (untrashed) for instance_id, else returns empty string.
} {
    if { $instance_id eq "" } {
        # set instance_id subsite_id
        set instance_id [ad_conn subsite_id]
    }
    set asset_exists_p [db_0or1row hf_asset_get_id_from_label2 {select asset_id from hf_asset_label_map 
        where label = :asset_label and instance_id = :instance_id and not ( trashed_p = '1' ) } ]
    if { !$asset_exists_p } {
        set asset_id ""
    }
    return $asset_id
}

ad_proc -public hf_asset_create { 
    label
    name
    asset_type_id
    title
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
    {from_template_id ""}
} {
    Creates hf asset. returns asset_id, or 0 if error. instance_id is usually subsite_id
} {

    if { $instance_id eq "" } {
        # set instance_id subsite_id
        set instance_id [ad_conn subsite_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
        set untrusted_user_id [ad_conn untrusted_user_id]
    }
    set return_asset_id 0
   # set create_p \[permission::permission_p -party_id $user_id -object_id $instance_id -privilege create\]
    set create_p [hf_permission_p $user_id "" assets create_p $instance_id]
    ns_log Notice "hf_asset_create: create_p $create_p"
    if { $create_p } {
        set template_id ""
        set trashed_p 0
        set asset_label_exists_p [db_0or1row hf_label_get_asset_id {select asset_id from hf_asset_label_map where label = :label and instance_id = :instance_id } ]
        if { $asset_label_exists_p } {
            set asset_id_exists_p [db_0or1row hf_label_get_id { select asset_id from hf_asset_label_map where asset_id = :asset_id and instance_id = :instance_id } ]
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
                (id,template_id,name,asset_type_id,title,keywords,description,content,comments,template_p,templated_p,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created,from_template_id)
                values (:asset_id,:template_id,:name,:asset_type_id,:title,:keywords,:description,:content,:comments,:template_p,:templated_p,:publish_p,:monitor_p,:popularity,:triage_priority,:op_status,:ua_id,:ns_id,:qal_product_id,:qal_customer_id,:instance_id,:user_id,current_timestamp,current_timestamp,:from_template_id) }
            
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
                    set asset_id = :asset_id where label = :label and instance_id = :instance_id }
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
} {
    Returns an ordered list of keys that is parallel to the ordered list returned by hf_asset_stats.
} {
    set keys_list [list \
                       name \
                       title \
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
                       template_id]
    return $keys_list
}
    
ad_proc -public hf_asset_stats { 
    asset_id
    {instance_id ""}
    {user_id ""}
} {
    Returns asset stats as a list: name, title, asset_type_id, keywords, description, template_p, templated_p, trashed_p, trashed_by, publish_p, monitor_p, popularity, triage_priority, op_status, ua_id, ns_id, qal_product_id, qal_customer_id, instance_id, user_id, last_modified, created, flags, template_id
} {
    if { $instance_id eq "" } {
        # set instance_id subsite_id
        set instance_id [ad_conn subsite_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
        set untrusted_user_id [ad_conn untrusted_user_id]
    }
    # check permissions
    #set read_p \[permission::permission_p -party_id $user_id -object_id $instance_id -privilege read\]
    set read_p [hf_permission_p $user_id "" assets read $instance_id]
    if { $read_p } {
        set return_list_of_lists [db_list_of_lists hf_asset_stats { select name,title,asset_type_id,keywords,description,template_p,templated_p,trashed_p,trashed_by,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created,flags,template_id from hf_assets where id = :asset_id and instance_id = :instance_id } ] 
        # convert return_lists_of_lists to return_list
        set return_list [lindex $return_list_of_lists 0]
        # convert trash null/empty value to logical 0
        if { [llength $return_list] > 1 && [lindex $return_list 7] eq "" } {
            set return_list [lreplace $return_list 7 7 0]
        }

    } else {
        set return_list [list ]
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
        # set instance_id subsite_id
        set instance_id [ad_conn subsite_id]
    }
    if { $user_id eq "" } {
        set party_id [ad_conn user_id]
        set untrusted_user_id [ad_conn untrusted_user_id]
    } else {
        set party_id $user_id
    }
   # set read_p [permission::permission_p -party_id $party_id -object_id $instance_id -privilege read]
    set read_p [hf_permission_p $user_id "" assets read $instance_id]
    if { $read_p } {
        if { $template_id eq "" } {
            if { $user_id ne "" } {
                # get a list of asset_ids that are mapped to a label for instance_id and where the current revision was created by user_id
                set return_list [db_list hf_assets_user_list { select id from hf_assets where instance_id = :instance_id and user_id = :user_id and id in ( select asset_id from hf_asset_label_map where instance_id = :instance_id ) order by last_modified desc } ]
            } else {
                # get a list of all asset_ids mapped to a label for instance_id.
                set return_list [db_list hf_assets_list { select id as asset_id from hf_assets where id in ( select asset_id from hf_asset_label_map where instance_id = :instance_id ) order by last_modified desc } ]
            }
        } else {
            # is the template_id valid?
            set has_template [db_0or1row hf_asset_template { select template_id as db_template_id from hf_assets where template_id= :template_id limit 1 } ]
            if { $has_template && [info exists db_template_id] && $template_id > 0 } {
                if { $user_id ne "" } {
                    # get a list of all asset_ids of the revisions of asset (template_id) that user_id created.
                    set return_list [db_list hf_assets_t_u_list { select id from hf_assets where instance_id = :instance_id and user_id = :user_id and template_id = :template_id order by last_modified desc } ]
                } else {
                    # get a list of all asset_ids of the revisions of asset (template_id) 
                    set return_list [db_list hf_assets_list { select id from hf_assets where instance_id = :instance_id and template_id = :template_id order by last_modified } ]
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
    set keys_list [list \
                       name \
                       title \
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
    Returns asset contents of asset_id. Returns asset as list of attribute values: name,title,asset_type_id,keywords,description,content,comments,trashed_p,trashed_by,template_p,templated_p,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created,template_id

} {
    if { $instance_id eq "" } {
        # set instance_id subsite_id
        set instance_id [ad_conn subsite_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
        set untrusted_user_id [ad_conn untrusted_user_id]
    }
   # set read_p \[permission::permission_p -party_id $user_id -object_id $instance_id -privilege read\]
    set read_p [hf_permission_p $user_id "" assets read $instance_id]
    set return_list [list ]
    if { $read_p } {
        set return_list_of_lists [db_list_of_lists hf_asset_get { select name, title, asset_type_id, keywords, description, content, comments, trashed_p, trashed_by, template_p, templated_p, publish_p, monitor_p, popularity, triage_priority, op_status, ua_id,ns_id, qal_product_id, qal_customer_id, instance_id, user_id, last_modified, created, template_id from hf_assets where id = :asset_id and instance_id = :instance_id } ] 
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
    title
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
        # set instance_id subsite_id
        set instance_id [ad_conn subsite_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
        set untrusted_user_id [ad_conn untrusted_user_id]
    }
   # set write_p \[permission::permission_p -party_id $user_id -object_id $instance_id -privilege write\]
    set write_p [hf_permission_p $user_id "" assets write $instance_id]
    set new_asset_id ""

    if { $write_p } {
        set asset_exists_p [db_0or1row hf_asset_get_user_id {select user_id as creator_id from hf_assets where id = :asset_id } ]
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
                (id,template_id,name,title,asset_type_id,keywords,description,content,comments,template_p,templated_p,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created)
                values (:asset_id,:template_id,:name,:title,:asset_type_id,:keywords,:description,:content,:comments,:template_p,:templated_p,:publish_p,:monitor_p,:popularity,:triage_priority,:op_status,:ua_id,:ns_id,:qal_product_id,:qal_customer_id,:instance_id,:user_id,current_timestamp,current_timestamp) }
                ns_log Notice "hf_asset_write: hf_asset_id_update asset_id '$new_asset_id' instance_id '$instance_id' old_asset_id '$old_asset_id'"
                db_dml hf_asset_id_update { update hf_asset_label_map
                    set asset_id = :new_asset_id where instance_id = :instance_id and label = :label }
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
        # set instance_id subsite_id
        set instance_id [ad_conn subsite_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    #set delete_p \[permission::permission_p -party_id $user_id -object_id $instance_id -privilege delete\]
    set delete_p [hf_permission_p $user_id "" assets delete $instance_id]
    set success_p 0
    set asset_id_active_p 0
    ns_log Notice "hf_asset_delete: delete_p '$delete_p' asset_id '$asset_id' template_id '$template_id'"
    if { $delete_p } {
        
        if { $asset_id ne "" } {
            set template_id [lindex [hf_asset_stats $asset_id $instance_id] 5]
            # delete a revision
            db_dml hf_asset_delete { delete from hf_assets 
                where id=:asset_id and instance_id =:instance_id and trashed_p = '1' }
            # is asset_id the active revision for template_id?
            set asset_id_active_p [db_0or1row hf_label_from_asset_id { select label from hf_asset_label_map 
                where asset_id = :asset_id and instance_id = :instance_id } ]
        } elseif { $template_id ne "" } {
            # delete all revisions of template_id and the label_mapped to it
            # get active asset_id for reference later
            set asset_id [hf_asset_label_id_from_template_id $template_id $instance_id]
            # delete all revisions
            db_dml hf_template_delete { delete from hf_assets 
                where template_id=:template_id and instance_id =:instance_id and trashed_p = '1' }
            set asset_id_active_p 1
        }

    } else {

        # a user can only delete their own creations
        if { $asset_id ne "" } {
            set template_id [lindex [hf_asset_stats $asset_id $instance_id] 5]
            # delete a revision
            db_dml hf_asset_delete_u { delete from hf_assets 
                where id=:asset_id and instance_id =:instance_id and user_id=:user_id and trashed_p = '1' }
            # is asset_id the active revision for template_id?
            set asset_id_active_p [db_0or1row hf_label_from_asset_id { select label from hf_asset_label_map 
                where asset_id = :asset_id and instance_id = :instance_id } ]
            set success_p 1
        } elseif { $template_id ne "" } {
            # delete all revisions of template_id and the label_mapped to it
            # get active asset_id for reference later
            set asset_id [hf_asset_label_id_from_template_id $template_id $instance_id]
            # delete all revisions
            db_dml hf_template_delete_u { delete from hf_assets 
                where template_id=:template_id and instance_id =:instance_id and user_id = :user_id and trashed_p = '1' }
            set asset_id_active_p 1
        }
        
    }

    if { $asset_id_active_p } {
        # change the asset_id mapped to the label, or delete it if no alternates exist
        # find the most recent untrashed revision
        set new_untrashed_id_exists_p [db_0or1row hf_previous_asset_id { select id as new_asset_id from hf_assets 
            where template_id = :template_id and instance_id = :instance_id and not ( trashed_p = '1') and not ( id = :asset_id ) order by created desc limit 1 } ]
        if { $new_untrashed_id_exists_p } {
            #  point to the most recent untrashed revision
            db_dml hf_asset_id_update { update hf_asset_label_map set asset_id = :new_asset_id 
                where instance_id = :instance_id and asset_id = :asset_id }
        } else {
            # point to the most recent trashed revision, and trash the mapped label status for consistency
            set new_trashed_id_exists_p [db_0or1row hf_previous_asset_id2 { select id as new_asset_id from hf_assets 
                where template_id = :template_id and instance_id = :instance_id and not ( id = :asset_id ) order by created desc limit 1 } ]
            if { $new_trashed_id_exists_p } {
                db_dml hf_asset_id_update_trashed { update hf_asset_label_map
                    set asset_id = :new_asset_id, trashed_p = '1'
                    where instance_id = :instance_id and asset_id = :asset_id }
            } else {
                # the revision being deleted is the last revision, delete the mapped label entry
                set label [hf_asset_label_from_id $template_id]
                db_dml hf_asset_label_delete { delete from hf_asset_label_map
                    where label =:label and instance_id =:instance_id }
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
        # set instance_id subsite_id
        set instance_id [ad_conn subsite_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
        set untrusted_user_id [ad_conn untrusted_user_id]
    }
    #set write_p \[permission::permission_p -party_id $user_id -object_id $instance_id -privilege write\]
    set write_p [hf_permission_p $user_id "" assets write $instance_id]
    set asset_id_active_p 0

    # if write_p, don't need to scope to user_id == asset_user_id
    if { $write_p } {

        if { $asset_id ne "" } {
            # trash revision
            set template_id [lindex [hf_asset_stats $asset_id $instance_id] 5]
            set label [hf_asset_label_from_id $template_id]
            # wtr = write privilege trash revision
            db_dml hf_asset_trash_wtr { update hf_assets set trashed_p =:trash_p, last_modified = current_timestamp
                where id=:asset_id and instance_id =:instance_id }
            # is asset_id associated with a label ie published?
            set asset_id_active_p [db_0or1row hf_label_from_asset_id { select label from hf_asset_label_map 
                where asset_id = :asset_id and instance_id = :instance_id } ]

        } elseif { $template_id ne "" } {
            set label [hf_asset_label_from_id $template_id]
            # template_id affects all revisions. 
            # asset_id is blank. set asset_id to asset label's asset_id
            set asset_id [hf_asset_id_from_label $label]
            # wtp = write privilege trash asset ie bulk trashing revisions
            db_dml hf_asset_trash_wtp { update hf_assets set trashed_p =:trash_p, last_modified = current_timestamp
                where template_id=:template_id and instance_id =:instance_id }
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
            db_dml hf_asset_trash_utr { update hf_assets set trashed_p =:trash_p, last_modified = current_timestamp
                where id=:asset_id and instance_id =:instance_id and user_id=:user_id }
            # is asset_id associated with a label ie published?
            set asset_id_active_p [db_0or1row hf_label_from_asset_id { select label from hf_asset_label_map 
                where asset_id = :asset_id and instance_id = :instance_id } ]
            
        } elseif { $template_id ne "" 0 } {
            # trash for all revisions possible for same template_id
            set label [hf_asset_label_from_id $template_id]
            set asset_id [hf_asset_id_from_label $label]
            
            # utp = user privilege trash asset (as many revisions as they created)
            db_dml hf_asset_trash_utp { update hf_assets set trashed_p =:trash_p, last_modified = current_timestamp
                where template_id=:template_id and instance_id =:instance_id and user_id=:user_id }            
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
            where template_id = :template_id and instance_id = :instance_id and not (trashed_p = '1') and not ( id =:asset_id ) order by created desc limit 1 } ]
        if { $new_asset_id_exists } {
            ns_log Notice "hf_asset_trash(583): new_asset_id $new_asset_id"
            #  point to the most recent untrashed revision
            if { $asset_id ne $new_asset_id } {
                ns_log Notice "hf_asset_trash: changing active asset_id from $asset_id to $new_asset_id"
                db_dml hf_asset_label_id_update { update hf_asset_label_map set asset_id = :new_asset_id 
                    where instance_id = :instance_id and asset_id = :asset_id }
                # we avoided having to update trashed status for label_map
                set $asset_id_active_p 0
            }
        } 
    }

    if { !$trash_p } {
        # if asset_id of label_map is trashed, untrash it.

        db_0or1row hf_asset_label_trashed_p { select trashed_p as label_trashed_p from hf_asset_label_map
            where label = :label and instance_id = :instance_id }
        set label_trashed_p_exists_p [info exists label_trashed_p]
        if { !$label_trashed_p_exists_p || ( $label_trashed_p_exists_p && $label_trashed_p ne "1" ) } {
            set label_trashed_p 0
        }
        if { $label_trashed_p } {
            set label_asset_id [hf_asset_id_from_label $label $instance_id]
 #           ns_log Notice "hf_asset_trash(603): updating trash and asset_id '$label_asset_id' for label '$label' to asset_id '$asset_id' untrashed"
            db_dml hf_asset_label_map_update2 { update hf_asset_label_map set asset_id = :asset_id, trashed_p = :trash_p
                    where instance_id = :instance_id and asset_id = :label_asset_id }
            set asset_id_active_p 0
        }
        # untrash the label
    }

    # if asset_id active or untrashing asset_id and asset_label trashed
    if { $asset_id_active_p } {
        # published asset_id is affected, set mapped asset trash also.
        ns_log Notice "hf_asset_trash: updating hf_asset_label_map asset_id '$asset_id' instance_id '$instance_id'"
        db_dml hf_asset_label_trash_update { update hf_asset_label_map set trashed_p = :trash_p 
            where asset_id = :asset_id and instance_id = :instance_id }
    }
    return 1
}
