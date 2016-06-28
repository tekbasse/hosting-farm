ad_library {
    Automated tests for hosting-farm
    @creation-date 2015-03-19
}

aa_register_case -cats {api smoke} permissions_check {
    Test hf_permissions_p proc for all cases
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {
            
            ns_log Notice "aa_register_case.13: Begin test permissions_check"
            # Use default permissions provided by tcl/hosting-farm-init.tcl
            set instance_id ""
            
            
            #aa_true "Test for .." $passed_p
            #aa_equals "Test for .." $test_value $expected_value
            
        }
}
