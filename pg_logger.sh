#!/bin/bash

MACHINE=$(hostname)
VERSION="9.2"
LOGPATH="/var/log/pgsql/$VERSION/data/pg_log"
LOG="postgresql-$(date +%a -d 'yesterday').log"
LOGDIR="/home/travego/pgLogger/pglogs/"
OUTPUTDIR="/home/travego/pgLogger/finished/"
OUTPUTLOG="$MACHINE-$LOG"
HOST="travego@10.22.2.110:"


rsync -av $LOGPATH/$LOG $LOGDIR/$COMINGLOG
pgfouine -file $LOGDIR/$LOG -logtype stderr > $OUTPUTDIR/$OUTPUTLOG

