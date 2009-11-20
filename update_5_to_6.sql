/* Script to update apps.db from schema version 5 to 6 */

begin exclusive transaction;

/* Fix incorrect long name */

update country set name = 'Vietnam' where iso2 = 'VN';

/* update schema_version */ 

/*
update meta set schema_version = 5; 
*/

commit;