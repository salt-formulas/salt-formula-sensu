#!/bin/bash
#check nova service-list on ctls

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

read -ra nova_state_down <<< $(nova --os-username $user --os-password $passwd --os-tenant-name $tenant --os-auth-url $host service-list | head -n -1 | tr -d "|" | awk '/'down'/ {print "Service " $2 " on " $3 " is DOWN" ";"}')

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
                EXITVAL=2
        fi

    read -ra conductor_test <<< ${nova_state_down[@]#nova-conductor}

        if [ ${#nova_state_down[@]} -ne ${#conductor_test[@]} ]; then
                EXITVAL=2
        fi

    read -ra compute_test <<< ${nova_state_down[@]#nova-compute}

        if [ ${#nova_state_down[@]} -ne ${#compute_test[@]} ]; then
                EXITVAL=2
        fi

fi

if [ $EXITVAL != 0 ]; then
        echo ${nova_state_down[@]}
fi

exit $EXITVAL
