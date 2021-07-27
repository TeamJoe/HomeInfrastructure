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
pidLocation='~/plex-encoding.pid'
threadCount=4 # 0 is unlimited
encodingQuality=18 # 1-50, lower is better quailty
compressComplexity='fast' # ultrafast, superfast, veryfast, fast, medium, slow, slower, veryslow, placebo
audioCodec='aac'
videoCodec='libx264'
subtitlesImageCodec='dvbsub'
subtitlesTextCodec='subrip'
bitratePerAudioChannel=96 # 64 is default
outputExtension='.mkv'
sortBy='size'
metadataCodecName='ENCODER-CODEC'
metadataAudioBitRate='ENCODER-BIT-RATE'
metadataVideoPreset='ENCODER-PRESET'
metadataVideoQuality='ENCODER-QUALITY'
lockfileExtension='.compression.lock.pid'

error() {
	log "[ERROR] $@"
}

warn() {
	log "[WARN] $@"
}

info() {
	log "[INFO] $@"
}

debug() {
	log "[DEBUG] $@"
}

trace() {
	log "[TRACE] $@"
}

log() {
	echo "[$(getTime)] $@"
}

getTime() {
	echo "$(date +%FT%TZ)"
}

getCommand() {
	local command="${1}"
	echo "'$path' '$command' --audio '${audioCodec}' --bit '${bitratePerAudioChannel}' --cplex '${compressComplexity}' $(if [ "$dryRun" = true ]; then echo '--dry '; fi) --ext '${outputExtension}' -i '${inputDirectory}' --log '${logFile}' --pid '${pidLocation}' --quality '${encodingQuality}' --sort '${sortBy}' --subi '${subtitlesImageCodec}' --subt '${subtitlesTextCodec}' --thread '${threadCount}' --tmp '${tmpDirectory}' --video '${videoCodec}'"
} 


normalizeAudioCodec() {
	local codecName="${1,,}"
	case "${codecName}" in
		libfdk_aac | aac | aac_fixed ) echo 'aac';;
		libfdk_ac3 | ac3 | ac3_fixed ) echo 'ac3';;
		* ) echo "${codecName}";;
	esac
}

normalizeVideoCodec() {
	local codecName="${1,,}"
	case "${codecName}" in
		libx265 | h265 | x265 | hevc | hevc_v4l2m2m | hevc_vaapi ) echo 'hevc';;
		libx264 | h264 | x264 | libx264rgb | h264_v4l2m2m | h264_vaapi | h264_omx ) echo 'h264';; 
		* ) echo "${codecName}";;
	esac
}

normalizeSubtitleCodec() {
	local codecName="${1,,}"
	case "${codecName}" in
		subrip | srt ) echo 'subrip';;
		dvbsub | dvb_subtitle ) echo 'dvbsub';;
		dvdsub | dvd_subtitle ) echo 'dvdsub';;
		pgssub | hdmv_pgs_subtitle ) echo 'pgssub';;
		cc_dec | eia_608 ) echo 'cc_dec';;
		libzvbi_teletextdec | dvb_teletext ) echo 'libzvbi_teletextdec';;
		ssa | ass ) echo 'ass';;
		* ) echo "${codecName}";;
	esac
}

getComplexityOrder() {
	local compressComplexity="${1,,}"
	case "${compressComplexity}" in
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

getSubtitleEncodingType() {
	local codecName="${1,,}"
	case "${codecName}" in
		dvbsub ) echo 'image';;
		dvdsub ) echo 'image';;
		pgssub ) echo 'image';;
		xsub ) echo 'image';;
		arib_caption ) echo 'text';;
		ass ) echo 'text';;
		cc_dec ) echo 'text';;
		hdmv_text_subtitle ) echo 'text';;
		jacosub ) echo 'text';;
		libzvbi_teletextdec ) echo 'text';;
		microdvd ) echo 'text';;
		mov_text ) echo 'text';;
		mpl2 ) echo 'text';;
		realtext ) echo 'text';;
		sami ) echo 'text';;
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

