#!/bin/bash
#
# Key for libvirt-client: command="sudo /srv/sensu/checks/check_virsh_list.sh $SSH_ORIGINAL_COMMAND",no-port-forwarding,no-x11-forwarding,no-agent-forwarding ssh-rsa ...
#check_virsh_list.sh:
#
#!/bin/bash
#case $1 in
#    list) virsh list --all;;
#    dumpxml) virsh dumpxml $2;;
#    *) echo invalid option;exit 1;;
#esac
#
#Usage:
# check_kvm.sh -i instance_id -u user_name -p user_password -t tenant_name -w auth_url


while getopts ":i:u:p:t:w:" opt; do
    case $opt in
        i)
            inst_id=${OPTARG};;
        u)
            user=${OPTARG};;
      	p)
	          passwd=${OPTARG};;
      	t)
            tenant_name=${OPTARG};;
	      w)
            auth_url=${OPTARG};;
        \?)
            echo "Invalid option";exit 1;;
        : ) echo "Option -"$OPTARG" requires an argument." >&2
            exit 1;;
    esac
done
#keystone:
export OS_USERNAME=$user
export OS_PASSWORD=$passwd
export OS_TENANT_NAME=$tenant_name
export OS_AUTH_URL=$auth_url

#Clear getopts variables
for ((i=1 ; i <= 9 ; i++))
do
      shift
done

#Get hypervisor name
hypervisor=`nova show $inst_id | grep hypervisor_hostname | awk '{print $4}'`

#Get kvm instance name
inst_name=`ssh -i /opt/sensu/.ssh/id_rsa libvirt-client@$hypervisor "dumpxml $inst_id" | grep '<name>'`
#inst_name=`ssh root@$hypervisor "virsh dumpxml $inst_id | grep '<name>'"`
inst_name=`awk '{gsub("<name>", "");print}' <<< $inst_name`
inst_name=`awk '{gsub("</name>", "");print}' <<< $inst_name`

#Get state
state=`ssh -i /opt/sensu/.ssh/id_rsa libvirt-client@$hypervisor "list" | sed '1,2d' | sed '/^$/d'| awk '{print $2" "$3}' | grep $inst_name `
#state=`ssh root@$hypervisor "virsh list --all | sed '1,2d' | sed '/^$/d'| awk '{print $2" "$3}' | grep $inst_name "`
state=$(echo $state | awk -F" " '{print $2}')

OK=0
WARN=0
CRIT=0
NUM=0

  case "$state" in
    running|blocked) OK=$(expr $OK + 1) ;;
    paused) WARN=$(expr $WARN + 1) ;;
    shutdown|shut*|crashed) CRIT=$(expr $CRIT + 1) ;;
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

echo hosts:$NUM OK:$OK WARN:$WARN CRIT:$CRIT - $LIST

exit $EXITVAL
