#!/bin/sh
# /server/generic/iLO3Server.sh
source /server/generic/iLOServer.sh

isPoweredOn() {
  local iloApiAddress="${1}"; shift
  local user="${1}"; shift
  local password="${1}"; shift
	local state="$(curl "${iloApiAddress}" --fail --max-time 5 --insecure --data "<RIBCL VERSION=\"2.0\"><LOGIN USER_LOGIN=\"${user}\" PASSWORD=\"${password}\"><SERVER_INFO MODE=\"read\"><GET_HOST_POWER_STATUS/></SERVER_INFO></LOGIN></RIBCL>" --silent --location | awk '{print tolower($0)}')"
	local power="$(echo "${state}" | grep -o 'host_power="[^"]*"' | grep -o '="[^"]*"' | grep -o '"[^"]*"' | grep -o '[^"]*' | awk '{print tolower($0)}')"
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
	local state="$(curl "${iloApiAddress}" --max-time 30 --insecure --data "<RIBCL VERSION=\"2.0\"> <LOGIN USER_LOGIN=\"${user}\" PASSWORD=\"${password}\"><SERVER_INFO MODE=\"write\"><PRESS_PWR_BTN/></SERVER_INFO></LOGIN></RIBCL>" --silent --location | awk '{print tolower($0)}')"
	local result="$(echo "${state}" | grep -o 'no error')"
	if [ -z "${result}" ]; then
		echo "Failed to Start"
	else
		echo "Starting"
	fi
}
