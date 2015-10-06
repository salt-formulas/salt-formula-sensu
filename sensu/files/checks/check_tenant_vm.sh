#!/bin/bash
#check vm state in tenant

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
read -ra nova_vm_state <<< $(nova --os-username $user --os-password $passwd --os-tenant-name $tenant --os-auth-url $host list | head -n -1 | tr -d "|" | awk '/'ERROR'/ {print "VM: " $2 " ID: " $1 "  is in ERROR state" ";"}')

EXITVAL=0

if [[ -n ${nova_vm_state[@]} ]]; then
    EXITVAL=1
fi

if [ $EXITVAL != 0 ]; then
        echo "Tenant: $tenant ${nova_vm_state[@]}"
fi
exit $EXITVAL
