#hosting-farm/tcl/hosting-farm-biz-procs.tcl
ad_library {

    business logic for Hosting Farm
    @creation-date 17 Jun 2016
    @Copyright (c) 2014-2016 Benjamin Brink
    @license GNU General Public License 2
    @see project home or http://www.gnu.org/licenses/gpl-2.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com
}

ad_proc -public hf_constructor_a {
    a_arr_name
    {arg1 ""}
    {arg2 ""}
    {arg3 ""}
} {
    <p>
    Examines available asset and attr references in array: 
    ( <code>asset_id f_id sub_asset_id sub_f_id</code>) and <code>asset_type_id</code>.
    </p><p>
    Returns state of hf object from user perspective:
    <code>asset_only asset_attr asset_primary_attr attr_only</code>
    </p><ul><li>
    <code>asset_only</code>:         Only contains an hf_assets record. Not related attribute.
    </li><li>
    <code>asset_attr</code>:         Combination of asset and one attribute.
    </li><li>
    <code>asset_primary_attr</code>: This is the asset with its primary attribute.
    </li><li>
    <code>attr_only</code>:          This is an attribute record without corresponding asset.
    </li></ul><p>
    and populates <code>a_arr_name</code> with defaults if data is missing, but will
    not populate with data from db.
    </p><p>
    If <code>asset_type_id</code>, is not available, and nothing qualifies,
    <code>a_arr_name</code> is populated with hf_asset defaults and 
    empty string for asset_type_id.
    </p><p>
    If arg1 is "default" and arg2 is one of the states,
    then if no state is determined that includes attr or asset, then
    constructor will fill missing data to fit arg2 state.
    If existing asset_type_id is unavailable, then asset_type_id will
    be set to value supplied by arg3
    </p><p>
    If arg1 is "force" and arg2 is one of the states, 
    then constructor  will analyze existing state, 
    and force state accordingly by
    either adding missing or defaults, or unset related info
    and return force_state as the state. If arg3 is set to an asset_type_id,
    state will be forced to the arg3 asset_type_id instead of
    any existing asset_type_id.
    </p>
    @return a string: asset_only asset_attr asset_primary_attr attr_only
} {
    upvar 1 $a_arr_name an_arr
    upvar 1 instance_id instance_id
    upvar 1 asset_id asset_id
    upvar 1 f_id f_id
    upvar 1 sub_f_id sub_f_id
    upvar 1 asset_type_id asset_type_id


    # This is a paradigm of combining an asset and/or attribute
    # Consider creating an hf_constructor_b etc. if you
    # want a different way of combining an total asset object.
    # See also the hf_asset_properties for another paradigm
    # used by non UI hf_nc_* system.

    # validate for cases

    # Cases to consider, depending on vars:
    #   asset_type_id   f_id   sub_f_id
    set asset_type_id_p 0
    set asset_id_p 0
    set sub_asset_id_p 0
    set sub_f_id_is_primary_p 0
    set asset_id_supplied_p 0
    set sub_f_id_supplied_p 0
    # set state_forced_p 0
    # set asset_type_id_forced_p 0
    
    # determine asset_id_p
    set f_id_of_asset_id ""
    if { $asset_id ne "" } {
        set asset_id_supplied_p 1
        set f_id_of_asset_id [hf_f_id_of_asset_id $asset_id]
    }
    if { $f_id_of_asset_id eq "" } {
        ns_log Notice "hf_constructor_a: f_id_of_asset_id is '', setting asset_id ''"
        set asset_id ""

    } else {
        set asset_id_p 1
    }

    # determine sub_asset_id_p
    if { $sub_f_id ne "" } {
        set sub_f_id_supplied_p 1
        set sub_list [hf_sub_asset $sub_f_id $f_id]
        qf_lists_to_array sub_arr $sub_list [hf_sub_asset_map_keys]
        if { $sub_arr(trashed_p) } {
            # sub_f_id is not current 
            # do not use.
            set sub_f_id ""
        }
        if { $sub_arr(trashed_p) == 0 } {
            if { $f_id ne "" && $sub_arr(f_id) eq $f_id } {
                set sub_asset_id_p 1
            } else {
                set f_id ""
                set sub_f_id ""
            }
        }
    }

    # determine sub_is_primary_p
    if { $sub_asset_id_p && $asset_id_p } {
        set sub_f_id_primary [hf_asset_primary_attr $asset_id]
        if { $sub_f_id_primary eq $sub_f_id } {
            set sub_f_id_is_primary_p 1
        }
    }

    # determine asset_type_id_p
    if { $sub_asset_id_p == 0 && $asset_id_p == 0 } {
        if { $asset_type_id ne "" } {
            set asset_type_id_p 1
        } else {
            set asset_type_id ""
        }
    }

    # Default to most specific case.
    set state ""
    set state_old $state

    if { $sub_f_id_is_primary_p } {
        set state "asset_primary_attr"
    } elseif { $sub_asset_id_p && $asset_id_p } {
        set state "asset_attr"
    } elseif { $sub_asset_id_p } {
        set state "attr_only" 
    } elseif { $asset_id_p } {
        # see *_supplied_p vars for intention.
        if { $sub_f_id_supplied_p && $asset_type_id_p } {
            # assume there was a problem with sub_f_id
            # offer a new attribute of same type
            set state "asset_attr"
        } else {
            set state "asset_only"
        }
    } elseif { $asset_type_id_p } {
        # see *_supplied_p vars for intention.
        if { $asset_id_supplied_p && $sub_f_id_supplied_p } {
            set state "asset_attr"
        } elseif { $sub_f_id_supplied_p } {
            set state "attr_only"
        } elseif { $asset_id_supplied_p } {
            set state "asset_only"
        } else {
            # create a blank asset_primary_attr
            set state "asset_primary_attr"
        }
    } else {
        if { $arg1 eq "default" } {
            ns_log Notice "hf_constructor_a.156: using default arg2 '${arg2}' arg3 '${arg3}'"
            set asset_type_id $arg3
            if { $state eq "" } {
                set state $arg2
            }
        } 
        # provide default default
        if { $state eq "" } {
            set state "attr_only"
            ns_log Notice "hf_constructor_a.164: using default default"
        }
    }

    if { $arg1 eq "force" } {
        if { $state ne $arg2 } {
            set state_old $state
            set state $arg2
            # set state_forced_p 1
        }
        if { $asset_type_id ne $arg3 } {
            set asset_type_id_old $asset_type_id
            set asset_type_id $arg3
            # set asset_type_id_forced_p 1
        }
    } 

    # fill array, track keys for removing dangler keys
    set keys_list [list ]
    if { [string match "*asset*" $state] } {
        hf_asset_defaults an_arr
        set keys_list [set_union $keys_list [hf_asset_keys]]
    }
    if { [string match "*attr*" $state] } {
        if { $asset_type_id in [hf_asset_type_id_list] } {
            # substitution in command avoids a long switch
            hf_${asset_type_id}_defaults an_arr
            set keys_list [set_union $keys_list [hf_${asset_type_id}_keys]]
            hf_sub_asset_map_defaults an_arr
            set keys_list [set_union $keys_list [hf_sub_asset_map_keys]]
        } else {
            ns_log Warning "hf_constructor_a.193: unknown asset_type_id '${asset_type_id}'"
            ad_script_abort
        }
    }
    # Remove any unconstructed keys
    # For the sake a neurotic/paranoid security feature, and/or expected housekeeping
    set arr_keys_list [array names an_arr]
    set_difference_named_v arr_keys_list $keys_list
    foreach arr_key $arr_keys_list {
        array unset an_arr $arr_key
    }

    if { $f_id eq "" && $asset_id ne "" } {
        # maybe save a trip to db to get f_id
        set f_id $f_id_of_asset_id
    }
    return $state
}

