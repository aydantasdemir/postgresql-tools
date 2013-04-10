#!/bin/bash

DB="testdb"
SERVER=$(hostname)
PATH="/data/archives/backups"
EMAIL="info@email.com"

find $PATH/ -name "*.dump" -exec rm {} \;
pg_dump -U postgres -F c -b -f "$PATH/$(date +%a)-$DB.dump" $DB
if [ $? > 0 ]
then
   ls -lh $PATH/$(date +%a)-$DB.dump | mail -s "PROBLEM: $DB($SERVER) dump" $EMAIL
   exit;
fi
ls -lh $PATH/$(date +%a)-$DB.dump | mail -s "$DB($SERVER) dump complete" $EMAIL
