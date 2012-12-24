#!/bin/bash


TABLE_TODAY=$(date +%Y_%m_%d)
TABLE_YESTERDAY=$(date +%Y_%m_%d -d '1 day ago')
TABLE_LAST=$(date +%Y_%m_%d -d '1 day')
TABLE_NEW=$(date +%Y_%m_%d -d '2 day')

STARTDATE=$(date +%Y-%m-%d -d '2 day')
ENDDATE=$(date +%Y-%m-%d -d '3 day')

YESTERDAY=$(date +%Y-%m-%d -d '1 day ago')
TODAY=$(date +%Y-%m-%d)
TOMORROW=$(date +%Y-%m-%d -d '1 day')
LASTDAY=$(date +%Y-%m-%d -d '2 day')

echo $tomorrow
echo $next

echo "CREATE TRIGGER insert_int_log_table_trigger BEFORE INSERT on int_log_table for each row execute procedure int_log_table_insert_trigger();"
echo "CREATE TABLE int_log_table_$TABLE_NEW ( CHECK ( log_insert_time >= DATE '$STARTDATE' AND log_insert_time < DATE '$ENDDATE' ) ) INHERITS (int_log_table); "

setup()
{
cat << EOF
    BEGIN;
    CREATE TABLE int_log_table_$TABLE_NEW ( CHECK ( log_insert_time >= DATE '$STARTDATE' AND log_insert_time < DATE '$ENDDATE' ) ) INHERITS (int_log_table);
    CREATE OR REPLACE FUNCTION int_log_table_insert_trigger()
    RETURNS TRIGGER AS \$\$
    BEGIN
           IF ( NEW.log_insert_time >= DATE '$YESTERDAY' AND
                NEW.log_insert_time < DATE '$TODAY' ) THEN
                    INSERT INTO int_log_table_$TABLE_YESTERDAY VALUES (NEW.*);
        ELSIF ( NEW.log_insert_time >= DATE '$TODAY' AND
                NEW.log_insert_time < DATE '$TOMORROW' ) THEN
                    INSERT INTO int_log_table_$TABLE_TODAY VALUES (NEW.*);
        ELSIF ( NEW.log_insert_time >= DATE '$TOMORROW' AND
                NEW.log_insert_time < DATE '$LASTDAY' ) THEN
                    INSERT INTO int_log_table_$TABLE_LAST VALUES (NEW.*);
        END IF;
    RETURN NULL;
    END;
    \$\$
    LANGUAGE plpgsql;
    COMMIT;
EOF
}

setup
#setup | psql -U postgres travegodb

current_partition:='int_log_table_$TABLE_TODAY_'||to_char(NEW.created_at,'yyyy_mm_dd');
exit

echo "
CREATE OR REPLACE FUNCTION int_log_table_insert_trigger()
RETURNS TRIGGER AS \$\$
BEGIN
       IF ( NEW.log_insert_time >= DATE '$YESTERDAY' AND
            NEW.log_insert_time < DATE '$TODAY' ) THEN
                INSERT INTO int_log_table_$TABLE_YESTERDAY VALUES (NEW.*);
    ELSIF ( NEW.log_insert_time >= DATE '$TODAY' AND
            NEW.log_insert_time < DATE '$TOMORROW' ) THEN
                INSERT INTO int_log_table_$TABLE_TODAY VALUES (NEW.*);
    ELSIF ( NEW.log_insert_time >= DATE '$TOMORROW' AND
            NEW.log_insert_time < DATE '$LASTDAY' ) THEN
                INSERT INTO int_log_table_$TABLE_LAST VALUES (NEW.*);
    END IF;
RETURN NULL;
END;
\$\$
LANGUAGE plpgsql;
"
exit;

TABLE_PREFIX="emaillog_"
BASETABLE="emaillog_master"
TABLESPACE="emaillog_tblspc"
PARTITION_COl="log_insert_time"
echo $tomorrow
echo $next



echo "CREATE TABLE $TABLE_PREFIX$TABLENAME ( CHECK ( $PARTITION_COl >= DATE '$STARTDATE' AND $PARTITION_COl < DATE '$ENDDATE' ) ) INHERITS ($BASETABLE) TABLESPACE '$TABLESPACE' ; "
