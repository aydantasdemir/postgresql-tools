#!/bin/bash

DB="travegodb"
SERVER=$(hostname)
BCKP_PATH="/data/archives/backups"
EMAIL="travego@localhost"

find /data/archives/backups/ -name "*.dump" -exec rm {} \;
pg_dump -U postgres -F c -b -f "$BCKP_PATH/$(date +%a)-$DB.dump" $DB
if [ $? > 0 ]
then
   ls -lh $BCKP_PATH/$(date +%a)-$DB.dump | mail -s "PROBLEM: $DB($SERVER) dump" $EMAIL
   exit;
fi
ls -lh $BCKP_PATH/$(date +%a)-$DB.dump | mail -s "$DB($SERVER) dump complete" $EMAIL
