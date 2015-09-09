-- hosting-farm-cron-create.sql
--
-- @author Dekka Corp.
-- @cvs-id
--

CREATE SEQUENCE hf_beat_id_seq start 1;
SELECT nextval ('hf_beat_id_seq');

-- For general qaf app delayed process logs
CREATE TABLE hf_beat_log (
    id integer not null primary key,
    instance_id integer,
    user_id integer,
    asset_id integer,
    trashed_p varchar(1) default '0',
    name varchar(40),
    title varchar(80),
    created timestamptz default now(),
    last_modified timestamptz,
    log_entry text
);

create index hf_beat_log_id_idx on hf_beat_log (id);
create index hf_beat_log_instance_id_idx on hf_beat_log (instance_id);
create index hf_beat_log_user_id_idx on hf_beat_log (user_id);
create index hf_beat_log_asset_id_idx on hf_beat_log (asset_id);
create index hf_beat_log_trashed_p_idx on hf_beat_log (trashed_p);

CREATE TABLE hf_beat_log_viewed (
     id integer not null,
     instance_id integer,
     user_id integer,
     asset_id integer, 
     last_viewed timestamptz
);

create index hf_beat_log_viewed_id_idx on hf_beat_log_viewed (id);
create index hf_beat_log_viewed_instance_id_idx on hf_beat_log_viewed (instance_id);
create index hf_beat_log_viewed_user_id_idx on hf_beat_log_viewed (user_id);
create index hf_beat_log_viewed_asset_id_idx on hf_beat_log_viewed (asset_id);


CREATE TABLE hf_beat_stack (
       id integer primary key,
       -- assumes procedure is only scheduled/called once
       proc_name varchar(40),
       proc_args text,
       proc_out text,
       user_id integer,
       instance_id integer,
       priority integer,
       order_time timestamptz,
       started_time timestamptz,
       completed_time timestamptz,
       process_seconds integer
);

CREATE index hf_beat_stack_id_key on hf_beat_stack(id);
CREATE index hf_beat_stack_priority_key on hf_beat_stack(priority);
CREATE index hf_beat_stack_started_time_key on hf_beat_stack(started_time);

CREATE TABLE hf_beat_args (
       stack_id integer,
       -- list_number 0 for standard args. if arg contains a regexp \1
       -- or other integer, then insert list built from list_number = n (1 for example).
       list_number integer,
       arg_number integer,
       arg_value text
);

CREATE index hf_beat_args_stack_id on hf_beat_args(stack_id);
