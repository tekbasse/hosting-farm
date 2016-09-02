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
        if { $f_id_of_asset_id eq "" } {
            ns_log Notice "hf_constructor_a.91: f_id_of_asset_id is '' for asset_id '${asset_id}', setting asset_id ''"
            set asset_id ""
        } else {
            set asset_id_p 1
        }
    }

    # determine primary_attr_id
    set primary_attr_id ""
    if { $asset_id_p } {
        set primary_attr_id [hf_asset_primary_attr $asset_id]
    }

    # determine sub_asset_id_p
    if { $sub_f_id ne "" || $primary_attr_id ne "" } {
        set sub_f_id_supplied_p 1
        set sub_f_id [qal_first_nonempty_in_list [list $sub_f_id $primary_attr_id]]
        set sub_list [hf_sub_asset $sub_f_id $f_id]
        if { [llength $sub_list] > 0 } {
            qf_lists_to_array sub_arr $sub_list [hf_sub_asset_map_keys]
            if { [qf_is_true $sub_arr(trashed_p)] } {
                # sub_f_id is not current 
                # do not use.
                ns_log Warning "hf_constructor_a.112: sub_f_id '${sub_f_id}' is trashed. Setting sub_f_id ''"
                set sub_f_id ""
            } else {
                if { $f_id ne "" } {
                    set asset_f_id [hf_asset_f_id_of_sub_f_id $sub_f_id]
                    if { $sub_arr(f_id) eq $f_id || $asset_f_id eq $f_id } {
                        set sub_asset_id_p 1
                        array set an_arr [array get sub_arr]
                    } else {
                        ns_log Warning "hf_constructor_a.122: Unexpected f_id '${f_id}' s/b '${asset_f_id}' or '$sub_arr(f_id)' Setting to ''"
                        set f_id ""
                        set sub_f_id ""
                    }
                }
            }
        } else {
            ns_log Warning "hf_constructor_a.130: hf_sub_asset sub_f_id '${sub_f_id}' f_id '${f_id}' not found, but expected."
        }
    }


    # determine sub_is_primary_p
    if { $sub_asset_id_p && $asset_id_p && ( $primary_attr_id eq $sub_f_id ) } {
        set sub_f_id_is_primary_p 1
    }

    # determine asset_type_id_p
    if { $sub_asset_id_p == 0 && $asset_id_p == 0 } {
        if { $asset_type_id in [hf_asset_type_id_list] } {
            set asset_type_id_p 1
        } 
    }
    # determine type_id_p
    set an_type_id ""
    set an_type_id_p [info exists an_arr(type_id) ]
    if { $an_type_id_p } {
        if { $an_arr(type_id) in [hf_asset_type_id_list] } {
            set an_type_id $an_arr(type_id)
        } else {
            #  set an_type_id ""
            set an_type_id_p 0
        }
    }
    if { !$an_type_id_p && $asset_type_id_p } {
        set an_type_id $asset_type_id
        set an_type_id_p 1
    }

    # determine sub_type_id_p
    set an_sub_type_id ""
    set an_sub_type_id_p [info exists an_arr(sub_type_id)]
    if { $an_sub_type_id_p } {
        if { $an_arr(sub_type_id) in [hf_asset_type_id_list] } {
            set an_sub_type_id $an_arr(sub_type_id)
        } else {
            #   set an_sub_type_id ""
            ns_log Warning "hf_constructor_a.172: an_arr(sub_type_id) '$an_arr(sub_type_id)' setting to ''."
            set an_sub_type_id_p 0
            set an_arr(sub_type_id) ""
        }
    }

    # Default to most specific case.
    set state ""
    set state_old $state

    # sanity check
    if { $an_type_id_p && $asset_type_id_p } {
        if { $an_type_id ne $asset_type_id } {
            ns_log Warning "hf_constructor_a.178: an_type_id '${an_type_id} != asset_type_id '${asset_type_id}'. \
 state must be 'attr_only'"
            set state "attr_only"
        }
    }

    if { $state eq "" } {
        if { $sub_f_id_is_primary_p } {
            set state "asset_primary_attr"
            ns_log Notice "hf_constructor_a.188"
        } elseif { $sub_asset_id_p && $asset_id_p } {
            set state "asset_attr"
            ns_log Notice "hf_constructor_a.191"
        } elseif { $sub_asset_id_p } {
            set state "attr_only" 
            ns_log Notice "hf_constructor_a.194"
        } elseif { $asset_id_p } {
            # see *_supplied_p vars for intention.
            if { $sub_f_id_supplied_p && $asset_type_id_p } {
                # assume there was a problem with sub_f_id
                # offer a new attribute of same type
                set state "asset_attr"
                ns_log Notice "hf_constructor_a.197"
            } else {
                if { $primary_attr_id ne "" } {
                    ns_log Notice "hf_constructor_a.160 asset info supplied as asset_only, but has primary attribute. set state 'asset_primary_attr'"
                    set state "asset_primary_attr"
                    set sub_f_id $primary_attr_id
                    set an_arr(sub_f_id) $primary_attr_id
                    set f_id $f_id_of_asset_id
                    if { [info exists sub_arr(f_id)] } {
                        set an_arr(f_id) $sub_arr(f_id)
                    }
                    if { [info exists sub_arr(sub_type_id) ] } {
                        set asset_type_id $sub_arr(sub_type_id)
                    }
                    set an_arr(sub_type_id) $asset_type_id
                    set an_arr(type_id) $asset_type_id
                } else {
                    set state "asset_only"
                    ns_log Notice "hf_constructor_a.209"
                }
            }
        } elseif { $asset_type_id_p && ( $asset_id_supplied_p || $sub_f_id_supplied_p ) } {
            # see *_supplied_p vars for intention.
            if { $asset_id_supplied_p && $sub_f_id_supplied_p } {
                if { $an_sub_type_id_p && $an_type_id_p } {
                    if { $an_sub_type_id eq $an_type_id } {
                        set state "asset_primary_attr"
                        ns_log Notice "hf_constructor_a.210"
                    } else {
                        set state "asset_attr"
                        ns_log Notice "hf_constructor_a.220"
                    }
                }
            } elseif { $sub_f_id_supplied_p } {
                set state "attr_only"
                ns_log Notice "hf_constructor_a.232"
            } elseif { $asset_id_supplied_p } {
                set state "asset_only"
                ns_log Notice "hf_constructor_a.235"
            } else {
                # create a blank asset_primary_attr
                set state "asset_primary_attr"
                ns_log Notice "hf_constructor_a.239"
            }
        } elseif { $an_type_id_p || $an_sub_type_id_p } {
            #ns_log Notice "hf_constructor_a.232: an_type_id_p '${an_type_id_p}' an_sub_type_id_p '${an_sub_type_id_p}' an_type_id '${an_type_id}' an_sub_type_id '${an_sub_type_id}' "
            if { $an_type_id_p && $an_sub_type_id_p } {
                if { $an_type_id eq $an_sub_type_id } {
                    # must be new, so primary
                    set state "asset_primary_attr"
                ns_log Notice "hf_constructor_a.247"
                } else { 
                    set state "asset_attr"
                    ns_log Notice "hf_constructor_a.239: an_type_id '${an_type_id}' an_sub_type_id '${an_sub_type_id}'"
                }
            } elseif { $an_type_id_p } {
                set state "asset_only" 
                ns_log Notice "hf_constructor_a.241"
            } elseif { $an_sub_type_id_p } {
                set state "attr_only"
                ns_log Notice "hf_constructor_a.243"
            } elseif { $state eq "" } {
                ns_log Warning "hf_constructor_a.246: array type_id and/or sub_type_id not valid. \
 type_id '${an_type_id}' sub_type_id '${an_sub_type_id}'. Both set to ''"
                set an_arr(sub_type_id) ""
                set an_arr(type_id) ""
            }
        } else {
            if { $arg1 eq "default" } {
                if { $state eq "" } {
                    if { $arg2 in [list asset_primary_attr asset_attr attr_only asset_only] } {
                        set state $arg2
                        ns_log Notice "hf_constructor_a.256: using default asset_type arg2 '${arg2}'"
                        if { $asset_type_id eq "" } {
                            if { $arg3 in [hf_asset_type_id_list] } {
                                ns_log Notice "hf_constructor_a.259: using default asset_type_id/arg3 '${arg3}'"
                                set asset_type_id $arg3
                            } elseif { $arg3 ne "" } {
                                ns_log Warning "hf_constructor_a.262: arg3 '${arg3}' not valid."
                                set arg3 ""
                            }
                        }
                    } else {
                        ns_log Warning "hf_constructor_a.267: arg2 '${arg2}' not valid"
                    }
                }
            } 
            # provide default default
            if { $state eq "" } {
                set state "attr_only"
                ns_log Notice "hf_constructor_a.274: using default default ie asset_type 'attr_only'"
            }
        }
    }
    if { $arg1 eq "force" } {
        # only makes sense when asset_only, attr_only, or asset_primary_attr
        if { $state ne $arg2 } {
            set state_old $state
            set state $arg2
            ns_log Notice "hf_constructor_a.283: state forced from '${state_old}' to '${arg2}'"
            # set state_forced_p 1
        }
        if { $asset_type_id ne $arg3 } {
            if { $arg3 in [hf_asset_type_id_list] } {
                set asset_type_id_old $asset_type_id
                set asset_type_id $arg3
                ns_log Notice "hf_constructor_a.290: asset_type_id forced from '${asset_type_id_old}' to '${arg3}'"
            } elseif { $arg3 ne "" } {
                ns_log Warning "hf_constructor_a.292: asset_type_id supplied by force '${arg3}' is not valid"
                set arg3 ""
            }
            # set asset_type_id_forced_p 1
        }
    }

    # fill array, track keys for removing dangler keys
    set keys_list [list ]
    if { [string match "*asset*" $state] } {
        hf_asset_defaults an_arr
        set an_arr(asset_type_id) $asset_type_id
        set keys_list [set_union $keys_list [hf_asset_keys]]
    }
    if { [string match "*attr*" $state] } {
        if { $asset_type_id in [hf_asset_type_id_list] } {
            # substitution in command avoids a long switch
            hf_${asset_type_id}_defaults an_arr
            if { $arg1 eq "force" && $arg3 ne "" } {
                set an_arr(type_id) $asset_type_id
            }
            set keys_list [set_union $keys_list [hf_${asset_type_id}_keys]]
            hf_sub_asset_map_defaults an_arr
            if { $state eq "asset_primary_attr" } {
                set an_arr(attribute_p) 0
            }
            if { $arg1 eq "force" && $arg3 ne "" } {
                set an_arr(sub_type_id) $asset_type_id
            }
            set keys_list [set_union $keys_list [hf_sub_asset_map_keys]]
        } else {
            # attr_only
            set sub_type_id ""
            if { $an_sub_type_id_p } {
                set sub_type_id $an_arr(sub_type_id)
            }
            if { [info exists sub_arr(sub_type_id) ] } {
                set sub_type_id $sub_arr(sub_type_id)
            }
            if { $arg1 eq "force" && $arg3 ne "" } {
                set sub_type_id $arg3
            }
            if { $sub_type_id in [hf_asset_type_id_list] } {
                # attr_only
                hf_${sub_type_id}_defaults an_arr
                set keys_list [set_union $keys_list [hf_${sub_type_id}_keys]]
                hf_sub_asset_map_defaults an_arr
                set keys_list [set_union $keys_list [hf_sub_asset_map_keys]]
                
            } else {
                
                ns_log Warning "hf_constructor_a.340: unknown asset_type_id '${asset_type_id}', sub_type_id '${sub_type_id}'  ad_script_abort"
                ad_script_abort
            }
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
    #ns_log Notice "hf_constructor_a.357: array get ${a_arr_name} '[array get an_arr]'"
    return $state
}

ad_proc -public hf_constructor_b {
    a_array_name
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
    and populates <code>a_array_name</code> with relevant data.
    </p><p>
    If <code>asset_type_id</code>, is not available, and nothing qualifies,
    <code>a_array_name</code> is populated with hf_asset defaults and 
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
    upvar 1 $a_array_name yan_arr
    upvar 1 instance_id instance_id
    upvar 1 asset_id asset_id
    upvar 1 f_id f_id
    upvar 1 sub_f_id sub_f_id
    upvar 1 asset_type_id asset_type_id
    upvar 1 user_id user_id

    set asset_type [hf_constructor_a yan_arr $arg1 $arg2 $arg3]
    #ns_log Notice "hf_constructor_b.413: asset_type '${asset_type}'"
    if { $asset_id ne "" && $f_id ne "" } {
        set asset_id_old $asset_id
        set asset_id [hf_asset_id_of_f_id_if_untrashed $f_id]
        if { $asset_id ne $asset_id_old } {
            ns_log Warning "hf_constructor_b.418: asset_id changed from '${asset_id_old}' to '${asset_id}'"
        }
    }
    if { $asset_id ne "" } {
        set asset_list [hf_asset_read $asset_id]
        ns_log Notice "hf_constructor_b.423: asset_list '${asset_list}'"
        set hf_asset_keys_list [hf_asset_keys]
        set result_list [qf_lists_to_array yan_arr $asset_list $hf_asset_keys_list]
        if { [llength $asset_list] != [llength $hf_asset_keys_list] || [llength $result_list] > 0 } {
            ns_log Warning "hf_constructor_b.427: asset_list length differs from hf_asset_keys"
        }
        #array set yan_arr \[array get yan2_arr\]
    } 
    if { [string match "*asset*" $asset_type] && ![exists_and_not_null yan_arr(asset_id) ] } {
        ns_log Warning "hf_constructor_b.432: asset_id '${asset_id}' not set in ${a_array_name}.\
 array get: '[array get yan_arr]'"

    }
    if { $sub_f_id eq "" && [exists_and_not_null yan_arr(sub_f_id) ] } {
        set sub_f_id $yan_arr(sub_f_id)
    }
    if { $sub_f_id ne "" } {
        if { $f_id eq "" && [exists_and_not_null yan_arr(f_id) ] } {
            set f_id $yan_arr(f_id)
        }
        set sub_asset_map_list [hf_sub_asset $sub_f_id $f_id]
        qf_lists_to_array yan_arr $sub_asset_map_list [hf_sub_asset_map_keys]
        set sub_type_id $yan_arr(sub_type_id)
        if { $sub_type_id in [hf_asset_type_id_list] } {
            set sub_asset_list [hf_${sub_type_id}_read $sub_f_id]
            qf_lists_to_array yan_arr $sub_asset_list [hf_${sub_type_id}_keys]
        } else {
            ns_log Warning "hf_constructor_b.450: sub_type_id not valid '${sub_type_id}'"
        }
    }
    if { [string match "*attr*" $asset_type ] && ![exists_and_not_null yan_arr(sub_f_id) ] } {
        ns_log Warning "hf_constructor_b.454: sub_f_id '${sub_f_id}' not set in ${a_array_name}.\
 array get: '[array get yan_arr]'"
    }
    return $asset_type
}
