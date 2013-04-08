#!/bin/bash

usage()
{
cat << EOF

Example-1:  ./dbstats_tracker.sh --max-ratio 1 --db dbname --user dbuser --email user@mail.com -run
Example-2:  ./dbstats_tracker.sh --max-ratio 1 --db dbname --user dbuser --email user@mail.com -update
     
     Description: *** This helps to track database tables growth rates and to report the result to given email address ***
            Notes: *** Action options should be the last parameter of script ***
             
OPTIONS:
  ACTION OPTIONS
   -run         run at once. it is used for get table sizes into file where log file not exist
   -update      update periodically to get the result
    

  SETTER OPTIONS
   --db         sets the database name  
   --user       sets the database user 
   --email      sets the email which is sent the result
   --max-ratio  sets the ratio value. if growth ratio of the table is exceeded, that table is recorded  
EOF
}


db=""
dbuser=""
email=""
max_ratio="0"
path="/tmp"
file="$path/dbstat.txt"
tmp_file="$path/tmpdb.txt"
sizepost="MB"
today=$(date +%d.%m.%y)""
table_file="$path/table.csv"
index_file="$path/index.csv"

run()
{
    psql -d $db -U $dbuser -At -c "copy (select t1.relname,pg_relation_size(oid) as size from pg_class t1, pg_stat_user_tables t2 where t1.relname=t2.relname order by size desc ) to '$table_file' DELIMITER ' ' CSV"
    psql -d $db -U $dbuser -At -c "copy (select t2.indexrelname,pg_relation_size(oid) as size from pg_class t1, pg_stat_user_indexes t2 where t1.relname=t2.indexrelname order by size desc ) to '$index_file' DELIMITER ' ' CSV"
}

if [ $# -eq 0 ]
then
    usage
fi

while [ $# -gt 0 ]
do
    exp=$(echo "$1" | grep '^-[[:lower:]]')
    if [ "$1" = "$exp" ]
    then
        case "$1" in 
        "-h")
            usage
            exit
            ;;
        "-run")
            run
            ;;
        "-update")
            if ! [ -e $table_file -a -e $index_file ]
                then
                echo "Error: Required files don't exist so they will be created.."
                run
                exit
            fi

            echo "DB Name: $db | $today" > $file
            echo "" >> $file
            echo "Table Growth Ratios: desc order" >> $file
            echo "-------------------------------" >> $file

            if [ -e $tmp_file ]
                then
                rm $tmp_file
            fi
            while read line ; do
                table=$(echo $line | awk 'BEGIN{FS=" "}{print $1}')
                size=$(echo $line | awk 'BEGIN{FS=" "}{print $2}')

                newsize=`psql -d $db -U $dbuser -At -c "select pg_relation_size(c.oid) as size from pg_class c where relname='$table'"`
                echo $table
                if [[ $size > 0 ]]
                then
                    ratio=`echo "scale = 2; 100.0*($newsize-$size)/$size" | bc | awk '{printf("%.2f\n",$1)}'`
                    statement=`echo $ratio'>='$max_ratio | bc`
                    
                    if [ $statement -eq 1 ]
                    then
                        #size=`psql -d $db -U $dbuser -At -c "select pg_size_pretty($size)"`
                        newsize=`echo "scale = 2; $newsize/1024/1024" | bc | awk '{printf("%.2f",$1)}'`
                        statement=`echo $newsize'<'1000 | bc`
                        if [ $statement -eq 1 ]
                            then
                            sizepost="MB"
                        else
                            sizepost="GB"
                            newsize=`echo "scale = 2; $newsize/1024" | bc | awk '{printf("%.2f",$1)}'`
                        fi
                        echo "$table %$ratio ($newsize $sizepost)" >> $tmp_file
                    fi
                else
                    ratio=0
                fi
            done < $table_file

            if [ -e $tmp_file ]
            then
                cat $tmp_file | sort -k 2 -r >> $file
                rm $tmp_file
            fi
            
            echo "" >> $file
            echo "Index Growth Ratios: desc order" >> $file
            echo "-------------------------------" >> $file

            while read line ; do
                index=$(echo $line | awk 'BEGIN{FS=" "}{print $1}')
                size=$(echo $line | awk 'BEGIN{FS=" "}{print $2}')
                newsize=`psql -d $db -U $dbuser -At -c "select pg_relation_size(c.oid) as size from pg_class c where relname='$index'"`
                echo $index
                if [[ $size > 0 ]]
                then
                    ratio=`echo "scale = 2; 100.0*($newsize-$size)/$size*1.0" | bc | awk '{printf("%.2f\n",$1)}'`
                    statement=`echo $ratio'>='$max_ratio | bc`
                    if [ $statement -eq 1 ]
                    then
                        #size=`psql -d $db -U $dbuser -At -c "select pg_size_pretty($size)"`
                        newsize=`echo "scale = 2; $newsize/1024/1024" | bc | awk '{printf("%.2f\n",$1)}'`
                        statement=`echo $newsize'<'1000 | bc`
                        if [ $statement -eq 1 ]
                            then
                            sizepost="MB"
                        else
                            sizepost="GB"
                            newsize=`echo "scale = 2; $newsize/1024" | bc | awk '{printf("%.2f",$1)}'`
                        fi
                        echo "$index %$ratio ($newsize $sizepost)" >> $tmp_file
                    fi
                else
                    ratio=0
                fi
            done < $index_file
            
            if [ -e $tmp_file ]
            then
                cat $tmp_file | sort -k 2 -r >> $file
                rm $tmp_file
            fi
            run
            cat $file
            mail -s "$db DB Growth Ratios" $email < $file
            ;;
        *)
            echo "Unknown option: $1"
            exit
            ;;
        esac
        shift
    elif [ "$1" = $(echo "$1" | grep '^--[[:lower:]]') ]
    then
        case "$1" in
        "--db")
            db=$2
            file="$path/dbstat_$db.txt"
            table_file="$path/$db-table.csv"
            index_file="$path/$db-index.csv"
            ;;
        "--user")
            dbuser=$2
            ;;
        "--email")
            email=$2
            ;;
        "--max-ratio")
            max_ratio=$2
            ;;
        *)
            echo "Unknown option: $1"
            exit
            ;;
        esac
        echo "  $1 is setted to $2"
        shift 2
    else
        echo "Error $1: wrong parameter"    
        exit
    fi
done