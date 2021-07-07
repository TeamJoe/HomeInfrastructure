#!/bin/bash

# sudo crontab -u root -e
# */5 * * * * /root/inactiveService.sh

runningCommands=('echo false')

activeCommands=('echo false')

shutdownCommands=('echo No-Action')

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
