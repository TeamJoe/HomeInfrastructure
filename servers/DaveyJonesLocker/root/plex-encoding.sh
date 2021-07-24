#!/bin/bash

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
outputExtension='.mkv'
compressionExtension='.compression'
compressionMod=444

getCommand() {
	local command="${1}"
	echo "'$path' '$command' --audio '${audioCodec}' --bit '${bitratePerAudioChannel}' --cext '${compressionExtension}' $(if [ "$cleanRun" = true ]; then echo '--clean '; fi) --cmod '${compressionMod}' --cplex '${compressComplexity}' $(if [ "$dryRun" = true ]; then echo '--dry '; fi) --ext '${outputExtension}' -i '${inputDirectory}' --log '${logFile}' --pid '${pidLocation}' --quality '${encodingQuality}' --subi '${subtitlesImageCodec}' --subt '${subtitlesTextCodec}' --thread '${threadCount}' --tmp '${tmpDirectory}' --video '${videoCodec}'"
}

getAudioEncodingSettings() {
	local inputFile="${1}"
	local audioEncoding=""
	local streamCount="$(ffprobe "${inputFile}" -show_entries format=nb_streams -v 1 -of compact=p=0:nk=1)"
	for (( i=0; i<=${streamCount}; i++ )); do
		local channelCount="$(ffprobe -i "${inputFile}" -show_streams -select_streams a:${i} | grep -o '^channels=[0-9]*$' | grep -o '[0-9]*')"
		if [ -n "$channelCount" ]; then
			local bitrate="$(( $channelCount * $bitratePerAudioChannel))"
			local audioEncoding="${audioEncoding} -c:a:${i} $audioCodec -b:a:${i} ${bitrate}k"
		fi
	done
	echo "${audioEncoding}"
}

getVideoEncodingSettings() {
	local inputFile="${1}"
	local videoEncoding=""
	local streamCount="$(ffprobe "${inputFile}" -show_entries format=nb_streams -v 1 -of compact=p=0:nk=1)"
	for (( i=0; i<=${streamCount}; i++ )); do
		local codecName="$(ffprobe -i "${inputFile}" -show_streams -select_streams v:${i} | grep -o '^codec_name=.*$' | grep -o '[^=]*$')"
		if [ -n "$codecName" ]; then
			if [ "$codecName" == 'h264' ] && [ "${videoCodec}" == 'libx264' ] && [ "${compressComplexity}" == 'ultrafast' ]; then
				local videoEncoding="${videoEncoding} -c:v:${i} copy"
			else
				local videoEncoding="${videoEncoding} -c:v:${i} $videoCodec"
			fi
		fi
	done
	echo "${videoEncoding}"
}

getSubtitleEncodingType() {
	local codec="${1}"
	case "$codec" in
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
	local subtitleEncoding=""
	local streamCount="$(ffprobe "${inputFile}" -show_entries format=nb_streams -v 1 -of compact=p=0:nk=1)"
	for (( i=0; i<=${streamCount}; i++ )); do
		local codecName="$(ffprobe -i "${inputFile}" -show_streams -select_streams s:${i} | grep -o '^codec_name=.*$' | grep -o '[^=]*$')"
		if [ -n "$codecName" ]; then
			local codecType="$(getSubtitleEncodingType "${codecName}")"
			if [ "${codecType}" = "image" ]; then
				local subtitleEncoding="${subtitleEncoding} -c:s:${i} $subtitlesImageCodec"
			else
				local subtitleEncoding="${subtitleEncoding} -c:s:${i} $subtitlesTextCodec"
			fi
		fi
	done
	echo "${subtitleEncoding}"
}

assembleArguments() {
	local inputFile="$(echo "${1}" | sed -e "s/'/'\"'\"'/g")"
	local outputFile="$(echo "${2}" | sed -e "s/'/'\"'\"'/g")"

	echo "-i '${inputFile}' -crf 18 -map 0 $(getAudioEncodingSettings "${inputFile}") $(getSubtitleEncodingSettings "${inputFile}") $(getVideoEncodingSettings "${inputFile}") -threads ${threadCount} -preset ${compressComplexity} '${outputFile}'"
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

