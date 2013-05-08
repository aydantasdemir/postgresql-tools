#!/bin/bash

#############################
## Script: make_replica.sh ##
## Coded by Erkin Çakar    ##
## Date: 16-04-2013        ##
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
echo -n  "   ## Enter tablespace directory paths if you have in master: "
read TABLESPACES

for TBLSPC in $TABLESPACES
do
    if ! [ -e $TBLSPC ]
    then
        mkdir -p $TBLSPC ||throw_ex "$TBLSPC directory cannot be created"
        chown -R postgres: $TBLSPC ||throw_ex "$TBLSPC owner cannot be changed to postgres"
        echo "   [CREATED]: The directory \"$TBLSPC\""
    else
        rm -rf $TBLSPC/* ||throw_ex "$TBLCSPC cannot be deleted"
        echo "   [CLEANED]: The directory \"$TBLSPC\""
    fi
done

[ -e "$PG_CONF" -a -e "$HBA_CONF" -a -e "$RECOVERY_CONF" ] \
&& echo "   [EXIST]: File \"$PG_CONF\""  && echo "   [EXIST]: File \"$HBA_CONF\""  && echo "   [EXIST]: File \"$RECOVERY_CONF\""  \
||throw_ex "Please check [ postgresql.conf & pg_hba.conf & recovery.conf ] in \"$CONFPATH\" path"

/etc/init.d/postgresql-$VERSION stop 2> $OUTPUT ||throw_ex "Cannot stop PostgreSQL!"

rm -rf $DATADIR/* ||throw_ex "Cannot be deleted Data directory!"
echo "   [DELETED]: PostgreSQL data directory: \"$DATADIR\""
echo "   [STARTING]: pg_basebackup"
/usr/pgsql-$VERSION/bin/pg_basebackup -h $HOST -U $USER -D $DATADIR/ -P -x -c fast -l new_replica ||throw_ex "Problem in pg_basebackup tool"
echo "   [COMPLETED]: pg_basebackup √"
cp $PG_CONF $HBA_CONF $RECOVERY_CONF $DATADIR/ ||throw_ex "Cannot be copied config files"
echo "   [COPIED]: #postgresql.conf #pg_hba.conf #recovery.conf --> data directory \"$DATADIR\""
chown -R postgres: $DATADIR/* ||throw_ex "Owner of data directory cannot be changed!"
echo "   --> The owner of data directory setted to postgres"
echo " ## Hot standby PostgreSQL Server is ready to start! ##"
