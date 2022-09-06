#!/bin/bash
source /server/discord.sh

# sudo crontab -u root -e
# */5 * * * * /root/shutdown.sh

shutdownCommands=('netstat | grep ssh | grep -c ESTABLISHED'
'sh /home/factorio/FactorioServer.sh active'
'sh /home/minecraft/ATM3Server.sh active'
'sh /home/minecraft/ATM5Server.sh active'
'sh /home/minecraft/VanillaServer.sh active'
'sh /home/minecraft/Vanilla-1-16.sh active'
'sh /home/minecraft/Vanilla-1-17-1.sh active'
'sh /home/minecraft/Vanilla-1-19-2.sh active'
'sh /home/minecraft/RLCraftServer.sh active'
'sh /home/minecraft/SkyFactory4Server.sh active'
'sh /home/minecraft/SevTechServer.sh active'
'sh /home/steam/dst-master.sh active'
'sh /home/steam/dst-caves.sh active')

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
		  sendMessage "Shutting Down"
			/sbin/shutdown
		fi
	fi
}

checkActive >> /home/joe/shutdown.log 2>&1

