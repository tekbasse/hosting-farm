# hosting-farm/tcl/hosting-farm-monitor-procs.tcl
ad_library {

    library for monitoring of Hosting Farm assets
    Monitoring uses a separate scheduling paradigm than hosting-farm-scheduled.tcl library
    to avoid instabilities and conflicts from other processes
    @creation-date 2015-09-12
    @Copyright (c) 2015 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl-2.0.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com

}

namespace eval ::hf::monitor {}
namespace eval ::hf::monitor::do {}

# once every few seconds, hf::monitor::do is called. ( see tcl/hosting-farm-scheduled-init.tcl )

# DEVELOPER NOTE. Year 2036 may have subtle bug.
# Instead of using tcl scan to convert times for detla t values,
# hf_monitor_log.report_id uses machine time seconds.
# The db type uses bigint or varchar(19) --not bigserial as report_id is not a sequence.
# We can sanity check for machine time since the 
# list has already been sorted by time.
# And then subtract report_ids for faster, approximate delta t.
# Thereby, issues and delays of using 'clock scan' are avoided.


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
                set instance_id [qc_set_instance_id]
            }
            if { ![qf_is_natural_number $user_id] } {
                ns_log Notice "hf_beat_log_create.451: user_id was '${user_id}' changing.."
                if { [ns_conn isconnected] } {
                    set user_id [ad_conn user_id]
                } else {
                    set user_id [hf_user_id_of_asset_id $asset_id]
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
    If max_old is empty, returns all unseen logs for user. (no count limit).
    Returns empty list if no entry exists.
} {
    # hf_beat_log_read has been split into hf_beat_log_alert_q and hf_beat_log_read
    # due to the more complex implementation of beat log alerts of hf_beat_log_read than its predecessor hf_process_log_read.

    set nowts [dt_systime -gmt 1]
    if { ![qf_is_natural_number $instance_id] } {
        ns_log Notice "hf_beat_log_create.451: instance_id '${instance_id}' changing.."
        set instance_id [qc_set_instance_id]
    }
    if { ![qf_is_natural_number $user_id] } {
        ns_log Notice "hf_beat_log_create.451: user_id was '${user_id}' changing.."
        if { [ns_conn isconnected] } {
            set user_id [ad_conn user_id]
        } else {
            set user_id [hf_user_id_of_asset_id $asset_id]
        }
    }
    set return_lol [list ]

    # CREATE TABLE hf_beat_log_viewed (
    #      id integer not null,
    #      instance_id integer,
    #      user_id integer,
    #      last_viewed timestamptz
    # );

    set last_viewed [hf_beat_log_viewed_last $user_id $instance_id]

    # View history is not reset, because all these logs have already been viewed once.
    # These queries check view history against created time, since last_modified could have been revised to newer than last_viewed
    if { $last_viewed ne "" } {
        set last_viewed [string range $last_viewed 0 18]
            
        set entries_lol [db_list_of_lists hf_beat_log_read_old  
            "select id, name, title, log_entry, asset_id, monitor_id, critical_alert_p,confirm_p,confirmed_p, created from hf_beat_log 
            where instance_id = :instance_id and user_id =:user_id and trashed_p!='1' and alert_p='1' and created < :last_viewed order by created desc limit :max_old" ]
        
        ns_log Notice "hf_beat_log_read.173: last_viewed ${last_viewed}  entries_lol $entries_lol"

    } else {
        # no unseen history to show
    }
    return $return_lol
}

ad_proc -private hf_beat_log_viewed_last {
    user_id
    instance_id
} {
    set viewing_history_p [db_0or1row hf_beat_log_viewed_last_q { select last_viewed from hf_beat_log_viewed where instance_id = :instance_id and user_id = :user_id } ]
    if { $viewing_history_p } {
        set last_viewed [string range $last_viewed 0 18]
    } else {
        set last_viewed ""
    }
    return $last_viewed
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
        set instance_id [qc_set_instance_id]
    }
    if { ![qf_is_natural_number $user_id] } {
        ns_log Notice "hf_beat_log_create.451: user_id was '${user_id}' changing.."
        if { [ns_conn isconnected] } {
            set user_id [ad_conn user_id]
        } else {
            set user_id [hf_user_id_of_asset_id $asset_id]
        }
    }
    set return_lol [list ]

    # CREATE TABLE hf_beat_log_viewed (
    #      id integer not null,
    #      instance_id integer,
    #      user_id integer,
    #      last_viewed timestamptz
    # );

    set last_viewed [hf_beat_log_viewed_last $user_id $instance_id]

    
    # set new view history time
    if { $last_viewed ne "" } {
        
        set entries_lol [db_list_of_lists hf_beat_log_read_new { 
            select id, name, title, log_entry, asset_id, monitor_id, critical_alert_p,confirm_p,confirmed_p, last_modified from hf_beat_log 
            where instance_id = :instance_id and user_id =:user_id and trashed_p!='1' and alert_p='1' and ( last_modified > :last_viewed or ( confirm_p='1' and confirmed_p='0' ) ) order by last_modified desc } ]
        
        ns_log Notice "hf_beat_log_read.267: last_viewed ${last_viewed}  entries_lol $entries_lol"
        
    } else {
        # same query, but without last_modified > :last_viewed or confirm_p and confirmed_p
        set entries_lol [db_list_of_lists hf_beat_log_read_new0 { 
            select id, name, title, log_entry, asset_id, monitor_id, critical_alert_p,confirm_p,confirmed_p, last_modified from hf_beat_log 
            where instance_id = :instance_id and user_id =:user_id and trashed_p!='1' and alert_p='1' order by last_modified desc } ]
        
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
    if { $last_viewed ne "" } {
        # last_modified ne "", so update
        db_dml hf_beat_log_viewed_update { 
            update hf_beat_log_viewed "set last_viewed=:nowts where instance_id=:instance_id and user_id=:user_id"
        }
    } else {
        # first case, insert
        db_dml hf_beat_log_viewed_insert {
            insert into hf_beat_log_viewed (last_viewed,instance_id,user_id)
            values (:nowts,:instance_id,:user_id)
        }
    }
    return $return_lol
}

ad_proc -private hf::monitor::check {

} {
    Returns current values from hf_beat_stack_bus table (active_id, debug_p, priority_threshold, cycle_time)  into the calling environment
} {
    upvar 1 active_id active_id 
    upvar 1 debug_p debug_p 
    upvar 1 priority_threshold priority_threshold
    upvar 1 cycle_time cycle_time
   
    set active_id ""
    if { ![db_0or1row hf_beat_stack_bus_ck "select active_id, debug_p,priority_threshold,cycle_time from hf_beat_stack_bus limit 1"] } {

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
        set debug_p 0
        set priority_threshold 13

        #set cycle_time [expr { int( 5 * 60 ) } ]
        set cycle_time [expr { int( 60 ) } ]
        # cycle_time varies with active monitors at time of start
        db_1row hf_active_assets_count { select count(monitor_id) as monitor_count from hf_monitor_config_n_control where active_p='1' }
        if { $monitor_count > 0 } {
            set cycle_time [expr { int( $cycle_time / $monitor_count ) + 1 } ] 
        } 
        
        # create the row
        db_dml hf_beat_stack_bus_cr { insert into hf_beat_stack_bus (active_id,debug_p,priority_threshold,cycle_time) values (:active_id,:debug_p,:priority_threshold,:cycle_time) }
    }
    return 1
}

ad_proc -private ::hf::monitor::do {

} { 
    Process any scheduled monitoring procedures. Future monitors are suspended until this process reports batch complete.
} {
    hf_nc_proc_context_set
    
    # If no proc called by hf::monitor::do is active (check hf_beat_stack_active.id ),
    # call the next monitor proc in the stack (from hosting-farm-local-procs.tcl)
    # the called procedure calls hf_monitor_configs_read and gets asset parameters, then calls hf_call_read to determine appropriate call_name for monitor
    # then calls returned proc_name
    # proc_name grabs info from external server, normalizes and saves info via hf_monitor_update,
    # At less frequent intervals, hf::monitor::do (or theoretically hf::scheduled::do) can call hf_monitor_statistics
    # If monitor config data indicates to flag an alert, flag a notification.

    # First, check if a monitor process is running and get status of debug_p
    set debug_p 0
    hf::monitor::check

    # hf_nc_proc_that_tests_context_checking

    if { $active_id eq "" } {
        set success_p 0

        #       -- stack is prioritized by
        #       -- time must be > last time + interval_s + last_completed_time 
        #       -- priority
        #       -- relative priority: priority - (now - last_completed_time )/ interval_s - last_completed_time
        #       -- relative priority kicks in after threshold priority procs have been exhausted for the interval
        #       -- trigger_s is  ( last_started_clock_s + last_process_s - interval_s ) 
        set clock_sec [clock seconds]
        # consider separating this into two separate queries, so if first query with priority is empty, then query for dynamic_priority..
        set batch_lists [db_list_of_lists hf_beat_stack_read_adm_p0_s { select id,proc_name,asset_id,user_id,instance_id, priority, order_clock_s, last_started_clock_s,last_completed_clock_s,last_process_s,interval_s,(priority - (:clock_sec - last_completed_clock_s) /greatest('1',interval_s ) + last_process_s) as dynamic_priority , trigger_s from hf_beat_stack where trigger_s < :clock_sec order by priority asc, dynamic_priority asc } ]

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
        #       -- relative priority kicks in after threshold priority procs have been exhausted for the interval
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
                    ns_log Notice "hf::monitor::do.409: begin while.."
                    set mon_list [lindex $batch_lists $bi]
                    # set proc_list lindex combo from sched_list
                    
                    #set allowed_procs \[parameter::get -parameter MonitorProcsAllowed -package_id $instance_id\]
                    set allowed_procs [qc_parameter_get MonitorProcsAllowed $instance_id]
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
                                update hf_beat_stack set started_time=:nowts, last_started_clock_s=:start_sec where id=:id
                            }
                            
                            #ns_log Notice "hf::monitor::do.69: id $id to Eval: '${proc_list}' list len [llength $proc_list]."

                            # Load properties into an array "buffer" before calling custom proc.
                            hf_asset_properties $asset_id asset_prop_arr $instance_id $user_id

                            if {  [catch { set calc_value [eval $proc_name] } this_err_text] } {
                                ns_log Warning "hf::monitor::do.71: id $id Eval '${proc_list}' errored with ${this_err_text}."
                                # don't time an error. This provides a way to manually identify errors via sql sort
                                set nowts [dt_systime -gmt 1]
                                set success_p 0
                                db_dml hf_beat_stack_write {
                                    update hf_beat_stack set proc_out=:this_err_text, completed_time=:nowts where id=:id 
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
                                    update hf_beat_stack set proc_out=:calc_value, completed_time=:nowts, process_seconds=:dur_sec where id=:id 
                                }
                                ns_log Notice "hf::monitor::do.83: id $id completed in circa ${dur_sec} seconds."
                            }
                            # Alert user that job is done?  
                            # util_user_message doesn't accept user_id instance_id, only session_id
                            # We don't have session_id available.. and it may have changed or not exist..
                            # Email?  that would create too many alerts for lots of quick jobs.
                            # auth::sync::job::* api does this.
                            # hf::schedule::api is available for user conveniences like active alerts..


                            # Empty asset properties buffer
                            array unset asset_prop_arr
                        }
                    } else {
                        ns_log Warning "hf::monitor::do.87: id $id proc_name '${proc_name}' attempted but not allowed. user_id ${user_id} instance_id ${instance_id}"
                    }
                    # next batch index
                    incr bi
                }
            } else {
                # if do is idle. Here's an opportunity to do some background maintenance.
                # Nothing for now.
                if { $debug_p } {
                    ns_log Notice "hf::monitor::do.91: Idle. Entering passive maintenance mode."
                }
                set success_p 1
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
    set session_package_id [qc_set_instance_id]
    # We assume user has permission.. but qualify by verifying that instance_id is either user_id or package_id
    if { $instance_id eq $user_id || $instance_id eq $session_package_id } {
        #set allowed_procs \[parameter::get -parameter ScheduledProcsAllowed -package_id $session_package_id\]
        set allowed_procs [qc_parameter_get ScheduledProcsAllowed $session_package_id]
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
    set session_package_id [qc_set_instance_id]
    set success_p 0
    #set create_p [permission::permission_p -party_id $session_user_id -object_id $session_package_id -privilege create]
    #set write_p [permission::permission_p -party_id $session_user_id -object_id $session_package_id -privilege write]
    # keep permissions simple for now
    set admin_p [permission::permission_p -party_id $session_user_id -object_id [ad_conn package_id] -privilege admin]
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
    set session_package_id [qc_set_instance_id]
    set admin_p [permission::permission_p -party_id $session_user_id -object_id [ad_conn package_id] -privilege admin]
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
        set session_package_id [qc_set_instance_id]
        set admin_p [permission::permission_p -party_id $session_user_id -object_id [ad_conn package_id] -privilege admin]
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


ad_proc -private hf_ui_go_ahead_q {
    privilege
    {asset_id_varnam "asset_id"}
    {property "assets"}
    {break_p "1"}
} {
    Confirms process is not run via connection, or 
    is run by connected user with privilege and in scope of customer_id_list. 
    Defines customer_id_list if asset_id and customer_id_list are undefined.
} {
    if { $asset_id_varnam eq "" } {
        set asset_id_varnam "asset_id"
    }
    upvar 1 $asset_id_varnam asset_id
    upvar 1 instance_id proc_instance_id
    upvar 1 user_id proc_user_id
    upvar 1 customer_id proc_customer_id
    upvar 1 customer_id_list proc_customer_id_list
    if { [ns_conn isconnected] } {
        set asset_type_id ""
        set user_id [ad_conn user_id]
        set instance_id [qc_set_instance_id]
        #set go_ahead \[permission::permission_p -party_id $user_id -object_id \[ad_conn package_id\] -privilege admin\]
        if { ![info exists asset_id] } {
            set asset_id ""
        }
        if { $privilege eq "create" && $asset_id eq "" } {
            # No existing asset_id to check.
            # Vet an existing customer_id, or set it if there is only 1.
            set customer_id_list [hf_customer_ids_for_user $user_id $instance_id]
            if { ![info exists proc_customer_id_list] } {
                set proc_customer_id_list $customer_id_list
            }
            set cid_list_len [llength $customer_id_list]
            if { ![info exists proc_customer_id] } {
                set proc_customer_id ""
            }
            if { $proc_customer_id eq "" && $cid_list_len == 1 } {
                set proc_customer_id [lindex $customer_id_list 0]
            }
            set cid_idx [lsearch -exact $customer_id_list $proc_customer_id]
            if { $cid_idx > -1 } {
                set customer_id [lindex $customer_id_list $cid_idx]
                ns_log Warning "hf_ui_go_ahead_q.618: customer_id was empty but required. Since there is only 1 for user_id '${user_id}'. Set it."
                set proc_customer_id $customer_id
            } else {
                set customer_id ""
                set admin_p [permission::permission_p -party_id $user_id -object_id [ad_conn package_id] -privilege admin]
                if { $admin_p } {
                    # A sys admin doesn't need a customer_id
                    set go_ahead 1
                } else {
                    ns_log Warning "hf_ui_go_ahead_q.650: Could not identify a unique customer_id for user_id '${user_id}'"
                    set go_ahead 0
                }
            }
        } else {
            set customer_id [hf_customer_id_of_asset_id $asset_id ]
            if { $customer_id ne "" && [exists_and_not_null proc_customer_id_list]} {
                set c_idx [lsearch -exact $proc_customer_id_list $customer_id]
                if { $c_idx < 0 } {
                    set go_ahead 0
                    ns_log Warning "hf_ui_go_ahead_q.698: customer_id '${customer_id}' not in customer_id_list '${customer_id_list}'"
                }
            } else {
                # Make sure asset_id is consistent to asset_type_id
                set asset_type_id [hf_nc_asset_type_id $asset_id]
                if { $property eq "" || $property eq "assets" } {
                    set property $asset_type_id
                }
            }
        }
        if { ![exists_and_not_null go_ahead] } {
            set go_ahead [qc_permission_p $user_id $customer_id $property $privilege $instance_id]
        }
        if { !$go_ahead } {
            ns_log Warning "hf_ui_go_head_q.700: failed. Called by user_id '${user_id}' args: asset_id_varnam '${asset_id_varnam}' instance_id '${instance_id}' asset_id '${asset_id}' asset_type_id '${asset_type_id}' property '${property}'"
        } else {
            if { ![exists_and_not_null proc_user_id] } {
                set proc_user_id $user_id
            }
            if { ![exists_and_not_null proc_instance_id] } {
                set proc_instance_id $instance_id
            }
        }
    } else {
        # no connection
        if { ![info exists user_id] } {
            set user_id ""
        }
        if { ![info exists instance_id] } {
            set instance_id ""
        }
        set msg_extra ""
        set q1 1
        if { [exists_and_not_null proc_instance_id] } {
            set q1 [qf_is_natural_number $proc_instance_id]
            if { !$q1 } {
                append msg_extra " instance_id '${proc_instance_id}'"
            }
        } 
        set q2 1
        if { [exists_and_not_null proc_user_id] } {
            set q2 [qf_is_natural_number $proc_user_id]
            if { !$q2 } {
                append msg_extra " user_id '${proc_user_id}"
            }
        } 
        set q3 1
        ns_log Notice "hf_nc_go_ahead: ns_thread name [ns_thread name] ns_thread id [ns_thread id] ns_info threads [ns_info threads] ns_info scheduled [ns_info scheduled]"
        #if { ![string match {hf_*} $argv0 ] && ![string match {hfl_*} $argv0 ] } {
        #    set q3 0
        #} 
        if { $q1 == 0 || $q2 == 0 || $q3 == 0 } {
            set go_ahead 0
            if { ![info exists $asset_id_varnam] } {
                set asset_id "does *not* exist"
            }
            ns_log Warning "hf_ui_go_head_q.734: failed. args: privilege '${privilege}' asset_id_varnam '${asset_id_varnam}' asset_id '${asset_id}' property '${property}' ${msg_extra}"
        } else {
            set go_ahead 1
        }
    }
    if { $go_ahead ne 1 && $go_ahead ne 0 } {
        ns_log Warning "hf_ui_go_ahead_q.771: Returned non logical 0/1 go_ahead '${go_ahead}' given privilege '${privilege}' asset_id_varnam '${asset_id_varnam}' property '${property}' break_p '${break_p}'"
    }
    if { !$go_ahead && $break_p } {
        ad_script_abort
    }
    return $go_ahead
}


ad_proc -private hf_monitor_configs_keys {
} {
    Returns an ordered list of keys that is parallel to the ordered list returned by hf_monitor_configs_read: instance_id monitor_id asset_id label active_p portions_count calculation_switches health_percentile_trigger health_threshold interval_s alert_by_privilege alert_by_role
} {
    set keys_list [list instance_id monitor_id asset_id label active_p portions_count calculation_switches health_percentile_trigger health_threshold interval_s alert_by_privilege alert_by_role]
    return $keys_list
}

ad_proc -private hf_asset_id_of_monitor_id {
    monitor_id
    {instance_id ""}
} {
    Returns asset_id or empty string if monitor_id doesn't exist.
} {
    set asset_id ""
    set success_p [db_0or1row hf_asset_id_of_mon_id "select asset_id from hf_monitor_config_n_control where instance_id=:instance_id and monitor_id=:monitor_id"]
    return $asset_id
}

ad_proc -private hf_monitor_configs_read {
    {id}
    {instance_id ""}
} {
    Read the configuration parameters of one  hf monitored service or system. 
    id is either a monitor_id or asset_id.
    returns an ordered list: instance_id, monitor_id, asset_id, label, active_p, portions_count, calculation_switches, health_percentile_trigger, health_threshold, interval_s, alert_by_privilege, alert_by_role. Returns empty list if not found.
} {
    set return_list [list ]
    # validate system
    if { [qf_is_natural_number $id] } {

        
        # check permissions
        set asset_id [hf_asset_id_of_monitor_id $monitor_id $instance_id]
        set admin_p [hf_ui_go_ahead_q admin]
        
        #CREATE TABLE hf_monitor_config_n_control (
        #    instance_id               integer,
        #    monitor_id                integer unique not null DEFAULT nextval ( 'hf_id_seq' ),
        #    asset_id                  integer not null,
        #    label                     varchar(200) not null,
        #    active_p                  varchar(1) not null,
        #    -- (MAX) number of portions to use in frequency distribution curve
        #    portions_count            integer not null,
        #    -- allow some control over how the distribution curves are represented:
        #    calculation_switches      varchar(20),
        #    -- Following 2 are used to suggest hf_monitor_status.expected_health:
        #    -- the percentile rank that triggers an alarm
        #    -- 0% rarely triggers, 100% triggers on most everything.
        #    health_percentile_trigger numeric,
        #    -- the health_value matching health_percentile_trigger
        #    health_threshold          integer
        #    -- any monitor value equal or greather than health_percentile_trigger or health_thread
        #    -- triggers an alert.
        #    priority varchar(19) default '' not null,
        #    -- interval in seconds
        #    interval_s varchar(19) default '' not null,
        #    -- If privilege specified, all users with permission of type privilege get notified.
        #    alert_by_privilege     varchar(12),
        #    -- If not null, alerts are sent to specified user(s) of specified role
        #    alert_by_role varchar(300)
        #);

        if { $admin_p && [qf_is_natural_number $instance_id ] } {
            set return_list [db_list_of_lists hf_mon_con_n_ctrl_get1 "select label, active_p, portions_count, calculation_switches, health_percentile_trigger, health_threshold, interval_s, alert_by_privilege, alert_by_role from hf_monitor_config_n_control where instance_id=:instance_id and (monitor_id=:id or asset_id=:id) limit 1"]
            set return_list [lindex $return_list 0]
        }
    }    
    return $return_list
}

ad_proc -private hf_monitor_configs_write {
    label
    active_p
    portions_count
    calculation_switches
    health_percentile_trigger
    health_threshold
    interval_s
    {asset_id ""}
    {monitor_id ""}
    {instance_id ""}
    {alert_by_privilege ""}
    {alert_by_role ""}
} {
    Writes (updates or creates) configuration parameters of one hf monitored service or system. Returns monitor_id or 0 if unsuccesssful.
    If monitor_id is blank, will assign a new monitor_id.
} {
    set return_id 0

    # validate system
    set asset_id_p [qf_is_natural_number $asset_id] 
    set monitor_id_p [qf_is_natural_number $monitor_id]
    set asset_id [hf_asset_id_of_monitor_id $monitor_id $instance_id]
    set admin_p [hf_ui_go_ahead_q admin]

    if { $asset_id_p || $monitor_id_p } {
        if { [string length $label ] < 201 && [string length $calculation_switches] < 21 } {
            set label_p 1
            set cs_p 1
            set active_p_p 0
            if { $active_p eq "1" || $active_p eq "0" } {
                set active_p_p 1
            } 
            set instance_id_p [qf_is_natural_number $instance_id] 
            set interval_s_p [qf_is_natural_number $interval_id] 
            set health_threshold_p [qf_is_natural_number $health_threshold] 
            set hpt_p [qf_is_decimal $health_percentile_trigger]
            
            # check permissions
            set admin_p 0
            if { !$nc_p } {
                set admin_p [qc_permission_p $user_id "" assets admin $instance_id]
            } 
            if { ( $admin_p || $nc_p ) && $label_p && $cs_p && $active_p_p && $instance_id_p && $interval_s_p && $health_threshold_p && $hpt_p } {

                # confirm/get index parameters

                if { $monitor_id_p && $asset_id_p } {
                    # if monitor_id_p, does it exist in context of asset_id?
                    set mon_id_exists_p [db_0or1row hf_monitor_id_ck "select monitor_id from hf_monitor_config_n_control where instance_id=:instance_id and asset_id=:asset_id and monitor_id=:monitor_id" ] 
                } elseif { $monitor_id_p } {
                    # While checking monitor_id, define asset_id if monitor_id exists
                    set mon_id_exists_p [db_0or1row hf_mon_id_ck_w_aid "select asset_id from hf_monitor_config_n_control where instance_id=:instance_id and asset_id=:asset_id and monitor_id=:monitor_id" ] 
                } else {
                    # monitor_id doesn't exist, but asset_id is supposed to exist per validation check.
                    # If hf_monitor_config_n_control.asset_id exists, create a new monitor_id, otherwise assign monitor_id same as asset_id
                    db_1row hf_asset_ck "select count(*) as asset_id_count from hf_monitor_config_n_control where instance_id=:instance_id and asset_id=:asset_id"
                    if { $asset_id_count > 0 } {
                        # Create new  monitor_id
                        set monitor_id [db_nextval hf_id_seq]
                    } else {
                        set monitor_id $asset_id
                    }
                }
                # write db record
                if { $mon_id_exists_p || $asset_id_count > 0 } {
                    # update record
                    db_dml { 
                        update hf_monitor_config_n_control set label=:label,active_p=:active_p,portions_count=:portions_count,calculation_switches=:calculation_switches,health_percentile_trigger=:health_percentile_trigger,health_threshold=:health_threshold,interval_s=:interval_s,alert_by_privilege=alert_by_privilage,alert_by_role=:alert_by_role where instance_id=:instance_id and monitor_id=:monitor_id and asset_id=:asset_id
                    }
                } else  {
                    # create new record
                    db_dml { 
                        insert into hf_monitor_config_n_control 
                        (label, active_p, portions_count, calculation_switches, health_percentile_trigger, health_threshold, interval_s, instance_id, monitor_id, asset_id, alert_by_privilege, alert_by_role )
                        values (:label,:active_p,:portions_count,:calculation_switches,:health_percentile_trigger,:health_threshold,:interval_s,:instance_id,:monitor_id,:asset_id,:alert_by_privilege,:alert_by_role)
                    }
                }
                set return_id $monitor_id
            } else {
                ns_log Warning "hf_monitor_configs_write(3383): could not write. admin_p '${admin_p}' nc_p '${nc_p}' asset_id '${asset_id}' monitor_id '${monitor_id}' label '${label}' active_p '${active_p}'"
                ns_log Warning "hf_monitor_configs_write(3384): .. portions '${portions_count}' calc sws '${calculation_switches}' health% trigger '${health_percentile_trigger}' health threash. '${health_threshold}' interval_s '${interval_s}'"
            }
        }
    }
    return $return_id
}


ad_proc -private hf_monitor_logs {
    {asset_ids ""}
    {instance_id ""}
} {
    Returns a list of hf_monitor_config_n_control.monitor_ids associated with asset_id(s). List is empty if there are none.
} {
    # validate
    set asset_id_list [list ]
    foreach asset_id_q $asset_ids {
        if { [hf_ui_go_ahead_q read asset_id_q "" 0] } {
            lappend asset_id_list $asset_id_q
        }
    }
    set monitor_id_list [db_list hf_monitor_ids_get "select monitor_id from hf_monitor_config_n_control where instance_id =:instance_id and asset_id in ([template::util::tcl_to_sql_list $asset_id_list])"]
    return $monitor_id_list
}


ad_proc -private hf_monitor_update {
    asset_id
    monitor_id
    reported_by
    health
    report
    significant_change_p
    {report_id ""}
    {instance_id ""}
} {
    Write an update to a monitor log, ie create a new entry. monitor_id is asset_id or hf_monitor_config_n_control.monitor_id
    Some other proc collects info from server and interprets health status,
    Said proc is probably defined in hosting-farm-local-procs.tcl
    Text of args should include calling proc name and version number for adapting to parameter and returned value revisions
    If report_id is supplied, it will be incremented by 1.
    Monitor data sets use signficant_change_p set to 1 as boundary, indicating significant change to monitored configuration 
    implies the possibility of a change in monitoring performance curve.
    Returns report_id
} {
    # validate
    hf_ui_go_ahead_q write
    if { [ns_conn isconnected] && $reported_by eq "" } {
        # feed some connection info
        set addrs [ad_conn peeraddrs]
        set reported_by "user_id '${user_id}' instance_id '${instance_id}' peeraddrs '${addrs}'"
    }
    if { ![qf_is_natural_number $report_id ] } {
        set report_id [clock seconds]
    } else {
        set report_id [expr { $report_id + 1 } ]
    }
    set reported_by [string range $reported_by 0 119]
    if { ![qf_is_natural_number $health] } {
        # log error
        ns_log Warning "hf_monitor_update(3449): health value unexpected '${health}'. Set to 0 for asset_id '${asset_id}' monitor_id '${monitor_id}'"
        if { !$nc_p } {
            ns_log Warning "hf_monitor_update(3450): ..  user_id '${user_id}' instance_id '${instance_id}'"
        }
        set health 0
    }  
    if { $significant_change_p ne "1" } {
        set significant_change_p "0"
    }
    #CREATE TABLE hf_monitor_log (
    #    instance_id          integer,
    #    monitor_id           integer not null,
    #    -- if monitor_id is 0 such as when adding activity note, user_id should not be 0
    #    user_id              integer not null,
    #    asset_id             integer not null,
    #    -- increases by 1 for each monitor_id's report of asset_id
    #    report_id            integer not null,
    #    -- reported_by provides means to identify/verify reporting source
    #    reported_by          varchar(120),
    #    report_time          timestamptz,
    #    -- 0 dead, down, not normal
    #    -- 10000 nominal, allows for variable performance issues
    #    -- health = numeric summary index ie indicator determined by hf_procs
    #    health               integer,
    #    -- latest report from monitoring
    #    report text,
    #    -- sysadmins can log significant changes to asset, such as sw updates
    #    -- with health is null and/or:
    #    significant_change   varchar(1)
    #    -- Changes mark boundaries for data samples
    #);

    # log it no matter what to not lose info
    db_dml hf_monitor_log_add { insert into hf_monitor_log 
        (instance_id,monitor_id,user_id,asset_id,report_id,reported_by,report_time,health,report,significant_change)
        values (:instance_id,:monitor_id,:user_id,:asset_id,:report_id,:reported_by,now(),:health,:report,:significant_change_p)
    }
    
    return $report_id
}

ad_proc -private hf_monitor_status {
    {monitor_id_list ""}
    {instance_id ""}
    {most_recent_ct ""}
} {
    Analyzes data from unprocessed hf_monitor_update, posts to hf_monitor_status, hf_monitor_freq_dist_curves, and hf_monitor_statistics
    Standardizes analysis (ie change of health ) of standardized info health reported from hf_monitor_update.
    Data is in list of lists format, where each list represents a monitor_id and contains this ordered info:
    monitor_id, asset_id, report_id, health_p0, health_p1, expected_health, health_percentile, expected_percentile
    Where report_id is id of most recent hf_monitor_update.
    health_p0 is the health value previous to current health.
    health_p1 is the most recent (current) health value.
    expected_health is the projected health value (either at next report, or at quota point if monitor has a quota.)
} {
    # in oscilloscope terms, if hf_monitor_update is "signal in", then hf_monitor_status is the data that gets posted to screen output.
    
    # expected_health is expected to have been calculated by a proc in hosting-farm-local-procs.tcl, just prior to
    # issuing an hf_monitor_update.

    # hf_monitor_statistics is called for final analysis and to determine health (percentile) 
    hf_ui_go_ahead_q admin

    # validation
    set monitor_id_list [hf_monitor_logs $monitor_ids]
    if { [qf_is_natural_number $most_recent_ct] } {
        set limit_sql "limit :most_recent_ct"
    }

    set status_lists [db_list_of_lists hf_monitor_status_current "select monitor_id, asset_id,analysis_id_p0, analysis_id_p1, health_p0, health_p1,expected_health,health_percentile,expected_percentile from hf_monitor_status where instance_id=:instance_id and monitor_id in ([template::util::tcl_to_sql_list $monitor_id_list]) order by analysis_id_p1 desc ${limit_sql}"]
    return $status_lists
}

ad_proc -public hf_monitor_distribution {
    asset_id
    monitor_id
    {instance_id ""}
    {sample_ct "1"}
    {duration_s ""}
    {points_ct ""}
    {sample_pt_rate "1"}
    {sample_s_rate ""}
} {
    Returns an unsorted distribution curve of a monitor_id as a list of lists with first row y,delta_x, report_id, report_time.
    Defaults to most recent contiguous sample (trace). 
    If duration_s (seconds), clips total sample(s) to duration.
    If points_ct is included, results in points_ct most recent data points.
    If sample_ct, duration_s and points_ct is blank, returns all sample points associated with monitor_id.
    A sample_pt_rate of "1" is default ie no points skipped. If sample_pt_rate is 2, then every other point is skipped etc.
    sample_s_rate is number of seconds between samples. sample_s_rate is ignored if sample_pt_rate is also specified.
    Errors return empty list.
    Note: report_id is derived from tcl \[clock seconds\] which provides a practical way to handle timing procedures --as long as there is only
    one machine running the system.  report_time is in timestampz, so there is a way to recover or integrate data if multiple machines
    or multiple time references require transformations.

} {
    # in oscilloscope terms, if hf_monitor_update is "signal in", then hf_monitor_distribution returns a sample trace of signal.

    # At some point, it may be beneficial to cache static distributions.
    # Static distributions are distributions that have been made static by the introduction
    # of a significant_change flag in a newer record.
    # A significant_change implies that sample (data) between significant_change flags have 
    # a unique set of parameters that may indicate a unique distribution. 
    # Here is a pre-defined table for the cache, should it be implemented:

    # qaf_discrete_dist_report expects delta_x and y.
    #-- Curves are normalized to 1.0
    #-- Percents are represented decimally 0.01 is one percent
    #-- Maybe one day "Per mil" notation should be used instead of percent.
    #-- http://en.wikipedia.org/wiki/Permille
    #-- curve resolution is count of points
    #-- This model keeps old curves, to help with long-term performance insights
    #-- see accounts-finance  qaf_discrete_dist_report 
    #CREATE TABLE hf_monitor_freq_dist_curves (
    #    instance_id      integer not null,
    #    monitor_id       integer not null,
    #    -- analysis_id might contribute 1 or a few points
    #    analysis_id      integer not null,
    #    -- distribution_id represents a distribution between
    #    -- hf_monitor_log.significant_change flags
    #    -- because this is a static distribution -no new points can be added.
    #    distribution_id  integer not null,
    #    -- position x is a sequential position below curve
    #    -- median is where cumulative_pct = 0.50 
    #    -- x_pos is unlikely to be sampled from intervals of exact same size.
    #    -- initial cases assume x_pos is a system time in seconds.
    #    x_pos            integer not null,
    #    -- The sum of all delta_x_pct from 0 to this x_pos.
    #    -- cumulative_pct increases to 1.0 (from 0 to 100 percentile)
    #    cumulative_pct   numeric,
    #    -- Sum of all delta_x_pct equals 1.0
    #    -- delta_x_pct may have some values near low limits of 
    #    -- digitial representation, so only delta_x values are stored.
    #    -- delta_x values might be equal, or not,
    #    -- Depends on how distribution is obtained.
    #    -- Initial use assumes delta_x is in seconds.
    #    delta_x      numeric not null,
    #    -- Duplicate of hf_monitor_log.health.
    #    -- Avoids excessive table joins and provides a clearer
    #    -- boundary between admin and user accessible table queries.
    #    monitor_y        numeric not null
    #);
    
    # A proc hf_monitor_distribution_history (asset_id monitor_id instance_id distro_id_list analysis_id_list)
    # might return a list of specific distribution_id or distributions that include a list of analysis_id
    # These distributions should be queried with "order by monitor_y ascending"


    # permissions
    set error_p [hf_ui_go_ahead_q read "" "" 0]
    if { !$error_p } {
        # initializations
        set sample_sql ""
        set duration_sql ""
        set points_sql ""
        set sql_list [list ]
        set dist_lists [list ]
        
        # validate
        set monitor_id_p [qf_is_natural_number $monitor_id]
        set asset_id_p [qf_is_natural_number $asset_id]
        set sample_ct_p [qf_is_decimal_number $sample_ct]
        set duration_s_p [qf_is_decimal_number $duration_s]
        set points_ct_p [qf_is_decimal_number $points_ct]
        set sample_pt_rate_p [qf_is_decimal_number $sample_pt_rate]
        set sample_s_rate_p [qf_is_decimal_number $sample_s_rate]
        if { $monitor_id_p } {
            if { !$asset_id_p } {
                # get asset_id
                set asset_id [hf_asset_id_of_monitor_id $monitor_id $instance_id]
                if { $asset_id eq "" } {
                    set error_p 1
                }
            }
        } else {
            set error_p 1
        }
    }
    if { !$error_p } {
        if { $sample_ct_p } {
            # get list of significant_change report_times
            set sc_list [db_list hf_monitor_log_read_sc "select report_time from hf_monitor_log where instance_id=:instance_id and monitor_id=:monitor_id and asset_id=:asset_id order by report_time desc"]
            # use the report_time as qualifier
            set i [expr { round( $sample_ct - 1 ) } ]
            set q_time [lindex $sc_list $i]
            if { $q_time ne "" } {
                set sample_sql "report_time > '${q_time}'"
                lappend sql_list $sample_sql
            }
        }
        if { $duration_s_p } {
            set now_s [clock seconds]
            set q2_time [expr { round( $now_s - $duration_s ) } ]
            set duration_sql "report_time < ${q2_time}"
            lappend sql_list $duration_sql
        }
        if { $points_ct_p } {
            if { $sample_pt_rate_p } {
                # ignore sample_s_rate
                set sample_s_rate_p 0

                # adjust initial sample size to handle later interval sampling
                # make this abs() to block any case of infinite case in later while loop
                set sample_pt_rate [expr { round( abs( $sample_pt_rate ) ) } ]
                if { $sample_pt_rate < 1 } {
                    set sample_pt_rate 1
                }
                set points_ct [expr { round( $points_ct * $sample_pt_rate ) + 1 } ]
            } else {
                set points_ct [expr { round( $points_ct ) } ]
            }
            set points_sql "limit :points_ct"

            if { $sample_s_rate_p } {
                # ignore this sql qualifier. count has to be made during sampling in tcl.
            } else {
                lappend sql_list $points_sql
            }
        }
        # join sql qualifiers
        set qualifier_sql [join $sql_list " and "]
    }

    if { !$error_p } {
        # get raw distribution from log
        set raw_lists [db_list_of_lists hf_monitor_log_read_dist "select health,report_id,report_time,significant_change from hf_monitor_log where instance_id=:instance_id and monitor_id=:monitor_id and asset_id=:asset_id order by report_time desc ${points_sql}"]
        set sample_ct [llength $raw_lists ]
        if { $sample_ct == 0 } {
            ns_log Warning "hf_monitor_distribution(3602): no distribution found for asset_id '${asset_id}' instance_id '${instance_id}' monitor_id '${monitor_id}'"
            set error_p 1
        }
    }
    if { !$error_p } {
        # set dist_lists \[list \]
        set i 0
        if { $sample_s_rate_p } {
            # to reduce sample by time 

            # If $points_ct, then limit to number of points.
            # pt_i is number of points minus 1, allowing for faster comparison in while statements.
            set pt_i -1
            while { $i < $sample_ct && $pt_i < $points_ct } {
                ns_log Notice "hf_monitor_distribution.1229 begin while.."
                set row_list [lindex $raw_lists $i]
                set sig_change [lindex $row_list 3]
                set t [lindex $row_list 2]
                while { $sig_change && $i < $sample_ct } {
                    ns_log Notice "hf_monitor_distribution.1234 begin while.."
                    incr i
                    set row_list [lindex $raw_lists $i]
                    set sig_change [lindex $row_list 3]
                    set t [lindex $row_list 2]
                }
                if { !$sig_change } {
                    lappend dist_lists $row_list
                    incr pt_i
                }
                # Increment by change in t (delta t or dt) instead of point count.
                # incr i $sample_pt_rate
                set dt_s $t
                while { $dt_s < $sample_s_rate && $i < $sample_ct && $pt_i < $points_ct } {
                    ns_log Notice "hf_monitor_distribution.1248 begin while.."
                    incr i
                    set row_list [lindex $raw_lists $i]
                    set sig_change [lindex $row_list 3]
                    set t [lindex $row_list 2]
                    incr dt_s $t
                }
            }

        } else {
            # Maybe reduce the sample size to count per sample (sample_pt_rate).
            # All cases included, except by sample_s_rate.

            while { $i < $sample_ct } {
                ns_log Notice "hf_monitor_distribution.1262 begin while.."
                set row_list [lindex $raw_lists $i]
                set sig_change [lindex $row_list 3]
                while { $sig_change && $i < $sample_ct } {
                    ns_log Notice "hf_monitor_distribution.1266 begin while.."
                    incr i
                    set row_list [lindex $raw_lists $i]
                    set sig_change [lindex $row_list 3]
                }
                if { !$sig_change } {
                    lappend dist_lists $row_list
                }
                incr i $sample_pt_rate
            }
        }
        
        # Create final distribution y, delta_x
        # list: health report_id report_time significant_change
        set t0 [lindex $row_i_prev 1]
        for {set i $boundary_i} {$i > 0 } {incr i -1 } {
            set row_i_list [lindex $raw_lists $i]
            # health is y
            set health [lindex $row_i_list 0]
            # report_id is t1
            set t1 [lindex $row_i_list 1]
            set report_time [lindex $row_i_list 2]
            # delta_t is delta x
            set delta_t [expr { abs( $t1 - $t0 ) } ]
            #set dist_row [list [lindex $row_i_list 0] $delta_t]
            set dist_row [list $health $delta_t $t1 $report_time]
            lappend dist_lists $dist_row
            set t0 $t1
        }
        # Add headers
        # If only y,x where y=health and x=delta_t:
        #set dist_lists [linsert $dist_lists 0 [list y x]]
        # But adding report_id and report_time from query, since they might be useful.
        # Query columns were: health, report_id, report_time, significant_change
        set dist_lists [linsert $dist_lists 0 [list y x report_id report_time]]

    }
    return $dist_lists
}

ad_proc -private hf_monitor_statistics {
    asset_id
    monitor_id
    report_id
    portions_count
    calculation_switches
    {interval_s ""}
    {instance_id ""}
    {user_id ""}
    {analysis_id ""}
} {
    Analyse most recent hf_monitor_update in context of distribution curve.
    returns analysis_id. Analysis_id can be retrieved via hf_monitor_report_read
    interval_s refers to distribution sampling.
} {
    # generates data for hf_monitor_status and hf_monitor_report
    # Data are put into separate tables for faster referencing and updates.
    # hf_monitor_status for simple status queries and raw log data
    # hf_monitor_statistics for indepth status queries



    # initializations
    set statistics_list [list ]
    set success_p 1

    # validate
    if { ![qf_is_natural_number $asset_id] } {
        set asset_id ""
    }
    set error_p [hf_ui_go_ahead_q admin "" "" 0]
    if { !$error_p } {
        set monitor_id_p [qf_is_natural_number $monitor_id]
        set report_id_p [qf_is_natural_number $report_id]
        set portions_count_p [qf_is_natural_number $portions_count]
        set interval_s_p [qf_is_decimal_number $interval_s]
        set health_p [qf_is_decimal_number $health]
        set analysis_id_p [qf_is_natural_number $analysis_id]
        if { $monitor_id_p && $report_id_p && $portions_count_p && $interval_s_p && $health_p && $analysis_id_p } {
            # do nothing
        } else {
            set error_p 1
        }
    }
    if { !$error_p && [string length $calculation_switches] < 21 } {
        set calculation_switches_p 1
    } else {
        set calculation_switches_p 0
        set error_p 1
    }
    

    if { !$error_p } {
        # collect from hf_monitor_log:
        #   user_id, asset_id, report_id, health

        set configs_list [hf_monitor_configs_read $monitor_id]
        # portions_count = max number of sample points
        set portions_count [lindex $configs_list 5]
        #  hf_monitor_configs_read contains hf_monitor_configs.interval_s for timing (next) expected_health 
        #  The sceduled time interval between p1 and p0 may depend on monitor stack priorities
        set config_interval_s [lindex $configs_list 9]
        
        # Currently, this paradigm assumes a new curve with each new log entry.
        # Each distribution is not re-saved.
        # For scaling at some point in the future, it may be useful to 
        # schedule distributions for saving in db at some interval, perhaps updating
        # only as data points reach near trigger outliers, or when 
        # a significant change flags the end of changes of a distribution sample.
        set dist_lists [hf_monitor_distribution $asset_id $monitor_id $instance_id "1" "" $portions_count "1" $interval_s ]
        # Returns: row y, delta_x, report_id, report_time
        set dist_lists_len [llength $dist_lists]
        if { $dist_lists_len == 0 } {
            # error logged by hf_monitor_distribution
            set error_p 1
        }
    }
    
    
    if { !$error_p } {
        # Calculations to populate a record of hf_monitor_status

        # get previous status info. (Already queried from hf_monitor_distribution)

        #CREATE TABLE hf_monitor_status (
        #    instance_id                integer not null,
        #    monitor_id                 integer unique not null,
        #    asset_id                   varchar(19) not null DEFAULT '',
        #    --  analysis_id at p0
        #    analysis_id_p0             varchar(19) not null DEFAULT '',
        #    -- most recent analysis_id ie at p1
        #    analysis_id_p1             varchar(19) not null DEFAULT '',
        #    -- health at p0
        #    health_p0                  varchar(19) not null DEFAULT '',
        #    -- for calculating differential, p1 is always 1, just as p0 is 0
        #    -- health at p1
        #    health_p1                  varchar(19) not null DEFAULT '',
        #    health_percentile          varchar(19) not null DEFAULT '',
        #    -- 
        #    expected_health            varchar(19) not null DEFAULT '',
        #    expected_percentile        varchar(19) not null DEFAULT ''
        #);

        # Convert to cobbler list by sortying by y, after removing header
        set normed_lists [lsort -index 0 -real [lrange $dist_lists 1 end]]
        # re-insert heading
        set normed_lists [linsert $normed_lists 0 [lrange $dist_lists 0 0]]

        # Determine health_percentile
        set health_latest [lindex [lindex $raw_lists 0] 0]
        set health_percentile [qaf_p_at_y_of_dist_curve $health_latest $normed_lists]

        # calculate a new record for hf_monitor_status
        # including a new analysis_id
        if { $dist_lists_len > 2 } {
            set first_log_point_p 0
            # two points exist. Calculate p0 and p1 points
            # row_list columns: (y aka health) (x aka delta_t) report_id report_time
            set row0_list [lindex $dist_lists 1]
            set health_p0 [lindex $row0_list 0]
            set analysis_id_p0 [lindex $row0_list 2]
            set row1_list [lindex $dist_lists 2]
            set health_p1 [lindex $row1_list 0]
            set analysis_id_p1 [lindex $row1_list 2]
        } else {
            set first_log_point_p 1
            # This is a new analysis distribution
            # set p0 to same as p1
            set row0_list [lindex $dist_lists 1]
            set health_p0 [lindex $row0_list 0]
            set health_p1 $health_p0
            set analysis_id_p1 [lindex $row0_list 2]
            set analysis_id_p0 [expr { $analysis_id_p1 - $config_interval_s } ]
        }

        set health_percentile_trigger [lindex $configs_list 7]
        set health_threshold [lindex $configs_list 8]

        # Determine expected_health ie health projected out one interval ahead or
        # If monitor has a quota, the quota end point should be the point for projected health.
        # Any quota parameters should be passed via calc_switches to avoid extra db queries.
        set calc_switches [lindex $configs_list 6]
        # Currently, only VMs have performance quotas.
        #-- Reserved for VM quota calcs, 'T' for traffic 'S' for storage 'M' for memory
        #-- A VM monitor should start with only one of T,S,M followed by an aniversary date YYYYMMDD.
        set calc_type ""
        if { [string match {[TSM][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]*} $calc_switches] } {
            set calc_type [string range $calc_switches 0 0]
            set month_aniv [string trim [string range $calc_switches 5 6] "0 "]
            set day_aniv  [string trim [string range $calc_switches 7 8] "0 "]
        }


        # analysis_id is a time based integer derived from tcl clock scan
        # Delta t in seconds for latest two analysis, should always be positive
        set delta_t [expr { $analysis_id_p1 - $analysis_id_p0 } ]
        if { $delta_t < $config_interval_s } {
            # delta_t shouldn't ever be less than config_interval_s. Log a warning
            ns_log Warning "hf_monitor_statistics(3957): delta_t ${delta_t} for monitor_id ${monitor_id} asset_id ${asset_id}. Reset to config_interval_s ${config_interval_s}"
            set delta_t $config_interval_s
        }
        # Use seconds as the minimum time unit for maximum practical granularity in proportions.
        # Partial period calculations use these defaults.
        # a year is considered 365.25 days
        # a year in seconds: expr 365.25 * 24 * 60 * 60 
        set year_s 31557600.0
        # a month in seconds: expr 365.25 * 24 * 60 * 60 / 12  =
        set month_s 2629800.0
        # a day in seconds: 24 * 60 * 60
        set day_s 86400.0
        # a week is 7 days: 24 * 60 * 60 * 7
        set week_s 604800.0
        set hour_s 3600.0
        set now_s [clock seconds]
        set now_yyyymmdd_hhmmss [clock format $datetime_s -format "%Y%m%d %H%M%S"]
        set month_f [string range $now_yyyymmdd_hhmmss 4 5]
        set year_f [string range $now_yyyymmdd_hhmmss 0 3]
        set day_f [string range $now_yyyymmdd_hhmmss 6 7]

        # days in current month
        set days_in_month [dt_num_days_in_month $year_f $month_f]

        # Costs/expenses and usage (resource burn estimates) are calculated in a separate, less frequent process.
        # Partly, this is because prices per burn unit vary contractually, where
        # a month may be defined from aniversary day to day, or a consistent N number of days, or some other duration.
        # Cost calculations tend to include references to a start and end period, so don't want to 
        # drag extra complexity into frequent logging.

        # If we want, we can look at the prior week's performance for predictive purposes, and maybe average with
        # current expected_health.
        # Performance patterns tend to be most pronounced by day and day of week, so we can use a week
        # for estimating performance specs. 
        # For now, we keep it simple. Base next by extrapolating current trend.

        # extrapolate from points p0 and p1 to p2

        # Caculate the next approximate point based on delta_t
        set analysis_id_p2 [expr { $analysis_id_p1 + $delta_t } ]
        switch -exact -- $calc_type {
            T  { 
                # Traffic
                # ..is accumulative, or a snapshot of a period. Assume a snapshot count for delta_t
                # so value can rise or fall.
                set expected_health [qaf_extrapolate_p1p2_at_x $analysis_id_p0 $health_p0 $analysis_id_p1 $health_p1 $analysis_id_p2]
            }
            S  { 
                # Storage
                # ..is accumulative, or a snapshot of a period. Assume a snapshot count for delta_t
                # so value can rise or fall.
                set expected_health [qaf_extrapolate_p1p2_at_x $analysis_id_p0 $health_p0 $analysis_id_p1 $health_p1 $analysis_id_p2]
            }
            M  {
                # Memory
                # ..is accumulative, or a snapshot of a period. Assume a snapshot count for delta_t
                # so value can rise or fall.
                set expected_health [qaf_extrapolate_p1p2_at_x $analysis_id_p0 $health_p0 $analysis_id_p1 $health_p1 $analysis_id_p2]
            }
            default {
                # Assume value can rise or fall with performance. Extrapolate.
                set expected_health [qaf_extrapolate_p1p2_at_x $analysis_id_p0 $health_p0 $analysis_id_p1 $health_p1 $analysis_id_p2]
            }
        }
        set expected_percentile [qaf_p_at_y_of_dist_curve $expected_health $normed_lists]
        
        set range_min $analysis_id_p0
        set range_max $analysis_id_p1

        # create values for hf_monitor_statistics. Set min/max.        
        if { $first_log_point_p } {
            set sample_count 1
            set health_max $health_p1
            set health_min $health_p0
            set health_average $health_p1
        } else {
            set sample_count [expr { $dist_lists_len - 1 } ]
            set row_y_low [lindex $normed_lists 1]
            set health_min [lindex $row_y_low 0]
            set row_y_high [lindex $normed_lists end]
            set health_max [lindex $row_y_high 0]
            set health_average [expr{ ( $health_max + $health_min ) / 2. } ]
            set health_median [qaf_y_of_x_dist_curve 0.5 $normed_lists 1]
            # first centile instead of first quartile
            set health_first_tile [qaf_y_of_x_dist_curve 0.1 $normed_lists 1]
            set health_pre_last_tile set health_median [qaf_y_of_x_dist_curve 0.9 $normed_lists 1]
        }
        
        #CREATE TABLE hf_monitor_statistics (
        #    instance_id     integer not null,
        #    -- only most recent status statistics are reported here 
        #    -- A hf_monitor_log.significant_change flags boundary
        #    monitor_id      integer not null,
        #    -- same as hf_monitor_status.analysis_id_p1
        #    -- This ref is used to point to identify a specific hf_monitor_statistics analysis
        #    analysis_id     integer not null,
        #    sample_count    varchar(19) not null DEFAULT '',
        #    -- range_min is minimum value of hf_monitor_log.report_id used.
        #    range_min       varchar(19) not null DEFAULT '',
        #    -- range_max is current hf_monitor_log.report_id
        #    range_max       varchar(19) not null DEFAULT '',
        #    health_max      varchar(19) not null DEFAULT '',
        #    health_min      varchar(19) not null DEFAULT '',
        #    health_average  numeric,
        #    health_median   numeric
        #    -- first and pre-last n-tiles are more stable versions of range min/max                                                         
        #    -- As in first quartile, centile or whatever is used                                                                            
        #    health_first_tile  numeric,
        #    -- As in pre-last or 3 quartile of 4 quartiles, or 99 of 100 centiles, or                                                       
        #    -- pre-last decitile (.90) as the case is at the writing of this comment.                                                       
        #    health_pre_last_tile   numeric
        #); 
        
        # save calculations to hf_monitor_status and hf_monitor_statistics
        # use latest hf_monitor_log.report_id for analysis_id for new record ie analysis_id_1
        db_transaction {
            db_dml hf_monitor_status_add { insert into hf_monitor_status
                ( instance_id,monitor_id,asset_id,analysis_id_p0,analysis_id_p1,health_p0,health_p1,health_percentile,expected_health,expected_percentile,health_first_tile,health_pre_last_tile)
                (:instance_id,:monitor_id,:asset_id,:analysis_id_p0,:analysis_id_p1,:health_p0,:health_p1,:health_percentile,:expected_health,:expected_percentile,:health_first_tile,:health_pre_last_tile)
            }
            db_dml hf_monitor_statistics_add { insert into hf_monitor_statistics
                ( instance_id,monitor_id,analysis_id,sample_count,range_min,range_max,health_max,health_min,health_average,health_median,health_first_tile,health_pre_last_tile)
                values (:instance_id,:monitor_id,:analysis_id_p1,:sample_count,:range_min,:range_max,:health_max,:health_min,:health_average,:health_median,:health_first_tile,:health_pre_last_tile)
            }

        }

        # check triggers. ie hf_monitor_config_n_control.health_percentile_trigger and .health_threshold  
        # Either one will trigger a notification, but only one message per event.
        if { $health_p1 > $health_threshold } {
            # flag immediate
            set alert_title "#hosting-farm.Health_Score#: ${health}"
            set alert_message "#hosting-farm.Health_Score#: ${health} #hosting-farm.passed_alert_threshold#."
            ns_log Notice "hf_monitor_statistics.4085: asset_id '${asset_id} monitor_id '${monitor_id}' health_p1 '${health_p1}' health_threshold '${health_threshold}' Sending immediate notice."
            hf_monitor_alert_trigger $monitor_id $asset_id $alert_title $alert_message 1 $instance_id

        } elseif { $health_percentile > $health_percentile_trigger } {
            # send notification
            set alert_title "#hosting-farm.Health_Percentile#: ${health_percentile}"
            set alert_message "#hosting-farm.Health_Percentile#: ${health_percentile} #hosting-farm.passed_alert_threshold#."
            ns_log Notice "hf_monitor_statistics.4090: asset_id '${asset_id} monitor_id '${monitor_id}' health_percentile '${health_percentile}' health_percentile_trigger '${health_percentile_trigger}' Sending notice."
            hf_monitor_alert_trigger $monitor_id $asset_id $alert_title $alert_message 0 $instance_id

        }
    }    

    if { $error_p } {
        set success_p 0
    }
    return $success_p
}

ad_proc -private hf_monitor_stats_read {
    monitor_id 
    {analysis_id ""}
    {instance_id ""}
} {
    Returns statistics resulting from analysis of status info.
    analysis_id assumes most recent analysis. Can return a range of monitor history.
} {

    # validate 
    set monitor_id_p [qf_is_natural_number $monitor_id]
    if { $monitor_id_p } {
        set asset_id [hf_asset_id_of_monitor_id $monitor_id]
    }
    hf_ui_go_ahead_q read

    set analysis_id_p [qf_is_natural_number $analysis_id]

    # initializations
    set statistics_list [list ]

    if { $monitor_id_p } {
        if { $analysis_id_p } {
            set statistics_lists [db_list_of_lists hf_monitor_stats_get "select sample_count, range_min, range_max, health_min, health_max, health_average, health_median, analysis_id, monitor_id from hf_monitor_statistics where instance_id=:instance_id and monitor_id=:monitor_id and analysis_id=:analysis_id"]
        } else {
            # set analysis_id to the latest
            set statistics_lists [db_list_of_lists hf_monitor_stats_get "select sample_count, range_min, range_max, health_min, health_max, health_average, health_median, analysis_id, monitor_id from hf_monitor_statistics where instance_id=:instance_id and monitor_id=:monitor_id order by analysis_id desc limit 1"]
        }
        set statistics_list [lindex $statistics_lists 0]
    }
    return $statistics_list
}

ad_proc -private hf_monitor_alert_trigger {
    monitor_id
    asset_id
    alert_title
    alert_message
    {immediate_p "0"}
    {instance_id ""}
} {
    Send notification for alerts from monitors (and quota overage notices).
} {
    hf_ui_go_ahead_q admin
    # sender email is systemowner
    # to get user_id of systemowner:
    # party::get_by_email -email $email
    set sysowner_email [ad_system_owner]
    set sysowner_user_id [party::get_by_email -email $sysowner_email]

    # What users to send alert to?
    set config_list [hf_monitor_configs_read $asset_id $instance_id]
    if { [llength $config_list] > 0 } {
        set alert_by_privilege [lindex $config_list 7]
        set alert_by_role [lindex $config_list 8]
        set
    } else {
        set label "#hosting-farm.Asset# id ${asset_id}"
    }
    set users_list [hf_nc_users_of_asset_id $asset_id $instance_id $alert_by_privilege $alert_by_role]
    if { [llength $users_list ] == 0 } {
        set user_id [hf_user_id_of_asset_id $asset_id]
        set users_list [list $user_id]
    }
    set 
    if { [llength $users_list] > 0 } {
        # get TO emails from user_id
        set email_addrs_list [list ]
        foreach uid $users_list {
            lappend email_addrs_list [party::email -party_id $uid]
        }
        
        # What else is needed to send alert message?
        set subject "#hosting-farm.Alert# #hosting-farm.Asset_Monitor# id ${monitor_id} for ${label}: ${alert_title}"
        set body $alert_message
        # post to logged in user pages 
        hf_log_create $asset_id "#hosting-farm.Asset_Monitor#" "alert" "id ${monitor_id} ${subject} \n Message: ${body}" $user_id $instance_id 

        # send email message
        append body "#hosting-farm.Alerts_can_be_customized#. #hosting-farm.See_asset_configuration_for_details#."
        acs_mail_lite::send -send_immediately $immediate_p -to_addr $email_addrs_list -from_addr $sysowner_email -subject $subject -body $body

        # log/update alert status
        if { $immediate_p } {
            # show email has been sent
            
        } else {
            # show email has been scheduled for sending.


#    When a user reads hf_log_create message, the alert status for user_id should be updated to show message sent --even if it is shared with other users.
#    If user_id is an admin, this returns a list of lists of up to history_count messages not followed up with a user login. This allows the system to monitor for flags that are not responded to, allowing an opportunity for a sysadmin to check logs etc for proactive monitoring. List is sorted by critical alerts first.

        }
    }
    return 1
}

ad_proc -public hf_monitor_alerts_status {
    {user_id ""}
    {instance_id ""}
    {history_count ""}
} {
    Checks monitor alerts for user_id. 
    
} {
    # This is a wrapper. See hf_monitor_alerts_history for history of alerts
    # display messages for user
    hf_beat_log_alert_q $user_id $instance_id
    return 1
}


ad_proc -public hf_monitors_inactivate {
    asset_id
    monitor_ids
    {instance_id ""}
    {user_id ""}
} {
   Monitor_ids must be associated with asset_id. If asset_id is only provided, all monitors associated with an asset_id are inactivated.
} {
    # validate
    set nc_p [ns_conn isconnected]
    if { $nc_p } {
        set admin_p 1
    } else {
        set user_id [ad_conn user_id]
        # try and make it work
        if { $instance_id eq "" } {
            # set instance_id package_id
            set instance_id [qc_set_instance_id]
        }
        set admin_p [qc_permission_p $user_id "" assets admin $instance_id]
    }

    # if an asset_id, also force off monitor_p in hf_assets to indicate monitoring is not happening. 
    # Creating a ns_log warning if hf_assets.monitor_p was 0.


    ##code
}

