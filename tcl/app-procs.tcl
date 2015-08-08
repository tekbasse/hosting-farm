#hosting-farm/tcl/app-procs.tcl
ad_library {

    routines for hosting-farm UI-logs
    @creation-date 11 Feb 2014
    @Copyright (c) 2014 Benjamin Brink
    @license GNU General Public License 3, see project home or http://www.gnu.org/licenses/gpl-3.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com

    Temporary comment about git commit comments: http://xkcd.com/1296/
}

ad_proc -private hf_log_create {
    asset_id
    action_code
    action_title
    entry_text
    {user_id ""}
    {instance_id ""}
} {
    Log an entry for a hf process. Returns unique entry_id if successful, otherwise returns empty string.
} {
    set id ""
    set status [qf_is_natural_number $asset_id]
    if { $status } {
        if { $entry_text ne "" } {
            if { $instance_id eq "" } {
                ns_log Notice "hf_log_create.451: instance_id ''"
                set instance_id [ad_conn package_id]
            }
            if { $user_id eq "" } {
                ns_log Notice "hf_log_create.451: user_id ''"
                set user_id [ad_conn user_id]
            }
            set id [db_nextval hf_sched_id_seq]
            set trashed_p 0
            set nowts [dt_systime -gmt 1]
            set action_code [qf_abbreviate $action_code 38]
            set action_title [qf_abbreviate $action_title 78]
            db_dml hf_process_log_create { insert into hf_process_log
                (id,asset_id,instance_id,user_id,trashed_p,name,title,created,last_modified,log_entry)
                values (:id,:asset_id,:instance_id,:user_id,:trashed_p,:action_code,:action_title,:nowts,:nowts,:entry_text) }
            ns_log Notice "hf_log_create.46: posting to hf_process_log: action_code ${action_code} action_title ${action_title} '$entry_text'"
        } else {
            ns_log Warning "hf_log_create.48: attempt to post an empty log message has been ignored."
        }
    } else {
        ns_log Warning "hf_log_create.51: asset_id '$asset_id' is not a natural number reference. Log message '${entry_text}' ignored."
    }
    return $id
}

ad_proc -public hf_log_read {
    asset_id
    {max_old "1"}
    {user_id ""}
    {instance_id ""}
} {
    Returns any new log entries as a list via util_user_message, otherwise returns most recent max_old number of log entries.
    Returns empty string if no entry exists.
} {
    set return_lol [list ]
    set alert_p 0
    set nowts [dt_systime -gmt 1]
    set valid1_p [qf_is_natural_number $asset_id] 
    set valid2_p [qf_is_natural_number $asset_id]
    if { $valid1_p && $valid2_p } {
        if { $instance_id eq "" } {
            set instance_id [ad_conn package_id]
            ns_log Notice "hf_log_read.493: instance_id ''"
        }
        if { $user_id eq "" } {
            set user_id [ad_conn user_id]
            ns_log Notice "hf_log_read.497: user_id ''"
        }
        set return_lol [list ]
        set last_viewed ""
        set alert_msg_count 0
        set viewing_history_p [db_0or1row hf_process_log_viewed_last { select last_viewed from hf_process_log_viewed where instance_id = :instance_id and asset_id = :asset_id and user_id = :user_id } ]
        # set new view history time
        if { $viewing_history_p } {

            set last_viewed [string range $last_viewed 0 18]
            if { $last_viewed ne "" } {
                
                set entries_lol [db_list_of_lists hf_process_log_read_new { 
                    select id, name, title, log_entry, last_modified from hf_process_log 
                    where instance_id = :instance_id and asset_id =:asset_id and last_modified > :last_viewed order by last_modified desc } ]
                
                ns_log Notice "hf_log_read.80: last_viewed ${last_viewed}  entries_lol $entries_lol"
                
                if { [llength $entries_lol ] > 0 } {
                    set alert_p 1
                    set alert_msg_count [llength $entries_lol]
                    foreach row $entries_lol {
                        set message_txt "[lc_time_system_to_conn [string range [lindex $row 4] 0 18]] [lindex $row 3]"
                        set last_modified [lindex $row 4]
                        ns_log Notice "hf_log_read.79: last_modified ${last_modified}"
                        util_user_message -message $message_txt
                        ns_log Notice "hf_log_read.88: message '${message_txt}'"
                    }
                    set entries_lol [list ]
                } 
            }
            
            set max_old [expr { $max_old + $alert_msg_count } ]
            set entries_lol [db_list_of_lists hf_process_log_read_one { 
                select id, name, title, log_entry, last_modified from hf_process_log 
                where instance_id = :instance_id and asset_id =:asset_id order by last_modified desc limit :max_old } ]
            foreach row [lrange $entries_lol $alert_msg_count end] {
                set message_txt [lindex $row 2]
                append message_txt " ([lindex $row 1])"
                append message_txt " posted: [lc_time_system_to_conn [string range [lindex $row 4] 0 18]]\n "
                append message_txt [lindex $row 3]
                ns_log Notice "hf_log_read.100: message '${message_txt}'"
                lappend return_lol $message_txt
            }
            
            # last_modified ne "", so update
            db_dml hf_process_log_viewed_update { update hf_process_log_viewed set last_viewed = :nowts where instance_id = :instance_id and asset_id = :asset_id and user_id = :user_id }
        } else {
            # create history
            set id [db_nextval hf_sched_id_seq]
            db_dml hf_process_log_viewed_create { insert into hf_process_log_viewed
                ( id, instance_id, user_id, asset_id, last_viewed )
                values ( :id, :instance_id, :user_id, :asset_id, :nowts ) }
        }
    }
    return $return_lol
}

