/* Script to update apps.db from schema version 1 to 2 */

begin exclusive transaction;

/* table to hold reviews */

CREATE TABLE review (id INTEGER PRIMARY KEY, app_id INTEGER, country_code CHAR(2), review_date DATE, version VARCHAR, title VARCHAR, name VARCHAR, review VARCHAR, review_translated VARCHAR, stars REAL);

CREATE UNIQUE INDEX app_user_version ON review (app_id, name, version);





/* update schema_version */ 

update meta set schema_version = 2;

commit;