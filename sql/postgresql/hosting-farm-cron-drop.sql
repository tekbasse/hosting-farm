-- hosting-farm-cron-drop.sql
--
-- @author
-- @cvs-id
--
DROP index hf_sched_proc_args_stack_id;

DROP TABLE hf_sched_proc_args;

DROP index hf_sched_proc_stack_started_time_key;
DROP index hf_sched_proc_stack_priority_key;
DROP index hf_sched_proc_stack_id_key;

DROP TABLE hf_sched_proc_stack;

DROP index hf_file_id_key;
DROP index hf_case_id_key;
DROP index hf_case_log_case_id_key;
DROP index hf_case_log_other_hf_id_key;
DROP index hf_initial_conditions_id_key;
DROP index hf_model_id_key;
DROP index hf_log_points_id_key;
DROP index hf_post_calcs_id_key;
DROP index hf_post_calc_log_id_key;
DROP index hf_log_id_key;
DROP index hf_process_log_id_idx;
DROP index hf_process_log_instance_id_idx;
DROP index hf_process_log_user_id_idx;
DROP index hf_process_log_table_tid_idx;
DROP index hf_process_log_trashed_p_idx;
DROP index hf_process_log_viewed_id_idx;
DROP index hf_process_log_viewed_instance_id_idx;
DROP index hf_process_log_viewed_user_id_idx;
DROP index hf_process_log_viewed_table_tid_idx;

DROP TABLE hf_file;
DROP TABLE hf_case;
DROP TABLE hf_case_log;
DROP TABLE hf_initial_conditions;
DROP TABLE hf_model;
DROP TABLE hf_log_points;
DROP TABLE hf_post_calcs;
DROP TABLE hf_post_calc_log;
DROP TABLE hf_log;
DROP TABLE hf_process_log;
DROP TABLE hf_process_log_viewed;

DROP SEQUENCE hf_sched_id_seq;

