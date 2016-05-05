# hosting-farm/tcl/hosting-farm-monitor-procs.tcl
ad_library {

    Scheduled Monitor procedures for hosting-farm package.
    Monitoring uses a separate scheduling paradigm
    to avoid instabilities and conflicts from other processes
    @creation-date 2015-09-12
    @Copyright (c) 2015 Benjamin Brink
    @license GNU General Public License 3, see project home or http://www.gnu.org/licenses/gpl-3.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com

}

namespace eval hf::monitor {}

# once every few seconds, hf::monitor::do is called. ( see tcl/hosting-farm-scheduled-init.tcl )

ad_proc -private hf_beat_log_create {
    asset_id
    monitor_id
    user_id
    alert_p
    critical_alert_p
    confirm_p
    message_p
    name
    title
    log_entry
} {
    Log an entry for a hf_beat_log process. Returns unique entry_id if successful, otherwise returns empty string.
} {
    set id ""
    set asset_id_p [qf_is_natural_number $asset_id]
    if { $asset_id_p } {
        if { $log_entry ne "" } {
            if { ![qf_is_natural_number $instance_id] } {
                ns_log Notice "hf_beat_log_create.451: instance_id '${instance_id}' changing.."
                set instance_id [ad_conn package_id]
            }
            if { ![qf_is_natural_number $user_id] } {
                ns_log Notice "hf_beat_log_create.451: user_id was '${user_id}' changing.."
                if { [ns_conn isconnected] } {
                    set user_id [ad_conn user_id]
                } else {
                    set user_id [hf_user_id_from_asset_id $asset_id]
                }
            }
            if { $user_id ne "" } {
                set id [db_nextval hf_beat_id_seq]
                set trashed_p 0
                set message_sent_p 0
                set confirmed_p 0
                set nowts [dt_systime -gmt 1]
                set name [qf_abbreviate $name 38]
                set title [qf_abbreviate $title 78]
                set monitor_id_p [qf_is_natural_number $monitor_id]
                if { $alert_p ne "0" } {
                    set $alert_p "1"
                }
                if { $critical_alert_p ne "0" } {
                    set critical_alert_p "1"
                }
                if { $confirm_p ne "1" } {
                    set confirm_p "0"
                }
                if { $message_p ne "0" } {
                    set message_p "1"
                }

                # -- For beat process logs
                # CREATE TABLE hf_beat_log (
                #     id integer not null primary key,
                #     instance_id integer,
                #     user_id integer,
                #     asset_id integer,
                #     -- If there is a monitor_id associated, include it.
                #     monitor_id integer,
                #     trashed_p varchar(1) default '0',
                #     alert_p varchar(1) default '0',
                #     -- Is this a system alert or critical message requiring
                #     -- a flag for extra presentation handling?
                #     critical_alert_p varchar(1) default '0',
                #     -- If the alert needs a confirmation from a user
                #     confirm_p varchar(1) default '0',
                #     -- If confirmation required, confirmation received?
                #     confirmed_p varchar(1) default '0',
                #     -- send an email/sms etc with alert?
                #     message_p varchar(1) default '0',
                #     -- Was the email sent?
                #     -- This allows the system to batch multiple outbound messages to one user
                #     -- and potentially skip sending messages already received on screen.
                #     message_sent_p varchar(1) default '0',
                #     name varchar(40),
                #     title varchar(80),
                #     created timestamptz default now(),
                #     last_modified timestamptz,
                #     log_entry text
                # );
                if { $monitor_id_p } {
                    db_dml hf_beat_log_cr_w_id { insert into hf_beat_log
                        (id,instance_id,user_id,asset_id,monitor_id,trashed_p,alert_p,critical_alert_p,confirm_p,confirmed_p,message_p,message_sent_p,name,title,created,last_modified,log_entry)
                        values (:id,:instance_id,:user_id,:asset_id,:monitor_id,:trashed_p,:alert_p,:critical_alert_p,:confirm_p,:confirmed_p,:message_p,:message_sent_p,:name,:title,:nowts,:nowts,:log_entry)
                    }
                    ns_log Notice "hf_beat_log_create.104: posting to hf_beat_log: monitor_id '${monitor_id}' user_id '${user_id}' name '${name}' log_entry '${log_entry}'"
                } else {
                    db_dml hf_beat_log_cr_wo_id { insert into hf_beat_log
                        (id,instance_id,user_id,asset_id,trashed_p,alert_p,critical_alert_p,confirm_p,confirmed_p,message_p,message_sent_p,name,title,created,last_modified,log_entry)
                        values (:id,:instance_id,:user_id,:asset_id,:trashed_p,:alert_p,:critical_alert_p,:confirm_p,:confirmed_p,:message_p,:message_sent_p,:name,:title,:nowts,:nowts,:log_entry)
                    }
                    ns_log Notice "hf_beat_log_create.112: posting to hf_beat_log: monitor_id '' user_id '${user_id}' name '${name}' log_entry '${log_entry}'"
                }
            } else {
                ns_log Warning "hf_beat_log_create.115: ignored an attempt to post a log message without connection or user_id for asset_id '${asset_id}'"
            }
        } else {
            ns_log Warning "hf_beat_log_create.118: ignored an attempt to post an empty log message."
        }
    } else {
        ns_log Warning "hf_beat_log_create.121: asset_id '$asset_id' is not a natural number reference. Log message '${log_entry}' ignored."
    }
    return $id
}

