
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

            regsub -all -- {[\[;]} $c "" c
            set d [string length $c]
            incr d
            append c $c
            # word_len set to 8, so all end string chars are tested also.
            # Ideally, every combo of two letters should be tested 
            # at beginning and end of string
            set instance_id [ad_conn package_id]
            set encode_proc [parameter::get -package_id $instance_id -parameter EncodeProc -default hf_encode]
            set encode_key [parameter::get -package_id $instance_id -parameter EncodeKey -default [string range $c -1 [randomRange 52]-1 ]]
            set decode_proc [parameter::get -package_id $instance_id -parameter DecodeProc -default hf_decode]
            set mystify_proc [parameter::get -package_id $instance_id -parameter MystifyProc -default hf_mystify]
            set mystify_key [parameter::get -package_id $instance_id -parameter MystifyKey -default [string range $c -1 [randomRange 52]-1 ]]
            set demystify_proc [parameter::get -package_id $instance_id -parameter DemystifyProc -default hf_demystify]
            ns_log Notice "hosting-farm-coded-procs.tcl.17: c '${c}'"
            ns_log Notice "hosting-farm-coded-procs.tcl.18: encode_key '${encode_key}'"
            ns_log Notice "hosting-farm-coded-procs.tcl.19: mystify_key '${mystify_key}'"
            set word_len 9
            for {set i 1} {$i < $d} {incr i} {
                # set word_len [randomRange 20]
                # incr word_len
                set j [expr { $word_len + $i } ]
                set word [string range $c $i $j]

                set drow [safe_eval [list ${encode_proc} ${encode_key} $word]]
                #set drow [hf_encode $word]

                set id [db_nextval hf_id_seq]
                set drow_arr(${id}) $word
                db_dml hf_test_hf_ua_i { insert into hf_up (up_id,details) values (:id,:drow) }
            }
            foreach up_id [array names drow_arr] {
                db_1row hf_test_hf_ua_r { select details from hf_up where up_id=:up_id }

                set guess [safe_eval [list ${decode_proc} ${encode_key} $details]]
                #set guess [hf_decode $details]

                set word $drow_arr(${up_id})
                aa_equals "Word ${word} coded decoded" $guess $word
            }

            array unset drow_arr

            # word_len set to 8, so all end string chars are tested also.
            # Ideally, every combo of two letters should be tested 
            # at beginning and end of string
            set word_len 9
            for {set i 1} {$i < $d} {incr i} {
                # set word_len [randomRange 20]
                # incr word_len
                set j [expr { $word_len + $i } ]
                set word [string range $c $i $j]

                set drow [safe_eval [list $mystify_proc ${mystify_key} $word]]
               # set drow [hf_mystify $word]

                set id [db_nextval hf_id_seq]
                set drow_arr(${id}) $word
                db_dml hf_test_hf_ua_i2 { insert into hf_up (up_id,details) values (:id,:drow) }
            }
            foreach up_id [array names drow_arr] {
                db_1row hf_test_hf_ua_r2 { select details from hf_up where up_id=:up_id }

                #set guess [hf_demistify $details]
                set guess [safe_eval [list $demystify_proc ${mystify_key} $details]]

                set word $drow_arr(${up_id})
                aa_equals "Word ${word} mystify demistified" $guess $word
            }


        } 
    # -teardown_code {
    # 
    #acs_user::delete -user_id $user1_arr(user_id) -permanent
    
    # }
    #aa_true "Test for .." $passed_p
    #aa_equals "Test for .." $test_value $expected_value
}    

