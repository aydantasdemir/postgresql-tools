#!/bin/bash

VERSION="9.2"
HOST="10.22.22.138"
USER="moveme"
CONFPATH="~"

/etc/init.d/postgresql-$VERSION stop

rm -rf /var/lib/pgsql/$VERSION/data/*

/usr/pgsql-$VERSION/bin/pg_basebackup -h $HOST -x -U $USER -D /var/lib/pgsql/$VERSION/data/ -l new_replica

cp $CONFPATH/postgresql.conf $CONFPATH/recovery.conf /var/lib/pgsql/$VERSION/data/

chown -R postgres:postgres /var/lib/pgsql/$VERSION/data/*
