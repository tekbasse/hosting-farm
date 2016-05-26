#hosting-farm/tcl/hosting-farm-asset-util-procs.tcl
ad_library {

    utilities for hosting-farm assets
    @creation-date 25 May 2013
    @Copyright (c) 2014-2016 Benjamin Brink
    @license GNU General Public License 2, see project home or http://www.gnu.org/licenses/gpl-2.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com


}


ad_proc -private hf_nc_proc_context_set {
} {
    Set floating context
} {
    set a [ns_thread id]
    upvar 1 $a b
    set b $a
    set n "::hf::monitor::do::"
    set ${n}${a} $a
    ns_log Notice "hf_nc_proc_context_set: context set: '${a}' info level '[info level]' namespace current '[namespace current]'"
    return 1
}

ad_proc -private hf_nc_proc_in_context_q {
    {namespace_name "::hf::monitor::do::"}
} {
    Checks if a scheduled proc is running in context of its namespace.
} {
    #    {namespace_name "::"}
    # To work as expected, each proc in namespace must call this function
    set a [ns_thread id]
    upvar 3 $a $a
    #ns_log Notice "acs_nc_proc_in_context_q: local vars [info vars]"
    if { ![info exists $a] || ![info exists ${namespace_name}${a} ] || [set $a] ne [set ${namespace_name}${a} ]} {
        ns_log Warning "hf_nc_proc_in_context_q: namespace '${namespace_name}' no! ns_thread id '${a}' info level '[info level]' namespace current '[namespace current]' "
       # ns_log Notice "::${a} [info exists ::${a}] "
       # ns_log Notice "::hf::${a} [info exists ::hf::${a}] "
       # ns_log Notice "::hf::monitor::${a} [info exists ::hf::monitor::${a}] "
       # ns_log Notice "::hf::monitor::do::${a} [info exists ::hf::monitor::do::${a}] "
       # ns_log Warning " set ${namespace_name}$a '[set ${namespace_name}${a} ]'"
        #ad_script_abort
        set context_p 0
    } else {
        upvar 2 $a $a
        set context_p 1
    }
    #ns_log Notice "hf_nc_proc_in_context_q: ns_thread name [ns_thread name] ns_thread id [ns_thread id] ns_info threads [ns_info threads] ns_info scheduled [ns_info scheduled]"
    return $context_p
}

#ad_proc -private hf_nc_proc_that_tests_context_checking {
#} {
#    This is a dummy proc that checks if context checker is working.
#} {
#    ns_log Notice "hf_nc_proc_that_tests_context_checking: info level '[info level]' namespace current '[namespace current]'"
#    set allowed_p [hf_nc_go_ahead ]
#    ns_log Notice "hf_nc_proc_that_tests_context_checking: context check. PASSED."
#}

#ad_proc -private hf_check_randoms {
#    {context ""}
#} {
#    Compares output of random functions, to see if there is a difference 
#    when run in scheduled threads vs. connected threads.
#} {
#    set a [expr { srand(round(fmod([clock clicks],[clock seconds]))) } ]
#    ns_log Notice "hf_check_randoms: context [ns_thread name]: ${context}"
#    ns_log Notice "hf_check_randoms: clock clicks '[clock clicks]' '[clock clicks]' '[clock clicks]'"
#     ns_log Notice "hf_check_randoms: clock seconds '[clock seconds]' '[clock seconds]' '[clock seconds]'"
#    ns_log Notice "hf_check_randoms: srand '[expr { srand(round(fmod([clock clicks],[clock seconds]))) } ]' '[expr { srand(round(fmod([clock clicks],[clock seconds]))) } ]' '[expr { srand(round(fmod([clock clicks],[clock seconds]))) } ]'"
#    ns_log Notice "hf_check_randoms: rand '[expr { rand() } ]' '[expr { rand() } ]' '[expr { rand() } ]'"
#    ns_log Notice "hf_check_randoms: random '[random]' '[random]' '[random]'"
#}