getCurrentComplexity() {
	local file="${1}"
	
	local filePath="$(echo "$file" | sed 's/\(.*\)\..*/\1/')"
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
	
	echo "${currentFileExt}"
}

convert() {
	local inputFile="${1}"
	local outputFile="${2}"
	arguments="$(assembleArguments "${inputFile}" "${outputFile}")"
	echo "ffmpeg ${arguments}"
	eval "ffmpeg ${arguments}"
	convertErrorCode=$?
}

convertFile() {
	local inputFile="${1}"
	local tmpFile="${2}"
	local outputFile="${3}"
	local logFile="${4}"
	
	local mod="$(stat --format '%a' "${inputFile}")"
	local owner="$(ls -al "${inputFile}" | awk '{print $3}')"
	local group="$(ls -al "${inputFile}" | awk '{print $4}')"
	local originalSize="$(ls -al "${inputFile}" | awk '{print $5}')"
	
	local currentFileExt="$(getCurrentComplexity "${inputFile}")"
	local currentComplexity="$(getComplexityOrder "${currentFileExt}")"
	local newComplexity="$(getComplexityOrder "${compressComplexity}")"
	local finalSize=""
	
	if [ "$dryRun" = "true" ]; then
		local finalSize="$(ls -al "${inputFile}" | awk '{print $5}')"
		if [ "${currentComplexity}" -gt "${newComplexity}" ]; then
			echo "File '${inputFile}' is already '${currentFileExt}' compressed, will not compress to worse '${compressComplexity}' format"
		else
			echo "convert \"${inputFile}\" \"${tmpFile}\""
			echo "rm -v \"${inputFile}\""
			echo "mv -v \"$tmpFile\" \"${outputFile}\""
			echo "chown \"${owner}:${group}\" -v \"${outputFile}\""
			echo "chown \"${owner}:${group}\" -v \"${logFile}\""
			echo "chmod \"${mod}\" -v \"${outputFile}\""
			echo "chmod \"${compressionMod}\" -v \"${logFile}\""
			echo "File '${inputFile}' reduced to $((${finalSize}/1024/1204))MiB from original size $((${originalSize}/1024/1204))MiB"
		fi
	else
		if [ "${currentComplexity}" -gt "${newComplexity}" ]; then
			echo "File is already '${currentFileExt}' compressed, will not compress to worse '${compressComplexity}' format" > "${logFile}"
			echo "File '${inputFile}' is already '${currentFileExt}' compressed, will not compress to worse '${compressComplexity}' format"
		else
			convert "${inputFile}" "${tmpFile}" > "${logFile}"
			local finalSize="$(ls -al "${tmpFile}" | awk '{print $5}')"
			if [ -f "${tmpFile}" ] && [ "$convertErrorCode" = "0" ] && [ -n "${finalSize}" ] && [ "${finalSize}" -gt 0 ] && [ -n "${originalSize}" ] && [ "$((${originalSize}/${finalSize}))" -lt 1000 ]; then
				rm -v "${inputFile}" >> "${logFile}"
				mv -v "$tmpFile" "${outputFile}" >> "${logFile}"
				chown "${owner}:${group}" -v "${outputFile}" >> "${logFile}"
				chown "${owner}:${group}" -v "${logFile}" >> "${logFile}"
				chmod "${mod}" -v "${outputFile}" >> "${logFile}"
				chmod "${compressionMod}" -v "${logFile}" >> "${logFile}"
				echo "[$(date +%FT%T)] File '${inputFile}' reduced to $((${finalSize}/1024/1204))MiB from original size $((${originalSize}/1024/1204))MiB" >> "${logFile}"
				echo "[$(date +%FT%T)] File '${inputFile}' reduced to $((${finalSize}/1024/1204))MiB from original size $((${originalSize}/1024/1204))MiB"
			else
				echo "$(cat "${logFile}")"
				echo "[$(date +%FT%T)] Failed to compress '${inputFile}'. Exit Code '${convertErrorCode}' Final Size '${finalSize}' Original Size '${originalSize}'"
				rm "$tmpFile"
				rm "${logFile}"
			fi
		fi
	fi
}

