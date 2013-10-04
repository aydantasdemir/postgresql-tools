#!/bin/bash

################################################################################
### Partition a table according to given interval parameter (1 day, 1 month) ###
### Create partition tables, inserts rows, creates triggers                  ###
### ERKIN CAKAR @ markafoni - 2013                                           ###
################################################################################


## USER DEFINED SETTING PARAMETERS ##
DB="dbname"
DBUSER="postgres"
BASETABLE="tablename"
DIVISION_COLUMN="created_at"
INTERVAL="1 month"
INSERT_AFTER_TABLE_CREATED=0 ## Default 0: insert datas when creating table, 1: Create all sub tables and set insert trigger. then, insert data into sub tables


TYPE=`echo $INTERVAL | cut -d" " -f2`
TMP_BASETABLE="$BASETABLE"_tmp
TRIGGER=$BASETABLE"_insert_trigger"
START_DATE=`psql -U $DBUSER -d $DB -At -c "SELECT to_char(MIN($DIVISION_COLUMN),'YYYY-MM-01') FROM $BASETABLE"`
END_DATE=`psql -U $DBUSER -d $DB -At -c "SELECT to_char( (SELECT MAX($DIVISION_COLUMN) + interval '1 month' FROM $BASETABLE),'YYYY-MM-01' )"`

TRIGGER_FLAG=1

throw_ex() {
#if [ $? > 0 ]; then echo "ERROR: $1"; exit; fi
if [ $? > 0 ]; then if [ $DEBUG -eq 0 ]; then echo "ERROR: $1"; exit; fi fi
}

get_suffix() {
    DATE=$1
    YEAR=`echo $DATE | cut -d"-" -f1`
    MONTH=`echo $DATE | cut -d"-" -f2`
    if [ "$TYPE" = "day" ]
    then
        DAY=`echo $DATE | cut -d"-" -f3`
        suffix="_$YEAR""_$MONTH""_$DAY"
    elif [ "$TYPE" = "month" ]
    then
        suffix="_y$YEAR""m$MONTH"
    else
        echo "Partition type should be day or month"
        exit
    fi
}

# Find the min and max date from the table
DATE_RANGE=`psql -U $DBUSER -d $DB -At -c "SELECT to_char(generate_series('$START_DATE'::timestamp , '$END_DATE'::timestamp, '$INTERVAL'),'YYYY-MM-DD');"` ||throw_ex "Getting Date range array from DB"

echo -e '\nTABLE: '$BASETABLE' \nDATE BETWEEN: '$START_DATE' AND '$END_DATE' \nINTERVAL: '$INTERVAL' \nDATE RANGE: '$DATE_RANGE'\n'


TRIGGER_STATEMENT_START="
CREATE OR REPLACE FUNCTION $TRIGGER()
RETURNS TRIGGER AS \$\$
BEGIN"

TRIGGER_STATEMENT_END="
    END IF;
RETURN NULL;
END;
\$\$
LANGUAGE plpgsql;
"

TRIGGER_STATEMENT_BODY=""

# RENAME BASE TABLE AS TMP TABLE
psql -U $DBUSER $DB -c "ALTER TABLE $BASETABLE RENAME TO $TMP_BASETABLE;" > /dev/null ||throw_ex "Cannot renamed the table $BASETABLE to $TMP_BASETABLE"
echo "[ALTER]  TABLE \"$BASETABLE\" RENAMED TO \"$TMP_BASETABLE\""
# CREATE CLEAN BASE TABLE
psql -U $DBUSER $DB -c "CREATE TABLE $BASETABLE ( LIKE $TMP_BASETABLE INCLUDING ALL ) ;" > /dev/null ||throw_ex "The table \"$BASETABLE\" cannot be created"
echo "[CREATE] TABLE \"$BASETABLE\" ( LIKE \"$TMP_BASETABLE\" INCLUDING ALL )"


