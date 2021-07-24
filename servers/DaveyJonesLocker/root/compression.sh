#!/bin/bash
# /root/compression.sh

path="${0}"
command="${1}"
start='/root/plex-encoding.sh start "/home/public/Videos" "/home/joe/encodingTmp" "/root/plex-encoding.results" "false" "false" "/root/plex-encoding.pid"'
active='/root/plex-encoding.sh active "/home/public/Videos" "/home/joe/encodingTmp" "/root/plex-encoding.results" "false" "false" "/root/plex-encoding.pid"'
output='/root/plex-encoding.sh output "/home/public/Videos" "/home/joe/encodingTmp" "/root/plex-encoding.results" "false" "false" "/root/plex-encoding.pid"'
stop='/root/plex-encoding.sh stop "/home/public/Videos" "/home/joe/encodingTmp" "/root/plex-encoding.results" "false" "false" "/root/plex-encoding.pid"'

isActive() {
	local getValue="$(eval "$active")"
	if [ "$getValue" = "true" ]; then
		echo "Running"
	else
		echo "Stopped"
	fi
}


runCommand() {
	local runPath="$1"; shift
	local command="$1"; shift
	
	if [ "$command" == "start" ]; then
		eval "$start"
	elif [ "$command" == "status" ]; then
		echo "$(isActive)"
	elif [ "$command" == "output" ]; then
		eval "$output"
	elif [ "$command" == "stop" ]; then
		eval "$stop"
	else
		echo "Usage: $runPath [start|status|output|stop]"
		exit 1
	fi
}

runCommand "$path" "$command"