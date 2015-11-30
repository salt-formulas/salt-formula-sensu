#!/bin/bash

while getopts ":u:p:t:h:" opt; do
    case $opt in
        u)
            user=${OPTARG};;
        p)
            passwd=${OPTARG};;
        t)
            tenant=${OPTARG};;
        h)
            host=${OPTARG};;
       \?)
            echo "Invalid option";exit 1;;
        : ) echo "Option -"$OPTARG" requires an argument." >&2
            exit 1;;
    esac
done

status=$(nova --os-username $user --os-password $passwd --os-tenant-name $tenant --os-auth-url $host volume-list | grep TestVolume01 | awk '{print $4}')

if [[ -n $status ]]; then
	echo "Volume TestVolume01 already exist, please delete it and recheck cinder service!"
	exit 2
fi

nova --os-username $user --os-password $passwd --os-tenant-name $tenant --os-auth-url $host volume-create --display-name TestVolume01 1
sleep 3
read -ra vol_status <<< $(nova --os-username $user --os-password $passwd --os-tenant-name $tenant --os-auth-url $host volume-list | grep TestVolume01)

vol_id=${vol_status[1]}
status=${vol_status[3]}

if [[ "$status" == "available" ]];then
	echo "Volume $status. OK!"
	nova --os-username $user --os-password $passwd --os-tenant-name $tenant --os-auth-url $host volume-delete $vol_id
	exit 0
else
	echo "Volume TestVolume01 is in $status state, please check cinder service!"
	exit 2
fi

