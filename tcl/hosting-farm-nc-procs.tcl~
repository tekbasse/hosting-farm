# hosting-farm/tcl/hosting-farm-scheduled-procs.tcl
ad_library {

    Scheduled procedures for hosting-farm package.
    @creation-date 2014-09-12
    @Copyright (c) 2014 Benjamin Brink
    @license GNU General Public License 3, see project home or http://www.gnu.org/licenses/gpl-3.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com

}

namespace eval hf::schedule {}

#TABLE hf_sched_proc_stack
#       id integer primary key,
#       -- assumes procedure is only scheduled/called once
#       proc_name varchar(40),
#       proc_args text,
# -- proc_args is just a log of values. Values actually come from hf_sched_proc_args
#       proc_out text,
#       user_id integer,
#       instance_id integer,
#       priority integer,
#       order_time timestamptz,
#       started_time timestamptz,
#       completed_time timestamptz,
#       process_seconds integer

# TABLE hf_sched_proc_args
#    stack_id integer
#    arg_number integer
#    arg_value text


# set id [db_nextval hf_sched_id_seq]

ad_proc -private hf::schedule::do {

} { 
    Process any scheduled procedures. Future batches are suspended until this process reports batch complete.
} {
    set cycle_time 13
    incr cycle_time -1
    set success_p 0
    set batch_lists [db_list_of_lists hf_sched_proc_stack_read_adm_p0_s { select id,proc_name,user_id,instance_id, priority, order_time, started_time from hf_sched_proc_stack where completed_time is null order by started_time asc, priority asc , order_time asc } ]
    set batch_lists_len [llength $batch_lists]
    set dur_sum 0
    set first_started_time [lindex [lindex $batch_lists 0] 6]
    # set debug_p to 0 to reduce repeated log noise:
    set debug_p 1
    if { $debug_p } {
        ns_log Notice "hf::schedule::do.39: first_started_time '${first_started_time}' batch_lists_len ${batch_lists_len}"
    }
    if { $first_started_time eq "" } {
        if { $batch_lists_len > 0 } {
            set bi 0
            # if loop nears cycle_time, quit and let next cycle reprioritize with any new jobs
            while { $bi < $batch_lists_len && $dur_sum < $cycle_time } {
                set sched_list [lindex $batch_lists $bi]
                # set proc_list lindex combo from sched_list
                lassign $sched_list id proc_name user_id instance_id priority order_time started_time
                # package_id can vary with each entry
                
                set allowed_procs [parameter::get -parameter ScheduledProcsAllowed -package_id $instance_id]
                # added comma and period to "split" to screen external/private references and poorly formatted lists
                set allowed_procs_list [split $allowed_procs " ,."]
                set success_p [expr { [lsearch -exact $allowed_procs_list $proc_name] > -1 } ]
                if { $success_p } {
                    if { $proc_name ne "" } {
                        ns_log Notice "hf::schedule::do.54 evaluating id $id"
                        set nowts [dt_systime -gmt 1]
                        set start_sec [clock seconds]
                        # tell the system I am working on it.
                        set success_p 1
                        db_dml hf_sched_proc_stack_started {
                            update hf_sched_proc_stack set started_time =:nowts where id =:id
                        }
                        
                        set proc_list [list $proc_name]
                        set args_lists [db_list_of_lists hf_sched_proc_args_read_s { select arg_value, arg_number from hf_sched_proc_args where stack_id =:id order by arg_number asc} ]
                        foreach arg_list $args_lists {
                            set arg_value [lindex $arg_list 0]
                            lappend proc_list $arg_value
                        }
                        #ns_log Notice "hf::schedule::do.69: id $id to Eval: '${proc_list}' list len [llength $proc_list]."
                        if {  [catch { set calc_value [eval $proc_list] } this_err_text] } {
                            ns_log Warning "hf::schedule::do.71: id $id Eval '${proc_list}' errored with ${this_err_text}."
                            # don't time an error. This provides a way to manually identify errors via sql sort
                            set nowts [dt_systime -gmt 1]
                            set success_p 0
                            db_dml hf_sched_proc_stack_write {
                                update hf_sched_proc_stack set proc_out =:this_err_text, completed_time=:nowts where id = :id 
                            } 
                            # inform user of error
                            set scenario_tid [lindex [lindex $args_lists 0] 0]
                            hf_log_create $scenario_tid "#hosting-farm.process#" "error" "id ${id} Message: ${this_err_text}" $user_id $instance_id
                        } else {
                            set dur_sec [expr { [clock seconds] - $start_sec } ]
                            # part of while loop so that remaining processes are re-prioritized with any new ones:
                            set dur_sum [expr { $dur_sum + $dur_sec } ]
                            set nowts [dt_systime -gmt 1]
                            set success_p 1
                            db_dml hf_sched_proc_stack_write {
                                update hf_sched_proc_stack set proc_out =:calc_value, completed_time=:nowts, process_seconds=:dur_sec where id = :id 
                            }
                            ns_log Notice "hf::schedule::do.83: id $id completed in circa ${dur_sec} seconds."
                        }
                        # Alert user that job is done?  
                        # util_user_message doesn't accept user_id instance_id, only session_id
                        # We don't have session_id available.. and it may have changed or not exist..
                        # Email?  that would create too many alerts for lots of quick jobs.
                        # auth::sync::job::* api does this.
                        # Create another package for user conveniences like active alerts..
                        # maybe hook into util_user_message after querying users.n_sessions or something..
                    }
                } else {
                    ns_log Warning "hf::schedule::do.87: id $id proc_name '${proc_name}' attempted but not allowed. user_id ${user_id} instance_id ${instance_id}"
                }
                # next batch index
                incr bi
            }
        } else {
            # if do is idle, delete some (limit 100 or so) used args in hf_sched_proc_args. Ids may have more than 1 arg..
            if { $debug_p } {
                ns_log Notice "hf::schedule::do.91: Idle. Entering passive maintenance mode. deleting up to 60 used args, if any."
            }
            set success_p 1
            db_dml hf_sched_proc_args_delete { delete from hf_sched_proc_args 
                where stack_id in ( select id from hf_sched_proc_stack where process_seconds is not null order by id limit 60 ) 
            }
        }
    } else {
        ns_log Notice "hf::schedule::do.97: Previous hf::schedule::do still processing. Stopping."
        # the previous hf::schedule::do is still working. Don't clobber. Quit.
        set success_p 1
    }
    if { $debug_p || !$success_p } {
        ns_log Notice "hf::schedule::do.99: returning success_p ${success_p}"
    }
    return $success_p
}

