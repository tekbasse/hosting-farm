ad_library {

    example localize API for hosting-farm ( /local/bin )
    @creation-date 11 April 2015
    @Copyright (c) 2014 Benjamin Brink
    @license GNU General Public License 3, see project home or http://www.gnu.org/licenses/gpl-3.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com
}
# begin all procs here with hfl_ for hflocal.
ad_proc -private hfl_asset_halt_example {
    asset_id
    {user_id ""}
    {instance_id ""}
} {
    Halts the operation of an asset, such as service, vm, vhost etc
} {
    ##code

    # check permission
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { [ns_conn isconnected] } {
	# this shouldn't happen. All these are called via scheduled procs.
        set user_id [ad_conn user_id]
	ns_log Warning "hfl_asset_halt_example(29): direct execution attempted by user_id '${user_id}'. Aborted."
    } else {
	# determine customer_id of asset
	# name,title,asset_type_id,keywords,description,template_p,templated_p,trashed_p,trashed_by,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created,flags
	set asset_stats_list [hf_asset_stats $asset_id $instance_id $user_id]
	set customer_id [lindex $asset_stats_list 17]
	
	set admin_p [hf_permission_p $user_id $customer_id assets admin $instance_id]
	if { $admin_p } {
	    # determine asset_type
	    set asset_type_id [lindex $asset_stats_list 2]

	    # set asset attributes so that remaining code can use them for any nonlocal api calls.
	    set now [dt_systime -gmt 1]
	    ## read properties of asset_id for halting.
	    
	    ns_log Notice "hf_asset_halt id ${asset_id}' of type '${asset_type_id}'"
	    db_dml hf_asset_id_halt { update hf_assets
		set time_stop = :now where time_stop is null and asset_id = :asset_id 
	    }
	    #    set a priority for use with hf process stack
	    set priority [lindex $asset_stats_list 9]
	    if { $priority eq "" } {
		# triage_priority
		set priority [lindex $asset_stats_list 12]
	    }
	    
	    set proc_name [db_1row hf_asset_type_halt_proc_get { 
		select halt_proc from hf_asset_type where id = :asset_type_id and instance_id = :instance_id
	    } ]
	}
    }
    # return 1 if successful (at least has permission)
    return $admin_p
}


