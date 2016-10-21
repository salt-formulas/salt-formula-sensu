#!/bin/bash
#checks "rabbitmqctl eval 'rabbit_diagnostics:maybe_stuck().'" command.

usage() {
	echo "checks "rabbitmqctl eval 'rabbit_diagnostics:maybe_stuck().'" command."
	echo "Shows number of suspicious processes."
    echo "usage: ./check_rabbitmq_stuck_nodes.sh -w <warning.threshold> -c <critical.threshold>"
    exit 1
}

while getopts ":w:c:" opt; do
    case $opt in
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

if [ -z "${WARN}" ] || [ -z "${CRIT}" ]; then
    usage
fi

exit_critical() {
    echo "CRITICAL: $*"
    exit 1
}
exit_warning() {
    echo "WARNING: $*"
    exit 1
}
exit_ok() {
    echo "OK: $*"
    exit 0
}

read -ra rabbit_eval <<< $(sudo rabbitmqctl eval 'rabbit_diagnostics:maybe_stuck().' | grep -o "Found "[0-9]*" suspicious processes.")
if [[ -n ${rabbit_eval[@]} ]]; then
	if [[ ${rabbit_eval[1]} -lt $WARN ]]; then
		exit_ok ${rabbit_eval[@]}
	elif [[ ${rabbit_eval[1]} -lt $CRIT ]]; then
		exit_warning ${rabbit_eval[@]}
	else
		exit_critical ${rabbit_eval[@]}
	fi
else
	exit_critical "rabbit_diagnostic failed"
fi

