#!/bin/bash

usage() {
    echo "usage: ./check_metadata_instance.sh -t <check.last.x[hour]>"
    exit 1
}
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

while getopts ":t:" opt; do
    case $opt in
        t)
            LAST=${OPTARG};;
       \?)
            echo "Invalid option"
            usage;;
        : ) echo "Option -"$OPTARG" requires an argument." >&2
            usage;;
    esac
done

if [[ -z $LAST ]]; then
        usage
fi
LAST=$[LAST*3600]
metadata_down=()

for i in /var/lib/nova/instances/*/console.log ; do

    LASTCHANGED="$(expr `date +%s` - `stat -c %Y $i`)"

    if [[ $LASTCHANGED -lt $LAST ]]; then
        if [[ -n $(grep -l "Giving up on waiting for the metadata" $i) ]] ; then
            metadata_down+="$(echo "$i" | grep -o -P '(?<=instances/).*(?=/console)' | awk '{print "Instance " $1 " has broken metadata; "}')"
        fi
    fi
done

if [[ -z "${metadata_down[*]}" ]]; then
    exit_ok "All instances OK"
else
    echo "${metadata_down[*]}"
      exit 2
fi
exit_warning "Unknown error"