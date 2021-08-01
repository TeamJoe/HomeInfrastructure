#!/bin/bash
# /home/compression/compression.sh

# sudo crontab -u compression -e
# 0 4 * * * /home/compression/compression.sh start ultrafast 1 date libx264
# 0 4 * * 1,5 /home/compression/compression.sh start fast 1 reverse-size libx264
# 0 4 1,15 * * /home/compression/compression.sh start slow 1 size libx264

path="${0}"
command="${1}"
speed="${2}"
threads="${3}"
sort="${4}"
video="${5}"

target='/home/compression/plex-encoding.sh'
indexFolder='/home/public/Videos'
compressionFolder='/home/compression'

start="${target} start --input '${indexFolder}' --tmp '${compressionFolder}/${video}/${speed}' --log '${compressionFolder}/compression.${video}.${speed}.out' --pid '${compressionFolder}/compression.${video}.${speed}.pid' --video-preset '${speed}' --thread '${threads}' --sort '${sort}' --video ${video}"
active="${target} active --input '${indexFolder}' --tmp '${compressionFolder}/${video}/${speed}' --log '${compressionFolder}/compression.${video}.${speed}.out' --pid '${compressionFolder}/compression.${video}.${speed}.pid' --video-preset '${speed}' --thread '${threads}' --sort '${sort}' --video ${video}"
output="${target} output --input '${indexFolder}' --tmp '${compressionFolder}/${video}/${speed}' --log '${compressionFolder}/compression.${video}.${speed}.out' --pid '${compressionFolder}/compression.${video}.${speed}.pid' --video-preset '${speed}' --thread '${threads}' --sort '${sort}' --video ${video}"
stop="${target} stop --input '${indexFolder}' --tmp '${compressionFolder}/${video}/${speed}' --log '${compressionFolder}/compression.${video}.${speed}.out' --pid '${compressionFolder}/compression.${video}.${speed}.pid' --video-preset '${speed}' --thread '${threads}' --sort '${sort}' --video ${video}"

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
		echo "Usage: $runPath [start|status|output|stop] [speed ultrafast|superfast|veryfast|fast|medium|slow|slower|veryslow|placebo] [threadCount] [sort date|size] [videoCodec libx264|libx265]"
		exit 1
	fi
}

runCommand "$path" "$command"