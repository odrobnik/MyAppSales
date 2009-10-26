/* Script to update apps.db from schema version 3 to 4 */

begin exclusive transaction;

/* fix incorrect language for Turkey */

UPDATE Country SET language="tr", app_store_id=143480 WHERE ISO2="TR";

/* fix writing so that country is found for Jan 2009 report */
update country set Name = 'Great Britain' where iso2 = 'GB';
update country set name = 'Taiwan' where iso2 = 'TW';
update country set name = 'Russian Fed.' where iso2 = 'RU';
update country set name = 'South Korea' where iso2 = 'KR';
update country set name = 'Unit.Arab Emir.' where iso2 = 'AE';
update country set name = 'Czech. Republic' where iso2 = 'CZ';


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