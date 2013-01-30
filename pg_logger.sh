#!/bin/bash

MACHINE=$(hostname)
VERSION="9.2"
LOGPATH="/var/lib/pgsql/$VERSION/data/pg_log"
#LOGPATH="/var/lib/postgresql/$VERSION/main/pg_log"
LOG="postgresql-$(date +%a -d 'yesterday').log"
LOGDIR="/home/travego/pgLogger/pglogs"
OUTPUTDIR="/home/travego/pgLogger/finished"
OUTPUTLOG="$MACHINE-$LOG.html"
HOST="travego@10.22.2.110:"
HOST="root@tarantino.vpn.akinon.net:"
HOST="erkin.cakar@kirsten.vpn.akinon.net:"

echo $LOGPATH/$LOG
echo $LOGDIR/$LOG
 
#mkdir -p $OUTPUTDIR

rsync -av $HOST$LOGPATH/$LOG $LOGDIR/$LOG
pgfouine -file $LOGDIR/$LOG -logtype stderr > $OUTPUTDIR/$OUTPUTLOG