ad_proc -private hf::schedule::add {
    proc_name
    proc_args_list
    user_id
    instance_id
    priority
} {
    Adds a process to be "batched" in a process stack separate from page rendering.
} {
    # check proc_name against allowd ones.
    set session_package_id [ad_conn package_id]
    # We assume user has permission.. but qualify by verifying that instance_id is either user_id or package_id
    if { $instance_id eq $user_id || $instance_id eq $session_package_id } {
        set allowed_procs [parameter::get -parameter ScheduledProcsAllowed -package_id $session_package_id]
        # added comma and period to "split" to screen external/private references and poorly formatted lists
        set allowed_procs_list [split $allowed_procs " ,."]
        set success_p [expr { [lsearch -exact $allowed_procs_list $proc_name] > -1 } ]
        if { $success_p } { 
            set id [db_nextval hf_sched_id_seq]
            set ii 0
            db_transaction {
                set proc_args_txt [join $proc_args_list "\t"]
                set nowts [dt_systime -gmt 1]
                db_dml hf_sched_proc_stack_create { insert into hf_sched_proc_stack 
                    (id, proc_name, proc_args, user_id, instance_id, priority, order_time)
                    values (:id,:proc_name,:proc_args_txt,:user_id,:session_package_id,:priority,:nowts)
                    
                }
                foreach proc_arg $proc_args_list {
                    db_dml hf_sched_proc_args_create {
                        insert into hf_sched_proc_args
                        (stack_id, arg_number, arg_value)
                        values (:id,:ii,:proc_arg)
                    }
                    incr ii
                }
            } on_error {
                set success_p 0
                ns_log Warning "hf::schedule::add.90 failed for id '$id' ii '$ii' user_id ${user_id} instance_id ${instance_id} proc_args_list '${proc_args_list}'"
                ns_log Warning "hf::schedule::add.91 failed proc_name '${proc_name}' with message: ${errmsg}"
            }        
        }
    } else {
        ns_log Warning "hf::schedule::add.127 failed user_id ${user_id} session_package_id ${session_package_id} instance_id not valid: ${instance_id}"
        set success_p 0
    }
    return $success_p
}

