#!/bin/bash
# /home/compression/compression.sh

# sudo crontab -u compression -e
# 0 2 * * * /home/compression/compression.sh start ultrafast 1 date libx264
# 0 2 * * 1,5 /home/compression/compression.sh start fast 1 reverse-size libx265
# 0 2 1,15 * * /home/compression/compression.sh start slow 1 reverse-date libx265

path="${0}"
command="${1}"
speed="${2}"
threads="${3}"
sort="${4}"
video="${5}"

target='/home/compression/plex-encoding.sh'
indexFolder='/home/public/Videos'
compressionFolder='/home/compression'

parameters="--input '${indexFolder}' --tmp '${compressionFolder}/${video}/${speed}' --log '${compressionFolder}/compression.${video}.${speed}.out' --pid '${compressionFolder}/compression.${video}.${speed}.pid' --video-preset '${speed}' --thread '${threads}' --sort '${sort}'"

if [[ "${speed,,}" == 'ultrafast' ]]; then
  parameters="${parameters} --video-quality 18 --video '${video},libx264,libx265'"
else
  parameters="${parameters} --video-quality 20 --video '${video}'"
fi

start="${target} start ${parameters}"
active="${target} active ${parameters}"
output="${target} output ${parameters}"
stop="${target} stop ${parameters}"

isActive() {
	local getValue="$(eval "${active}")"
	if [ "${getValue}" = "true" ]; then
		echo "Running"
	elif [ "${getValue}" = "unknown" ]; then
		echo "Unknown"
	else
	  echo "Stopped"
	fi
}

runCommand() {
	local runPath="$1"; shift
	local command="$1"; shift
	
	if [ "${command}" == "start" ]; then
		eval "${start}"
	elif [ "${command}" == "status" ]; then
		echo "$(isActive)"
	elif [ "${command}" == "output" ]; then
		eval "${output}"
	elif [ "${command}" == "stop" ]; then
		eval "${stop}"
	else
		echo "Usage: $runPath [start|status|output|stop] [speed ultrafast|superfast|veryfast|fast|medium|slow|slower|veryslow|placebo] [threadCount] [sort date|size] [videoCodec libx264|libx265]"
		exit 1
	fi
}

runCommand "$path" "$command"