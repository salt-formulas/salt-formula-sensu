#!/bin/bash
#check supervisorctl status


read -ra STATUS <<< $(supervisorctl status | awk '/'STOPPED'|'STARTING'|'BACKOFF'|'STOPPING'|'EXITED'|'FATAL'|'UNKNOWN'/ {print "Supervisor service " $1 " is " $2  ";"}')

exit_critical() {
    echo "CRITICAL: $*"
    exit 2
}

exit_ok() {
    echo "OK: $*"
    exit 0
}

if [ -z ${STATUS[@]} ]; then
	exit_ok "All services RUNNING or STOPPED."
else
	exit_critical ${STATUS[@]}
fi

