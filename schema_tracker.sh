#!/bin/bash

usage()
{
cat << EOF

Example-1:  ./schema_tracker.sh --db dbname --user dbuser --email user@mail.com -run
Example-2:  ./schema_tracker.sh --db dbname --user dbuser --email user@mail.com -update
     
     Description: *** This helps to track database schema changes and to report the result to given email address ***
            Notes: *** Action options should be the last parameter of script ***
             
OPTIONS:
  ACTION OPTIONS
   -run         run at once. it is used to get database dump into file where fump file not exist
   -update      update periodically to get the result
    

  SETTER OPTIONS
   --db         sets the database name  
   --user       sets the database user 
   --email      sets the email which is sent the result
EOF
}

path="/tmp"
dump_file="$path/schema.dump"
new_dump_file="$path/schema.new.dump"
diff_file="diff.txt"
db=""
dbuser=""
email=""


if [ $# -eq 0 ]
then
    usage
fi

while [ $# -gt 0 ]
do
    exp=$(echo "$1" | grep '^-[[:lower:]]')
    if [ "$1" = "$exp" ]
    then
        #echo $1
        case "$1" in 
        "-h")
            usage
            exit
            ;;
        "-run")
            pg_dump -s $db -U $dbuser -f $dump_file
            ;;
        "-update")
            if [ ! -e $dump_file ]
            then
                echo "ERROR: $db not exist. It will be created.."
                pg_dump -s $db -U $dbuser -f $dump_file
                exit
            fi

            pg_dump -s $db -U $dbuser -f $new_dump_file 
            diff $dump_file $new_dump_file > $diff_file
            if [  -s $diff_file ]
            then
                mail -s "$db schema changes" $email < $diff_file
            fi
            mv $new_dump_file $dump_file
            rm $diff_file
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
            dump_file="$path/$db.dump"
            new_dump_file="$path/$db.new.dump"
            diff_file="$path/$db.diff"
            ;;
        "--user")
            dbuser=$2
            ;;
        "--email")
            email=$2
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