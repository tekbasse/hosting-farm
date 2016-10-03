# hosting-farm/tcl/hosting-farm-init.tcl


# Default initialization?  check at server startup (here)

#    @creation-date 2016-05-05
#    @Copyright (c) 2016 Benjamin Brink
#    @license GNU General Public License 2.
#    @see project home or http://www.gnu.org/licenses/gpl-2.0.html
#    @project home: http://github.com/tekbasse/hosting-farm
#    @address: po box 20, Marylhurst, OR 97036-0020 usa
#    @email: tekbasse@yahoo.com


set instance_id 0
#ns_log Notice "hosting-farm/tcl/hosting-farm-init.tcl.16: begin"
if { [catch { set instance_id [apm_package_id_from_key hosting-farm] } error_txt] } {
    # more than one instance exists
    set instance_id 0
    #ns_log Notice "hosting-farm/tcl/hosting-farm-init.tcl.20: More than one instance exists. skipping."
} elseif { $instance_id != 0 } {
    # only one instance of hosting-farm exists.
} else {
    # package_id = 0, no instance exists
    # empty string converts to null for integers in db api
    set instance_id ""

}
ns_log Notice "hosting-farm/tcl/hosting-farm-init.tcl.29: instance_id '${instance_id}' "
if { $instance_id != 0 } {
    # If this is this the first run, add some defaults.
    if { [llength [qc_roles $instance_id]] == 0 } {
        hf_roles_init $instance_id
        hf_property_init $instance_id
        hf_privilege_init $instance_id
        hf_asset_type_id_init $instance_id
        # add defaults for no instance_id also
        set instance_id ""
        hf_roles_init $instance_id
        hf_property_init $instance_id
        hf_privilege_init $instance_id
        hf_asset_type_id_init $instance_id
    }
}
