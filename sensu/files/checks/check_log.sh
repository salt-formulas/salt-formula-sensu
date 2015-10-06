#!/bin/bash

#check logs
#usage: ./check_log.sh -p path_to_log -l check_for_last_x_minutes -r regular_expression_you_are_looking_for -c check_last_n_lines

while getopts ":p:l:r:c:" opt; do
    case $opt in
        p)
            LOGPATH=${OPTARG};;
        l)
            LAST=${OPTARG};;
        r)
            REGEXP=${OPTARG};;
        c)
            LINESCOUNT=${OPTARG};;
       \?)
            echo "Invalid option";exit 1;;
        : ) echo "Option -"$OPTARG" requires an argument." >&2
            exit 1;;
    esac
done

NAME=$(echo "$LOGPATH" | sed "s/.*\///" | sed "s/\..*//")

LASTCHANGED=$(expr `date +%s` - `stat -c %Y $LOGPATH`)

LAST=$[LAST*60]

if [[ $LASTCHANGED -gt $LAST ]]; then
        echo No new lines in file.
        exit 0
fi

tail -$LINESCOUNT $LOGPATH > LASTLINES_$NAME

ERRCODE=0
while read line; do
        if [[ $line == *"$REGEXP"* ]]; then
                EXITCODE=$[EXITCODE+1]
        fi
done < LASTLINES_$NAME

rm -rf /etc/sensu/plugins/LASTLINES_$NAME

if [[ $EXITCODE -gt 0 ]]; then
        echo CRIT:$EXITCODE from last $LINESCOUNT lines.
        exit 2
else
        echo OK:$EXITCODE
        exit 1
fi