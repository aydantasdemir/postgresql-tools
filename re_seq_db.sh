#!/bin/bash

## ERKİN ÇAKAR ##
## 05.04.2013  ##
## Script finds whether sequences are different    ##
## with table or not and fixes sequence with table ##

DB="markafoni"
USER="postgres"

TABLES=`psql -U $USER -d $DB -At -c "SELECT relname FROM pg_stat_user_tables order by relname;"`

echo "## Re-numbering of ID sequences for database $DB ##"
echo ""
for table in $TABLES
do
    TABLE_LAST_ID=`psql -U $USER -d $DB -At -c "SELECT max(id) FROM $table" 2> /dev/null`
    if [ $? -eq 0 ]
    then
        SEQ=$table"_id_seq"
        SEQ_LAST_ID=`psql -U $USER -d $DB -At -c "SELECT last_value FROM $SEQ" 2> /dev/null `
        if [ $? -eq 0 ]
        then
            if [ "$TABLE_LAST_ID" != "" ]
            then
                if [ "$TABLE_LAST_ID" != "$SEQ_LAST_ID" ]
                then
                    echo "SEQUENCE FIXED: $table($TABLE_LAST_ID) | $SEQ($SEQ_LAST_ID) -- $SEQ is setted to $TABLE_LAST_ID"
                    psql -U $USER -d $DB -c "SELECT setval('$SEQ',$TABLE_LAST_ID);" > /dev/null
                    if [ $? -ne 0 ]
                    then
                        echo "$SEQ cannot be setted."
                    fi
                fi
            fi
        else
            echo "IGNORED SEQUENCE: $SEQ"
        fi
    else
        echo "IGNORED TABLE: $table"
    fi
done
echo ""
echo "## Re-numbering is finished for database $DB ##"
