#!/bin/bash

VERSION="9.2"
DB_PATH="/var/lib/pgsql/$VERSION/data"
OLD_XLOG_DIR="$DB_PATH/pg_xlog"
NEW_XLOG_PATH="/data/archives"
NEW_XLOG_DIR="$NEW_XLOG_PATH/pg_xlog"

throw_ex() { if [ $? > 0 ]; then echo "ERROR: $1"; exit; fi }

rollback()
{
    echo " ## IMPORTANT! Something went wrong. Rollback is starting. ##"
    if [ -e "$OLD_XLOG_DIR"_old ]
    then
        rm -f $OLD_XLOG_DIR
        echo "      --> Link \"$OLD_XLOG_DIR\" is removed."
        mv "$OLD_XLOG_DIR"_old "$OLD_XLOG_DIR"
        echo "      --> The directory "$OLD_XLOG_DIR"_old renamed to $OLD_XLOG_DIR"
        echo " ## All changes are rollbacked. ##"
        exit;
    fi
}

echo " ## PostgreSQL pg_xlog directory will be linked by coping files another directory ##"
if ! [ -e $NEW_XLOG_DIR ]
then
    mkdir -p $NEW_XLOG_DIR ||throw_ex "The directory \"$NEW_XLOG_DIR\" cannot be created."
    chown postgres: $NEW_XLOG_DIR ||throw_ex "Owner of the directory \"$NEW_XLOG_DIR\" cannot be changed to postgres."
    echo "   --> $NEW_XLOG_DIR folder created."
else
    echo "   --> $NEW_XLOG_DIR already exists."
fi

echo "   --> Copying current pg_xlog directory to new one."
if ! [ -h $OLD_XLOG_DIR ] ## is symbolic link created?
then
    cp -R "$OLD_XLOG_DIR" "$NEW_XLOG_PATH/" ||throw_ex "The directory \"$OLD_XLOG_DIR\" cannot be copied to the directory \"$NEW_XLOG_DIR\"."
    chown postgres: -R "$NEW_XLOG_DIR" ||throw_ex "Owner of the directory \"$NEW_XLOG_DIR\" cannot be changed to postgres."
    echo "   --> The owner of $NEW_XLOG_PATH directory changed to postgres"
else
    echo "ERROR: Symbolic link was created. Script is terminated!"
    exit;
fi

mv "$OLD_XLOG_DIR" "$OLD_XLOG_DIR"_old ||throw_ex "The directory \"$OLD_XLOG_DIR\" cannot be removed. "
echo "   --> $OLD_XLOG_DIR/ directory is backed up."

ln -s "$NEW_XLOG_DIR/" "$DB_PATH/" ||(rollback && throw_ex "The link \"$NEW_XLOG_DIR\" -> \"$DB_PATH\" cannot be created. ")
echo "   --> $OLD_XLOG_DIR Link is created."

echo -n "Would you like to remove the directory "$OLD_XLOG_DIR"_old? [y/n]: "
read answer
if [ "$answer" == "y" ]
then
    rm -rf "$OLD_XLOG_DIR"_old ||throw_ex "The directory \"$OLD_XLOG_DIR\" cannot be removed. "
    echo "   --> "$OLD_XLOG_DIR"_old directory is removed."
fi

echo " ## Succesfully completed ##"