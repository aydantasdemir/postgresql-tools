#!/bin/bash

#######################################
## Script: alter_index_tablespace.sh ##
## Coded by Erkin Çakar              ##
## Date: 08-04-2013                  ##
#######################################

DB="travegodb"
TBLSPC="dikey_data"
idx_cnt=0

throw_ex() { if [ $? > 0 ]; then echo "ERROR: $1"; exit; fi }

echo " ## All indexes in database \"$DB\" will be setted to tablespace \"$TBLSPC\" ##"
echo -n " ## Are you sure? [y/n]: "
read answer
if [ "$answer" != "y" ]
then
    echo "Script is terminated!"
    exit;
fi

INDEXES=`psql -U postgres -d $DB -At -c "select indexrelname from pg_stat_user_indexes;"` ||throw_ex "Index list cannot be retrived!"

for INDEX in $INDEXES
do
    echo "   --> ALTER INDEX \"$INDEX\" SET TABLESPACE \"$TBLSPC;\""
    psql -U postgres $DB -c "ALTER INDEX $INDEX SET TABLESPACE $TBLSPC;" > /dev/null ||throw_ex "$INDEX cannot be moved to tablespace $TBLSPC"
    idx_cnt=$(( $idx_cnt + 1 ))
done

echo " ## Succesfully completed! Total $idx_cnt indexes are moved to tablespace \"$TBLSPC\" ##"