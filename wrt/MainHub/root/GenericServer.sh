#!/bin/sh
# /root/GenericServer.sh

path="$1"; shift
serverInternalAddresss="$1"; shift
serverExternalAddress="$1"; shift
command="$1"; shift

isBooted() {
	local status="$(curl "${serverInternalAddresss}/status" --connect-timeout 1 -s | grep 'Uptime')"
	if [ -n "${status}" ]; then
		echo "true"
	else
		echo "false"
	fi
}

currentStatus() {
	if [ "$(isBooted)" == "true" ]; then
		echo "Powered On"
	else
		echo "Powered Off"
	fi
}

runCommand() {
	local runPath="$1"; shift
	local command="$1"; shift
	
	if [ "$command" == "status" ]; then
		currentStatus
	elif [ "$command" == "address" ]; then
		echo "$serverExternalAddress"
	else
		echo "Usage: $runPath [status|address]"
		exit 1
	fi
}

runCommand "$path" "$command"
