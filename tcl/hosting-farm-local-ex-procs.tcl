# hosting-farm/tcl/local-ex-procs.tcl
ad_library {

    example localize API for hosting-farm ( /local/bin )
    @creation-date 11 April 2015
    @Copyright (c) 2014 Benjamin Brink
    @license GNU General Public License 3, see project home or http://www.gnu.org/licenses/gpl-3.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com
}
# begin all custom procs with hfl_ for hflocal.
# To be sure that your code is not overwritten during
# a package update, put your code in a separate tcl file 
# in this directory. 
# You might want to have one file for local monitor procs
# hosting-farm-local-mon-procs.tcl for example,
# and another for local maintenance calls
# hosting-farm-local-sys-procs.tcl for example.

# Note to sys admins:
# These procs are called from a scheduled proc stack.
# A system restart is required for the system to use
# any changes in code in this file.
# If you expect regular changes to some portions of code,
# consider putting volatile parts in a table named hfl_* in
# the database to avoid changing code.
# Most any proc in package/tcl/*.tcl is immediatedly updated 
# in an active system via broswer url /acs-admin/apm 
# except scheduled procs. 
# For testing purposes, an admin can call an updated proc
# in a test page after reloading via url /acs-admin/apm


ad_proc -private hfl_allow_q {
} {
    Confirms process is allowed.
} {
    set go_ahead 1
    #  not run via connection, or is run by an admin
    if { [ns_conn isconnected] } {
        set user_id [ad_conn user_id]
        set instance_id [ad_conn package_id]
        set go_ahead [permission::permission_p -party_id $user_id -object_id $instance_id -privilege admin]
        if { !$go_ahead } {
            ns_log Warning "hfl_go_head(24). failed. Called by user_id ${user_id}, instance_id ${instance_id}"
            ad_script_abort
        }
    }
    return $go_ahead
}


ad_proc -private hfl_asset_halt_example {
    asset_id
    {user_id ""}
    {instance_id ""}
} {
    An example local proc that: Halts the operation of an asset, such as service, vm, vhost etc
} {
    # This proc can filter by asset_type_id

    # check permission
    # basic pre-check:
    hf_nc_go_ahead
    # determine customer_id of asset
    # name,title,asset_type_id,keywords,description,template_p,templated_p,trashed_p,trashed_by,publish_p,monitor_p,popularity,triage_priority,op_status,ua_id,ns_id,qal_product_id,qal_customer_id,instance_id,user_id,last_modified,created,flags
    set asset_stats_list [hf_asset_stats $asset_id $instance_id $user_id]
    set customer_id [lindex $asset_stats_list 17]
    set allowed_p [hf_permission_p $user_id $customer_id assets $privilege $instance_id]

    if { $allowed_p } {
        # determine asset_type
        set asset_type_id [lindex $asset_stats_list 2]
        
        
        # set asset attributes so that remaining code can use them for any nonlocal api calls.
        set now [dt_systime -gmt 1]

        #    set a priority for use with hf process stack
        set priority [lindex $asset_stats_list 9]
        if { $priority eq "" } {
            # triage_priority
            set priority [lindex $asset_stats_list 12]
        }

        # log intent
        ns_log Notice "hfl_asset_halt_example id ${asset_id}' of type '${asset_type_id}' priority '${priority}'"
        # update properties of asset_id to halt.
        db_dml hf_asset_id_halt { update hf_assets
            set time_stop = :now where time_stop is null and asset_id = :asset_id 
        }

        if { $proc_name ne "" } {
            # load object properties in array obj_arr
            hf_asset_properties $asset_id obj_arr $instance_id

            # one way to filter by asset_type_id:
            switch -- $asset_type_id { 
                vm  {
                    # prep or call for halting virtual machine
                    # call proc, passing object info

                    # example system call
                    set daemon_uri "/usr/local/bin/vm-api halt"
                    safe_eval [list $daemon_uri $obj_arr(domain_name)]
                }
                vh,ss {
                    # prep or call for halting vh or service
                    # call proc, passing object info
                    # example external call: 
                    set admin_url "https://$obj_arr(domain_name):$obj_arr(port)/$obj_arr(url)?action=halt"
                    ns_httpget $admin_url
                }
                other {
                    # ignore other cases, but maybe log that it is being ignored if nonstandard

                    if { $asset_type_id ne "dc" } {
                        ns_log Warning "hfl_asset_halt_example(100): ignoring unexpected asset_type_id '${asset_type_id}'"
                    }
                }
            }
        }
    }
    
    # return 1 if successful (at least has permission)
    return $allowed_p
}


