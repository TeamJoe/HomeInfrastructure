#!/bin/bash
# /home/compression/compression.sh

# sudo crontab -u compression -e
# 0 2 * * * /home/compression/compression.sh start --speed ultrafast --video libx264 -- --thread 1 --sort date
# 0 2 * * 1,5 /home/compression/compression.sh start --speed fast --video libx265 -- --thread 1 --sort reverse-size
# 0 2 1,15 * * /home/compression/compression.sh start --speed slow --video libx265 -- --thread 1 --sort reverse-date

path="${0}"
command="${1}"; shift
options="${@}"

speed='ultrafast'
video='libx265'
outputLevel='all'

additionalParameters=''
while true; do
  case "${1}" in
    --output-level) outputLevel="${2}"; shift 2 ;;
    --speed) speed="${2}"; shift 2 ;;
    --video) video="${2}"; shift 2 ;;
    --) shift; additionalParameters="${additionalParameters} ${*}"; break ;;
    *)
      if [[ "${#1}" -eq 0 ]]; then
        break;
      else
        additionalParameters="${additionalParameters} ${1}"; shift
      fi
    ;;
  esac
done


target='/home/compression/plex-encoding.sh'
indexFolder='/home/public/Videos'
compressionFolder='/home/compression'

parameters="--input '${indexFolder}' --tmp '${compressionFolder}/${video}/${speed}' --log '${compressionFolder}/compression.${video}.${speed}.out' --pid '${compressionFolder}/compression.${video}.${speed}.pid' --video-preset '${speed}'"
if [[ "${speed,,}" == 'ultrafast' ]]; then
  parameters="${parameters} --video-quality 18 --video '${video},libx264,libx265'"
else
  parameters="${parameters} --video-quality 20 --video '${video}'"
fi
parameters="${parameters} ${additionalParameters}"

start="${target} start ${parameters}"
active="${target} active ${parameters}"
output="${target} output-${outputLevel} ${parameters}"
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
		echo "Usage: $runPath [start|status|output|stop] [--output-level error|warn|info|debug|trace|all] [--speed ultrafast|superfast|veryfast|fast|medium|slow|slower|veryslow|placebo] [--video libx264|libx265] [-- All values afterwards will be passed straight to ./plex-encoding.sh]"
		exit 1
	fi
}

runCommand "$path" "$command"