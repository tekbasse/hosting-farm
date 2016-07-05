ad_library {
    Automated tests for hosting-farm
    @creation-date 2015-03-19
}

aa_register_case -cats {api smoke} decode_encoded_check {
    Test encoding decoding api
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {
            ns_log Notice "aa_register_case.12: Begin test decode_encoded_check"
            # Use default permissions provided by tcl/hosting-farm-init.tcl
            # Yet, users must have read access permissions or test fails
            # Some tests will fail (predictably) in a hardened system
            set c [hf_chars "" 1]
            append c $c
            set d [string length $c]
            for {set i 1} {$i < $c} {incr i} {
                set word_len [randomRange 20]
                incr word_len
                set j [expr { $word_len + $i } ]
                set word [string range $c $i $j]
                set drow [hf_encode $word]
                set guess [hf_decode $drow]
                aa_equals "Word ${word} coded decoded" $guess $word 
            }
            
        } 
#        -teardown_code {
            # 
            #acs_user::delete -user_id $user1_arr(user_id) -permanent

#        }
    #aa_true "Test for .." $passed_p
    #aa_equals "Test for .." $test_value $expected_value


}
