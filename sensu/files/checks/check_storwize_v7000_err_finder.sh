#!/bin/bash

#check IBM v7000
#usage: ./check_storwize_v7000_err_finder.sh -p password -h host_ip -u user

while getopts ":u:p:h:" opt; do
    case $opt in
        u)
            USER=${OPTARG};;
        p)
            PASSWD=${OPTARG};;
        h)
            HOST=${OPTARG};;
       \?)
            echo "Invalid option";exit 1;;
        : ) echo "Option -"$OPTARG" requires an argument." >&2
            exit 1;;
    esac
done

command -v sshpass >/dev/null 2>&1 || { echo "Missing program sshpass. Aborting." >&2; exit 1; }

ERRCODE=`sshpass -p "$PASSWD" ssh $USER@$HOST -o StrictHostKeyChecking=no "svctask finderr" | cut -d "[" -f2 | cut -d "]" -f1`

if [[ ${ERRCODE[@]}="There are no unfixed errors" ]]; then
	exit 0
else
	CONDITION=`cat ./svc_error_database | grep $ERRCODE`
	echo "Storwize V7000 $HOST $CONDITION"
	exit 2
fi


