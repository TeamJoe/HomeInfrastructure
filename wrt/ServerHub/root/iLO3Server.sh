#!/bin/sh
# /root/iLO3Server.sh

path="$1"; shift
description="$1"; shift
iloApiAddress="$1"; shift
iloAddress="$1"; shift
serverInternalAddresss="$1"; shift
serverExternalAddress="$1"; shift
user="$1"; shift
password="$1"; shift
command="$1"; shift

isPoweredOn() {
	local state="$(curl "$iloApiAddress" --fail --max-time 5 --insecure --data "<RIBCL VERSION=\"2.0\"><LOGIN USER_LOGIN=\"${user}\" PASSWORD=\"${password}\"><SERVER_INFO MODE=\"read\"><GET_HOST_POWER_STATUS/></SERVER_INFO></LOGIN></RIBCL>" --silent --location | awk '{print tolower($0)}')"
	local power="$(echo "$state" | grep -o 'host_power="[^"]*"' | grep -o '="[^"]*"' | grep -o '"[^"]*"' | grep -o '[^"]*' | awk '{print tolower($0)}')"
	if [ "${power}" == "off" ] || [ -z "${power}" ]; then
		echo "false"
	else
		echo "true"
	fi
}

powerOn() {
	curl "$iloApiAddress" --max-time 30 --insecure --data "<RIBCL VERSION=\"2.0\"> <LOGIN USER_LOGIN=\"${user}\" PASSWORD=\"${password}\"><SERVER_INFO MODE=\"write\"><HOLD_PWR_BTN TOGGLE=\"YES\"/></SERVER_INFO></LOGIN></RIBCL>" --silent --location
}

isBooted() {
	local status="$(curl "${serverInternalAddresss}/ping" --fail --max-time 1 --silent | grep 'PONG')"
	if [ -n "${status}" ]; then
		echo "true"
	else
		echo "false"
	fi
}

startUp() {
	if [ "$(isPoweredOn)" != "true" ]; then
		powerOn
		echo "Powering On"
	else
		echo "Already On"
	fi
}

currentStatus() {
	if [ "$(isBooted)" == "true" ]; then
		echo "Powered On"
	elif [ "$(isPoweredOn)" == "true" ]; then
		echo "Starting"
	else
		echo "Powered Off"
	fi
}

getDescription() {
	echo "$description"
}

runCommand() {
	local runPath="$1"; shift
	local command="$1"; shift
	
	if [ "$command" == "start" ]; then
		startUp
	elif [ "$command" == "status" ]; then
		currentStatus
	elif [ "$command" == "description" ]; then
		getDescription
	elif [ "$command" == "ilo" ]; then
		echo "$iloAddress"
	elif [ "$command" == "address" ]; then
		echo "$serverExternalAddress"
	else
		echo "Usage: $runPath [start|status|description|ilo|address]"
		exit 1
	fi
}

runCommand "$path" "$command"
