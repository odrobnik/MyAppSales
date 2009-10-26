/* Script to update apps.db from schema version 0 to 1 */

begin exclusive transaction;

/* Add the meta table to keep the schema_version */ 

create table meta (schema_version integer);
insert into meta (schema_version) values (1);

/* temp table */

create table update_report as select * from report;

/* create new report table with additional column report_region_id */

drop table report;
CREATE TABLE report (id INTEGER PRIMARY KEY, report_type_id INTEGER, report_region_id INTEGER, from_date DATE, until_date DATE, downloaded_date DATE);

/* copy previous reports back to table */

insert into report (id, report_type_id, report_region_id, from_date, until_date, downloaded_date) select id, report_type_id, 0, from_date, until_date, downloaded_date from update_report;

/* clean up temp table */

drop table update_report;

commit;