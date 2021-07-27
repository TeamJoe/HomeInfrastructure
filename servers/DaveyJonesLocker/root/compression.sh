#!/bin/bash
# /root/compression.sh

# sudo crontab -u root -e
# 0 * * * * /root/compression.sh start ultrafast 1
# 0 4 * * * /root/compression.sh start fast 1
# 0 8 * * 1 /root/compression.sh start veryslow 1

path="${0}"
command="${1}"
speed="${2}"
threads="${3}"
start="/root/plex-encoding.sh start -i '/home/public/Videos' --tmp '/home/joe/encodingTmp/${speed}' --log '/root/plex-encoding.results.${speed}' --pid '/root/plex-encoding.pid.${speed}' --cplex '${speed}' --thread ${threads}"
active="/root/plex-encoding.sh active -i '/home/public/Videos' --tmp '/home/joe/encodingTmp/${speed}' --log '/root/plex-encoding.results.${speed}' --pid '/root/plex-encoding.pid.${speed}' --cplex '${speed}' --thread ${threads}"
output="/root/plex-encoding.sh output -i '/home/public/Videos' --tmp '/home/joe/encodingTmp/${speed}' --log '/root/plex-encoding.results.${speed}' --pid '/root/plex-encoding.pid.${speed}' --cplex '${speed}' --thread ${threads}"
stop="/root/plex-encoding.sh stop -i '/home/public/Videos' --tmp '/home/joe/encodingTmp/${speed}' --log '/root/plex-encoding.results.${speed}' --pid '/root/plex-encoding.pid.${speed}' --cplex '${speed}' --thread ${threads}"

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
		echo "Usage: $runPath [start|status|output|stop] [speed ultrafast|superfast|veryfast|fast|medium|slow|slower|veryslow|placebo] [threadCount]"
		exit 1
	fi
}

runCommand "$path" "$command"