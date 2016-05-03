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

DROP TABLE hf_sched_params;

DROP index hf_process_log_id_idx;
DROP index hf_process_log_instance_id_idx;
DROP index hf_process_log_user_id_idx;
DROP index hf_process_log_table_tid_idx;
DROP index hf_process_log_trashed_p_idx;
DROP index hf_process_log_viewed_id_idx;
DROP index hf_process_log_viewed_instance_id_idx;
DROP index hf_process_log_viewed_user_id_idx;
DROP index hf_process_log_viewed_table_tid_idx;

DROP TABLE hf_process_log_viewed;

DROP index hf_process_log_id_idx;
DROP index hf_process_log_instance_id_idx;
DROP index hf_process_log_user_id_idx;
DROP index hf_process_log_asset_id_idx;
DROP index hf_process_log_trashed_p_idx;

DROP TABLE hf_process_log;

DROP SEQUENCE hf_sched_id_seq;

