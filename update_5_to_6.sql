/* Script to update apps.db from schema version 5 to 6 */

begin exclusive transaction;

/* Fix incorrect long name */

update country set name = 'Vietnam' where iso2 = 'VN';

/* Fix incorrect language code for China */

update country set language = 'zh-CN' where iso2 = 'CN';


/* Remove reports without dates */

delete from sale where report_id in (select id from report where from_date is null or until_date is null);

delete from report where from_date is null or until_date is null;

/* Add table for IAP */

CREATE TABLE IF NOT EXISTS InAppPurchase ('id' INTEGER PRIMARY KEY, 'title' VARCHAR, 'vendor_identifier' VARCHAR, company_name VARCHAR, parent INTEGER);

/* move existing IAP */

replace into InAppPurchase (id, title, vendor_identifier, company_name) select id, title, vendor_identifier, company_name from app where id in (select distinct app_id from sale where type_id = 101);
delete from app where id in (select id from InAppPurchase);
delete from AppAppGrouping where app_id in (select id from InAppPurchase );


/* update schema_version */ 

/*
update meta set schema_version = 6; 
*/

commit;