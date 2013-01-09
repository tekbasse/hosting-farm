-- hosting-farm-create.sql
--
-- @author Dekka Corp.
-- @ported from Hub.org Hosting ams v2
-- @license GNU GENERAL PUBLIC LICENSE, Version 3
--

CREATE SEQUENCE hf_id start 10000;
SELECT nextval ('hf_id');


CREATE TABLE hf_template_accounts (
    chart_code varchar(30),
    description text,
    charttype varchar(5),
    gifi_accno varchar(100),
    category varchar(3),
    link varchar(300),
    accno varchar(100)
);

