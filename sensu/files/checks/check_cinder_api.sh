#!/bin/bash

usage() {
    echo "Check list of available quotas from cinder API"
    echo "usage: ./check_cinder_api.sh -u <openstack.user> -p <openstack.password> -t <openstack.tenant> -h 'http://<openstack.host>' -w <warning-threshold [s]>"
    exit 1
}

if [[ ! $@ =~ ^\-.+ ]]
then
        usage
fi

while getopts ":u:p:t:h:w:" opt; do
    case $opt in
        u)
            USER=${OPTARG};;
        p)
            PASSWD=${OPTARG};;
        t)
            TENANT=${OPTARG};;
        h)
            HOST=${OPTARG};;
        w)
            WARNING=${OPTARG};;
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

command -v curl >/dev/null 2>&1 || { exit_critical "Missing program curl."; }

TOKEN=$(curl -s -X 'POST' $HOST:5000/v2.0/tokens -d '{"auth":{"passwordCredentials":{"username": "'$USER'", "password":"'$PASSWD'"}, "tenantName":"'$TENANT'"}}' -H 'Content-type: application/json' | python -c "import sys, json; print json.load(sys.stdin)['access']['token']['id']")

TENANT_ID=$(curl -s -H "X-Auth-Token: $TOKEN" $HOST:5000/v2.0/tenants | python -c "import sys, json; print json.load(sys.stdin)['tenants'][0]['id']")

if [ -z "$TENANT_ID" ]; then
    exit_critical "Unable to get tenant id"
fi

START=`date +%s`
QUOTAS=$(curl -s -H "X-Auth-Token: $TOKEN" $HOST:8776/v1/$TENANT_ID/os-quota-sets/$TENANT/defaults | grep "gigabytes")
END=`date +%s`

LIST_TIME=$[END-START]

if [[ -z $QUOTAS ]]; then
        exit_critical "Unable to get quotas, cinder API is not working"
    elif [[ $LIST_TIME -gt $WARNING ]]; then
        exit_warning "Get quotas took more than $LIST_TIME seconds, it's too long.|response_time=$LIST_TIME"
else
        exit_ok "Get quotas, cinder API is working: list quota in $LIST_TIME seconds.|response_time=$LIST_TIME"
fi