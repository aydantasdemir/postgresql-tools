#!/bin/bash

LOG_PATH="/home/report/pgLogger"
INCOMING_PATH="$LOG_PATH/incomings"
ANALYZED_LOG_PATH="$LOG_PATH/analyzedLogs"
DAY=$(date +%a -d 'yesterday')
LOG="postgresql-$DAY.log"
LINK="/var/www/logs"
USER="root"
VERSION="9.2"
PG_DATA="/var/lib/pgsql/$VERSION/data"

SERVER_LIST="server1 server2 server3"

for SERVER_NAME in $SERVER_LIST
do
    SERVER=$SERVER_NAME".domain.vpn"
    echo -n "\nServer: $SERVER\n"
    /usr/bin/scp "$USER@$SERVER:$PG_DATA/pg_log/$LOG" "$INCOMING_PATH/$SERVER_NAME-$LOG"
    echo "--> pgFouine is starting"
    pgfouine -file "$INCOMING_PATH/$SERVER_NAME-$LOG" -logtype stderr > "$ANALYZED_LOG_PATH/$SERVER_NAME-$DAY.html" 2> /dev/null
    echo "--> pgFoiune Completed"
    cp "$ANALYZED_LOG_PATH/$SERVER_NAME-$DAY.html" "$LINK/$SERVER_NAME-$DAY.html"
    echo "172.18.140.17/logs/$SERVER_NAME-$DAY.html"
done

