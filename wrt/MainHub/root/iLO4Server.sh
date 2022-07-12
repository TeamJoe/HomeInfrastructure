#!/bin/sh
# /root/iLO4Server.sh

path="$1"; shift
description="$1"; shift
iloApiAddress="$1"; shift
iloAddress="$1"; shift
serverInternalAddress="$1"; shift
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
	
	local state="$(curl "$iloApiAddress" --max-time 30 --insecure --user "${user}:${password}" --data '{ "Action": "PowerButton", "PushType": "Press", "Target": "/Oem/Hp"}' --header 'Content-Type: application/json' --silent --location)"
	local result="$(echo "$state" | grep -o 'Success')"
	if [ -z "${result}" ]; then
		echo "Failed to Start"
	else
		echo "Starting Server"
	fi
}

isBooted() {
	local status="$(curl "${serverInternalAddress}/ping" --fail --max-time 1 --silent | grep 'PONG')"
	if [ -n "${status}" ]; then
		echo "true"
	else
		echo "false"
	fi
}

startUp() {
	if [ "$(isBooted)" == "true" ]; then
		echo "Already On"
	elif [ "$(isPoweredOn)" == "true" ]; then
		echo "Starting"
	else
		echo "$(powerOn)"
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
