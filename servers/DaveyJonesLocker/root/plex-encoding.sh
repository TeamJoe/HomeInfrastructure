#!/bin/bash

# sudo crontab -u root -e
# 0 * * * * /root/plex-encoding.sh start -i "/home/public/Videos" --tmp "/home/joe/encodingTmp/ultrafast" --log "/root/plex-encoding.results.ultrafast" --pid "/root/plex-encoding.pid.ultrafast" --cplex "ultrafast" --thread 3
# 0 4 * * * /root/plex-encoding.sh start -i "/home/public/Videos" --tmp "/home/joe/encodingTmp/fast" --log "/root/plex-encoding.results.fast" --pid "/root/plex-encoding.pid.fast" --cplex "fast" --thread 2
# 0 8 * * 1 /root/plex-encoding.sh start -i "/home/public/Videos" --tmp "/home/joe/encodingTmp/veryslow" --log "/root/plex-encoding.results.veryslow" --pid "/root/plex-encoding.pid.veryslow" --cplex "veryslow" --thread 1

## Input Values
path="${0}"
command="${1}"; shift
options="$@"

## Options
inputDirectory='~/Videos' #/home/public/Videos/TV/Sonarr
tmpDirectory='/tmp'
logFile='~/encoding.results'
dryRun='false'
cleanRun='false'
pidLocation='~/plex-encoding.pid'
threadCount=0 # 0 is unlimited
encodingQuality=18 # 1-50, lower is better quailty
compressComplexity='veryslow' # ultrafast, superfast, veryfast, fast, medium, slow, slower, veryslow, placebo
audioCodec='aac' #libfdk_aac
videoCodec='libx264'
bitratePerAudioChannel=96 # 64 is default
outputExtension='.mp4'
compressionExtension='.compression'

getCommand() {
	local command="${1}"
	echo "'$path' '$command' --audio '${audioCodec}' --bit '${bitratePerAudioChannel}' --cext '${compressionExtension}' $(if [ "$cleanRun" = true ]; then echo '--clean '; fi) --cplex '${compressComplexity}' $(if [ "$dryRun" = true ]; then echo '--dry '; fi) --ext '${outputExtension}' -i '${inputDirectory}' --log '${logFile}' --pid '${pidLocation}' --quality '${encodingQuality}' --thread '${threadCount}' --tmp '${tmpDirectory}' --video '${videoCodec}'"
}

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
	local inputFile="$(echo "${1}" | sed -e "s/'/'\"'\"'/g")"
	local logFile="$(echo "${2}" | sed -e "s/'/'\"'\"'/g")"

	echo "-i '${inputFile}' -crf 18 -map 0 $(getAudioEncodingSettings "${inputFile}") $(getSubtitleEncodingSettings "${inputFile}") $(getVideoEncodingSettings "${inputFile}") -threads ${threadCount} -preset ${compressComplexity} '${logFile}'"
}

convert() {
	local inputFile="${1}"
	local logFile="${2}"
	arguments="$(assembleArguments "${inputFile}" "${logFile}")"
	echo "ffmpeg ${arguments}"
	eval "ffmpeg ${arguments}"
}

