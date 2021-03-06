-- hosting-farm-cron-create.sql
--
-- @author Benjamin Brink
-- @copyright 2015 see GPL License for distribution info
--

CREATE SEQUENCE hf_beat_id_seq start 1;
SELECT nextval ('hf_beat_id_seq');

-- For monitor process logs
CREATE TABLE hf_beat_log (
    id integer not null primary key,
    instance_id integer,
    user_id integer,
    asset_id integer,
    -- If there is a monitor_id associated, include it.
    monitor_id integer,
    trashed_p varchar(1) not null DEFAULT '0',
    alert_p varchar(1) default '0',
    -- Is this a system alert or critical message requiring
    -- a flag for extra presentation handling?
    critical_alert_p varchar(1) default '0',
    -- If the alert needs a confirmation from a user
    confirm_p varchar(1) default '0',
    -- If confirmation required, confirmation received?
    confirmed_p varchar(1) default '0',
    -- send an email/sms etc with alert?
    message_p varchar(1) default '0',
    -- Was the email sent?
    -- This allows the system to batch multiple outbound messages to one user
    -- and potentially skip sending messages already received on screen.
    message_sent_p varchar(1) default '0',
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
create index hf_beat_log_monitor_id_idx on hf_beat_log (monitor_id);
create index hf_beat_log_trashed_p_idx on hf_beat_log (trashed_p);
create index hf_beat_log_alert_p_idx on hf_beat_log (alert_p);

CREATE TABLE hf_beat_log_viewed (
     id integer not null,
     instance_id integer,
     user_id integer,
     last_viewed timestamptz
);

create index hf_beat_log_viewed_id_idx on hf_beat_log_viewed (id);
create index hf_beat_log_viewed_instance_id_idx on hf_beat_log_viewed (instance_id);
create index hf_beat_log_viewed_user_id_idx on hf_beat_log_viewed (user_id);


CREATE TABLE hf_beat_stack_bus (
       -- instead of querying hf_beat_stack for active proc
       -- the value is stored and updated here for speed.
       active_id varchar(19) default '',
       -- when checking for active_id, can also get a dynamic value for debug_p with low overhead
       debug_p varchar(1) default '1',
       -- What is the lowest priority that takes precedence in scheduling over all other delayed 
       -- priorities? Highest priority is 1, Lowest is a high integer.
       priority_threshold integer default '13',
       -- scheduled cycle time in seconds
       cycle_time integer default '300'
);


CREATE TABLE hf_beat_stack (
       id integer primary key,
       -- Assumes procedure is called repeatedly
       -- Since procedure is repeated, cannot
       -- use empty completed_time to infer active status
       -- instead, see hf_beat_stack_bus.active_id

       -- stack is prioritized by
       -- time must be > last time + interval_s + last_process_time_s
       -- priority
       -- relative priority: priority - (now - last_completed_time )/ interval_s + last_process_s
       -- relative priority kicks in after threshold priority procs have been exhausted for the interval
       proc_name varchar(40),
       asset_id integer,
       monitor_id integer,
       proc_args text,
       proc_out text,
       user_id integer,
       instance_id integer,
       priority integer,
       -- when first requested in machine clock seconds
       order_clock_s integer,
       -- last time proc was started in machine clock seconds
       last_started_clock_s integer,
       -- last time proc completed in machine clock seconds
       last_completed_clock_s integer,
       -- last response_time in seconds; should be about same as last_completed_time_s - last_started_time_s
       last_process_s integer,
       -- requested interval between calls
       -- this value is extracted from hf_monitor_config_n_control
       interval_s integer,
       -- trigger_s is last_started_clock_s + last_process_s - interval_s 
       trigger_s integer,
       order_time timestamptz,
       last_started_time timestamptz,
       last_completed_time timestamptz,
       call_counter integer
);

CREATE index hf_beat_stack_id_key on hf_beat_stack(id);
CREATE index hf_beat_stack_asset_id_key on hf_beat_stack(asset_id);
CREATE index hf_beat_stack_priority_key on hf_beat_stack(priority);


--CREATE TABLE hf_beat_args (
--       stack_id integer,
       -- list_number 0 for standard args. if arg contains a regexp \1
       -- or other integer, then insert list built from list_number = n (1 for example).
--       list_number integer,
--       arg_number integer,
--       arg_value text
--);

--CREATE index hf_beat_args_stack_id on hf_beat_args(stack_id);

