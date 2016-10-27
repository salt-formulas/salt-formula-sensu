#!/bin/bash
#checks nova hypervisor-stats for available disk space.

usage() {
        echo "checks nova hypervisor-stats for available disk space."
        echo "Shows available space on hypervisors"
    echo "usage: ./check_nova_compute_disk_space.sh -u <openstack.user> -p <openstack.password> -t <openstack.tenant> -h 'http://<openstack.host>:<openstack.port>/v2.0' -r <region.name> -w <warning.threshold> [default 150] -c <critical.threshold> [default 50]"
    exit 1
}

if [[ ! $@ =~ ^\-.+ ]]
then
        usage
fi

while getopts ":u:p:t:h:r:w:c:" opt; do
    case $opt in
        u)
            USER=${OPTARG};;
        p)
            PASSWD=${OPTARG};;
        t)
            TENANT=${OPTARG};;
        h)
            HOST=${OPTARG};;
        r)
            REGION=${OPTARG};;
        w)
            WARN=${OPTARG};;
        c)
            CRIT=${OPTARG};;
       \?)
            echo "Invalid option"
            usage;;
        : ) echo "Option -"$OPTARG" requires an argument." >&2
            usage;;
    esac
done

WARN=${WARN:-150}
CRIT=${CRIT:-50}

exit_ok() {
    echo "OK: $*"
    exit 0
}
exit_warning() {
    echo "WARNING: $*"
    exit 1
}
exit_critical() {
    echo "CRITICAL: $*"
    exit 2
}

DISK_SPACE=$(nova --os-username $USER --os-password $PASSWD --os-tenant-name $TENANT --os-auth-url $HOST --os-region-name $REGION hypervisor-stats | grep disk_available_least | awk '{print $4}')

if [[ -z $DISK_SPACE ]]; then
        exit_critical "Unknown error"
fi

if [[ -n $DISK_SPACE ]]; then
        if [[ $DISK_SPACE -le $WARN ]]; then
                exit_warning Disk available space $DISK_SPACE GB
	elif [[ $DISK_SPACE -le $CRIT ]]; then
                exit_critical Disk available space $DISK_SPACE GB
	else
		exit_ok Disk available space $DISK_SPACE GB
        fi
else
        exit_critical "Unknown error"
fi