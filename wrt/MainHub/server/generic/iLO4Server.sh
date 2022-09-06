#!/bin/sh
# /server/generic/iLO4Server.sh
source /server/generic/iLOServer.sh

isPoweredOn() {
  local iloApiAddress="${1}"; shift
  local user="${1}"; shift
  local password="${1}"; shift
	local state="$(curl "${iloApiAddress}" --fail --max-time 5 --insecure --user "${user}:${password}" --silent --location | awk '{print tolower($0)}')"
	local power="$(echo "${state}" | grep -o '"power":"[^"]*",' | grep -o ':"[^"]*"' | grep -o '"[^"]*"' | grep -o '[^"]*' | awk '{print tolower($0)}')"
	if [ "${power}" == "off" ] || [ -z "${power}" ]; then
		echo "false"
	else
		echo "true"
	fi
}

powerOn() {
  local iloApiAddress="${1}"; shift
  local user="${1}"; shift
  local password="${1}"; shift
	local state="$(curl "${iloApiAddress}" --max-time 30 --insecure --user "${user}:${password}" --data '{ "Action": "PowerButton", "PushType": "Press", "Target": "/Oem/Hp"}' --header 'Content-Type: application/json' --silent --location)"
	local result="$(echo "${state}" | grep -o 'Success')"
	if [ -z "${result}" ]; then
		echo "Failed to Start"
	else
		echo "Starting"
	fi
}