ad_proc -private hf::schedule::trash {
    sched_id
    user_id
    instance_id
} {
    Removes an incomplete process from the process stack by noting it as completed.
} {
    # There is no delete for hf::schedule

    # noting a process as completed in the stack keeps the proc api simple
    # Theoretically, one could create an untrash (reschedule) proc for this also..
    set session_user_id [ad_conn user_id]
    set session_package_id [ad_conn package_id]
    set success_p 0
    #set create_p [permission::permission_p -party_id $session_user_id -object_id $session_package_id -privilege create]
    #set write_p [permission::permission_p -party_id $session_user_id -object_id $session_package_id -privilege write]
    # keep permissions simple for now
    set admin_p [permission::permission_p -party_id $session_user_id -object_id $session_package_id -privilege admin]
    # always allows a user to stop their own processes.
    if { $admin_p || ($session_user_id eq $user_id && ( $session_package_id eq $instance_id || $session_user_id eq $session_package_id ) ) } {
        set nowts [dt_systime -gmt 1]
        set proc_out "Process unscheduled by user_id $session_user_id."
        set success_p [db_dml hf_sched_proc_stack_trash { update hf_sched_proc_stack
            set proc_out=:proc_out, started_time=:nowts, completed_time=:nowts where sched_id=:sched_id and user_id=:user_id and instance_id=:instance_id and proc_out is null and started_time is null and completed_time is null } ]
    }
    return $success_p
}

ad_proc -private hf::schedule::read {
    sched_id
    user_id
    instance_id
} {
    Returns a list containing process status and results as: id,proc_name,proc_args,proc_out,user_id,instance_id, priority, order_time, started_time, completed_time, process_seconds.  Otherwise returns an empty list.
} {
    set session_user_id [ad_conn user_id]
    set session_package_id [ad_conn package_id]
    set admin_p [permission::permission_p -party_id $session_user_id -object_id $session_package_id -privilege admin]
    set process_stats_list [list ]
    if { $admin_p || ($session_user_id eq $user_id && ( $session_package_id eq $instance_id || $session_user_id eq $session_package_id ) ) } {
        set process_stats_list [db_list_of_lists hf_sched_proc_stack_read { select id,proc_name,proc_args,proc_out,user_id,instance_id, priority, order_time, started_time, completed_time, process_seconds from hf_sched_proc_stack where id =:sched_id and user_id=:user_id and instance_id=:instance_id } ]
    }
    return $process_stats_list
}