## CREATE Partition tables and INSERT values to partitioned tables according to given INTERVAL parameter
for DATE in $DATE_RANGE
do
    get_suffix "$DATE"
    NEXT_DATE=`eval "date --date='$DATE $INTERVAL ' +%Y-%m-%d"`

    ## CREATING partition tables
    CREATE_STATEMENT="CREATE TABLE $BASETABLE$suffix ( LIKE $BASETABLE INCLUDING ALL, CHECK ( $DIVISION_COLUMN >= '$DATE'::timestamp with time zone AND $DIVISION_COLUMN < '$NEXT_DATE'::timestamp with time zone ) ) INHERITS ($BASETABLE);"
    ## INSERTING partition values
    INSERT_STATEMENT="INSERT INTO $BASETABLE$suffix ( SELECT * FROM $TMP_BASETABLE WHERE $DIVISION_COLUMN >= DATE '$DATE' AND $DIVISION_COLUMN < DATE '$NEXT_DATE' );"

    psql -U $DBUSER $DB -c "$CREATE_STATEMENT" > /dev/null 2>&1 ||throw_ex "The partitioned sub table \"$BASETABLE$suffix\" cannot be created"

    if [ $INSERT_AFTER_TABLE_CREATED -eq 0 ]
        then
        echo -n "[CREATE:SUB] TABLE $BASETABLE$suffix"
        psql -U $DBUSER $DB -c "$INSERT_STATEMENT" > /dev/null ||throw_ex "Inserting data into the table \"$BASETABLE$suffix\""
        echo " -> [INSERTED]"
    else
        echo "[CREATE:SUB] TABLE $BASETABLE$suffix"
    fi
    psql -U $DBUSER $DB -c "alter table $BASETABLE$suffix add FOREIGN KEY (action_object_content_type_id) REFERENCES django_content_type(id) DEFERRABLE INITIALLY DEFERRED;" > /dev/null ||throw_ex "ADDING FOREIGN KEY"
    psql -U $DBUSER $DB -c "alter table $BASETABLE$suffix add FOREIGN KEY (actor_content_type_id) REFERENCES django_content_type(id) DEFERRABLE INITIALLY DEFERRED;" > /dev/null ||throw_ex "ADDING FOREIGN KEY"
    psql -U $DBUSER $DB -c "alter table $BASETABLE$suffix add FOREIGN KEY (target_content_type_id) REFERENCES django_content_type(id) DEFERRABLE INITIALLY DEFERRED;" > /dev/null ||throw_ex "ADDING FOREIGN KEY"
    if [ $TRIGGER_FLAG -eq 1 ]
    then
        TRIGGER_STATEMENT_BODY="$TRIGGER_STATEMENT_BODY
    IF ( NEW.$DIVISION_COLUMN >= DATE '$DATE' AND NEW.$DIVISION_COLUMN < DATE '$NEXT_DATE' ) THEN
        INSERT INTO $BASETABLE$suffix VALUES (NEW.*);"
        TRIGGER_FLAG=0
    else
        TRIGGER_STATEMENT_BODY="$TRIGGER_STATEMENT_BODY
    ELSIF ( NEW.$DIVISION_COLUMN >= DATE '$DATE' AND NEW.$DIVISION_COLUMN < DATE '$NEXT_DATE' ) THEN
        INSERT INTO $BASETABLE$suffix VALUES (NEW.*);"
    fi
       #psql -U postgres $DB -c "DROP TABLE $BASETABLE$suffix;"
done

## If required, you can drop tmp table after distributing values from tmp table
#psql -U $DBUSER $DB -c "DROP TABLE $TMP_BASETABLE;"

TRIGGER_STATEMENT="$TRIGGER_STATEMENT_START""$TRIGGER_STATEMENT_BODY""$TRIGGER_STATEMENT_END"
echo -n "$TRIGGER_STATEMENT" | psql -U $DBUSER $DB > /dev/null ||throw_ex "The trigger \"$TRIGGER\" cannot be created" ## Exception is not working
echo "[CREATE] TRIGGER \"$TRIGGER\""

# CREATE TRIGGER
psql -U $DBUSER $DB -c "CREATE TRIGGER $BASETABLE""_trigger BEFORE INSERT on $BASETABLE for each row execute procedure $BASETABLE""_insert_trigger();" > /dev/null ||throw_ex "The trigger \"$BASETABLE""_insert_trigger\" cannot be created "
echo "[CREATE] TRIGGER \"$BASETABLE""_trigger\""


if [ $INSERT_AFTER_TABLE_CREATED -eq 1 ]
    then
    for DATE in $DATE_RANGE
    do
        echo -n "[INSERTING] The table \"$BASETABLE$suffix\""
        get_suffix "$DATE"
        NEXT_DATE=`eval "date --date='$DATE $INTERVAL ' +%Y-%m-%d"`

        INSERT_STATEMENT="INSERT INTO $BASETABLE$suffix ( SELECT * FROM $TMP_BASETABLE WHERE $DIVISION_COLUMN >= DATE '$DATE' AND $DIVISION_COLUMN < DATE '$NEXT_DATE' );"
        psql -U $DBUSER $DB -c "$INSERT_STATEMENT" > /dev/null ||throw_ex "Inserting data into the table \"$BASETABLE$suffix\""
        echo " -> [INSERTED]"
    done
fi

echo "The table $BASETABLE partitioning process OK"

##  var olan partition sistemi için süre uzatımı
##select proname,prosrc from pg_proc where proname='part_insert_trigger'
