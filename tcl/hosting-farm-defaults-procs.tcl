#hosting-farm/tcl/hosting-farm-defaults-procs.tcl
ad_library {

    misc API for hosting-farm defaults
    @creation-date 6 June 2016
    @Copyright (c) 2016 Benjamin Brink
    @license GNU General Public License 2,
    @see project home or http://www.gnu.org/licenses/gpl-2.0.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com
    

}


ad_proc -private hf_ss_defaults {
    array_name
} {
    Sets defaults for an hf_service record into array_name
    if element does not yet exist in array. 
} {
    upvar 1 $array_name ss_arr
    upvar 1 instance_id instance_id
    set ss [list instance_id $instance_id \
                ss_id "" \
                server_name  \
                service_name $name \
                daemon_ref $ss_nsd_file \
                protocol "http" \
                port $http_port \
                ss_type "" \
                ss_subtype "" \
                ss_undersubtype "" \
                ss_ultrasubtype "" \
                config_uri $ss_config_file \
                memory_bytes "" \
                details ""\
                time_trashed ""\
                time_created $nowts]
    foreach {key value} $ss {
        if { ![info exists ss_arr(${key}) ] } {
            set ss_arr(${key}) $value
        }
    }
    if { [llength [set_difference_named_v ss [hf_ss_keys]]] > 0 } {
        ns_log Warning "hf_ss_defaults: Update this proc. \
It is out of sync with hf_ss_keys"
    }
    return 1
}

hf_sub_asset_map_defaults {
    { attribute_p "1" }
} {
    upvar 1 $array_name sam_arr
    upvar 1 instance_id instance_id
    set sam_list [list f_id "" \
                      type_id "" \
                      sub_f_id "" \
                      sub_type_id "" \
                      sub_sort_order "" \
                      sub_label "" \
                      attribute_p $attribute_p \
                      trashed_p "" ]
    foreach {key value} $sam {
        if { ![info exists sam_arr(${key}) ] } {
            set sam_arr(${key}) $value
        }
    }
    return 1
}


