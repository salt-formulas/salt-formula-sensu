#!/bin/bash
#checks nova hypervisor available RAM.

usage() {
    echo "checks nova hypervisor-stats for available RAM space on hypervisors."
    echo "usage: ./check_nova_compute_ram_space.sh -u <openstack.user> -p <openstack.password> -t <openstack.tenant> -h 'http://<openstack.host>:<openstack.port>/v2.0' -r <region.name> -w <warning.threshold> [default 100] -c <critical.threshold> [default 30]"
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

WARN=${WARN:-100}
CRIT=${CRIT:-30}

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

FREE_RAM=$(nova --os-username $USER --os-password $PASSWD --os-tenant-name $TENANT --os-auth-url $HOST --os-region-name $REGION hypervisor-stats | grep free_ram_mb | awk '{print $4}')

if [[ -z $FREE_RAM ]]; then
        exit_critical "Unknown error"
fi

if [[ -n $FREE_RAM ]]; then
        if [[ $FREE_RAM -le $WARN ]]; then
                exit_warning Available RAM $FREE_RAM GB
	elif [[ $FREE_RAM -le $CRIT ]]; then
                exit_critical Available RAM $FREE_RAM GB
	else
		exit_ok Available RAM $FREE_RAM GB
        fi
else
        exit_critical "Unknown error"
fi