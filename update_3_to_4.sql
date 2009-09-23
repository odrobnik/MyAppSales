/* Script to update apps.db from schema version 2 to 3 */

begin exclusive transaction;

/* fix incorrect language for Turkey */

UPDATE Country SET language="tr", app_store_id=143480 WHERE ISO2="TR";

/* update schema_version */ 

/* update meta set schema_version = 3; */

commit;