ad_proc -private hf::schedule::list {
    user_id
    instance_id
    {processed_p "0"}
    {n_items "all"}
    {m_offset "0"}
    {sort_by "order_time"}
    {sort_type "asc"}
} {
    Returns a list of active processes in stack ie. to be processed or in process; ordered by order_time. 
    List of lists includes: id,proc_name,proc_args,user_id,instance_id,priority,order_time,started_time,completed_time,process_seconds.
    If processed_p = 1, includes stack history, otherwise completed_time is blank. 
    List can be segmented by n items offset by m. 
} {
    set process_stats_list [list ]
    
    if { [ns_conn isconnected] && [qf_is_natural_number $user_id] && $user_id > 0 } {
        set session_user_id [ad_conn user_id]
        set session_package_id [ad_conn package_id]
        set admin_p [permission::permission_p -party_id $session_user_id -object_id $session_package_id -privilege admin]
    } 

    if { $admin_p || ($session_user_id eq $user_id && ( $session_package_id eq $instance_id || $session_user_id eq $session_package_id ) ) } {

        if { ![qf_is_natural_number $m_offset]} {
            set m_offset 0
        }
        if { ![qf_is_natural_number $n_items] } {
            set n_items "all"
        }
        set fields_list [list id proc_name proc_args user_id instance_id priority order_time started_time completed_time process_seconds]
        if { [lsearch -exact $fields_list $sort_by] == -1 } {
            set sort_by "order_time"
            set sort_type "asc"
        } elseif { $sort_type ne "asc" && $sort_type ne "desc" } {
            set sort_type "asc"
        }

        if { $admin_p } {
            if { $processed_p } {
                set process_stats_list [db_list_of_lists hf_sched_proc_stack_read_adm_p1 " select id,proc_name,proc_args,user_id,instance_id, priority, order_time, started_time, completed_time, process_seconds from hf_sched_proc_stack order where instance_id=:instance_id by $sort_by $sort_type limit $n_items offset :m_offset " ]
            } else {
                set process_stats_list [db_list_of_lists hf_sched_proc_stack_read_adm_p0 " select id,proc_name,proc_args,user_id,instance_id, priority, order_time, started_time, completed_time, process_seconds from hf_sched_proc_stack where completed_time is null order by $sort_by $sort_type limit $n_items offset :m_offset " ]
            }
        } else {
            if { $processed_p } {
                set process_stats_list [db_list_of_lists hf_sched_proc_stack_read_user_p1 " select id,proc_name,proc_args,user_id,instance_id, priority, order_time, started_time, completed_time, process_seconds from hf_sched_proc_stack where user_id=:user_id and ( instance_id=:instance_id or instance_id=:user_id) order by $sort_by $sort_type limit $n_items offset :m_offset " ]
            } else {
                set process_stats_list [db_list_of_lists hf_sched_proc_stack_read_user_p0 " select id,proc_name,proc_args,user_id,instance_id, priority, order_time, started_time, completed_time, process_seconds from hf_sched_proc_stack where completed_time is null and user_id=:user_id and ( instance_id=:instance_id or instance_id=:user_id) order by $sort_by $sort_type limit $n_items offset :m_offset " ]
            }
        }
    }
    return $process_stats_list
}


ad_proc -private hf::schedule::go_ahead {
} {
    Confirms process is not run via connection, or is run by an admin
} {
    if { [ns_conn isconnected] } {
        set user_id [ad_conn user_id]
        set instance_id [ad_conn package_id]
        set go_ahead [permission::permission_p -party_id $user_id -object_id $instance_id -privilege admin]
        if { !$go_ahead } {
            ns_log Warning "hf::schedule::go_head failed. Called by user_id ${user_id}, instance_id ${instance_id}"
        }
    } else {
        set go_ahead 1
    }
    if { !$go_ahead } {
        ad_script_abort
    }

    return $go_ahead
}


ad_proc -private hf::schedule::ip_read {
    id
    arr_name
} {
    Adds elements to an array. Creates array if it doesn't exist.
} {
    upvar 1 $arr_name obj_arr
    set success [hf::schedule::go_ahead ]

    return $success
}


