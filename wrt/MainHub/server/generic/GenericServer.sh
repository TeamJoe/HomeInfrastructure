#!/bin/sh
# /server/generic/GenericServer.sh
source /server/discord.sh

isBooted() {
  local serverInternalAddress="${1}"; shift
	local status="$(curl "${serverInternalAddress}/ping" --max-time 2 --silent | grep 'PONG')"
	if [ -n "${status}" ]; then
		echo "true"
	else
		echo "false"
	fi
}

currentStatus() {
  local serverInternalAddress="${1}"; shift
	if [ "$(isBooted "${serverInternalAddress}")" == "true" ]; then
		echo "Powered On"
	else
		echo "Powered Off"
	fi

}

runCommand() {
	local runPath="${1}"; shift
	local name="${1}"; shift
	local description="${1}"; shift
	local serverInternalAddress="${1}"; shift
	local serverExternalAddress="${1}"; shift
	local command="${1}"; shift
	local status=""
	
	if [ "$command" == "status" ]; then
		status="$(currentStatus "${serverInternalAddress}")"
		sendMessageAndUpdateIfDiffer "${status}" "${runPath}.status" "${name} is now '${status}'"
		echo "${status}"
  elif [ "$command" == "name" ]; then
    echo "$name"
  elif [ "$command" == "description" ]; then
    echo "$description"
	elif [ "$command" == "address" ]; then
		echo "$serverExternalAddress"
	else
		echo "Usage: $runPath [status|name|description|address]"
		exit 1
	fi
}

if [ -n "${prefix}" ]; then
  name="$(getProperty "${prefix}.name")"
  description="$(getProperty "${prefix}.description")"
  serverInternalAddress="$(getProperty "${prefix}.address.internal")"
  serverExternalAddress="$(getProperty "${prefix}.address.external")"
fi