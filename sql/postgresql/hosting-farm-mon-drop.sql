-- hosting-farm-cron-drop.sql
--
-- @author
-- @cvs-id
--
--DROP index hf_beat_args_stack_id;

--DROP TABLE hf_beat_args;

DROP index hf_beat_stack_started_time_key;
DROP index hf_beat_stack_priority_key;
DROP index hf_beat_stack_id_key;

DROP TABLE hf_beat_stack;

DROP TABLE hf_beat_stack_active;

DROP index hf_beat_log_id_idx;
DROP index hf_beat_log_instance_id_idx;
DROP index hf_beat_log_user_id_idx;
DROP index hf_beat_log_table_tid_idx;
DROP index hf_beat_log_trashed_p_idx;
DROP index hf_beat_log_viewed_id_idx;
DROP index hf_beat_log_viewed_instance_id_idx;
DROP index hf_beat_log_viewed_user_id_idx;
DROP index hf_beat_log_viewed_table_tid_idx;

DROP TABLE hf_beat_log;
DROP TABLE hf_beat_log_viewed;

DROP SEQUENCE hf_beat_id_seq;

