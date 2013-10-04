#!/bin/bash

DB="travego"
SERVER=$(hostname)
BCKP_PATH="/data/archives/backups"
EMAIL="erk.cakar@gmail.com"

#find /data/archives/backups/ -name "*.dump" -exec rm {} \;
#rm -f "$BCKP_PATH/$(date +%a -d '2 days ago')-$DB.dump"

pg_dump -U postgres -F c -b -f "$BCKP_PATH/$(date +%a)-$DB.dump" $DB 2> /tmp/bckscrpt.log \
&& ls -lh $BCKP_PATH/$(date +%a)-$DB.dump | mail -s "$DB($SERVER) dump complete" $EMAIL \
|| cat /tmp/bckscrpt.log | mail -s "PROBLEM: $DB($SERVER) dump" $EMAIL
