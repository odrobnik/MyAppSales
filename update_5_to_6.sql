/* Script to update apps.db from schema version 5 to 6 */

begin exclusive transaction;

/* Fix incorrect long name */

update country set name = 'Vietnam' where iso2 = 'VN';


/* Remove reports without dates */

delete from sale where report_id in (select id from report where from_date is null or until_date is null);

delete from report where from_date is null or until_date is null;



/* update schema_version */ 

/*
update meta set schema_version = 5; 
*/

commit;