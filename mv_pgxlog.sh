#!/bin/bash

VERSION="9.2"
DB_PATH="/var/lib/pgsql/$VERSION/data"
OLD_XLOG_DIR="$DB_PATH/pg_xlog"
NEW_XLOG_PATH="/data/archives"
NEW_XLOG_DIR="$NEW_XLOG_PATH/pg_xlog"

if ! [ -e $NEW_XLOG_DIR ]
then
    mkdir $NEW_XLOG_DIR
    chown postgres: $NEW_XLOG_DIR
    echo "$NEW_XLOG_DIR folder created."
else
    echo "$NEW_XLOG_DIR already exists."
fi

echo "Copying old pg_xlog directory to new one."
cp -R "$OLD_XLOG_DIR" "$NEW_XLOG_PATH/" 

chown postgres: -R "$NEW_XLOG_DIR"
echo "The owner of $NEW_XLOG_PATH directory changed to postgres"

rm -rf "$OLD_XLOG_DIR"
echo "$OLD_XLOG_DIR/ directory is removed."

ln -s "$NEW_XLOG_DIR/" "$DB_PATH/"
echo "$OLD_XLOG_DIR Link is created."