ad_proc -public hf_constructor_b {
    a_arr_name
    {arg1 ""}
    {arg2 ""}
    {arg3 ""}
} {
    <p>
    Examines available asset and attr references in array: 
    ( <code>asset_id f_id sub_asset_id sub_f_id</code>) and <code>asset_type_id</code>.
    </p><p>
    Returns state of hf object from user perspective:
    <code>asset_only asset_attr asset_primary_attr attr_only</code>
    </p><ul><li>
    <code>asset_only</code>:         Only contains an hf_assets record. Not related attribute.
    </li><li>
    <code>asset_attr</code>:         Combination of asset and one attribute.
    </li><li>
    <code>asset_primary_attr</code>: This is the asset with its primary attribute.
    </li><li>
    <code>attr_only</code>:          This is an attribute record without corresponding asset.
    </li></ul><p>
    and populates <code>a_arr_name</code> with relevant data.
    </p><p>
    If <code>asset_type_id</code>, is not available, and nothing qualifies,
    <code>a_arr_name</code> is populated with hf_asset defaults and 
    empty string for asset_type_id.
    </p><p>
    If arg1 is "default" and arg2 is one of the states,
    then if no state is determined that includes attr or asset, then
    constructor will fill missing data to fit arg2 state.
    If existing asset_type_id is unavailable, then asset_type_id will
    be set to value supplied by arg3
    </p><p>
    If arg1 is "force" and arg2 is one of the states, 
    then constructor  will analyze existing state, 
    and force state accordingly by
    either adding missing or defaults, or unset related info
    and return force_state as the state. If arg3 is set to an asset_type_id,
    state will be forced to the arg3 asset_type_id instead of
    any existing asset_type_id.
    </p>
    @return a string: asset_only asset_attr asset_primary_attr attr_only
} {
    upvar 1 $a_arr_name an_arr
    upvar 1 instance_id instance_id
    upvar 1 asset_id asset_id
    upvar 1 f_id f_id
    upvar 1 sub_f_id sub_f_id
    upvar 1 asset_type_id asset_type_id

    set asset_type [hf_constructor_a obj_arr $arg1 $arg2 $arg3]
    
    if { $asset_id ne "" && $f_id ne "" } {
        set asset_id_old $asset_id
        set asset_id [hf_asset_id_of_f_id_if_untrashed $f_id]
        if { $asset_id ne $asset_id_old } {
            ns_log Notice "hf_constructor_b.282: asset_id changed from '${asset_id_old}' to '${asset_id}'"
        }
    }
    if { $asset_id ne "" } {
        set asset_list [hf_asset_read $asset_id]
        qf_lists_to_array obj_arr $asset_list [hf_asset_keys]
    }
    if { $sub_f_id ne "" } {
        set sub_asset_map_list [hf_sub_asset $sub_f_id $f_id]
        qf_lists_to_array obj_arr $sub_asset_map_list [hf_sub_asset_map_keys]
        if { $sub_type_id in [hf_asset_type_id_list] } {
            set sub_asset_list [hf_${sub_type_id}_read $sub_f_id]
            qf_lists_to_array obj_arr $sub_asset_list [hf_${sub_type_id}_keys]
        }
    }
    return $asset_type
}