# hfl_system_swap_monitor_ex


ad_proc -private hfl_system_cpu {
    {asset_id "" }
    {user_id ""}
    {instance_id ""}
} {
    Get cpu usage last 5 10 15 minutes.
    # permissions ck
    hfl_allow_q

    # Assumes local system
    set system_type [ns_eval uname]
    set spc_idx [string first " " $system_type]
    if { $spc_id > -1 } {
        set system_type [string trim [string tolower [string range $system_type 0 $spc_idx]]
    } else {
        set system_type [string trim [string tolower $system_type]]
    }
    if { $system_type eq "linux" } {
        set cmd "uptime"
        set since_cmd "uptime -s"
    }
    if { $system_type eq "freebsd" } {

        set cmd "uptime"
    }
    
}

ad_proc -private hfl_system_memory {
    asset_id
    monitor_id
    instance_id
} {
    upvar 1 asset_prop_arr obj_arr

    # Get memory usage
    # permissions ck
    hfl_allow_q
    set cmd ""
    set health 0
    if { [string match -nocase "*linux*" $obj_arr(os_label)] } {
        set cmd "top -b -n1"
    } elseif { [string match -nocase "*freebsd*" $obj_arr(os_label)] } {
        set cmd "top -n"
    }

    if { $cmd ne "" } {
        set raw [eval $cmd]
        if { $raw eq "" } {
            # For some reason, eval results aren't returned to variable. 
            # use some static data from local system
            set raw {EXAMPLE DATA Tasks: 201 total,   1 running, 200 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
KiB Mem:   6101420 total,  1392588 used,  4708832 free,   278264 buffers
KiB Swap:  8380412 total,        0 used,  8380412 free.   572532 cached Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND  \n
    1 root      20   0   33912   4536   2720 S   0.0  0.1   0:03.06 init     \n
    2 root      20   0       0      0      0 S   0.0  0.0   0:00.00 kthreadd \n
    3 root      20   0       0      0      0 S   0.0  0.0   0:05.89 ksoftirqd/0 ...}
            # set unit
            set unit "KiB"
            set low_idx [string first "Mem" $raw]
            incr low_idx 4
            set high_idx [string first "Swap" $raw]
            set used_low_idx [string first "total" $raw $low_idx]
            set total_high_idx $used_low_idx
            incr used_low_idx 6
            set used_high_idx [string first "used" $raw $low_idx]
            incr used_high_idx -1
            set total_low_idx $low_idx
            incr total_high_idx -1
            set total_u [string trim [string range $raw $total_low_idx $total_high_idx]]
            set used_u [string trim [string range $raw $used_low_idx $used_high_idx]]
            set used_bytes [hf_convert_to_iec_bytes $used_u $unit]
            set total_bytes [hf_convert_to_iec_bytes $total_u $unit]
            set health [expr { round( $used_bytes / $total_bytes) } ]
            set report $raw
        }
    } else {
        set report "*error* system not freebsd or linux. Report error to technical administrator."
    }
    hf_monitor_update $asset_id $monitor_id hfl_system_memory $health $report "" "" $instance_id
}

# test cases:
# hfl_problem_server_cpu
# hfl_problem_server_storage
# hfl_problem_server_traffic

# using 7*24*3600 second cycles in x seconds ie fastforward_rate_s = 7*24*3600/x
    # using a cyclic, noisy function, something like:
# f(t) = min + (max-min) * sigma(for n=1 to 7*24) of 2pi * delta_t_s * N / t) + random
# in addition to sin, cos, there is also acc_fin::pos_sine_cycle, and thrashing with fibonacci or other progression as factor for example.
