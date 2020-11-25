#!/bin/bash

#CRON: */5 * * * * root /root/inactiveServices.sh

runningCommands=('sh /home/minecraft/ATM3Server.sh started'
'sh /home/minecraft/ATM5Server.sh started'
'sh /home/minecraft/VanillaServer.sh started'
'sh /home/minecraft/Vanilla-1-16-3.sh started'
'sh /home/minecraft/RLCraftServer.sh started'
'sh /home/minecraft/SkyFactory4Server.sh started'
'sh /home/minecraft/SevTechServer.sh started'
'echo "$(if [ `/home/steam/dst-master.sh started` == "true" ] || [ `/home/steam/dst-caves.sh started` == "true" ]; then echo true; else echo false; fi)"')

activeCommands=('sh /home/minecraft/ATM3Server.sh active'
'sh /home/minecraft/ATM5Server.sh active'
'sh /home/minecraft/VanillaServer.sh active'
'sh /home/minecraft/Vanilla-1-16-3.sh active'
'sh /home/minecraft/RLCraftServer.sh active'
'sh /home/minecraft/SkyFactory4Server.sh active'
'sh /home/minecraft/SevTechServer.sh active'
'echo "$(if [ `/home/steam/dst-master.sh active` -gt 0 ] || [ `/home/steam/dst-caves.sh active` -gt 0 ]; then echo true; else echo false; fi)"')

shutdownCommands=('systemctl stop minecraft-atm3.service; /home/minecraft/ATM3Server.sh stop'
'systemctl stop minecraft-atm5-1-10.service; /home/minecraft/ATM3Server.sh stop'
'systemctl stop minecraft-vanilla-1-15-2.service; /home/minecraft/VanillaServer.sh stop'
'systemctl stop minecraft-vanilla-1-16-3.service; /home/minecraft/Vanilla-1-16-3.sh stop'
'systemctl stop minecraft-rlcraft-1-5-0.service; /home/minecraft/RLCraftServer.sh stop'
'systemctl stop minecraft-skyfactory-4-2-2.service; /home/minecraft/SkyFactory4Server.sh stop'
'systemctl stop minecraft-sevtech-3-1-7.service; /home/minecraft/SevTechServer.sh stop'
'systemctl stop dst_cluster1_master.service; systemctl stop dst_cluster1_caves.service; /home/steam/dst-master.sh stop; /home/steam/dst-caves.sh stop')

isTrue() {
	if [ "${1}" == "false" ] || [ "${1}" == "0" ]; then
		echo "false"
	else
		echo "true"
	fi
}

shutdownIfNotActive() {
	local index="${1}"
	local runningCommand="${runningCommands[${index}]}"
	local activeCommand="${activeCommands[${index}]}"
	local shutdownCommand="${shutdownCommands[${index}]}"
	local isRunning="$(isTrue "$(eval '${runningCommand}')")"
	local isActive="$(isTrue "$(eval '${activeCommand}')")"
	
	if [ "$isRunning" == "true" ] && [ "$isActive" == "false" ]; then
		eval "${shutdownCommand}"
	fi
}

runCommands() {
	for i in $(echo ${!runningCommands[@]}); do
		shutdownIfNotActive "$i" &
	done
}

runCommands
