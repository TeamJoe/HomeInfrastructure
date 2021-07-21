#!/bin/bash
# /root/ServiceStatus.sh

path="$1"; shift
service="$1"; shift
externalAddress="$1"; shift
command="$1"; shift

isActive() {
	local isActive="$(systemctl is-active "$service")"
	if [ "$isActive" == "active" ]; then
		echo 'true'
	else
		echo 'false'
	fi
}

powerOn() {
	systemctl start "$service"
}

startUp() {
	if [ "$(isActive)" == "true" ]; then
		echo "Already On"
	else
		echo "$(powerOn)"
	fi
}

currentStatus() {
	if [ "$(isActive)" == "true" ]; then
		echo "Powered On"
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
	elif [ "$command" == "address" ]; then
		echo "$externalAddress"
	else
		echo "Usage: $runPath [start|status|address]"
		exit 1
	fi
}

runCommand "$path" "$command"