convertAll() {
	local inputDirectory="${1}"
	local tmpDirectory="${2}"
	local pid="${3}"
	if [ "$cleanRun" = "true" ]; then
		find "${inputDirectory}" -type f -name "*${compressionExtension}.${compressComplexity}" -delete
	fi

	echo "[$(date +%FT%T)] Starting"
	IFS=$'\n'
	for inputFile in $(find "${inputDirectory}" -type f -exec file -N -i -- {} + | sed -n 's!: video/[^:]*$!!p'); do
		if [ "${pid}" != "$(cat "${pidLocation}")" ]; then
			echo "[$(date +%FT%T)] PID mismatch; Stopping"
			break
		fi

		local filePath="$(echo "${inputFile}" | sed 's/\(.*\)\..*/\1/')"
		local fileNameWithExt="$(basename "${inputFile}")"
		local currentExt="${fileNameWithExt##*.}"
		local logFile="${filePath}${compressionExtension}.${compressComplexity}"
		if [ "${currentExt}" != "part" ] && [ ! -f "${logFile}" ]; then
			local tmpFile="${tmpDirectory}/$(basename "${filePath}")${outputExtension}"
			local outputFile="${filePath}${outputExtension}"
			echo "[$(date +%FT%T)] Converting '${inputFile}' to '${outputFile}'"
			convertFile "${inputFile}" "${tmpFile}" "${outputFile}" "${logFile}"
		fi
	done
	echo "[$(date +%FT%T)] Completed"
}

startLocal() {
	if [ "$(isRunning)" = "true" ]; then
		echo "Daemon is already running"
	else
		echo "Starting On Local Process"
		pid="$$"
		echo "${pid}" > "${pidLocation}"
		echo "$(getCommand "$command")" >> "${logFile}"
		convertAll "${inputDirectory}" "${tmpDirectory}" "${pid}" >> "${logFile}"
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
	if [ -f "${pidLocation}" ]; then
		local pid="$(cat "${pidLocation}")"
		
		if [ -n "${pid}" ]; then
			local isRunning="$(ps ax | awk '{print $1}' | grep "${pid}")"
			if [ -n "$isRunning" ]; then
				echo 'true'
			else
				echo 'false'
				rm "${pidLocation}"
			fi
		else
			echo 'false'
		fi
	else
		echo 'false'
	fi
}

stopProcess() {
	if [ "$(isRunning)" = "true" ]; then
		local pid="$(cat "${pidLocation}")"
		echo "-1" >> "${pidLocation}"
	else
		echo "Daemon is not running"
	fi
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
		echo "$(tail -n 1000 "${logFile}")"
	elif [ "$command" = "stop" ]; then
		echo "$(getCommand "$command")"
		echo "$(stopProcess)"
	else
		echo "$(getCommand "${1}")"
		echo "Usage \"$0 [active|start|start-local|output|stop] [--audio audioCodec aac] [--bit bitratePerAudioChannel 96] [--cext compressionExtension .compression] [--clean] [--cmod compressionMod 444] [--cplex compressComplexity ultrafast|superfast|veryfast|fast|medium|slow|slower|veryslow|placebo] [--dry] [--ext outputExtension .mp4] [-i inputDirectory ~/Video] [--log logFile ~/encoding.results] [--pid pidFile ~/plex-encoding.pid] [--subi subtitlesImageCodec dvbsub] [--subt subtitlesTextCodec srt] [--quality encodingQuality 1-50] [--thread threadCount 3] [--tmp tmpDirectory /tmp] [--video videoCodec libx264]"
		exit 1
	fi
}

while true; do
	case "${1}" in
		--audio ) audioCodec="${2}"; shift 2;;
		--bit ) bitratePerAudioChannel="${2}"; shift 2;;
		--cext ) compressionExtension="${2}"; shift 2;;
		--clean ) cleanRun="true"; shift;;
		--cmod ) compressionMod="${2}"; shift 2;;
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


