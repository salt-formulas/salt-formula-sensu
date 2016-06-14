#!/bin/bash
#check cinder service-list on ctls

usage() {
    echo "usage: ./check_cinder_services.sh -u <openstack.user> -p <openstack.password> -t <openstack.tenant> -h 'http://<openstack.host>:<openstack.port>/v2.0'"
    exit 1
}

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
        \? )
            echo "Invalid option"
            usage;;
        : ) echo "Option -"$OPTARG" requires an argument." >&2
            usage;;
    esac
done

exit_critical() {
    echo "CRITICAL: $*"
    exit 2
}

exit_ok() {
    echo "OK: $*"
    exit 0
}
read -ra cinder_state <<< $(cinder --os-username $user --os-password $passwd --os-tenant-name $tenant --os-auth-url $host service-list)

if [[ -z ${cinder_state[@]} ]]; then
    exit_critical "Unknown error."
fi

read -ra cinder_state_down <<< $(cinder --os-username $user --os-password $passwd --os-tenant-name $tenant --os-auth-url $host service-list | head -n -1 | tr -d "|" | awk '/'down'/ {print "Service " $1 " on " $2 " is DOWN" ";"}')

EXITVAL=0

if [[ -n ${cinder_state_down[@]} ]]; then

    read -ra scheduler_test <<< ${cinder_state_down[@]#cinder-scheduler}

        if [ ${#cinder_state_down[@]} -ne ${#scheduler_test[@]} ]; then
        EXITVAL=2
        fi

    read -ra volume_test <<< ${cinder_state_down[@]#cinder-volume}

        if [ ${#cinder_state_down[@]} -ne ${#volume_test[@]} ]; then
        EXITVAL=2
        fi
fi

if [ $EXITVAL != 0 ]; then
    exit_critical ${cinder_state_down[@]}
else
    exit_ok "All cinder services up."
fi