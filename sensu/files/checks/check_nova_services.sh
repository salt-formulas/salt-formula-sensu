#!/bin/bash
#check nova service-list on ctls

usage() {
    echo "usage: ./check_nova_services.sh -u <openstack.user> -p <openstack.password> -t <openstack.tenant> -h 'http://<openstack.host>:<openstack.port>/v2.0' -r <region.name>"
    exit 1
}

while getopts ":u:p:t:h:r:" opt; do
    case $opt in
        u)
            user=${OPTARG};;
        p)
            passwd=${OPTARG};;
        t)
            tenant=${OPTARG};;
        h)
            host=${OPTARG};;
        r)
            region=${OPTARG};;
       \?)
            echo "Invalid option"
            usage;;
        : ) echo "Option -"$OPTARG" requires an argument." >&2
            usage;;
    esac
done

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

read -ra nova_state <<< $(nova --os-username $user --os-password $passwd --os-tenant-name $tenant --os-auth-url $host service-list)

if [[ -z ${nova_state[@]} ]]; then
        exit_critical "Unknown error"
fi
    
read -ra nova_state_down <<< $(nova --os-username $user --os-password $passwd --os-tenant-name $tenant --os-auth-url $host --os-region-name $region service-list | head -n -1 | tr -d "|" | grep enabled | awk '/'down'/ {print "Service " $2 " on " $3 " is DOWN" ";"}')

EXITVAL=0

if [[ -n ${nova_state_down[@]} ]]; then

    read -ra console_test <<< ${nova_state_down[@]#nova-console}

        if [ ${#nova_state_down[@]} -ne ${#console_test[@]} ]; then
        EXITVAL=1
        fi

    read -ra consoleauth_test <<< ${nova_state_down[@]#nova-consoleauth}

        if [ ${#nova_state_down[@]} -ne ${#consoleauth_test[@]} ]; then
                EXITVAL=1
        fi

    read -ra cert_test <<< ${nova_state_down[@]#nova-cert}

        if [ ${#nova_state_down[@]} -ne ${#cert_test[@]} ]; then
                EXITVAL=1
        fi

    read -ra scheduler_test <<< ${nova_state_down[@]#nova-scheduler}

        if [ ${#nova_state_down[@]} -ne ${#scheduler_test[@]} ]; then
                exit_critical ${nova_state_down[@]}
        fi

    read -ra conductor_test <<< ${nova_state_down[@]#nova-conductor}

        if [ ${#nova_state_down[@]} -ne ${#conductor_test[@]} ]; then
                exit_critical ${nova_state_down[@]}
        fi

    read -ra compute_test <<< ${nova_state_down[@]#nova-compute}

        if [ ${#nova_state_down[@]} -ne ${#compute_test[@]} ]; then
                exit_critical ${nova_state_down[@]}
        fi

fi

if [ $EXITVAL = 1 ]; then
        exit_warning ${nova_state_down[@]}
else
        exit_ok "All nova services running."
fi
