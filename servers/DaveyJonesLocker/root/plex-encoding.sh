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
subtitlesImageCodec='dvbsub'
subtitlesTextCodec='srt'
bitratePerAudioChannel=96 # 64 is default
outputExtension='.mp4'
compressionExtension='.compression'

getCommand() {
	local command="${1}"
	echo "'$path' '$command' --audio '${audioCodec}' --bit '${bitratePerAudioChannel}' --cext '${compressionExtension}' $(if [ "$cleanRun" = true ]; then echo '--clean '; fi) --cplex '${compressComplexity}' $(if [ "$dryRun" = true ]; then echo '--dry '; fi) --ext '${outputExtension}' -i '${inputDirectory}' --log '${logFile}' --pid '${pidLocation}' --quality '${encodingQuality}' --subi '${subtitlesImageCodec}' --subt '${subtitlesTextCodec}' --thread '${threadCount}' --tmp '${tmpDirectory}' --video '${videoCodec}'"
}

getAudioEncodingSettings() {
	local inputFile="${1}"
	local streamCount="$(ffprobe "$inputFile" -show_entries format=nb_streams -v 1 -of compact=p=0:nk=1)"
	for (( i=0; i<=${streamCount}; i++ )); do
		local channelCount="$(ffprobe -i "$inputFile" -show_streams -select_streams a:${i} | grep -o '^channels=[0-9]*$' | grep -o '[0-9]*')"
		if [ -n "$channelCount" ]; then
			local bitrate="$(( $channelCount * $bitratePerAudioChannel))"
			echo " -c:a:${i} $audioCodec -b:a:${i} ${bitrate}k"
		fi
	done
}

getVideoEncodingSettings() {
	local inputFile="${1}"
	echo " -c:v $videoCodec"
}

getSubtitleEncodingType() {
	local codec="${1}"
	case "$compressComplexity" in
		dvb_subtitle ) echo 'image';;
		dvbsub ) echo 'image';;
		dvd_subtitle ) echo 'image';;
		dvdsub ) echo 'image';;
		hdmv_pgs_subtitle ) echo 'image';;
		pgssub ) echo 'image';;
		xsub ) echo 'image';;
		arib_caption ) echo 'text';;
		ass ) echo 'text';;
		cc_dec ) echo 'text';;
		dvb_teletext ) echo 'text';;
		eia_608 ) echo 'text';;
		hdmv_text_subtitle ) echo 'text';;
		jacosub ) echo 'text';;
		libzvbi_teletextdec ) echo 'text';;
		microdvd ) echo 'text';;
		mov_text ) echo 'text';;
		mpl2 ) echo 'text';;
		realtext ) echo 'text';;
		sami ) echo 'text';;
		srt ) echo 'text';;
		ssa ) echo 'text';;
		stl ) echo 'text';;
		subrip ) echo 'text';;
		subviewer ) echo 'text';;
		text ) echo 'text';;
		ttml ) echo 'text';;
		vplayer ) echo 'text';;
		webvtt ) echo 'text';;
		* ) echo 'unknown';;
	esac
}