getAudioEncodingSettings() {
	local inputFile="${1}"

	local audioEncoding=""
	local streamCount="$(ffprobe "${inputFile}" -loglevel error -select_streams a -show_entries stream=index -of csv=p=0 | wc -l)"
	local probeResult=''
	local stream=0
	local codecName=''
	local channelCount=''
	local oldBitRate=''
	local wantedBitRate=''

	for stream in $(seq 0 1 ${streamCount}); do
		probeResult="$(ffprobe -i "${inputFile}" -loglevel error -show_streams -select_streams a:${stream})"
		codecName="$(echo "${probeResult}" | grep -o "^TAG:${metadataCodecName}=.*$" | grep -o '[^=]*$')"
		if [ -z "${codecName}" ]; then
			codecName="$(echo "${probeResult}" | grep -o '^codec_name=.*$' | grep -o '[^=]*$')"
		fi
		channelCount="$(echo "${probeResult}" | grep -o '^channels=.*$' | grep -o '[^=]*$')"
		if [ -z "$channelCount" ]; then
			channelCount=2
		fi
		oldBitRate="$(echo "${probeResult}" | grep -o "^TAG:${metadataAudioBitRate}=.*$" | grep -o '[^=]*$')"
		if [ -z "$oldBitRate" ] || [ "$oldBitRate" = "N/A" ]; then
			oldBitRate="$(echo "${probeResult}" | grep -o '^bit_rate=.*$' | grep -o '[^=]*$')"
		fi
		if [ -z "$oldBitRate" ] || [ "$oldBitRate" = "N/A" ] || [ "$oldBitRate" = "0" ]; then
			oldBitRate="$(( 100 * 1024 * 1024 ))"
		fi
		if [[ "${oldBitRate^^}" =~ .*K$ ]]; then
			oldBitRate="$(( "${oldBitRate::-1}" ))"
		elif [[ "${oldBitRate^^}" =~ .*M$ ]]; then
			oldBitRate="$(( "${oldBitRate::-1}" * 1024 ))"
		else
			oldBitRate="$(( "${oldBitRate}" / 1024 ))"
		fi
		wantedBitRate="$(( $channelCount * $bitratePerAudioChannel ))"
		if [ "${wantedBitRate}" -gt "${oldBitRate}" ]; then
			wantedBitRate="${oldBitRate}"
		fi
		if [ -n "${codecName}" ]; then
			normalizedOldCodecName="$(normalizeAudioCodec "${codecName}")"
			normalizedNewCodecName="$(normalizeAudioCodec "${audioCodec}")"
			if [ "${normalizedOldCodecName}" = "${normalizedNewCodecName}" ] && [ "${oldBitRate}" -le "${wantedBitRate}" ]; then
				audioEncoding="${audioEncoding} -c:a:${stream} copy -metadata:s:a:${stream} ${metadataAudioBitRate}=$(( $oldBitRate * 1024 )) -metadata:s:a:${stream} ${metadataCodecName}=${codecName}"
			else
				audioEncoding="${audioEncoding} -c:a:${stream} ${audioCodec} -b:a:${stream} ${wantedBitRate}k -metadata:s:a:${stream} ${metadataAudioBitRate}=$(( $wantedBitRate * 1024 )) -metadata:s:a:${stream} ${metadataCodecName}=${audioCodec}"
			fi
		fi
	done
	echo "${audioEncoding}"
}

