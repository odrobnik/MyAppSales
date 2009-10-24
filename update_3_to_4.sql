/* Script to update apps.db from schema version 3 to 4 */

begin exclusive transaction;

/* fix incorrect language for Turkey */

UPDATE Country SET language="tr", app_store_id=143480 WHERE ISO2="TR";

/* add account table */

CREATE TABLE AppGrouping (id INTEGER PRIMARY KEY, description VARCHAR);

/* add accountapps table */

CREATE TABLE AppAppGrouping( app_id INTEGER PRIMARY KEY, appgrouping_id INTEGER);

/* add accountapps table */

CREATE TABLE ReportAppGrouping (report_id INTEGER PRIMARY KEY, appgrouping_id INTEGER);

/* set defaults, assume that all reports came from same app grouping aka account */

insert into AppGrouping (id, description) values (1, 'Default');
insert into AppAppGrouping (app_id, appgrouping_id) select distinct app_id, 1 from sale;
insert into ReportAppGrouping (report_id, appgrouping_id) select distinct id, 1 from report;

/* update schema_version */ 

update meta set schema_version = 4; 

commit;