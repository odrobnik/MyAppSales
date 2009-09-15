/* Script to update apps.db from schema version 2 to 3 */

begin exclusive transaction;

/* add language column to country */

/* temp table */

create table update_country as select * from country;

/* create new country table with additional column language */

drop table country;

create table country (
   CountryID            int                  not null,
   Iso2                 char(2)              not null,
   Iso3                 char(3)              not null,
   Name                 varchar(100)         not null,
   app_store_id			int,
   language	char(5),
   constraint PK_COUNTRY primary key (CountryID)
);

/* copy previous countries back to table */

insert into country (CountryID, Iso2, Iso3, Name, app_store_id) select CountryID, Iso2, Iso3, Name, app_store_id from update_country;

/* clean up temp table */

drop table update_country;

/* update country */

UPDATE Country SET language="es", app_store_id=143485 WHERE ISO2="PA";
UPDATE Country SET language="de", app_store_id=143443 WHERE ISO2="DE";
UPDATE Country SET language="vi", app_store_id=143471 WHERE ISO2="VN";
UPDATE Country SET language="lt", app_store_id=143520 WHERE ISO2="LT";
UPDATE Country SET language="es", app_store_id=143454 WHERE ISO2="ES";
UPDATE Country SET language="sl", app_store_id=143499 WHERE ISO2="SI";
UPDATE Country SET language="en", app_store_id=143477 WHERE ISO2="PK";
UPDATE Country SET language="es", app_store_id=143513 WHERE ISO2="PY";
UPDATE Country SET app_store_id=143446 WHERE ISO2="BE";
UPDATE Country SET app_store_id=143464 WHERE ISO2="SG";
UPDATE Country SET language="es", app_store_id=143512 WHERE ISO2="NI";
UPDATE Country SET app_store_id=143473 WHERE ISO2="MY";
UPDATE Country SET language="en", app_store_id=143449 WHERE ISO2="IE";
UPDATE Country SET language="es", app_store_id=143507 WHERE ISO2="PE";
UPDATE Country SET language="nl", app_store_id=143452 WHERE ISO2="NL";
UPDATE Country SET language="en", app_store_id=143460 WHERE ISO2="AU";
UPDATE Country SET language="es", app_store_id=143502 WHERE ISO2="VE";
UPDATE Country SET language="ro", app_store_id=143487 WHERE ISO2="RO";
UPDATE Country SET language="id", app_store_id=143476 WHERE ISO2="ID";
UPDATE Country SET language="ar", app_store_id=143497 WHERE ISO2="LB";
UPDATE Country SET language="es", app_store_id=143514 WHERE ISO2="UY";
UPDATE Country SET app_store_id=143516 WHERE ISO2="EG";
UPDATE Country SET language="ar", app_store_id=143479 WHERE ISO2="SA";
UPDATE Country SET language="en", app_store_id=143461 WHERE ISO2="NZ";
UPDATE Country SET language="pt", app_store_id=143503 WHERE ISO2="BR";
UPDATE Country SET language="en", app_store_id=143472 WHERE ISO2="ZA";
UPDATE Country SET language="es", app_store_id=143504 WHERE ISO2="GT";
UPDATE Country SET language="es", app_store_id=143505 WHERE ISO2="AR";
UPDATE Country SET language="zh-TW", app_store_id=143470 WHERE ISO2="TW";
UPDATE Country SET app_store_id=143515 WHERE ISO2="MO";
UPDATE Country SET language="es", app_store_id=143480 WHERE ISO2="TR";
UPDATE Country SET language="fr", app_store_id=143442 WHERE ISO2="FR";
UPDATE Country SET language="ja", app_store_id=143462 WHERE ISO2="JP";
UPDATE Country SET language="hi", app_store_id=143467 WHERE ISO2="IN";
UPDATE Country SET language="es", app_store_id=143509 WHERE ISO2="EC";
UPDATE Country SET language="sv", app_store_id=143456 WHERE ISO2="SE";
UPDATE Country SET language="sk", app_store_id=143496 WHERE ISO2="SK";
UPDATE Country SET language="es", app_store_id=143468 WHERE ISO2="MX";
UPDATE Country SET language="es", app_store_id=143506 WHERE ISO2="SV";
UPDATE Country SET app_store_id=143491 WHERE ISO2="IL";
UPDATE Country SET app_store_id=143451 WHERE ISO2="LU";
UPDATE Country SET language="no", app_store_id=143457 WHERE ISO2="NO";
UPDATE Country SET app_store_id=143517 WHERE ISO2="KZ";
UPDATE Country SET language="en", app_store_id=143455 WHERE ISO2="CA";
UPDATE Country SET app_store_id=143475 WHERE ISO2="TH";
UPDATE Country SET language="es", app_store_id=143495 WHERE ISO2="CR";
UPDATE Country SET language="en", app_store_id=143511 WHERE ISO2="JM";
UPDATE Country SET language="da", app_store_id=143458 WHERE ISO2="DK";
UPDATE Country SET language="en", app_store_id=143444 WHERE ISO2="GB";
UPDATE Country SET language="pt", app_store_id=143453 WHERE ISO2="PT";
UPDATE Country SET language="tl", app_store_id=143474 WHERE ISO2="PH";
UPDATE Country SET language="es", app_store_id=143508 WHERE ISO2="DO";
UPDATE Country SET language="ee", app_store_id=143518 WHERE ISO2="EE";
UPDATE Country SET language="fi", app_store_id=143447 WHERE ISO2="FI";
UPDATE Country SET language="el", app_store_id=143448 WHERE ISO2="GR";
UPDATE Country SET app_store_id=143523 WHERE ISO2="MD";
UPDATE Country SET language="zn", app_store_id=143465 WHERE ISO2="CN";
UPDATE Country SET language="es", app_store_id=143510 WHERE ISO2="HN";
UPDATE Country SET language="es", app_store_id=143501 WHERE ISO2="CO";
UPDATE Country SET language="ar", app_store_id=143493 WHERE ISO2="KW";
UPDATE Country SET language="ko", app_store_id=143466 WHERE ISO2="KR";
UPDATE Country SET language="cs", app_store_id=143489 WHERE ISO2="CZ";
UPDATE Country SET language="de", app_store_id=143445 WHERE ISO2="AT";
UPDATE Country SET language="cr", app_store_id=143494 WHERE ISO2="HR";
UPDATE Country SET language="ar", app_store_id=143481 WHERE ISO2="AE";
UPDATE Country SET language="es", app_store_id=143483 WHERE ISO2="CL";
UPDATE Country SET language="mt", app_store_id=143521 WHERE ISO2="MT";
UPDATE Country SET language="zh-TW", app_store_id=143463 WHERE ISO2="HK";
UPDATE Country SET language="ru", app_store_id=143469 WHERE ISO2="RU";
UPDATE Country SET language="ar", app_store_id=143498 WHERE ISO2="QA";
UPDATE Country SET app_store_id=143459 WHERE ISO2="CH";
UPDATE Country SET language="pl", app_store_id=143478 WHERE ISO2="PL";
UPDATE Country SET app_store_id=143486 WHERE ISO2="LK";
UPDATE Country SET app_store_id=143482 WHERE ISO2="HU";
UPDATE Country SET language="en", app_store_id=143441 WHERE ISO2="US";
UPDATE Country SET language="lv", app_store_id=143519 WHERE ISO2="LV";
UPDATE Country SET language="it", app_store_id=143450 WHERE ISO2="IT";

/* update schema_version */ 

update meta set schema_version = 3;

commit;