ad_proc -public hf_beat_log_read {
    max_old
    {user_id ""}
    {instance_id ""}
} {
    max_old is max count. It's named max_old, because it only returns logs that have already been viewed.
    If max_old is empty, returns all logs (no count limit).
    Returns empty list if no entry exists.
    Set all_p to 1 to return all logs for user_id including logs not previously viewed.
} {
    # hf_beat_log_read has been split into hf_beat_log_alert_q and hf_beat_log_read
    # due to the more complex implementation of beat log alerts of hf_beat_log_read than its predecessor hf_process_log_read.

    set nowts [dt_systime -gmt 1]
    if { ![qf_is_natural_number $instance_id] } {
        ns_log Notice "hf_beat_log_create.451: instance_id '${instance_id}' changing.."
        set instance_id [ad_conn package_id]
    }
    if { ![qf_is_natural_number $user_id] } {
        ns_log Notice "hf_beat_log_create.451: user_id was '${user_id}' changing.."
        if { [ns_conn isconnected] } {
            set user_id [ad_conn user_id]
        } else {
            set user_id [hf_user_id_from_asset_id $asset_id]
        }
    }
    set return_lol [list ]
    set last_viewed ""
    set extra_sql ""
    if { [qf_is_natural_number $max_old ] } {
        set extra_sql "limit :max_old"
    }
    # CREATE TABLE hf_beat_log_viewed (
    #      id integer not null,
    #      instance_id integer,
    #      user_id integer,
    #      last_viewed timestamptz
    # );
    
    set viewing_history_p [db_0or1row hf_beat_log_viewed_last { select last_viewed from hf_beat_log_viewed where instance_id = :instance_id and user_id = :user_id } ]
    # View history is not reset, because all these logs have already been viewed once.
    # These queries check view history against created time, since last_modified could have been revised to newer than last_viewed
    if { $viewing_history_p } {
        set last_viewed [string range $last_viewed 0 18]
            
        set entries_lol [db_list_of_lists hf_beat_log_read_old  
            "select id, name, title, log_entry, asset_id, monitor_id, critical_alert_p,confirm_p,confirmed_p, created from hf_beat_log 
            where instance_id = :instance_id and user_id =:user_id and trashed_p='0' and alert_p='1' and created < :last_viewed order by created desc ${extra_sql}" ]
        
        ns_log Notice "hf_beat_log_read.173: last_viewed ${last_viewed}  entries_lol $entries_lol"

    } else {

        # same query, but without created > :last_viewed
        set entries_lol [db_list_of_lists hf_beat_log_read_old0  
            "select id, name, title, log_entry, asset_id, monitor_id, critical_alert_p,confirm_p,confirmed_p, created from hf_beat_log 
            where instance_id = :instance_id and user_id =:user_id and trashed_p='0' and alert_p='1' order by created desc ${extra_sql}" ]
        
        ns_log Notice "hf_beat_log_read.181: entries_lol $entries_lol"
    }
    return $return_lol
}


ad_proc -public hf_beat_log_alert_q {
    {user_id ""}
    {instance_id ""}
} {
    Returns any new log entries as a list via util_user_message.
    Returns empty list if no entry exists.
} {
    # hf_beat_log_read has been split into hf_beat_log_alert_q and hf_beat_log_read
    # due to the more complex implementation of beat log alerts of hf_beat_log_read than its predecessor hf_process_log_read.

    set nowts [dt_systime -gmt 1]
    if { ![qf_is_natural_number $instance_id] } {
        ns_log Notice "hf_beat_log_create.451: instance_id '${instance_id}' changing.."
        set instance_id [ad_conn package_id]
    }
    if { ![qf_is_natural_number $user_id] } {
        ns_log Notice "hf_beat_log_create.451: user_id was '${user_id}' changing.."
        if { [ns_conn isconnected] } {
            set user_id [ad_conn user_id]
        } else {
            set user_id [hf_user_id_from_asset_id $asset_id]
        }
    }
    set return_lol [list ]
    set last_viewed ""
    
    # CREATE TABLE hf_beat_log_viewed (
    #      id integer not null,
    #      instance_id integer,
    #      user_id integer,
    #      last_viewed timestamptz
    # );
    
    set viewing_history_p [db_0or1row hf_beat_log_viewed_last { select last_viewed from hf_beat_log_viewed where instance_id = :instance_id and user_id = :user_id } ]
    # set new view history time
    if { $viewing_history_p } {

        set last_viewed [string range $last_viewed 0 18]
        if { $last_viewed ne "" } {
            
            set entries_lol [db_list_of_lists hf_beat_log_read_new { 
                select id, name, title, log_entry, asset_id, monitor_id, critical_alert_p,confirm_p,confirmed_p, last_modified from hf_beat_log 
                where instance_id = :instance_id and user_id =:user_id and trashed_p='0' and alert_p='1' and ( last_modified > :last_viewed or ( confirm_p='1' and confirmed_p='0' ) ) order by last_modified desc } ]
            
            ns_log Notice "hf_beat_log_read.267: last_viewed ${last_viewed}  entries_lol $entries_lol"
           
        } else {
            # same query, but without last_modified > :last_viewed or confirm_p and confirmed_p
            set entries_lol [db_list_of_lists hf_beat_log_read_new0 { 
                select id, name, title, log_entry, asset_id, monitor_id, critical_alert_p,confirm_p,confirmed_p, last_modified from hf_beat_log 
                where instance_id = :instance_id and user_id =:user_id and trashed_p='0' and alert_p='1' order by last_modified desc } ]
            
            ns_log Notice "hf_beat_log_read.275: last_viewed ${last_viewed}  entries_lol $entries_lol"

        }
        # prepare messages for display
        if { [llength $entries_lol ] > 0 } {
            
            foreach row $entries_lol {
                set message_txt "posted: [lc_time_system_to_conn [string range [lindex $row 4] 0 18]]:\n [lindex $row 3]"
                set last_modified [lindex $row 4]
                ns_log Notice "hf_beat_log_read.79: last_modified ${last_modified}"
                util_user_message -message $message_txt
                ns_log Notice "hf_beat_log_read.88: message '${message_txt}'"
            }
        } 
        
        # last_modified ne "", so update
        db_dml hf_beat_log_viewed_update { 
            update hf_beat_log_viewed set last_viewed = :nowts where instance_id = :instance_id and user_id = :user_id 
        }
    } else {
        # create history
        set id [db_nextval hf_beat_id_seq]
        db_dml hf_beat_log_viewed_create { insert into hf_beat_log_viewed
            ( id, instance_id, user_id, asset_id, last_viewed )
            values ( :id, :instance_id, :user_id, :asset_id, :nowts ) }
    }
    return $return_lol
}

ad_proc -private hf::monitor::check {

} {
    Returns current values from hf_beat_stack_bus table (active_id, debug_p, priority_threashold, cycle_time)  into the calling environment
} {
    upvar 1 active_id active_id 
    upvar 1 debug_p debug_p 
    upvar 1 priority_threashold priority_threashold
    upvar 1 cycle_time cycle_time
    set active_id ""
    if { ![db_0or1row hf_beat_stack_bus_ck "select active_id, debug_p,priority_threashold,cycle_time from hf_beat_stack_bus limit 1"] } {

        #CREATE TABLE hf_beat_stack_bus (
        #       -- instead of querying hf_beat_stack for active proc
        #       -- the value is stored and updated here for speed.
        #       active_id varchar(19),
        #       -- when checking for active_id, can also get a dynamic value for debug_p with low overhead
        #       debug_p varchar(1) 
        #)


        # set defaults
        set active_id ""
        # set debug_p to 1 for more log info
        set debug_p 1
        set priority_threashold 13

        set cycle_time [expr { int( 5 * 60 ) } ]
        # cycle_time varies with active monitors at time of start
        db_1row hf_active_assets_count { select count(monitor_id) as monitor_count from hf_monitor_config_n_control where active_p == '1' }
        if { $monitor_count > 0 } {
            set cycle_time [expr { int( $cycle_time / $monitor_count ) + 1 } ] 
        } 
        
        # create the row
        db_dml hf_beat_stack_bus_cr { insert into hf_beat_stack_bus (active_id,debug_p,priority_threashold,cycle_time) values (:active_id,:debug_p,:priority_threashold,:cycle_time) }
    }
    return 1
}

ad_proc -private hf::monitor::do {

} { 
    Process any scheduled monitoring procedures. Future monitors are suspended until this process reports batch complete.
} {

    
    # If no proc called by hf::monitor::do is active (check hf_beat_stack_active.id ),
    # call the next monitor proc in the stack (from hosting-farm-local-procs.tcl)
    # the called procedure calls hf_monitor_configs_read and gets asset parameters, then calls hf_call_read to determine appropriate call_name for monitor
    # then calls returned proc_name
    # proc_name grabs info from external server, normalizes and saves info via hf_monitor_update,
    # At less frequent intervals, hf::monitor::do (or theoretically hf::scheduled::do) can call hf_monitor_statistics
    # If monitor config data indicates to flag an alert, flag a notification.

    # First, check if a monitor process is running and get status of debug_p
    hf::monitor::check
    if { $active_id eq "" } {
        set success_p 0

        #       -- stack is prioritized by
        #       -- time must be > last time + interval_s + last_completed_time 
        #       -- priority
        #       -- relative priority: priority - (now - last_completed_time )/ interval_s - last_completed_time
        #       -- relative priority kicks in after threashold priority procs have been exhausted for the interval
        #       -- trigger_s is  ( last_started_clock_s + last_process_s - interval_s ) 
        set clock_sec [clock seconds]
        # consider separating this into two separate queries, so if first query with priority is empty, then query for dynamic_priority..
        set batch_lists [db_list_of_lists hf_beat_stack_read_adm_p0_s { select id,proc_name,asset_id,user_id,instance_id, priority, order_clock_s, last_started_clock_s,last_completed_clock_s,last_process_s,interval_s,(priority - (:clock_sec - last_completed_clock_s) /greatest('1',interval_s ) + last_process_s) as dynamic_priority , trigger_s from hf_beat_stack where trigger_s < :clock_sec, order by priority asc, dynamic_priority asc } ]

        #CREATE TABLE hf_beat_stack (
        #       id integer primary key,
        #       -- Assumes procedure is called repeatedly
        #       -- Since procedure is repeated, cannot
        #       -- use empty completed_time to infer active status
        #       -- instead, see hf_beat_stack_bus.active_id
        #
        #       -- stack is prioritized by
        #       -- time must be > last time + interval_s + last_process_time_s
        #       -- priority
        #       -- relative priority: priority - (now - last_completed_time )/ interval_s + last_process_s
        #       -- relative priority kicks in after threashold priority procs have been exhausted for the interval
        #       proc_name varchar(40),
        #       asset_id integer,
        #       proc_args text,
        #       proc_out text,
        #       user_id integer,
        #       instance_id integer,
        #       priority integer,
        #       -- when first requested in  machine clock seconds
        #       order_clock_s integer,
        #       -- last time proc was started in machine clock seconds
        #       last_started_clock_s integer,
        #       -- last time proc completed in machine clock seconds
        #       last_completed_clock_s integer,
        #       -- response_time in seconds; should be about same as last_completed_time - last_started_time
        #       last_process_s integer,
        #       -- requested interval between calls
        #       -- this value is extracted from hf_monitor_config_n_control
        #       interval_s integer,
        #       trigger_s integer,
        #       order_time timestamptz,
        #       last_started_time timestamptz,
        #       last_completed_time timestamptz,
        #       call_counter integer
        #);

        set batch_lists_len [llength $batch_lists]
        set dur_sum 0
        set first_started_time [lindex [lindex $batch_lists 0] 6]
        if { $debug_p } {
            ns_log Notice "hf::monitor::do.39: first_started_time '${first_started_time}' batch_lists_len ${batch_lists_len}"
        }
        if { $first_started_time eq "" } {
            if { $batch_lists_len > 0 } {
                set query_key_list [list id proc_name asset_id user_id instance_id priority order_clock_s last_started_clock_s last_completed_clock_s last_process_s interval_s dynamic_priority trigger_s]
                # instance_id can vary with each entry
                set bi 0
                # if loop nears cycle_time, quit and let next cycle reprioritize with any new jobs
                while { $bi < $batch_lists_len && $dur_sum < $cycle_time } {
                    set mon_list [lindex $batch_lists $bi]
                    # set proc_list lindex combo from sched_list
                    
                    set allowed_procs [parameter::get -parameter MonitorProcsAllowed -package_id $instance_id]
                    # added comma and period to "split" to screen external/private references and poorly formatted lists
                    set allowed_procs_list [split $allowed_procs " ,."]
                    set success_p [expr { [lsearch -exact $allowed_procs_list $proc_name] > -1 } ]
                    if { $success_p } {
                        if { $proc_name ne "" } {
                            ns_log Notice "hf::monitor::do.54 evaluating id $id"
                            # create asset properties array
                            set i 0
                            foreach key $query_key_list {
                                set asset_prop_arr(${key}) [lindex $mon_list $i]
                            }

                            set nowts [dt_systime -gmt 1]
                            set start_sec [clock seconds]
                            # tell the system I am working on it.
                            set success_p 1
                            db_dml hf_beat_stack_started {
                                update hf_beat_stack set started_time =:nowts, last_started_clock_s =:start_sec where id =:id
                            }
                            
                            #ns_log Notice "hf::monitor::do.69: id $id to Eval: '${proc_list}' list len [llength $proc_list]."
                            # This works in tcl env. should work here:
                            # get asset attributes
                            # getasset type
                            # Make this a proc.. useful for generalizing app ui
                            db_1row "select asset_type_id from hf_assets where asset_id = "

                            # switch $asset_type ...
                            # ss { hf_ss_read $id} ...
                            if {  [catch { set calc_value [eval $proc_name] } this_err_text] } {
                                ns_log Warning "hf::monitor::do.71: id $id Eval '${proc_list}' errored with ${this_err_text}."
                                # don't time an error. This provides a way to manually identify errors via sql sort
                                set nowts [dt_systime -gmt 1]
                                set success_p 0
                                db_dml hf_beat_stack_write {
                                    update hf_beat_stack set proc_out =:this_err_text, completed_time=:nowts where id = :id 
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
                                db_dml hf_beat_stack_write {
                                    update hf_beat_stack set proc_out =:calc_value, completed_time=:nowts, process_seconds=:dur_sec where id = :id 
                                }
                                ns_log Notice "hf::monitor::do.83: id $id completed in circa ${dur_sec} seconds."
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
                        ns_log Warning "hf::monitor::do.87: id $id proc_name '${proc_name}' attempted but not allowed. user_id ${user_id} instance_id ${instance_id}"
                    }
                    # next batch index
                    incr bi
                }
            } else {
                # if do is idle, delete some (limit 100 or so) used args in hf_sched_proc_args. Ids may have more than 1 arg..
                if { $debug_p } {
                    ns_log Notice "hf::monitor::do.91: Idle. Entering passive maintenance mode. deleting up to 60 used args, if any."
                }
                set success_p 1
                db_dml hf_sched_proc_args_delete { delete from hf_sched_proc_args 
                    where stack_id in ( select id from hf_beat_stack where process_seconds is not null order by id limit 60 ) 
                }
            }
        } else {
            ns_log Notice "hf::monitor::do.97: Previous hf::monitor::do still processing. Stopping."
            # the previous hf::monitor::do is still working. Don't clobber. Quit.
            set success_p 1
        }
        if { $debug_p || !$success_p } {
            ns_log Notice "hf::monitor::do.99: returning success_p ${success_p}"
        }
    } else {
        # a previous monitor process is still in progress
        ns_log Notice "hf::monitor::do.242: previous monitor active_id '${active_id}' processing. Cancelled new batch processing."
    }
    return $success_p
}

ad_proc -private hf::monitor::add {
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
                db_dml hf_beat_stack_create { insert into hf_beat_stack 
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
                ns_log Warning "hf::monitor::add.90 failed for id '$id' ii '$ii' user_id ${user_id} instance_id ${instance_id} proc_args_list '${proc_args_list}'"
                ns_log Warning "hf::monitor::add.91 failed proc_name '${proc_name}' with message: ${errmsg}"
            }        
        }
    } else {
        ns_log Warning "hf::monitor::add.127 failed user_id ${user_id} session_package_id ${session_package_id} instance_id not valid: ${instance_id}"
        set success_p 0
    }
    return $success_p
}

ad_proc -private hf::monitor::trash {
    sched_id
    user_id
    instance_id
} {
    Removes an incomplete process from the process stack by noting it as completed.
} {
    # There is no delete for hf::monitor

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
        set success_p [db_dml hf_beat_stack_trash { update hf_beat_stack
            set proc_out=:proc_out, started_time=:nowts, completed_time=:nowts where sched_id=:sched_id and user_id=:user_id and instance_id=:instance_id and proc_out is null and started_time is null and completed_time is null } ]
    }
    return $success_p
}

ad_proc -private hf::monitor::read {
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
        set process_stats_list [db_list_of_lists hf_beat_stack_read { select id,proc_name,proc_args,proc_out,user_id,instance_id, priority, order_time, started_time, completed_time, process_seconds from hf_beat_stack where id =:sched_id and user_id=:user_id and instance_id=:instance_id } ]
    }
    return $process_stats_list
}

ad_proc -private hf::monitor::list {
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
                set process_stats_list [db_list_of_lists hf_beat_stack_read_adm_p1 " select id,proc_name,proc_args,user_id,instance_id, priority, order_time, started_time, completed_time, process_seconds from hf_beat_stack order where instance_id=:instance_id by $sort_by $sort_type limit $n_items offset :m_offset " ]
            } else {
                set process_stats_list [db_list_of_lists hf_beat_stack_read_adm_p0 " select id,proc_name,proc_args,user_id,instance_id, priority, order_time, started_time, completed_time, process_seconds from hf_beat_stack where completed_time is null order by $sort_by $sort_type limit $n_items offset :m_offset " ]
            }
        } else {
            if { $processed_p } {
                set process_stats_list [db_list_of_lists hf_beat_stack_read_user_p1 " select id,proc_name,proc_args,user_id,instance_id, priority, order_time, started_time, completed_time, process_seconds from hf_beat_stack where user_id=:user_id and ( instance_id=:instance_id or instance_id=:user_id) order by $sort_by $sort_type limit $n_items offset :m_offset " ]
            } else {
                set process_stats_list [db_list_of_lists hf_beat_stack_read_user_p0 " select id,proc_name,proc_args,user_id,instance_id, priority, order_time, started_time, completed_time, process_seconds from hf_beat_stack where completed_time is null and user_id=:user_id and ( instance_id=:instance_id or instance_id=:user_id) order by $sort_by $sort_type limit $n_items offset :m_offset " ]
            }
        }
    }
    return $process_stats_list
}


