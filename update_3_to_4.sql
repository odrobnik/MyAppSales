/* Script to update apps.db from schema version 4 to 5 */

begin exclusive transaction;

/* Remove index causing problems */

drop index app_name;

/* update schema_version */ 

/*
update meta set schema_version = 4; 
*/
commit;