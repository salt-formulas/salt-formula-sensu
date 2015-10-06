#!/bin/bash

#check IBM v7000
#usage: ./check_storwize_v7000.sh -p password -h host_ip -u user -i ignored_argument

while getopts ":u:p:h:i:" opt; do
    case $opt in
        u)
            USER=${OPTARG};;
        p)
            PASSWD=${OPTARG};;
        h)
            HOST=${OPTARG};;
        i)
            IGNORE=${OPTARG};;
       \?)
            echo "Invalid option";exit 1;;
        : ) echo "Option -"$OPTARG" requires an argument." >&2
            exit 1;;
    esac
done

command -v sshpass >/dev/null 2>&1 || { echo "Missing program sshpass. Aborting." >&2; exit 1; }
sshpass -p $PASSWD ssh $USER@$HOST -o StrictHostKeyChecking=no "lseventlog -message no" | grep alert > /etc/sensu/plugins/lsevents_$HOST.log

declare -a LINES
let i=0
ERRCODES=()
CRIT=0
while IFS=$'\n' read -r line_data; do
    LINES[i]="${line_data}"
    VAR="${LINES[i++]}"
    VAR=" ${VAR:100}|"
    if [[ -n $IGNORE && $VAR == *"$IGNORE"* ]]; then
        VAR=
    fi
    CRIT=$[CRIT+1]
    ERRCODES+=$VAR
done < /etc/sensu/plugins/lsevents_$HOST.log
rm -rf /etc/sensu/plugins/lsevents_$HOST.log

if [[ -z ${ERRCODES[@]} ]]; then
        echo OK
        exit 0
else
        echo CRIT:$CRIT - ${ERRCODES[@]}
        exit 2
fi