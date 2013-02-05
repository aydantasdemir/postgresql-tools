#!/bin/bash

DB=$1
FILE=$2

echo $FILE
echo $DB

psql -U postgres $DB < $FILE

