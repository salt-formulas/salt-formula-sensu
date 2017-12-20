#!/bin/bash
#
# check vrouter status on compute nodes

service=vrouter

for p in /tmp /var/run; do
  if [ -S $p/supervisord_$service.sock ]; then
    SUPERVISOR_SOCKET_PATH=$p/supervisord_$service.sock
  fi
done

read -ra contrail_status <<< $(sudo supervisorctl -s unix://$SUPERVISOR_SOCKET_PATH status)

check_ok=0
state=RUNNING

read -ra contrail_test <<< ${contrail_status[@]#contrail-$service-agent}
#compare arrays
if [ ${#contrail_status[@]} -ne ${#contrail_test[@]} ]; then
        check_ok=1
fi

if [ $check_ok = 1 ]; then

        read -ra contrail_test <<< ${contrail_status[@]#STARTING}

        if [ ${#contrail_status[@]} -ne ${#contrail_test[@]} ]; then
                state=STARTING
        fi

        read -ra contrail_test <<< ${contrail_status[@]#STOPPED}
        if [ ${#contrail_status[@]} -ne ${#contrail_test[@]} ]; then
                state=STOPPED
        fi

        read -ra contrail_test <<< ${contrail_status[@]#FATAL}
        if [ ${#contrail_status[@]} -ne ${#contrail_test[@]} ]; then
                state=FATAL
        fi

        read -ra contrail_test <<< ${contrail_status[@]#EXITED}
        if [ ${#contrail_status[@]} -ne ${#contrail_test[@]} ]; then
                state=FATAL
        fi
else
        state=FATAL
fi

OK=0
WARN=0
CRIT=0
NUM=0

case "$state" in
	RUNNING) OK=$(expr $OK + 1) ;;
	STOPPED|STARTING) WARN=$(expr $WARN + 1) ;;
	FATAL) CRIT=$(expr $CRIT + 1) ;;
	*) CRIT=$(expr $CRIT + 1) ;;
esac

if [ "$NUM" -eq "$OK" ]; then
	EXITVAL=0 #Status 0 = OK (green)
fi

if [ "$WARN" -gt 0 ]; then
	EXITVAL=1 #Status 1 = WARNING (yellow)
fi

if [ "$CRIT" -gt 0 ]; then
	EXITVAL=2 #Status 2 = CRITICAL (red)
fi

echo State of contrail-$service OK:$OK WARN:$WARN CRIT:$CRIT - $LIST

exit $EXITVAL