getVideoEncodingSettings() {
	local inputFile="${1}"

	local videoEncoding=""
	local streamCount="$(ffprobe "${inputFile}" -loglevel error -select_streams v -show_entries stream=index -of csv=p=0 | wc -l)"
	local probeResult=''
	local stream=0
	local codecName=''
	local oldPreset=''
	local oldQuality=''
	local oldComplexity=''
	local newComplexity=''

	for stream in $(seq 0 1 ${streamCount}); do
		probeResult="$(ffprobe -i "${inputFile}" -loglevel error -show_streams -select_streams v:${stream})"
		codecName="$(echo "${probeResult}" | grep -o "^TAG:${metadataCodecName}=.*$" | grep -o '[^=]*$')"
		if [ -z "${codecName}" ]; then
			codecName="$(echo "${probeResult}" | grep -o '^codec_name=.*$' | grep -o '[^=]*$')"
		fi
		oldPreset="$(echo "${probeResult}" | grep -o "^TAG:${metadataVideoPreset}=.*$" | grep -o '[^=]*$')"
		oldQuality="$(echo "${probeResult}" | grep -o "^TAG:${metadataVideoQuality}=.*$" | grep -o '[^=]*$')"
		oldComplexity="$(getComplexityOrder "$oldPreset")"
		newComplexity="$(getComplexityOrder "$compressComplexity")"
		
		if [ -z "$oldQuality" ]; then
			oldQuality=0
		fi
		if [ -n "${codecName}" ]; then
			normalizedOldCodecName="$(normalizeVideoCodec "${codecName}")"
			normalizedNewCodecName="$(normalizeVideoCodec "${videoCodec}")"
			if [ "${normalizedOldCodecName}" = "${normalizedNewCodecName}" ] && [ "${oldComplexity}" -ge "${newComplexity}" ] && [ "${oldQuality}" -ge "${encodingQuality}" ]; then
				videoEncoding="${videoEncoding} -c:v:${stream} copy -metadata:s:v:${stream} ${metadataVideoPreset}=${oldPreset} -metadata:s:v:${stream} ${metadataVideoQuality}=${oldQuality} -metadata:s:v:${stream} ${metadataCodecName}=${codecName}"
			elif [[ "${normalizedOldCodecName}" = "${normalizedNewCodecName}" || "${normalizedOldCodecName}" = 'h264' || "${normalizedOldCodecName}" = 'hevc' ]] && [ "${compressComplexity}" = 'ultrafast' ]; then
				videoEncoding="${videoEncoding} -c:v:${stream} copy -metadata:s:v:${stream} ${metadataVideoPreset}=${compressComplexity} -metadata:s:v:${stream} ${metadataVideoQuality}=${oldQuality} -metadata:s:v:${stream} ${metadataCodecName}=${codecName}"
			else
				videoEncoding="${videoEncoding} -c:v:${stream} ${videoCodec} -metadata:s:v:${stream} ${metadataVideoPreset}=${compressComplexity} -metadata:s:v:${stream} ${metadataVideoQuality}=${encodingQuality} -metadata:s:v:${stream} ${metadataCodecName}=${videoCodec}"
			fi
		fi
	done
	echo "${videoEncoding}"
}

