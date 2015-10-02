-- hosting-farm-cron-drop.sql
--
-- @author
-- @cvs-id
--

DROP index hf_beat_stack_priority_key;
DROP index hf_beat_stack_id_key;
DROP index hf_beat_stack_asset_id_key;
DROP TABLE hf_beat_stack;

DROP TABLE hf_beat_stack_bus;

drop index hf_beat_log_viewed_asset_id_idx;
drop index hf_beat_log_viewed_user_id_idx;
drop index hf_beat_log_viewed_instance_id_idx;
drop index hf_beat_log_viewed_id_idx;

DROP TABLE hf_beat_log_viewed;

drop index hf_beat_log_trashed_p_idx;
drop index hf_beat_log_asset_id_idx;
drop index hf_beat_log_user_id_idx;
drop index hf_beat_log_instance_id_idx;
drop index hf_beat_log_id_idx;

DROP TABLE hf_beat_log;

DROP SEQUENCE hf_beat_id_seq;
