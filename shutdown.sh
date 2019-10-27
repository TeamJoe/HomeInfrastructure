#!/bin/bash

#CRON: */5 * * * * root /home/joe/shutdown.sh

command="/home/joe/ATM3Server.sh active"
minimum_server_boot_time=3600

checkActive() {
	local timeSinceBoot="$(printf '%.0f\n' "$(awk '{print $1}' /proc/uptime)")"
	
	if [ $minimum_server_boot_time -lt $timeSinceBoot ]; then
		local isActive="$($command)"
		if [ "$isActive" == "false" ]; then
			shutdown
		fi
	fi
}

checkActive