convertAll() {
	local inputDirectory="${1}"
	local tmpDirectory="${2}"
	local dryRun="${3}"
	local cleanRun="${4}"
	IFS=$'\n'
	if [ "$cleanRun" = "true" ]; then
		find "${inputDirectory}" -type f -name "*${compressionExtension}.${compressComplexity}" -delete
	fi

	echo "[$(date +%FT%T)] Starting"
	for file in $(find "${inputDirectory}" -type f -exec file -N -i -- {} + | sed -n 's!: video/[^:]*$!!p'); do
		local mod="$(stat --format '%a' "$file")"
		local owner="$(ls -al "$file"  | awk '{print $3}')"
		local group="$(ls -al "$file"  | awk '{print $4}')"
		local originalSize="$(($(ls -al "$file" | awk '{print $5}')/1024/1024))"
		local filePath="$(echo "$file" | sed 's/\(.*\)\..*/\1/')"
		local fileNameWithExt="$(basename "$file")"
		local fileName="$(basename "$filePath")"
		local oldExt="${fileNameWithExt##*.}"
		local newComplexity="$(getComplexityOrder "${compressComplexity}")"
		if [ "$oldExt" != "part" ] && [ ! -f "${filePath}${compressionExtension}.${compressComplexity}" ]; then		
			local tmpFile="${tmpDirectory}/${fileName}${outputExtension}"
			echo "[$(date +%FT%T)] Converting '${file}' to '${filePath}${outputExtension}'"
			local currentComplexity="0"
			local currentFileExt=""
			for compressFile in $(ls -1 "${filePath}${compressionExtension}."*); do
				local compressFileBasename="$(basename "$compressFile")"
				local compressFileExt="${compressFileBasename##*.}"
				local oldComplexity="$(getComplexityOrder "${compressFileExt}")"
				if [ "$oldComplexity" -gt "$currentComplexity" ]; then
					local currentComplexity="$oldComplexity"
					local currentFileExt="$compressFileExt"
				fi
			done
			
			if [ "$dryRun" = "true" ]; then
				if [ "$currentComplexity" -gt "$newComplexity" ]; then
					echo "File '$file' is already '$currentFileExt' compressed, will not compress to worse '$compressComplexity' format"
				else
					echo "convert \"${file}\" \"${tmpFile}\""
					echo "rm -v \"$file\""
					echo "mv -v \"$tmpFile\" \"${filePath}${outputExtension}\""
					echo "chown \"${owner}:${group}\" -v \"${filePath}${outputExtension}\""
					echo "chown \"${owner}:${group}\" -v \"${filePath}${compressionExtension}.${compressComplexity}\""
					echo "chmod $mod -v \"${filePath}${outputExtension}\""
					echo "chmod 444 -v \"${filePath}${compressionExtension}.${compressComplexity}\""
					local finalSize="$(($(ls -al "${file}" | awk '{print $5}')/1024/1024))"
					echo "File '$file' reduced to ${finalSize}MiB from original size ${originalSize}MiB"
				fi
			else
				if [ "$currentComplexity" -gt "$newComplexity" ]; then
					echo "File is already '$currentFileExt' compressed, will not compress to worse '$compressComplexity' format" > "${filePath}${compressionExtension}.${compressComplexity}"
				else
					convert "${file}" "${tmpFile}" > "${filePath}${compressionExtension}.${compressComplexity}"
					if [ -f "${tmpFile}" ]; then
						rm -v "$file" >> "${filePath}${compressionExtension}.${compressComplexity}"
						mv -v "$tmpFile" "${filePath}${outputExtension}" >> "${filePath}${compressionExtension}.${compressComplexity}"
						chown "${owner}:${group}" -v "${filePath}${outputExtension}" >> "${filePath}${compressionExtension}.${compressComplexity}"
						chown "${owner}:${group}" -v "${filePath}${compressionExtension}.${compressComplexity}" >> "${filePath}${compressionExtension.${compressComplexity}}"
						chmod $mod -v "${filePath}${outputExtension}" >> "${filePath}${compressionExtension}.${compressComplexity}"
						chmod 444 -v "${filePath}${compressionExtension}.${compressComplexity}" >> "${filePath}${compressionExtension}.${compressComplexity}"
						local finalSize="$(($(ls -al "${filePath}${outputExtension}" | awk '{print $5}')/1024/1024))"
						echo "File reduced to ${finalSize}MiB from original size ${originalSize}MiB" >> "${filePath}${compressionExtension}.${compressComplexity}"
						echo "[$(date +%FT%T)] File reduced to ${finalSize}MiB from original size ${originalSize}MiB"
					else
						echo "$(cat "${filePath}${compressionExtension}.${compressComplexity}")"
						echo "[$(date +%FT%T)] Failed to compress '${file}'"
						rm "${filePath}${compressionExtension}.${compressComplexity}"
					fi
				fi
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
		echo "$(getCommand "$command")" >> "${logFile}"
		convertAll "${inputDirectory}" "${tmpDirectory}" "${dryRun}" "${cleanRun}" >> "${logFile}"
	fi
}

startDaemon() {
	if [ "$(isRunning)" = "true" ]; then
		echo "Daemon is already running"
	else
		echo "Starting Daemon"
		local vars="$(getCommand "start-local")"
		eval "nohup $vars >/dev/null 2>&1 &"
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

getComplexityOrder() {
	local compressComplexity="${1}"
	case "$compressComplexity" in
		ultrafast ) echo '1';;
		superfast ) echo '2';; 
		veryfast ) echo '3';;
		fast ) echo '4';;
		medium ) echo '5';;
		slow ) echo '6';;
		slower ) echo '7';;
		veryslow ) echo '8';;
		placebo ) echo '9';;
		* ) echo '-1';;
	esac
}

runCommand() {
	local command="${1}"
	
	if [ "$(getComplexityOrder $compressComplexity)" -lt 1 ]; then
		echo "--cplex is an invalid value"
		command="badVariable"
	fi
	
	if [ "$command" = "active" ]; then
		echo "$(isRunning)"
	elif [ "$command" = "start-local" ]; then
		echo "$(getCommand "$command")"
		startLocal
	elif [ "$command" = "start" ]; then
		echo "$(getCommand "$command")"
		startDaemon
	elif [ "$command" = "output" ]; then
		cat "${logFile}"
	elif [ "$command" = "stop" ]; then
		echo "$(getCommand "$command")"
		echo "$(stopProcess)"
	else
		echo "$(getCommand "${1}")"
		echo "Usage \"$0 [active|start|start-local|output|stop] [--audio audioCodec aac] [--bit bitratePerAudioChannel 96] [--cext compressionExtension .compression] [--clean] [--cplex compressComplexity ultrafast|superfast|veryfast|fast|medium|slow|slower|veryslow|placebo] [--dry] [--ext outputExtension .mp4] [-i inputDirectory ~/Video] [--log logFile ~/encoding.results] [--pid pidFile ~/plex-encoding.pid] [--quality encodingQuality 1-50] [--thread threadCount 3] [--tmp tmpDirectory /tmp] [--video videoCodec libx264]"
		exit 1
	fi
}

while true; do
	case "${1}" in
		--audio ) audioCodec="${2}"; shift 2;;
		--bit ) bitratePerAudioChannel="${2}"; shift 2;;
		--cext ) compressionExtension="${2}"; shift 2;;
		--clean ) cleanRun="true"; shift;;
		--cplex ) compressComplexity="${2}"; shift 2;;
		--dry ) dryRun="true"; shift;;
		--ext ) outputExtension="${2}"; shift 2;;
		-i ) inputDirectory="${2}"; shift 2;;
		--log ) logFile="${2}"; shift 2;;
		--pid ) pidLocation="${2}"; shift 2;;
		--quality ) encodingQuality="${2}"; shift 2;;
		--thread ) threadCount="${2}"; shift 2;;
		--tmp ) tmpDirectory="${2}"; shift 2;;
		--video ) videoCodec="${2}"; shift 2;;
		-- ) shift; break;;
		* ) break;;
	esac
done


runCommand "$command"
