ad_library {
    Automated tests for hosting-farm
    @creation-date 2015-03-19
}

aa_register_case -cats {api smoke} scramble_check {
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
            ns_log Notice "hosting-farm-coded-procs.tcl.17: c $c"
            set d [string length $c]
            incr d
            append c $c
            # word_len set to 8, so all end string chars are tested also.
            set j 8
            # Ideally, every combo of two letters should be tested 
            # at beginning and end of string
            set word_len 9
            for {set i 1} {$i < $d} {incr i} {
                # set word_len [randomRange 20]
                # incr word_len
                set j [expr { $word_len + $i } ]
                set word [string range $c $i $j]
                set drow [hf_encode $word]
                set id [db_nextval hf_id_seq]
                set drow_arr(${id}) $word
                db_dml hf_test_hf_ua_i { insert into hf_up (up_id,details) values (:id,:drow) }
            }
            foreach up_id [array names drow_arr] {
                db_1row hf_test_hf_ua_r { select details from hf_up where up_id=:up_id }
                set guess [hf_decode $details]
                aa_equals "Word ${word} coded decoded" $guess $drow_arr(${up_id})
            }
        } 
    # -teardown_code {
    # 
    #acs_user::delete -user_id $user1_arr(user_id) -permanent
    
    # }
    #aa_true "Test for .." $passed_p
    #aa_equals "Test for .." $test_value $expected_value
}    

