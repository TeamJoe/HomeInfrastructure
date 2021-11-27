#!/bin/bash

# sudo crontab -u root -e
# */5 * * * * /root/shutdown.sh

shutdownCommands=('echo false')

minimum_server_boot_time=3600

isTrue() {
	if [[ "${1}" == "false" || "${1}" == "0" ]]; then
		echo "false"
	else
		echo "true"
	fi
}

isActive() {
	local index="${1}"
	local shutdownCommand="${shutdownCommands[${index}]}"
	local active="$(isTrue "$(eval "${shutdownCommand}")")"
	
	echo "${active}"
}

runCommands() {
	local active='false'

	for i in $(echo ${!shutdownCommands[@]}); do
		active="$(isActive "$i")"
		if [[ "$active" == "true" ]]; then
			break
		fi
	done
	
	if [[ "$active" == "true" ]]; then
		echo "true"
	else
		echo "false"
	fi
}

checkActive() {
	local isActive='false'
	local timeSinceBoot="$(printf '%.0f\n' "$(awk '{print $1}' /proc/uptime)")"
	
	if [[ $minimum_server_boot_time -lt $timeSinceBoot ]]; then
		isActive="$(runCommands)"
		
		if [[ "$isActive" == "false" ]]; then
			/sbin/shutdown
		fi
	fi
}

checkActive >> /home/joe/shutdown.log 2>&1

