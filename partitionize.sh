#!/bin/bash


DB="travegodb"
DBUSER="postgres"
BASETABLE="$1"
BASETABLE="part"
DIVISION_COLUMN="$2"
DIVISION_COLUMN="created_at"
INTERVAL="1 month"
TMP_BASETABLE="$BASETABLE"_tmp

TRIGGER=$BASETABLE"_insert_trigger"

START_DATE=`psql -U $DBUSER -d $DB -At -c "SELECT MIN($DIVISION_COLUMN) FROM $BASETABLE"`
END_DATE=`psql -U $DBUSER -d $DB -At -c "SELECT MAX($DIVISION_COLUMN) FROM $BASETABLE"`

echo "Table: \"$BASETABLE\" DATE RANGE BETWEEN \"$START_DATE\" AND \"$END_DATE\" "

# Find the min and max date from the table
DATE_RANGE=`psql -U $DBUSER -d $DB -At -c "select to_char(generate_series('$START_DATE'::timestamp , '$END_DATE'::timestamp, '$INTERVAL'),'YYYY-MM-DD');"`

echo $DATE_RANGE

echo "CREATE TRIGGER $BASETABLE""_trigger BEFORE INSERT on $BASETABLE for each row execute procedure $BASETABLE""_insert_trigger();"

TRIGGER_STATEMENT="CREATE OR REPLACE FUNCTION $TRIGGER()
        RETURNS TRIGGER AS \$\$
        DECLARE
            current_partition text;
        BEGIN
        asd
        asd
        "
exit

# RENAME BASE TABLE AS TMP TABLE
psql -U $DBUSER $DB -c "ALTER TABLE $BASETABLE RENAME TO $TMP_BASETABLE;"
# CREATE CLEAN BASE TABLE
psql -U $DBUSER $DB -c "CREATE TABLE $BASETABLE ( LIKE $TMP_BASETABLE INCLUDING ALL ) ;"
# CREATE TRIGGER 
psql -U $DBUSER $DB -c "CREATE TRIGGER $BASETABLE""_trigger BEFORE INSERT on $BASETABLE for each row execute procedure $BASETABLE""_insert_trigger();"



## CREATE Partition tables according to given INTERVAL parameter
for DATE in $DATE_RANGE
do 
    YEAR=`echo $DATE | cut -d"-" -f1`
    MONTH=`echo $DATE | cut -d"-" -f2`
    #DAY=`echo $DATE | cut -d"-" -f3`
    #suffix="_y$YEAR""m$MONTH""d$DAY"   day month olarak düzenle
    suffix="_y$YEAR""m$MONTH"

    DATE_STR=`echo "date --date='$DATE $INTERVAL ' +%Y-%m-%d"`
    NEXT_DATE=`eval $DATE_STR`
    
    CREATE_STATEMENT="CREATE TABLE $BASETABLE$suffix ( CHECK ( $DIVISION_COLUMN >= DATE '$DATE' AND $DIVISION_COLUMN < DATE '$NEXT_DATE' ) ) INHERITS ($BASETABLE);"
    INSERT_STATEMENT="INSERT INTO $BASETABLE$suffix ( SELECT * FROM $TMP_BASETABLE WHERE $DIVISION_COLUMN >= DATE '$DATE' AND $DIVISION_COLUMN < DATE '$NEXT_DATE' );"
    
    psql -U $DBUSER $DB -c "$CREATE_STATEMENT"
    psql -U $DBUSER $DB -c "$INSERT_STATEMENT"
        #psql -U postgres $DB -c "DROP TABLE $BASETABLE$suffix;"

done

#psql -U $DBUSER $DB -c "DROP TABLE $TMP_BASETABLE;" 

exit

STARTDATE=$(date +%Y-%m-%d -d '2 day')
ENDDATE=$(date +%Y-%m-%d -d '3 day')
TODAY=$(date +%Y-%m-%d)
TOMORROW=$(date +%Y-%m-%d -d '1 day')

BASETABLE="int_log_table"
COLUMN="log_insert_time"
TRIGGER=$BASETABLE"_insert_trigger"
OLD_PARTITION=$BASETABLE$(date +_%Y_%m_%d -d '8 day ago')
NEW_PARTITION=$BASETABLE$(date +_%Y_%m_%d -d '2 day')
NEW_PARTITION_INDEX=$NEW_PARTITION\_$COLUMN\_idx
TODAY_PARTITION=$BASETABLE$(date +_%Y_%m_%d)

setup()
{
cat << EOF
    BEGIN;
        CREATE TABLE $NEW_PARTITION ( CHECK ( $COLUMN >= DATE '$STARTDATE' AND $COLUMN < DATE '$ENDDATE' ) ) INHERITS ($BASETABLE);
    COMMIT;
    BEGIN;
        CREATE OR REPLACE FUNCTION $TRIGGER()
        RETURNS TRIGGER AS \$\$
        DECLARE
            current_partition text;
        BEGIN
            current_partition:='$BASETABLE'||to_char(NEW.$COLUMN,'_yyyy_mm_dd');
            IF ( NEW.$COLUMN >= DATE '$TODAY' AND NEW.$COLUMN < DATE '$TOMORROW' ) THEN
                INSERT INTO $TODAY_PARTITION VALUES (NEW.*);
            END IF;
        RETURN NULL;
        END;
        \$\$
        LANGUAGE plpgsql;
    COMMIT;
    BEGIN;
        CREATE INDEX $NEW_PARTITION_INDEX ON $NEW_PARTITION($COLUMN);
    COMMIT;
    BEGIN;
        DROP TABLE $OLD_PARTITION;
    COMMIT;
EOF
}

setup #| psql -U postgres travegodb

## TRIGGER RULE EXAMPLE ##
#echo "CREATE TRIGGER insert_int_log_table_trigger BEFORE INSERT on int_log_table for each row execute procedure int_log_table_insert_trigger();"

## CREATE PARTITION EXAMPLE ##
#echo "CREATE TABLE int_log_table_20121222 ( CHECK ( log_insert_time >= DATE '2012-12-22' AND log_insert_time < DATE '2012-12-23' ) ) INHERITS (int_log_table); "


##### crm urchin user #####
#CREATE TABLE urchin_user_p1 ( CHECK ( user_id >= "0" AND user_id < "40000000" ) ) INHERITS (urchin_user)  TABLESPACE "urchin_tblspc";
#CREATE TABLE urchin_user_p2 ( CHECK ( user_id >= "40000000" AND user_id < "80000000" ) ) TABLESPACE "crm_tblspc" INHERITS (urchin_user);
#CREATE TABLE urchin_user_p3 ( CHECK ( user_id >= "80000000" AND user_id < "120000000" ) ) TABLESPACE "crm_tblspc" INHERITS (urchin_user);
#CREATE TABLE urchin_user_p4 ( CHECK ( user_id >= "120000000" AND user_id < "160000000" ) ) TABLESPACE "crm_tblspc" INHERITS (urchin_user);



config = {_id: 'mkfrs1', members: [
{_id: 0, host: '192.168.3.197:27017'},
{_id: 1, host: '192.168.3.202:27017'}]}