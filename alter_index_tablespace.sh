#!/bin/bash

#DB="warehouse"
#TBLSPC="warehouse_idx_tblspc"

#INDEXES=$(psql -U postgres $DB -At -c "select indexname from pg_indexes where schemaname !='pg_catalog';")

#for INDEX in $INDEXES
#do
#	echo "ALTER INDEX $INDEX SET TABLESPACE $TBLSPC;"
#	psql -U postgres $DB -c "ALTER INDEX $INDEX SET TABLESPACE $TBLSPC;"
#done


