-- hosting-farm-cron-create.sql
--
-- @author Dekka Corp.
-- @cvs-id
--

CREATE SEQUENCE hf_sched_id_seq start 1;
SELECT nextval ('hf_sched_id_seq');

-- For general qaf app delayed process logs
CREATE TABLE hf_process_log (
    id integer not null primary key,
    instance_id integer,
    user_id integer,
    table_tid integer,
    trashed_p varchar(1) default '0',
    name varchar(40),
    title varchar(80),
    created timestamptz default now(),
    last_modified timestamptz,
    log_entry text
);

create index hf_process_log_id_idx on hf_process_log (id);
create index hf_process_log_instance_id_idx on hf_process_log (instance_id);
create index hf_process_log_user_id_idx on hf_process_log (user_id);
create index hf_process_log_table_tid_idx on hf_process_log (table_tid);
create index hf_process_log_trashed_p_idx on hf_process_log (trashed_p);

CREATE TABLE hf_process_log_viewed (
     id integer not null,
     instance_id integer,
     user_id integer,
     table_tid integer, 
     last_viewed timestamptz
);

create index hf_process_log_viewed_id_idx on hf_process_log_viewed (id);
create index hf_process_log_viewed_instance_id_idx on hf_process_log_viewed (instance_id);
create index hf_process_log_viewed_user_id_idx on hf_process_log_viewed (user_id);
create index hf_process_log_viewed_table_tid_idx on hf_process_log_viewed (table_tid);

-- model output is separate from case, even though it is one-to-one
-- for easier abstractions of output without associating case for 
-- multple case processing, such as double blind study simulations, using outputs for 
-- other case inputs etc etc.
-- think calculator wiki with revisions

CREATE TABLE hf_file (
    id integer primary key,  
    title varchar(60)
);



-- this table associates old ids with cases
-- multiple cases may be associated with various ids
-- no type is set for old id, since this will likely be joined with
-- another table
CREATE TABLE hf_case_log (
    case_id integer,
    other_hf_id integer
 -- log ids, old case model init_condition log_points post_calcs ids
);


CREATE TABLE hf_initial_conditions (
    id integer primary key,  
    code varchar(30),
    title varchar(30),
    user_id integer not null,
    time_created timestamptz not null DEFAULT now(),
    trashed_p varchar(1) default '0',
    description text
);

CREATE TABLE hf_model (
    id integer primary key,  
    code varchar(30),
    title varchar(30),
    user_id integer not null,
    time_created timestamptz not null DEFAULT now(),
    trashed_p varchar(1) default '0',
    description text,
    program text
);


CREATE TABLE hf_log_points (
    id integer primary key,  
    code varchar(30),
    title varchar(30),
    user_id integer not null,
    time_created timestamptz not null DEFAULT now(),
    trashed_p varchar(1) default '0',
    description text
);

CREATE TABLE hf_post_calcs (
    id integer primary key,  
    log_id integer,
        -- id of hf_log_point associated with process
    code varchar(30),
    title varchar(30),
    user_id integer not null,
    time_created timestamptz not null DEFAULT now(),
    trashed_p varchar(1) default '0',
    calculations text
);


CREATE TABLE hf_case (
    id integer primary key,  
    file_id integer,  
    -- file_id does not change when case_id changes
    code varchar(30),
    title varchar(30),
    description text,
    -- create a new case when changing any of the following ids
    init_condition_id integer not null,
    model_id integer not null,
    log_points_id integer not null,
    post_calcs_id integer not null,
    -- most recent results of calculations for this case at
    log_id integer,
    post_calc_log_id integer,
     -- following are attributes for utility use
    instance_id integer,
        -- object_id of mounted instance (context_id)
    user_id integer not null,
    time_created timestamptz not null DEFAULT now(),
    last_modified timestamptz not null DEFAULT now(),
    trashed_p varchar(1) default '0',
    time_closed timestamptz not null DEFAULT now()
);


-- hf_log.compute_log will contain a tcl list of lists
-- until we can reference a spreadsheet table, and
-- insert there.
CREATE TABLE hf_log (
    id integer primary key,
    code varchar(30),
    title varchar(30),
    user_id integer not null,
    time_created timestamptz not null DEFAULT now(),
    iterations_requested integer,
    iterations_completed integer,
    trashed_p varchar(1) default '0',
    description text,
    compute_log text,
    notes text
);

-- whereas log_points tracks model variables
-- post_calc_log automatically tracks all post_calc_variables
-- post_calc_variables can be filtered when aggregated into
-- another case using log_points
CREATE TABLE hf_post_calc_log (
    id integer primary key,
    code varchar(30),
    title varchar(30),
    user_id integer not null,
    time_created timestamptz not null DEFAULT now(),
    trashed_p varchar(1) default '0',
    description text,
    compute_log text,
    notes text
);

CREATE index hf_file_id_key on hf_file(id);
CREATE index hf_case_id_key on hf_case(id);
CREATE index hf_case_log_case_id_key on hf_case_log(case_id);
CREATE index hf_case_log_other_hf_id_key on hf_case_log(other_hf_id);
CREATE index hf_initial_conditions_id_key on hf_initial_conditions(id);
CREATE index hf_model_id_key on hf_model(id);
CREATE index hf_log_points_id_key on hf_log_points(id);
CREATE index hf_post_calcs_id_key on hf_post_calcs(id);
CREATE index hf_log_id_key on hf_log(id);
CREATE index hf_post_calc_log_id_key on hf_post_calc_log(id);


CREATE TABLE hf_sched_proc_stack (
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

CREATE index hf_sched_proc_stack_id_key on hf_sched_proc_stack(id);
CREATE index hf_sched_proc_stack_priority_key on hf_sched_proc_stack(priority);
CREATE index hf_sched_proc_stack_started_time_key on hf_sched_proc_stack(started_time);

CREATE TABLE hf_sched_proc_args (
       stack_id integer,
       -- list_number 0 for standard args. if arg contains a regexp \1
       -- or other integer, then insert list built from list_number = n (1 for example).
       list_number integer,
       arg_number integer,
       arg_value text
);

CREATE index hf_sched_proc_args_stack_id on hf_sched_proc_args(stack_id);
