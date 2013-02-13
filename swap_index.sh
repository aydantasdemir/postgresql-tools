#!/bin/bash

DB="testdb"
INDEX="$1"
TBLSPC="warehouse_idx_tblspc"


CREATE_INDEX=`psql -U postgres $DB -At -c "SELECT indexdef FROM pg_indexes WHERE indexname='$INDEX'"`
if [ "$CREATE_INDEX" = "" ]
    then
    echo "   ERROR: $INDEX NOT EXIST!"
    exit
fi
CREATE_INDEX=`echo $CREATE_INDEX | sed "s/$INDEX/$INDEX"_new"/" | sed 's/CREATE INDEX/CREATE INDEX CONCURRENTLY/' | sed "s/$/ TABLESPACE $TBLSPC;/"`

echo $CREATE_INDEX
echo "
ALTER INDEX $INDEX RENAME TO $INDEX"_old";
ALTER INDEX $INDEX"_new" RENAME TO $INDEX;
DROP INDEX CONCURRENTLY $INDEX"_old";"

