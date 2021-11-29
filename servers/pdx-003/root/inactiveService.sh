#!/bin/bash

# sudo crontab -u root -e
# */5 * * * * /root/inactiveService.sh

runningCommands=('sh /home/satisfactory/satisfactory.sh started'
'sh /home/satisfactory/satisfactory2.sh started')

activeCommands=('sh /home/satisfactory/satisfactory.sh active'
'sh /home/satisfactory/satisfactory2.sh active')

shutdownCommands=('systemctl stop satisfactory.service; sh /home/satisfactory/satisfactory.sh stop'
'systemctl stop satisfactory2.service; sh /home/satisfactory/satisfactory2.sh stop')

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
	local isRunning="$(isTrue "$(eval "${runningCommand}")")"
	local isActive="$(isTrue "$(eval "${activeCommand}")")"
	
	if [ "$isRunning" == "true" ] && [ "$isActive" == "false" ]; then
		eval "${shutdownCommand}"
	fi
}

runCommands() {
	local pids
	for i in $(echo ${!runningCommands[@]}); do
		shutdownIfNotActive "$i" &
		pids[${i}]=$!
	done
	for pid in ${pids[*]}; do
		wait $pid
	done
}

runCommands >> /home/joe/inactiveService.log 2>&1
