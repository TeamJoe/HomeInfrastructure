#!/bin/sh
# /server/generic/iLOServer.sh
source /server/generic/GenericServer.sh

startUp() {
  local serverInternalAddresss="${1}"; shift
  local iloApiAddress="${1}"; shift
  local user="${1}"; shift
  local password="${1}"; shift
	if [ "$(isBooted "${serverInternalAddress}")" == "true" ]; then
		echo "Already On"
	elif [ "$(isPoweredOn "${iloApiAddress}" "${user}" "${password}")" == "true" ]; then
		echo "Starting"
	else
		echo "$(powerOn "${iloApiAddress}" "${user}" "${password}")"
	fi
}

currentStatus() {
  local serverInternalAddresss="${1}"; shift
  local iloApiAddress="${1}"; shift
  local user="${1}"; shift
  local password="${1}"; shift
	if [ "$(isBooted "${serverInternalAddress}")" == "true" ]; then
		echo "Powered On"
	elif [ "$(isPoweredOn "${iloApiAddress}" "${user}" "${password}")" == "true" ]; then
		echo "Starting"
	else
		echo "Powered Off"
	fi
}

runCommand() {
	local runPath="${1}"; shift
	local name="${1}"; shift
	local description="${1}"; shift
	local iloApiAddress="${1}"; shift
  local iloAddress="${1}"; shift
  local serverInternalAddress="${1}"; shift
  local serverExternalAddress="${1}"; shift
  local user="${1}"; shift
  local password="${1}"; shift
	local command="${1}"; shift
	local status=""

	if [ "$command" == "start" ]; then
		status="$(startUp "${serverInternalAddress}" "${iloApiAddress}" "${user}" "${password}")"
		if [ "${status}" != "Already On" ]; then
		  sendMessageAndUpdateIfDiffer "${status}" "${runPath}.status" "${name} is now '${status}'"
		fi
		echo "${status}"
	elif [ "$command" == "status" ]; then
    status="$(currentStatus "${serverInternalAddress}" "${iloApiAddress}" "${user}" "${password}")"
		sendMessageAndUpdateIfDiffer "${status}" "${runPath}.status" "${name} is now '${status}'"
    echo "${status}"
	elif [ "$command" == "name" ]; then
		echo "$name"
	elif [ "$command" == "description" ]; then
		echo "$description"
	elif [ "$command" == "ilo" ]; then
		echo "$iloAddress"
	elif [ "$command" == "address" ]; then
		echo "$serverExternalAddress"
	else
		echo "Usage: $runPath [start|status|name|description|ilo|address]"
		exit 1
	fi
}

if [ -n "${prefix}" ]; then
  iloApiAddress="$(getProperty "${prefix}.ilo.internal")"
  iloAddress="$(getProperty "${prefix}.ilo.external")"
  user="$(getProperty "${prefix}.ilo.username")"
  password="$(getProperty "${prefix}.ilo.password")"
fi