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
    set $a $a
    unset a
    upvar 1 $a $a
}

ad_proc -private hf_nc_proc_in_context_q {
    {namespace_name "hf::monitor"}
} {
    Checks if a scheduled proc is running in context of its namespace.
} {
    # To work as expected, each proc in namespace must call this function
    set a [ns_thread id]
    upvar 2 $a $a
    ns_log Notice "acs_nc_proc_in_context_q: local vars [info vars]"
    if { ![info exists $a] || ![info exists ::${namespace_name}::$a] || [set $a] ne [set ::${namespace_name}::$a]} {
        ns_log Warning "acs_nc_proc_in_context_q: namespace '${namespace_name}' no! ns_thread id '${a}'"
        #ad_script_abort
        set context_p 0
    } else {
        upvar 1 $a $a
        set context_p 1
    }
    return $context_p
}

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
