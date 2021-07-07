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
	local state="$(curl "$iloApiAddress" --fail --max-time 5 --insecure --user "${user}:${password}" --silent --location | awk '{print tolower($0)}')"
	local power="$(echo "$state" | grep -o '"power":"[^"]*",' | grep -o ':"[^"]*"' | grep -o '"[^"]*"' | grep -o '[^"]*' | awk '{print tolower($0)}')"
	if [ "${power}" == "off" ] || [ -z "${power}" ]; then
		echo "false"
	else
		echo "true"
	fi
}

powerOn() {
	curl --max-time 30 --data '{ "Action": "PowerButton", "PushType": "Press", "Target": "/Oem/Hp"}' --header 'Content-Type: application/json' "$iloApiAddress" --insecure --user "${user}:${password}" --silent --location
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
