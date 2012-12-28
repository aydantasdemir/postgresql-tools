#!/bin/bash

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

setup | psql -U postgres travegodb

## TRIGGER RULE EXAMPLE ##
#echo "CREATE TRIGGER insert_int_log_table_trigger BEFORE INSERT on int_log_table for each row execute procedure int_log_table_insert_trigger();"

## CREATE PARTITION EXAMPLE ##
#echo "CREATE TABLE int_log_table_20121222 ( CHECK ( log_insert_time >= DATE '2012-12-22' AND log_insert_time < DATE '2012-12-23' ) ) INHERITS (int_log_table); "
