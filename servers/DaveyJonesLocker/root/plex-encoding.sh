#!/bin/bash

# sudo crontab -u root -e
# 0 4 * * * /root/plex-encoding.sh start "/home/public/Videos" "/home/joe/encodingTmp" "/root/plex-encoding.results" "false" "false" "/root/plex-encoding.pid"

## Options
audioCodec='aac' #libfdk_aac
videoCodec='libx264'
bitratePerAudioChannel=96 # 64 is default
outputExtension='.mp4'
threadCount=3 # 0 is unlimited
encodingQuality=18 # 1-50, lower is better quailty

## Input Values
path="${0}"
command="${1}"
inputDirectory="${2}" #/home/public/Videos/TV/Sonarr
tmpDriectory="${3:-/tmp}"
outputFile="${4:-~/encoding.results}"
dryRun="${5:-true}"
cleanRun="${6:-false}"
pidLocation="${7:-~/plex-encoding.pid}"


getAudioEncodingSettings() {
	local inputFile="${1}"
	audioEncoding=""
	streamCount="$(ffprobe "$inputFile" -show_entries format=nb_streams -v 1 -of compact=p=0:nk=1)"
	for (( i=0; i<=${streamCount}; i++ )); do
		channelCount="$(ffprobe -i "$inputFile" -show_streams -select_streams a:${i} | grep -o '^channels=[0-9]*$' | grep -o '[0-9]*')"
		if [ -n "$channelCount" ]; then
			bitrate="$(( $channelCount * $bitratePerAudioChannel))"
			audioEncoding="${audioEncoding} -c:a:${i} $audioCodec -b:a:${i} ${bitrate}k"
		fi
	done
	echo "$audioEncoding"
}

getVideoEncodingSettings() {
	local inputFile="${1}"
	echo " -c:v $videoCodec"
}

getSubtitleEncodingSettings() {
	local inputFile="${1}"
	echo " -scodec copy"
}

assembleArguments() {
	local inputFile="${1}"
	local outputFile="${2}"

	echo "-i '${inputFile}' -crf 18 -map 0 $(getAudioEncodingSettings "${inputFile}") $(getSubtitleEncodingSettings "${inputFile}") $(getVideoEncodingSettings "${inputFile}") -threads ${threadCount} -preset veryslow '${outputFile}'"
}

convert() {
	local inputFile="${1}"
	local outputFile="${2}"
	arguments="$(assembleArguments "${inputFile}" "${outputFile}")"
	echo "ffmpeg ${arguments}"
	eval "ffmpeg ${arguments}"
}

convertAll() {
	local inputDirectory="${1}"
	local tmpDriectory="${2}"
	local dryRun="${3}"
	local cleanRun="${4}"
	IFS=$'\n'
	if [ "$cleanRun" = "true" ]; then
		find "${inputDirectory}" -type f -name "*.compression" -delete
	fi

	echo "[$(date +%FT%T)] Starting"
	for file in $(find "${inputDirectory}" -type f -exec file -N -i -- {} + | sed -n 's!: video/[^:]*$!!p'); do
		local mod="$(stat --format '%a' "$file")"
		local owner="$(ls -al "$file"  | awk '{print $3}')"
		local group="$(ls -al "$file"  | awk '{print $4}')"
		local filePath="$(echo "$file" | sed 's/\(.*\)\..*/\1/')"
		local fileNameWithExt="$(basename "$file")"
		local fileName="$(basename "$filePath")"
		local oldExt="${fileNameWithExt##*.}"
		if [ "$oldExt" != "part" ] && [ ! -f "${filePath}.compression" ]; then
			local tmpFile="${tmpDriectory}/${fileName}${outputExtension}"
			echo "[$(date +%FT%T)] Converting '${file}' to '${filePath}${outputExtension}'"
			if [ "$dryRun" = "true" ]; then
				echo "DryRun" > "${filePath}.compression"
				echo "convert \"${file}\" \"${tmpFile}\"" >> "${filePath}.compression"
				echo "rm -v \"$file\"" >> "${filePath}.compression"
				echo "mv -v \"$tmpFile\" \"${filePath}${outputExtension}\"" >> "${filePath}.compression"
			else
				convert "${file}" "${tmpFile}" > "${filePath}.compression"
				rm -v "$file" >> "${filePath}.compression"
				mv -v "$tmpFile" "${filePath}${outputExtension}" >> "${filePath}.compression"
				chown "${owner}:${group}" -v "${filePath}${outputExtension}" >> "${filePath}.compression"
				chown "${owner}:${group}" -v "${filePath}.compression" >> "${filePath}.compression"
				chmod $mod -v "${filePath}${outputExtension}" >> "${filePath}.compression"
				chmod 444 -v "${filePath}.compression" >> "${filePath}.compression"
			fi
		fi
	done
	echo "[$(date +%FT%T)] Completed"
	rm "$pidLocation"
}

startLocal() {
	if [ "$(isRunning)" = "true" ]; then
		echo "Daemon is already running"
	else
		echo "Starting On Local Process"
		echo $$ > "$pidLocation"
		convertAll "${inputDirectory}" "${tmpDriectory}" "${dryRun}" "${cleanRun}" >> "${outputFile}"
	fi
}

startDaemon() {
	if [ "$(isRunning)" = "true" ]; then
		echo "Daemon is already running"
	else
		echo "Starting Daemon"
		nohup "$path" "start-local" "$inputDirectory" "$tmpDriectory" "$outputFile" "$dryRun" "$cleanRun" "$pidLocation" >/dev/null 2>&1 &
	fi
}

isRunning() {
	if [ -f "$pidLocation" ]; then
		local pid="$(cat "$pidLocation")"
		if [ -z "$pid" ]; then
			echo "false"
			rm "$pidLocation"
		elif ps -p $pid > /dev/null; then
			echo "true"
		else
			echo "false"
			rm "$pidLocation"
		fi
	else
		echo "false"
	fi
}

stopProcess() {
	if [ "$(isRunning)" = "true" ]; then
		local pid="$(cat "$pidLocation")"
		kill -9 $pid
		if [ "$(isRunning)" = "true" ]; then
			echo "Failed to remove process"
		fi
	else
		echo "Daemon is not running"
	fi
}

runCommand() {
	local command="${1}"
	if [ "$command" = "active" ]; then
		echo "$(isRunning)"
	elif [ "$command" = "start-local" ]; then
		startLocal
	elif [ "$command" = "start" ]; then
		startDaemon
	elif [ "$command" = "output" ]; then
		cat "${outputFile}"
	elif [ "$command" = "stop" ]; then
		echo "$(stopProcess)"
	else
		echo "Usage \"$0 [active|start|start-local|output|stop]"
	fi
}

runCommand "$command"