getSubtitleEncodingSettings() {
	local inputFile="${1}"

	local subtitleEncoding=""
	local streamCount="$(ffprobe "${inputFile}" -loglevel error -select_streams s -show_entries stream=index -of csv=p=0 | wc -l)"
	local probeResult=''
	local stream=0
	local codecName=''
	local codecType=''

	for stream in $(seq 0 1 ${streamCount}); do
		probeResult="$(ffprobe -i "${inputFile}" -loglevel error -show_streams -select_streams v:${stream})"
		codecName="$(echo "${probeResult}" | grep -o "^TAG:${metadataCodecName}=.*$" | grep -o '[^=]*$')"
		if [ -z "${codecName}" ]; then
			codecName="$(echo "${probeResult}" | grep -o '^codec_name=.*$' | grep -o '[^=]*$')"
		fi
		if [ -n "${codecName}" ]; then
			normalizedOldCodecName="$(normalizeSubtitleCodec "${codecName}")"
			codecType="$(getSubtitleEncodingType "${codecName}")"
			if [ "${codecType}" = "image" ]; then
				normalizedNewCodecName="$(normalizeSubtitleCodec "${subtitlesImageCodec}")"
				if [ "${normalizedOldCodecName}" = "${normalizedNewCodecName}" ]; then
					subtitleEncoding="${subtitleEncoding} -c:s:${stream} copy -metadata:s:s:${stream} ${metadataCodecName}=${codecName}"
				else
					subtitleEncoding="${subtitleEncoding} -c:s:${stream} ${subtitlesImageCodec} -metadata:s:s:${stream} ${metadataCodecName}=${subtitlesImageCodec}"
				fi
			else
				normalizedNewCodecName="$(normalizeSubtitleCodec "${subtitlesTextCodec}")"
				if [ "${normalizedOldCodecName}" = "${normalizedNewCodecName}" ]; then
					subtitleEncoding="${subtitleEncoding} -c:s:${stream} copy -metadata:s:s:${stream} ${metadataCodecName}=${codecName}"
				else
					subtitleEncoding="${subtitleEncoding} -c:s:${stream} ${subtitlesTextCodec} -metadata:s:s:${stream} ${metadataCodecName}=${subtitlesTextCodec}"
				fi
			fi
		fi
	done
	echo "${subtitleEncoding}"
}

assembleArguments() {
	local inputFile="${1}"
	local outputFile="${2}"

	local videoArguments=" $(getVideoEncodingSettings "${inputFile}")"
	local audioArguments=" $(getAudioEncodingSettings "${inputFile}")"
	local subtitleArguments=" $(getSubtitleEncodingSettings "${inputFile}")"

	echo "-i '$(echo "${inputFile}" | sed -e "s/'/'\"'\"'/g")' -crf ${encodingQuality} -map 0 ${videoArguments} ${audioArguments} ${subtitleArguments} -threads ${threadCount} -preset ${compressComplexity} '$(echo "${outputFile}" | sed -e "s/'/'\"'\"'/g")'"
}

lockFile() {
	local inputFile="${1}"
	local pid="${2}"
	local lockedPid=''
	if [ -f "${inputFile}${lockfileExtension}" ]; then
		if [ "$(isPidRunning "$(cat "${inputFile}${lockfileExtension}")")" = 'false' ]; then
			echo "${pid}" > "${inputFile}${lockfileExtension}"
		fi
	else
		echo "${pid}" > "${inputFile}${lockfileExtension}"
	fi
	
	if [ "$(cat "${inputFile}${lockfileExtension}")" = "${pid}" ]; then
		echo 'true'
	else
		echo 'false'
	fi
}

unlockFile() {
	local inputFile="${1}"
	local pid="${2}"
	local lockedPid=''
	if [ -f "${inputFile}${lockfileExtension}" ]; then
		if [ "$(cat "${inputFile}${lockfileExtension}")" = "${pid}" ]; then
			rm -f "${inputFile}${lockfileExtension}"
		fi
	fi
}

convert() {
	local inputFile="${1}"
	local outputFile="${2}"
	local pid="${3}"
	
	local arguments="$(assembleArguments "${inputFile}" "${outputFile}")"
	
	debug "ffmpeg ${arguments}"
	if [[ "${arguments}" =~ .*-c:v:[0-9]+' '*"${videoCodec}".* ]] \
		|| [[ "${arguments}" =~ .*-c:a:[0-9]+' '*"${audioCodec}".* ]] \
		|| [[ "${arguments}" =~ .*-c:s:[0-9]+' '*"${subtitlesImageCodec}".* ]] \
		|| [[ "${arguments}" =~ .*-c:s:[0-9]+' '*"${subtitlesTextCodec}".* ]]; then
		
		if [ "$(lockFile "${inputFile}" "${pid}")" = 'false' ]; then
			hasCodecChanges='conflict'
			convertErrorCode=0
		else
			hasCodecChanges='true'
			eval "ffmpeg ${arguments}"
			convertErrorCode=$?
		fi
		unlockFile "${inputFile}" "${pid}"
	else
		hasCodecChanges='false'
		convertErrorCode=0
	fi
}

