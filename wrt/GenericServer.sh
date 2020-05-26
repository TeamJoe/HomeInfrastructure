#!/bin/sh
# /root/GenericServer.sh

path="$1"; shift
iloApiAddress="$1"; shift
iloAddress="$1"; shift
serverInternalAddresss="$1"; shift
serverExternalAddress="$1"; shift
user="$1"; shift
password="$1"; shift
command="$1"; shift

isPoweredOn() {
	local state="$(curl "$iloApiAddress" --insecure -u "${user}:${password}" -L | awk '{print tolower($0)}')"
	local power="$(echo "$state" | grep -o '"power":"[^"]*",' | grep -o ':"[^"]*"' | grep -o '"[^"]*"' | grep -o '[^"]*' | awk '{print tolower($0)}')"
	if [ "${power}" == "off" ]; then
		echo "false"
	else
		echo "true"
	fi
}

powerOn() {
	curl -d '{ "Action": "PowerButton", "PushType": "Press", "Target": "/Oem/Hp"}' -H 'Content-Type: application/json' "$iloApiAddress" --insecure -u "${user}:${password}" -L
}

isBooted() {
	local status="$(curl "${serverInternalAddresss}/status" --connect-timeout 1 -s | echo 'connection refused')"
	if [ "${status}" =~ "Uptime" ]; then
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
	if [ "$(isPoweredOn)" == "true" ]; then
		echo "Powered On"
	elif [ "$(isPoweredOn)" == "true" ]; then
		echo "Starting"
	else
		echo "Powered Off"
	fi
}

runCommand() {
	local runPath="$1"; shift
	local command="$1"; shift
	
	if [ "$command" == "start" ]; then
		startUp
	elif [ "$command" == "status" ]; then
		currentStatus
	elif [ "$command" == "ilo" ]; then
		echo "$iloAddress"
	elif [ "$command" == "address" ]; then
		echo "$serverExternalAddress"
	else
		echo "Usage: $runPath [start|status|ilo|address]"
		exit 1
	fi
}

runCommand "$path" "$command"
