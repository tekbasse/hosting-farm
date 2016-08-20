# hosting-farm/tcl/local-ex-procs.tcl
ad_library {

    library showing example api to local interfaces for Hosting Farm
    @creation-date 11 April 2015
    @Copyright (c) 2014 Benjamin Brink
    @license GNU General Public License 3, see project home or http://www.gnu.org/licenses/gpl-3.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com
}


# Name all custom procs with prefix 'hfl_' for hf_local.
# to be sure that your code is not overwritten during
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


# With each asset change, call hf_monitor_log_create with significant_change_p=1 ?
# No. This should be done at the hfl_nc_* proc level, and/or admin specified via UI.


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
    } else {
        # make sure called by hf::monitor::do directly
       # if { $argv0 ne "hf::monitor::do" } {
       #     ns_log Warning "hfl_go_head(52). failed. Called by argv0 '${argv0}'"
       #     set go_head 0
       #     ad_script_abort
       # } 
        ns_log Notice "hf_nc_go_ahead: ns_thread name [ns_thread name] ns_thread id [ns_thread id] ns_info threads [ns_info threads] ns_info scheduled [ns_info scheduled]"

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
    # basic pre-check:  Using hf_nc_go_ahead instead of hfl_allow_q, because this can be called via UI directly.
    hf_nc_go_ahead

    # determine customer_id of asset

    
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
        set time_stop=:now where time_stop is null and asset_id=:asset_id 
    }
    
    if { $proc_name ne "" } {
        # load object properties in array obj_arr
        hf_asset_properties $asset_id obj_arr $instance_id

        # one way to filter by asset_type_id:
        switch -exact -- $asset_type_id { 
            vm  {
                # prep or call for halting virtual machine
                # call proc, passing object info

                # example system call
                set daemon_uri "/usr/local/bin/vm-api halt"
                exec [list $daemon_uri $obj_arr(domain_name)]
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
    return 1
}


# hfl_system_swap_monitor_ex


ad_proc -private hfl_system_cpu {
    {asset_id "" }
    {user_id ""}
    {instance_id ""}
} {
    Get cpu usage last 5 minutes.
    # permissions ck
    hfl_allow_q

    # Assumes local system
    # uptime
    # "The uptime utility displays the current time, the length of time the sys-
    # tem has been up, the number of users, and the load average of the system
    # over the last 1, 5, and 15 minutes.

    # linux output example:
    # 16:01:42 up 4 days, 7 min,  4 users,  load average: 0.03, 0.02, 0.05
    # freebsd example:
    # 11:03PM  up 15 days,  3:29, 1 user, load averages: 3.00, 2.58, 2.02

    set os_label $obj_arr(os_label)
    set load_5m ""
    set uptime "uptime"
    set report [exec $uptime]
    regexp -- {.*[\:][\ ]+([0-9\.]+)[, ]+([0-9\.]+)[, ]+([0-9\.]+).*} $report scratch load_5m load_10m load_15m

    # how many cpu's max?
    
    # guess a default:
    set cpu_count 8
    set cmd "guess"
    set report2 "default used"
    set health 0
    set success_p 0
    if { $os_label eq "freebsd" } {
        # 'sysctl hw.ncpu' returns:
        # hw.ncpu: 16
        set cmd "sysctl" 
        set arg1 "hw.ncpu"
        set report2 [exec $cmd $arg1]
        set spc_idx [string first " " $report2]
        if { $spc_idx > -1 } {
            set cpu_count [string trim [string range $report2 $spc_idx end]]
        }
    } elseif { $os_label eq "linux" } {
        set cmd "grep"
        set arg1 "-c"
        set arg2 "'^processor'"
        set arg3 "/proc/cpuinfo"
        set report2 [exec $cmd $arg1 $arg2 $arg3]
        set cpu_count [string trim $report2]
    }
    append report "\ncpu_count ${cmd}: ${report2}"
    if { [qf_is_decimal $load_5m ] } {
        # add 1 percent to prevent health of 0 on an idle system --insignificant on heavy loads
        set health [expr { round( 100. * ( $load_5m + 0.0149 * $cpu_count ) / $cpu_count ) } ]
        set success_p 1
    } 
    hf_monitor_update $asset_id $monitor_id hfl_system_memory $health $report "" "" $instance_id
    return $success_p
}

ad_proc -private hfl_system_memory {
    asset_id
    monitor_id
    instance_id
} {
    Returns monitor health. Example case of local monitor proc to retrieve local memory usage.
} {
    upvar 1 asset_prop_arr obj_arr

    # Get memory usage
    # permissions ck
    hfl_allow_q
    set os_label $obj_arr(os_label)
    set cmd ""
    set args ""
    set health 0
    set which "which"
    set cmd "top"
    set cmd [exec $which $cmd]
    if { [string match -nocase "*linux*" $os_label] } {
        set os_label "linux"
        set arg1 "-b"
        set arg2 "-n1"
    } elseif { [string match -nocase "*freebsd*" $os_label] } {
        set os_label "freebsd"
        set arg1 "-n"
        set arg2 ""
    }
    if { [string match -nocase "*error*" $cmd] || $cmd eq "" } {
        # There is a problem with cmd setup.
        set raw ""
    } else {
        set raw [exec $cmd $arg1 $arg2]
    }
    if { $raw eq "" } {
        set report "System error hfl_system_memory. Report error to technical administrator."
        if { $os_label eq "linux" } {
            # For some reason, results aren't returned to variable. 
            # use some static data from local system
            set raw {EXAMPLE DATA Tasks: 201 total,   1 running, 200 sleeping,   0 stopped,   0 zombie
                %Cpu(s):  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
                KiB Mem:   6101420 total,  1392588 used,  4708832 free,   278264 buffers
                KiB Swap:  8380412 total,        0 used,  8380412 free.   572532 cached Mem
                
                PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND  \n
                1 root      20   0   33912   4536   2720 S   0.0  0.1   0:03.06 init     \n
                2 root      20   0       0      0      0 S   0.0  0.0   0:00.00 kthreadd \n
                3 root      20   0       0      0      0 S   0.0  0.0   0:05.89 ksoftirqd/0 ...}

        } elseif { $os_label eq "freebsd" } {
            set raw {last pid: 87140;  load averages:  1.93,  1.99,  1.98  up 13+06:56:39    02:31:20
                29 processes:  1 running, 28 sleeping
                
                Mem: 886M Active, 11G Inact, 86G Wired, 131M Cache, 27G Free
                ARC: 73G Total, 29G MFU, 37G MRU, 5817K Anon, 383M Header, 6737M Other
                Swap: 16G Total, 16G Free


                PID USERNAME    THR PRI NICE   SIZE    RES STATE   C   TIME    WCPU COMMAND
                9196 openacs      18  20    0   518M   243M uwait   0   4:55   0.00% nsd
                7650 pgsql         1  20    0 39792K  7340K select 12   0:34   0.00% postgres
                7582 pgsql         1  20    0   180M 17220K select 15   0:20   0.00% postgres
                7741 cyrus         1  20    0 58580K  5784K select  1   0:09   0.00% master ... }
        }
    }
    if { $os_label eq "linux" } {
        # set unit
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
        set health [expr { round( 100. * $used_bytes / $total_bytes) } ]
        set report $raw
    } elseif { $os_label eq "freebsd" } {
        # set unit
        set low_idx [string first "Mem" $raw]
        incr low_idx 4
        set high_idx [string first "Swap" $raw]
        set used_low_idx [string first "Active" $raw $low_idx]
        set total_high_idx [string first "Wired" $raw $low_idx]
        incr used_low_idx 8
        set used_high_idx [string first "Inact" $raw $low_idx]
        set total_low_idx $used_high_idx
        incr total_low_idx 7
        incr used_high_idx -1
        incr total_high_idx -1
        set total_u [string trim [string range $raw $total_low_idx $total_high_idx]]
        set used_u [string trim [string range $raw $used_low_idx $used_high_idx]]
        set total_unit [string range $total_u end end]
        set used_unit [string range $used_u end end]
        set used_u [string range $used_u 0 end-1]
        set total_u [string range $total_u 0 end-1]
        set used_bytes [hf_convert_to_unit_metric $used_u $used_unit]
        set total_bytes [hf_convert_to_unit_metric $total_u $total_unit]
        set health [expr { round( 100. * $used_bytes / $total_bytes) } ]
        set report $raw
    }
    hf_monitor_update $asset_id $monitor_id hfl_system_memory $health $report "" "" $instance_id
}

ad_proc -private hfl_problem_server_cpu {
    asset_id
    monitor_id
    instance_id
} {
    Returns cpu health. This is a example local procedure for testing a phantom problem server.
} {
    upvar 1 asset_prop_arr obj_arr

    # Get memory usage
    # permissions ck
    hfl_allow_q


    # Using 1 week ( 7*24*3600=604800 second ) cycles.
    # If a day passes in 7 hours, then a week in 49 hours.
    # If a day passes in 3 hours, then a week in 21 hours ( 75600 seconds). 
    # A 24 hour test cycle should provide
    # sufficient resolution to detect bugs.
    # The cycle can start most anywhere in the timeline.

    set cycle_s 75600
    # in case there are multiple systems, lets further vary by an asset_id
    # factor. 
    set cycle_s [expr { round( $cycle_s / sqrt( $asset_id ) ) } ]
    #expr acos(0) * 2.=
    set twopi 3.141592653589793
    set one_7th 0.14285714285714285 
    set time_s [clock seconds]
    set cycle_t [expr { fmod( $time_s , $cycle_s ) } ]
    set t_pct [expr { $cycle_t / $cycle_s } ]
    set k [expr { $cycle_t * $twopi } ]
    set h0 [expr { sin( $k / $cycle_s ) } ]
    set cycle_7_s [expr { $cycle_s / 7. } ]
    set cycle_3_s [expr { $cycle_7_s * 3. } ]
    set h1 [expr { sin( $k / $cycle_7_s ) } ]
    set h2 [expr { sin( $k / $cycle_3_s + $one_7th ) } ]
    set h3 [expr { sin( $k / $cycle_7_s + $one_7th * 2. ) } ]
    set h4 [expr { sin( $k / $cycle_3_s + $one_7th * 3. ) } ]
    set h5 [expr { sin( $k / $cycle_3_s + $one_7th * 4. ) } ]
    set h6 [expr { sin( $k / $cycle_7_s + $one_7th * 5. ) } ]
    set noise [expr { ( [random] - .5 ) * 14. } ]
    set health [expr { 50. + 10. * ( $h0 + $h1 + $h2 + $h3 + $h4 + $h5 + $h6 ) + $noise } ]
    set health [f::max 0 $health]

    # A healthy signal amplitude is somewhere between 1 and 99, ie 7 * 7 * 2

    # In addition to sin, and cos, acc_fin::pos_sine_cycle, thrashing can be simulated with fibonacci or 
    # other progression as factor for example.

    hf_monitor_update $asset_id $monitor_id hfl_system_memory $health $report "" "" $instance_id
    return 1
}

ad_proc -private hfl_problem_server_storage {
    asset_id
    monitor_id
    instance_id
} {
    Returns cpu health. This is a example local procedure for testing a phantom problem server.
} {
    upvar 1 asset_prop_arr obj_arr

    # Get storage usage
    # permissions ck
    hfl_allow_q

    # Using 1 week ( 7*24*3600=604800 second ) cycles.
    # If a day passes in 7 hours, then a week in 49 hours.
    # If a day passes in 3 hours, then a week in 21 hours ( 75600 seconds). 
    # A 24 hour test cycle should provide
    # sufficient resolution to detect bugs.
    # The cycle can start most anywhere in the timeline.

    set cycle_s 75600
    #expr acos(0) * 2.=
    set twopi 3.141592653589793
    set one_7th 0.14285714285714285 
    set time_s [clock seconds]
    set cycle_t [expr { fmod( $time_s + $one_7th * $cycle_s , $cycle_s ) } ]
    set t_pct [expr { $cycle_t / $cycle_s } ]
    set k [expr { $cycle_t * $twopi } ]
    set cycle_7_s [expr { $cycle_s / 7. } ]
    set cycle_3_s [expr { $cycle_7_s * 3. } ]

    set h0 [expr { sin( $k / $cycle_s ) } ]
    set h1 [expr { sin( $k / $cycle_7_s ) } ]
    set h2 [expr { sin( $k / $cycle_3_s + $one_7th ) } ]
    set h3 [expr { sin( $k / $cycle_7_s + $one_7th * 2. ) } ]
    set h4 [expr { sin( $k / $cycle_3_s + $one_7th * 3. ) } ]
    set h5 [expr { sin( $k / $cycle_3_s + $one_7th * 4. ) } ]
    set h6 [expr { sin( $k / $cycle_7_s + $one_7th * 5. ) } ]
    set noise [expr { ( [random] - .5 ) * 14. } ]
    set health [expr { 50. + 14 * ( $h0 + $h1 + $h2 + $h3 + $h4 + $h5 + $h6 ) + $noise } ]
    set health [f::max 0 $health]

    # A healthy signal amplitude is somewhere between 1 and 99, ie 7 * 7 * 2

    # In addition to sin, and cos, acc_fin::pos_sine_cycle, thrashing can be simulated with fibonacci or 
    # other progression as factor for example.

    hf_monitor_update $asset_id $monitor_id hfl_system_memory $health $report "" "" $instance_id
    return 1
}

ad_proc -private hfl_problem_server_traffic {
    asset_id
    monitor_id
    instance_id
} {
    Returns cpu health. This is a example local procedure for testing a phantom problem server.
} {
    upvar 1 asset_prop_arr obj_arr

    # Get traffic

    # permissions ck
    hfl_allow_q
    # Using 1 week ( 7*24*3600=604800 second ) cycles.
    # If a day passes in 7 hours, then a week in 49 hours.
    # If a day passes in 3 hours, then a week in 21 hours ( 75600 seconds). 
    # A 24 hour test cycle should provide
    # sufficient resolution to detect bugs.
    # The cycle can start most anywhere in the timeline.

    set cycle_s 75600
    #expr acos(0) * 2.=
    set twopi 3.141592653589793
    set one_7th 0.14285714285714285 
    set time_s [clock seconds]
    set cycle_t [expr { fmod( $time_s + $one_7th * $cycle_s , $cycle_s ) } ]
    set t_pct [expr { $cycle_t / $cycle_s } ]
    set k [expr { $cycle_t * $twopi } ]
    set h0 [expr { sin( $k / $cycle_s ) } ]
    set cycle_7_s [expr { $cycle_s / 7. } ]
    set cycle_3_s [expr { $cycle_7_s * 3. } ]

    set h0 [expr { 5 * sin( $k / $cycle_s ) } ]
    set h1 [expr { sin( $k / $cycle_7_s ) } ]
    set h2 [expr { sin( $k / $cycle_3_s + $one_7th ) / 5. } ]
    set h3 [expr { sin( $k / $cycle_7_s + $one_7th * 2. ) / 5. } ]
    set h4 [expr { sin( $k / $cycle_3_s + $one_7th * 3. ) / 5. } ]
    set h5 [expr { sin( $k / $cycle_3_s + $one_7th * 4. ) / 5. } ]
    set h6 [expr { sin( $k / $cycle_7_s + $one_7th * 5. ) / 5. } ]
    set noise [expr { pow( ( [random] - .5 ) * 3. , 2. ) } ]
    set health [expr { 50. + 14 * ( $h0 + $h1 + $h2 + $h3 + $h4 + $h5 + $h6 ) + $noise } ]
    set health [f::max 0 $health]

    # A healthy signal amplitude is somewhere between 1 and 99, ie 7 * 7 * 2

    # In addition to sin, and cos, acc_fin::pos_sine_cycle, thrashing can be simulated with fibonacci or 
    # other progression as factor for example.

    hf_monitor_update $asset_id $monitor_id hfl_system_memory $health $report "" "" $instance_id
    return 1
}


ad_proc -private hfl_assets_allowed_by_user {
    set asset_type_id_list [list hw vm vh ss ]
    return $asset_type_id_list
}

ad_proc -private hfl_attributes_allowed_by_user {
    set asset_type_id_list [list vh ns ss ua ]
    return $asset_type_id_list
}