convertFile() {
	local inputFile="${1}"
	local tmpFile="${2}"
	local outputFile="${3}"
	local pid="${4}"

	local mod="$(stat --format '%a' "${inputFile}")"
	local owner="$(ls -al "${inputFile}" | awk '{print $3}')"
	local group="$(ls -al "${inputFile}" | awk '{print $4}')"
	local originalSize="$(ls -al "${inputFile}" | awk '{print $5}')"
	local finalSize=''
	
	if [ "$dryRun" = "true" ]; then
		finalSize="$(ls -al "${inputFile}" | awk '{print $5}')"
		echo "convert \"${inputFile}\" \"${tmpFile}\" \"${pid}\""
		echo "rm -v \"${inputFile}\""
		echo "mv -v \"$tmpFile\" \"${outputFile}\""
		echo "chown \"${owner}:${group}\" -v \"${outputFile}\""
		echo "chmod \"${mod}\" -v \"${outputFile}\""
		echo "File '${inputFile}' reduced to $((${finalSize}/1024/1204))MiB from original size $((${originalSize}/1024/1204))MiB"
	else
		convert "${inputFile}" "${tmpFile}" "${pid}"
		finalSize="$(ls -al "${tmpFile}" | awk '{print $5}')"
		if [ "${hasCodecChanges}" = 'false' ]; then
			trace "Not processing file '${inputFile}', as no changes would be made."
		elif [ "${hasCodecChanges}" = 'conflict' ]; then
			info "Cannot achieve lock on file '${inputFile}', Skipping."
		elif [ -f "${tmpFile}" ] && [ "${convertErrorCode}" = "0" ] && [ -n "${finalSize}" ] && [ "${finalSize}" -gt 0 ] && [ -n "${originalSize}" ] && [ "$((${originalSize}/${finalSize}))" -lt 1000 ]; then
			rm "${inputFile}"
			mv "${tmpFile}" "${outputFile}"
			chown "${owner}:${group}" "${outputFile}"
			chmod "${mod}" "${outputFile}"
			trace "File '${inputFile}' reduced to $((${finalSize}/1024/1204))MiB from original size $((${originalSize}/1024/1204))MiB"
		else
			warn "Failed to compress '${inputFile}'. Exit Code '${convertErrorCode}' Final Size '${finalSize}' Original Size '${originalSize}'"
			rm "${tmpFile}"
		fi
	fi
}

convertAll() {
	local inputDirectory="${1}"
	local tmpDirectory="${2}"
	local pid="${3}"
	local filePath=''
	local fileNameWithExt=''
	local currentExt=''
	local tmpFile=''
	local outputFile=''
	local inputFile=''
	local sortingType="$( if [[ "${sortBy^^}" =~ ^.*'DATE'$ ]]; then echo '%T@ %p\n'; else echo '%s %p\n'; fi )"
	local sortingOrder="$( if [[ "${sortBy^^}" =~ ^'REVERSE'.*$ ]]; then echo ' -n'; else echo '-rn'; fi )"
	local allInputFiles="$(find "${inputDirectory}" -type f -printf "${sortingType}" | sort ${sortingOrder} | awk '!($1="")' | sed 's/^ *//g' | xargs -d "\n" file -N -i | sed -n 's!: video/[^:]*$!!p')"
	
	info "Starting"
	IFS=$'\n'
	for inputFile in ${allInputFiles[@]}; do
		if [ "${pid}" != "$(cat "${pidLocation}")" ]; then
			info "PID mismatch; Stopping"
			break
		fi

		filePath="$(echo "${inputFile}" | sed 's/\(.*\)\..*/\1/')"
		fileNameWithExt="$(basename "${inputFile}")"
		currentExt="${fileNameWithExt##*.}"
		if [ "${currentExt}" != "part" ]; then
			tmpFile="${tmpDirectory}/$(basename "${filePath}")${outputExtension}"
			if [ -f "${tmpFile}" ]; then
				rm -f "${tmpFile}"
			fi
			outputFile="${filePath}${outputExtension}"
			if [ -f "${outputFile}" ] && [ "${inputFile}" != "${outputFile}" ]; then
				warn "Cannot convert '${inputFile}' as it would overwrite '${outputFile}'"
			else
				trace "Converting '${inputFile}' to '${outputFile}'"
				convertFile "${inputFile}" "${tmpFile}" "${outputFile}" "${pid}"
			fi
		fi
	done
	rm -rf "${tmpDirectory}"
	info "Completed"
}

