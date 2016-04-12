#!/bin/bash
#check systemctl --failed for failed processes.

FAIL_COUNT=$(systemctl --failed | grep "loaded units listed" | awk '{print $1}')

exit_ok() {
        echo "OK: $*"
        exit 0
}

exit_critical() {
    echo "CRITICAL: $*"
    exit 2
}

if [ $FAIL_COUNT -gt 0 ]; then
    exit_critical "Failed service: "$(systemctl --all | grep failed | awk '{print $1}')
else
    exit_ok "No failed services."
fi