getSubtitleEncodingSettings() {
	local inputFile="${1}"
	local streamCount="$(ffprobe "$inputFile" -show_entries format=nb_streams -v 1 -of compact=p=0:nk=1)"
	for (( i=0; i<=${streamCount}; i++ )); do
		local codecName="$(ffprobe -i "$inputFile" -show_streams -select_streams s:${i} | grep -o '^codec_name=.*$' | grep -o '[^=]*$')"
		if [ -n "$codecName" ]; then
			local codecType="$(getSubtitleEncodingType "${codecName}")"
			if [ "${codecType}" = "image" ]; then
				echo " -c:s:${i} $subtitlesImageCodec"
			else
				echo " -c:s:${i} $subtitlesTextCodec"
			fi
		fi
	done
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
	convertErrorCode=$?
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
		if [ "$$" != "$(cat "$pidLocation")" ]; then
			echo "[$(date +%FT%T)] PID mismatch; Stopping"
			break
		fi
		local mod="$(stat --format '%a' "$file")"
		local owner="$(ls -al "$file"  | awk '{print $3}')"
		local group="$(ls -al "$file"  | awk '{print $4}')"
		local originalSize="$(ls -al "$file" | awk '{print $5}')"
		local filePath="$(echo "$file" | sed 's/\(.*\)\..*/\1/')"
		local fileNameWithExt="$(basename "$file")"
		local fileName="$(basename "$filePath")"
		local oldExt="${fileNameWithExt##*.}"
		local newComplexity="$(getComplexityOrder "${compressComplexity}")"
		local fileLogPath="${filePath}${compressionExtension}.${compressComplexity}"
		if [ "$oldExt" != "part" ] && [ ! -f "${fileLogPath}" ]; then		
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
					echo "chown \"${owner}:${group}\" -v \"${fileLogPath}\""
					echo "chmod \"$mod\" -v \"${filePath}${outputExtension}\""
					echo "chmod \"444\" -v \"${fileLogPath}\""
					local finalSize="$(ls -al "${file}" | awk '{print $5}')"
					echo "File '$file' reduced to $((${finalSize}/1024/1204))MiB from original size $((${originalSize}/1024/1204))MiB"
				fi
			else
				if [ "$currentComplexity" -gt "$newComplexity" ]; then
					echo "File is already '$currentFileExt' compressed, will not compress to worse '$compressComplexity' format" > "${fileLogPath}"
				else
					convert "${file}" "${tmpFile}" > "${fileLogPath}"
					local finalSize="$(ls -al "${tmpFile}" | awk '{print $5}')"
					if [ -f "${tmpFile}" ] && [ "$convertErrorCode" = "0" ] && [ -n "$finalSize" ] && [ "$finalSize" -gt 0 ] && [ -n "$originalSize" ] && [ "$((${originalSize}/${finalSize}))" -lt 1000 ]; then
						rm -v "$file" >> "${fileLogPath}"
						mv -v "$tmpFile" "${filePath}${outputExtension}" >> "${fileLogPath}"
						chown "${owner}:${group}" -v "${filePath}${outputExtension}" >> "${fileLogPath}"
						chown "${owner}:${group}" -v "${fileLogPath}" >> "${fileLogPath}"
						chmod "$mod" -v "${filePath}${outputExtension}" >> "${fileLogPath}"
						chmod "444" -v "${fileLogPath}" >> "${fileLogPath}"
						local finalSize="$(ls -al "${file}" | awk '{print $5}')"
						echo "[$(date +%FT%T)] File '$file' reduced to $((${finalSize}/1024/1204))MiB from original size $((${originalSize}/1024/1204))MiB" >> "${fileLogPath}"
						echo "[$(date +%FT%T)] File '$file' reduced to $((${finalSize}/1024/1204))MiB from original size $((${originalSize}/1024/1204))MiB"
					else
						echo "$(cat "${fileLogPath}")"
						echo "[$(date +%FT%T)] Failed to compress '${file}'. Exit Code '$convertErrorCode' Final Size '$finalSize' Original Size '$originalSize'"
						rm "${fileLogPath}"
					fi
				fi
			fi
		fi
	done
	echo "[$(date +%FT%T)] Completed"
}

startLocal() {
	if [ "$(isRunning)" = "true" ]; then
		echo "Daemon is already running"
	else
		echo "Starting On Local Process"
		echo "$$" > "$pidLocation"
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
		elif ps -p "$pid" > /dev/null; then
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
		echo "-1" >> "$pidLocation"
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
		echo "Usage \"$0 [active|start|start-local|output|stop] [--audio audioCodec aac] [--bit bitratePerAudioChannel 96] [--cext compressionExtension .compression] [--clean] [--cplex compressComplexity ultrafast|superfast|veryfast|fast|medium|slow|slower|veryslow|placebo] [--dry] [--ext outputExtension .mp4] [-i inputDirectory ~/Video] [--log logFile ~/encoding.results] [--pid pidFile ~/plex-encoding.pid] [--subi subtitlesImageCodec vobsub] [--subt subtitlesTextCodec webvtt] [--quality encodingQuality 1-50] [--thread threadCount 3] [--tmp tmpDirectory /tmp] [--video videoCodec libx264]"
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
		--subi ) subtitlesImageCodec="${2}"; shift 2;;
		--subt ) subtitlesTextCodec="${2}"; shift 2;;
		--thread ) threadCount="${2}"; shift 2;;
		--tmp ) tmpDirectory="${2}"; shift 2;;
		--video ) videoCodec="${2}"; shift 2;;
		-- ) shift; break;;
		* ) break;;
	esac
done


runCommand "$command"
