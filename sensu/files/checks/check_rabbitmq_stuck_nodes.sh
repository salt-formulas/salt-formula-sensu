#!/bin/bash
#checks "rabbitmqctl eval 'rabbit_diagnostics:maybe_stuck().'" command.

exit_critical() {
    echo "CRITICAL: $*"
    exit 2
}
exit_ok() {
    echo "OK: $*"
    exit 0
}

read -ra rabbit_eval <<< $(sudo rabbitmqctl eval 'rabbit_diagnostics:maybe_stuck().' | grep -o "Found "[0-9]*" suspicious processes.")
if [[ -n ${rabbit_eval[@]} ]]; then
	if [[ ${rabbit_eval[1]} -eq 0 ]]; then
		exit_ok ${rabbit_eval[@]}
	else
		exit_critical ${rabbit_eval[@]}
	fi
else
	exit_critical "rabbit_diagnostic failed"
fi

