#!/bin/sh

#set -x

# Version 0.0.2 2010-08-24
# Return 3 for unknown results.

# Version 0.0.1 2010-05-21
# Ulric Eriksson <ulric.eriksson@dgc.se>

BASEOID=.1.3.6.1.4
IMMOID=$BASEOID.1.2.3.51.3

tempOID=$IMMOID.1.1
tempsOID=$tempOID.1.0
# Temperature sensor count
tempIndexOID=$tempOID.2.1.1
# Temperature sensor indexes
tempNameOID=$tempOID.2.1.2
# Names of temperature sensors
tempTempOID=$tempOID.2.1.3
tempFatalOID=$tempOID.2.1.5
tempCriticalOID=$tempOID.2.1.6
tempNoncriticalOID=$tempOID.2.1.7

voltOID=$IMMOID.1.2
voltsOID=$voltOID.1.0
voltIndexOID=$voltOID.2.1.1
voltNameOID=$voltOID.2.1.2
voltVoltOID=$voltOID.2.1.3
voltCritHighOID=$voltOID.2.1.6
voltCritLowOID=$voltOID.2.1.7

fanOID=$IMMOID.1.3
fansOID=$fanOID.1.0
fanIndexOID=$fanOID.2.1.1
fanNameOID=$fanOID.2.1.2
fanSpeedOID=$fanOID.2.1.3
fanMaxSpeedOID=$fanOID.2.1.8

healthStatOID=$IMMOID.1.4
# 255 = Normal, 0 = Critical, 2 = Non-critical Error, 4 = System-level Error

# 'label'=value[UOM];[warn];[crit];[min];[max]

usage()
{
	echo "Usage: $0 -H host -C community -T health|temperature|voltage|fans"
	exit 0
}

get_health()
{
	echo "$HEALTH"|grep "^$1."|head -1|sed -e 's,^.*: ,,'|tr -d '"'
}

get_temperature()
{
        echo "$TEMP"|grep "^$2.*$1 = "|head -1|sed -e 's,^.*: ,,'|tr -d '"'
}

get_voltage()
{
        echo "$VOLT"|grep "^$2.*$1 = "|head -1|sed -e 's,^.*: ,,'|tr -d '"'
}

get_fan()
{
        echo "$FANS"|grep "^$2.*$1 = "|head -1|sed -e 's,^.*: ,,'|tr -d '"'
}

if test "$1" = -h; then
	usage
fi

while getopts "H:C:T:" o; do
	case "$o" in
	H )
		HOST="$OPTARG"
		;;
	C )
		COMMUNITY="$OPTARG"
		;;
	T )
		TEST="$OPTARG"
		;;
	* )
		usage
		;;
	esac
done

RESULT=
STATUS=0	# OK

case "$TEST" in
health )
	HEALTH=`snmpwalk -v 1 -c $COMMUNITY -On $HOST $healthStatOID`
	healthStat=`get_health $healthStatOID`
	case "$healthStat" in
	0 )
		RESULT="Health status: Critical"
		STATUS=2	# Critical
		;;
	2 )
		RESULT="Health status: Non-critical error"
		STATUS=1
		;;
	4 )
		RESULT="Health status: System level error"
		STATUS=2
		;;
	255 )
		RESULT="Health status: Normal"
		;;
	* )
		RESULT="Health status: Unknown"
		STATUS=3
		;;
	esac
	;;
temperature )
	TEMP=`snmpwalk -v 1 -c $COMMUNITY -On $HOST $tempOID`
	# Figure out which temperature indexes we have
	temps=`echo "$TEMP"|
	grep -F "$tempIndexOID."|
	sed -e 's,^.*: ,,'`
	if test -z "$temps"; then
		RESULT="No temperatures"
		STATUS=3
	fi
	for i in $temps; do
		tempName=`get_temperature $i $tempNameOID`
		tempTemp=`get_temperature $i $tempTempOID`
		tempFatal=`get_temperature $i $tempFatalOID`
		tempCritical=`get_temperature $i $tempCriticalOID`
		tempNoncritical=`get_temperature $i $tempNoncriticalOID`
		RESULT="$RESULT$tempName = $tempTemp
"
		if test "$tempTemp" -ge "$tempCritical"; then
			STATUS=2
		elif test "$tempTemp" -ge "$tempNoncritical"; then
			STATUS=1
		fi
		PERFDATA="${PERFDATA}Temperature$i=$tempTemp;;;; "
	done
	;;
voltage )
	VOLT=`snmpwalk -v 1 -c $COMMUNITY -On $HOST $voltOID`
	volts=`echo "$VOLT"|
	grep -F "$voltIndexOID."|
	sed -e 's,^.*: ,,'`
	if test -z "$volts"; then
		RESULT="No voltages"
		STATUS=3
	fi
	for i in $volts; do
		voltName=`get_voltage $i $voltNameOID`
		voltVolt=`get_voltage $i $voltVoltOID`
		voltCritHigh=`get_voltage $i $voltCritHighOID`
		voltCritLow=`get_voltage $i $voltCritLowOID`
		RESULT="$RESULT$voltName = $voltVolt
"
		if test "$voltCritLow" -gt 0 -a "$voltVolt" -le "$voltCritLow"; then
			#echo "$voltVolt < $voltCritLow"
			STATUS=2
		elif test "$voltCritHigh" -gt 0 -a "$voltVolt" -ge "$voltCritHigh"; then
			#echo "$voltVolt > $voltCritLow"
			STATUS=2
		fi
		PERFDATA="${PERFDATA}Voltage$i=$voltVolt;;;; "
	done
	;;
fans )
	FANS=`snmpwalk -v 1 -c $COMMUNITY -On $HOST $fanOID`
	fans=`echo "$FANS"|
	grep -F "$fanIndexOID."|
	sed -e 's,^.*: ,,'`
	if test -z "$fans"; then
		RESULT="No fans"
		STATUS=3
	fi
	for i in $fans; do
		fanName=`get_fan $i $fanNameOID`
		fanSpeed=`get_fan $i $fanSpeedOID|tr -d 'h '`
		RESULT="$RESULT$fanName = $fanSpeed
"
		PERFDATA="${PERFDATA}Fan$i=$fanSpeed;;;; "
	done
	;;
* )
	usage
	;;
esac

echo "$RESULT|$PERFDATA"
exit $STATUS
