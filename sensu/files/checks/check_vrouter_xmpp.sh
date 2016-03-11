#!/bin/bash
#usage: ./check_vrouter_xmpp.sh vrouter_ip

vrouter_ip=$1

exit_critical() {
    echo "CRITICAL: $*"
    exit 2
}

exit_ok() {
    echo "OK: $*"
    exit 0
}

read -ra ips <<< $(curl -s http://$vrouter_ip:8085/Snh_AgentXmppConnectionStatusReq? | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')

if [[ ${#ips[@]} -eq 0 ]]; then
    exit_critical "No vrouter ip found"
fi

read -ra est <<< $(curl -s http://$vrouter_ip:8085/Snh_AgentXmppConnectionStatusReq? | grep -o 'Established')

if [[ ${#ips[@]} -eq ${#est[@]} ]]; then
    exit_ok "XMPP connection established"
else
    exit_critical "XMPP connection failed! http://$vrouter_ip:8085/Snh_AgentXmppConnectionStatusReq?"
fi

