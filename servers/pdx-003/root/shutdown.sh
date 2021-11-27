#!/bin/bash

# sudo crontab -u root -e
# */5 * * * * /root/shutdown.sh

shutdownCommands=('sh /home/satisfactory/satisfactory.sh active')

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
	local activeCommand="${activeCommands[${index}]}"
	local active="$(isTrue "$(eval "${activeCommand}")")"
	
	echo "${active}"
}

runCommands() {
	for i in $(echo ${!activeCommands[@]}); do
		local active="$(isActive "$i")"
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
	local timeSinceBoot="$(printf '%.0f\n' "$(awk '{print $1}' /proc/uptime)")"
	
	if [[ $minimum_server_boot_time -lt $timeSinceBoot ]]; then
		local isActive="$(runCommands)"
		if [[ "$isActive" == "false" ]]; then
			/sbin/shutdown
		fi
	fi
}

checkActive >> /home/joe/shutdown.log 2>&1