ad_proc -private hf_asset_properties {
    asset_id
    array_name
    {instance_id ""}
    {user_id ""}
} {
    passes properties of an asset into array_name; creates array_name if it doesn't exist. Returns 1 if asset is returned, otherwise returns 0.
} {
    upvar $array_name named_arr
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [ad_conn package_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }

    set success_p [db_0or1row hf_assets_asset_type_id_r "select asset_type_id from hf_assets where instance_id=:instance_id and id=:asset_id"]
    if { $success_p } {
        # Don't use hf_* API here. Create queries specific to system call requirements.
        set asset_prop_list [list ]
        switch -- $asset_type_id {
###  move these db calls into procs in hosting-farm-scheduled-procs.tcl as private procs with permission only for no ns_conn or admin_p true. (create proc: is_admin_p )
            dc {
                #set asset_prop_list hf_dcs $instance_id "" $asset_id
                set asset_list [db_list_of_lists hf_asset_prop_get1 "select label, templated_p, template_p, flags from hf_assets where instance_id=:instance_id and id=:asset_id"] 
                set ip_list [db_list_of_lists hf_ip_address_prop_get1 "select ipv4_addr ipv4_status, ipv6_addr, ipv6_status from hf_ip_addresses where instance_id=:instance_id and ip_id in (select ip_id from hf_asset_ip_map where asset_id=:asset_id and instance_id=:instance_id)"]
                if { [llength $ip_list] > 0 && [llength $asset_list] > 0 } { 
                    set asset_prop_list $asset_list
                    foreach el $ip_list {
                        lappend asset_prop_list $el
                    }
                }
                set asset_key_list [list label templated_p template_p flags ipv4_addr ipv4_status ipv6_addr ipv6_status]
            }
            hw {
                #set asset_prop_list [hf_hws $instance_id "" $asset_id]
                set asset_list [db_list_of_lists hf_asset_prop_get1 "select label, templated_p, template_p, flags from hf_assets where instance_id=:instance_id and id=:asset_id"] 
                set hw_list [db_list_of_lists hf_hardware_prop_get1 "select system_name, backup_sys, ns_id from hf_hardware where instance_id=:instance_id and hw_id=:asset_id)"]
                if { [llength $hw_list] > 1 } {
                    set ns_id [lindex $hw_list 2]
                    set hw_list [lrange $hw_list 0 end-1]
                    set ni_list [db_list_of_lists hf_network_interfaces_prop_get1 "select os_dev_ref, bia_mac_address, ul_mac_address ipv4_addr_range, ipv6_addr_range from hf_network_interfaces where instance_id=:instance_id and ni_id=:ni_id"]
                    set ip_list [db_list_of_lists hf_ip_address_prop_get1 "select ipv4_addr ipv4_status, ipv6_addr, ipv6_status from hf_ip_addresses where instance_id=:instance_id and ip_id in (select ip_id from hf_asset_ip_map where asset_id=:asset_id and instance_id=:instance_id)"]                
                    set os_list [db_list_of_lists hf_operating_systems_prop_get1 "select label, brand, version, kernel, orphaned_p, requires_upgrade_p from hf_operating_systems where instance_id=:instance_id and os_id in (select os_id from hf_hardware where instance_id=:instance_id and hw_id=:asset_id)"]
                    if { [llength $ip_list] > 0 && [llength $os_list] > 0 && [llength $ni_list] > 0 } { 
                        set asset_prop_list $asset_list
                        foreach el $hw_list {
                            lappend asset_prop_list $el
                        }
                        foreach el $ni_list {
                            lappend asset_prop_list $el
                        }
                        foreach el $ip_list {
                            lappend asset_prop_list $el
                        }
                        foreach el $os_list {
                            lappend asset_prop_list $el
                        }
                    }
                }
                set asset_key_list [list label templated_p template_p flags system_name backup_sys os_label os_brand os_version os_kernel os_orphaned_p os_req_upgrade_p os_dev_ref bia_mac_address ul_mac_address ipv4_addr_range ipv6_addr_range ipv4_addr ipv4_status ipv6_addr ipv6_status]
            }
            vm {
                #set asset_prop_list [hf_vms $instance_id "" $asset_id]
                # split query into separate tables to handle more dynamics
                # h_assets  hf_asset_ip_map hf_ip_addresses hf_virutal_machines hf_ua hf_up 
                set asset_list [db_list_of_lists hf_asset_prop_get1 "select label, templated_p, template_p, flags from hf_assets where instance_id=:instance_id and id=:asset_id"] 
                set vm_list [db_list_of_lists hf_virtual_machines_prop_get1 "select domain_name, type_id, resource_path, mount_union, ip_id, ni_id, ns_id, os_id from hf_virtual_machines where instance_id=:instance_id and vm_id=:asset_id"]
                if [llength $vm_list] > 1 } {
                    set ip_id [lindex $vm_list 4]
                    set ni_id [lindex $vm_list 5]
                    set ns_id [lindex $vm_list 6]
                    set os_id [lindex $vm_list 7]
###
                }
                set asset_prop_list [db_list_of_lists hf_vm_prop_get "select a.label as label, a.templated_p as templated_p, a.template_p as template_p, a.flags as flags, x.ipv4_addr as ipv4_addr, x.ipv4_status as ipv4_status, x.ipv6_addr as ipv6_addr, x.ipv6_status as ipv6_status, v.domain_name as domain_name, v.type_id as vm_type_id, v.resource_path as vm_resource_path, v.mount_union as mount_union from hf_assets a, hf_asset_ip_map i, hf_ip_addresses x, hf_virtual_machines v, hf_ua ua, hf_up up where a.instance_id=:instance_id and a.id=:asset_id and a.asset_type_id=:asset_type_id and i.instance_id=:instance_id and i.asset_id=:asset_id and x.instance_id=:instance_id and v.instance_id=a.instance_id and i.ip_id=x.ip_id and a.id=i.vm_id and a.id=v.vm_id and "]
                set asset_key_list [list label templated_p template_p flags ipv4_addr ipv4_status ipv6_addr ipv6_status domain_name vm_type_id vm_resource_path mount_union vm_user vm_pasw]
                # hf_up_get_from_ua_id ua_id instance_id 
            }
            vh {
                #set asset_prop_list [hf_vhs $instance_id "" $asset_id]
                # split query into separate tables to handle more dynamics
                set asset_prop_list [db_list_of_lists hf_vh_prop_get "select a.label as label, a.templated_p as templated_p, a.template_p as template_p, a.flags as flags, x.ipv4_addr as ipv4_addr, x.ipv4_status as ipv4_status, x.ipv6_addr as ipv6_addr, x.ipv6_status as ipv6_status, v.domain_name as domain_name, v.type_id as vm_type_id, v.resource_path as vm_resource_path, v.mount_union as mount_union, vh.domain_name as vh_domain from hf_assets a, hf_asset_ip_map i, hf_ip_addresses x, hf_virtual_machines v, hf_vm_vh_map hv, hf_vhosts vh  where a.instance_id=:instance_id and a.id=:asset_id and a.asset_type_id=:asset_type_id and i.instance_id=:instance_id and i.asset_id=:asset_id and x.instance_id=:instance_id and v.instance_id=a.instance_id and vh.instance_id=a.instance_id and i.ip_id=x.ip_id and a.id=i.vm_id and a.id=v.vm_id and hv.vm_id=a.id and hv.vh_id=:vhost_id"]
                set asset_key_list [list label templated_p template_p flags ipv4_addr ipv4_status ipv6_addr ipv6_status domain_name vm_type_id vm_resource_path mount_union vh_domain vh_user vh_pasw]
                # hf_up_get_from_ua_id ua_id Instance_id
            }
            hs,ss {
                # see ss, hs hosting service is saas: ss
                # hf_ss_map ss_id, hf_id, hf_services,
                # maybe ua_id hf_up
                set asset_prop_list [db_list_of_lists hf_ss_prop_get ""]
                set asset_key_list [list ]
                
            }
            ns {
                # ns , custom domain name service records
            }
            ot { 
                # other, nothing specific. Supply generic info.
            }

            default {
                ns_log Warning "hf_asset_properties: missing asset_type_id in switch options. asset_type_id '${asset_type_id}'"
            }
        }
        set i 0
        foreach key $asset_key_list {
            set named_arr($key) [lindex $asset_prop_list $i]
            incr i
        }
        if { $i == 0 } {
            set success_p 0
        }
    } else {
        ns_log Warning "hf_asset_properties: no asset_id '${asset_id}' found. instance_id '${instance_id}' user_id '${user_id}' array_name '${array_name}'"
    }
    return $success_p
}