startLocal() {
	local pid=''

	if [ "$(isRunning)" = "true" ]; then
		echo "Daemon is already running"
	else
		echo "Starting On Local Process"
		pid="$$"
		echo "${pid}" > "${pidLocation}"
		info "$(getCommand "$command")" >> "${logFile}"
		mkdir -p "${tmpDirectory}/${pid}"
		convertAll "${inputDirectory}" "${tmpDirectory}/${pid}" "${pid}" >> "${logFile}"
	fi
}

startDaemon() {
	local var=''

	if [ "$(isRunning)" = "true" ]; then
		echo "Daemon is already running"
	else
		echo "Starting Daemon"
		vars="$(getCommand "start-local")"
		eval "nohup $vars >/dev/null 2>&1 &"
	fi
}

isPidRunning() {
	local pid="${1}"
	if [ -n "${pid}" ]; then
		isRunning="$(ps ax | awk '{print $1}' | grep "${pid}")"
		if [ -n "$isRunning" ]; then
			echo 'true'
		else
			echo 'false'
		fi
	else
		echo 'false'
	fi
}

isRunning() {
	local pid=''
	local isRunning=''

	if [ -f "${pidLocation}" ]; then
		pid="$(cat "${pidLocation}" | awk 'NR==1{print $1}')"
		if [ "$(isPidRunning "${pid}")" = 'true' ]; then
			echo 'true'
		else
			echo 'false'
			rm "${pidLocation}"
		fi
	else
		echo 'false'
	fi
}

stopProcess() {
	if [ "$(isRunning)" = "true" ]; then
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
		echo "Usage \"$0 [active|start|start-local|output|stop] [--audio audioCodec aac] [--bit bitratePerAudioChannel 96] [--cplex compressComplexity ultrafast|superfast|veryfast|fast|medium|slow|slower|veryslow|placebo] [--dry] [--ext outputExtension .mp4] [-i inputDirectory ~/Video] [--log logFile ~/encoding.results] [--pid pidFile ~/plex-encoding.pid] [--sort sortBy date|size|reverse-date|reverse-size] [--subi subtitlesImageCodec dvbsub] [--subt subtitlesTextCodec srt] [--quality encodingQuality 1-50] [--thread threadCount 3] [--tmp tmpDirectory /tmp] [--video videoCodec libx264]"
		exit 1
	fi
}

while true; do
	case "${1}" in
		--audio ) audioCodec="${2}"; shift 2;;
		--bit ) bitratePerAudioChannel="${2}"; shift 2;;
		--cplex ) compressComplexity="${2}"; shift 2;;
		--dry ) dryRun="true"; shift;;
		--ext ) outputExtension="${2}"; shift 2;;
		-i ) inputDirectory="${2}"; shift 2;;
		--log ) logFile="${2}"; shift 2;;
		--pid ) pidLocation="${2}"; shift 2;;
		--quality ) encodingQuality="${2}"; shift 2;;
		--sort ) sortBy="${2}"; shift 2;;
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
