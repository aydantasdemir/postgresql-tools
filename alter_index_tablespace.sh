#!/bin/bash

#######################################
## Script: alter_index_tablespace.sh ##
## Coded by Erkin Çakar              ##
## Date: 08-04-2013                  ##
#######################################

DB="warehouse"
TBLSPC="warehouse_idx_tblspc"

function throw_exception()
{
	if [ $? > 0 ]; then echo "ERROR: $1"; exit; fi
}

echo " ## All indexes in database \"$DB\" will be setted to tablespace \"$TBLSPC\" ##"
echo -n "Are you sure? [y/n]: "
read answer
if [ "$answer" != "y" ]
then
    echo "Script is terminated!"
    exit;
fi

INDEXES=$(psql -U postgres $DB -At -c "select indexrelname from pg_stat_user_indexes;" )
throw_exception "Index list cannot be retrived!"

for INDEX in $INDEXES
do
    echo "   --> ALTER INDEX $INDEX SET TABLESPACE $TBLSPC;"
    psql -U postgres $DB -c "ALTER INDEX $INDEX SET TABLESPACE $TBLSPC;" || throw_exception "asdf"
done

echo " ## Succesfully completed! All indexes are placed in \"$TBLSPC\" ##"