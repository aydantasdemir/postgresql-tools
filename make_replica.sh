#!/bin/bash

#############################
## Script: make_replica.sh ##
## Coded by Erkin Çakar    ##
## Date: 08-04-2013        ##
#############################


VERSION="9.2"
HOST="10.22.22.138"
USER="moveme"
CONFPATH="/root"
DATADIR="/var/lib/pgsql/$VERSION/data"
OUTPUT="/dev/null"

PG_CONF="$CONFPATH"/postgresql.conf
HBA_CONF="$CONFPATH"/pg_hba.conf
RECOVERY_CONF="$CONFPATH"/recovery.conf

throw_ex() { if [ $? > 0 ]; then echo "ERROR: $1"; exit; fi }

echo " ## Hot standby replication server setup is starting now ##"

[ -e "$PG_CONF" -a -e "$HBA_CONF" -a -e "$RECOVERY_CONF" ] \
&& echo "   [OK] $PG_CONF"  && echo "   [OK] $HBA_CONF"  && echo "   [OK] $RECOVERY_CONF"  \
||throw_ex "Please check [ postgresql.conf & pg_hba.conf & recovery.conf ] in \"$CONFPATH\" path"

/etc/init.d/postgresql-$VERSION stop 2> $OUTPUT ||throw_ex "Cannot stop PostgreSQL!"

rm -rf $DATADIR/* ||throw_ex "Cannot be deleted Data directory!"
echo "   --> PostgreSQL data directory: \"$DATADIR\" is DELETED."
echo "   --> pg_basebackup tool is starting..."
/usr/pgsql-$VERSION/bin/pg_basebackup -h $HOST -U $USER -D $DATADIR/ -P -x -c fast -l new_replica ||throw_ex "Problem in pg_basebackup tool"
echo "   --> pg_basebackup completed! √"
cp $PG_CONF $HBA_CONF $RECOVERY_CONF $DATADIR/ ||throw_ex "Cannot be copied config files"
echo "   --> [postgresql.conf] & [pg_hba.conf] & [recovery.conf] are copied into data directory"
chown -R postgres: $DATADIR/* ||throw_ex "Owner of data directory cannot be changed!"
echo "   --> The owner of data directory setted to postgres"
echo " ## Hot standby PostgreSQL Server is ready to start! ##"
