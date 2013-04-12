#!/bin/bash

LIMIT=50000
FILE="silent.txt"
TMPFILE="tmp.file"
TOTAL=$(cat $FILE | wc -l)
LOOP=$(echo $TOTAL/$LIMIT | bc)
echo "Loop: $LOOP"
LOOP=$(echo $LOOP+1 | bc)
LOOP=75
SQL="UPDATE x SET finishes_at='2013-02-28 23:59:59' WHERE code IN "

#Splitting into small pieces
for row in $(seq 1 $LOOP)
do    
    echo "$FILE.$row"
    sed -n -e '1,50000p' $FILE > "$FILE.$row"
    sed -e "s/$/\'/g"  $FILE.$row | sed -e "s/^/\'/g" | sed -e "s/\n/,/g" | sed -e ':a;N;$!ba;s/\n/,/g' | sed -e 's/^/(/' | sed -e 's/$/);/' | sed -e "s/^/$SQL/"  >  $TMPFILE
    cat $TMPFILE > $FILE.$row
    sed -e '1,50000d' $FILE > $TMPFILE
    cat $TMPFILE > $FILE
done

#Run splitted files in psql
for row in $(ls $FILE.*)
do
    echo $row
    psql -U postgres db < $row
    sleep 2
done
