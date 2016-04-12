#!/bin/bash
#check supervisorctl status

read -ra STATUS <<< $(supervisorctl status | awk '/'STOPPED'|'STARTING'|'BACKOFF'|'STOPPING'|'EXITED'|'FATAL'|'UNKNOWN'/ {print "Supervisor service " $1 " is " $2  " ;"}')

exit_critical() {
    echo "CRITICAL: $*"
    exit 2
}

exit_warning() {
    echo "WARNING: $*"
    exit 1
}

exit_ok() {
    echo "OK: $*"
    exit 0
}

read -ra BACKOFF_TEST <<< ${STATUS[@]#BACKOFF}
if [ ${#STATUS[@]} -ne ${#BACKOFF_TEST[@]} ]; then
    exit_critical ${STATUS[@]}
fi

read -ra EXITED_TEST <<< ${STATUS[@]#EXITED}
if [ ${#STATUS[@]} -ne ${#EXITED_TEST[@]} ]; then
	exit_critical ${STATUS[@]}
fi

read -ra FATAL_TEST <<< ${STATUS[@]#FATAL}
if [ ${#STATUS[@]} -ne ${#FATAL_TEST[@]} ]; then
	exit_critical ${STATUS[@]}
fi

read -ra UNKNOWN_TEST <<< ${STATUS[@]#UNKNOWN}
if [ ${#STATUS[@]} -ne ${#UNKNOWN_TEST[@]} ]; then
	exit_critical ${STATUS[@]}
fi

read -ra STOPPED_TEST <<< ${STATUS[@]#STOPPED}
if [ ${#STATUS[@]} -ne ${#STOPPED_TEST[@]} ]; then
    exit_warning ${STATUS[@]}
fi

read -ra STARTING_TEST <<< ${STATUS[@]#STARTING}
if [ ${#STATUS[@]} -ne ${#STARTING_TEST[@]} ]; then
	exit_warning ${STATUS[@]}
fi

read -ra STOPPING_TEST <<< ${STATUS[@]#STOPPING}
if [ ${#STATUS[@]} -ne ${#STOPPING_TEST[@]} ]; then
	exit_warning ${STATUS[@]}
fi

read -ra RUNNING_TEST <<< $(supervisorctl status | grep RUNNING)
if [[ -n ${RUNNING_TEST[@]} ]]; then
    exit_ok "All services RUNNING."
else
	exit_critical "supervisorctl status failed"
fi
