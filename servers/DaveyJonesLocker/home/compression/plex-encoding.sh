#!/bin/bash

## Input Values
path="${0}"
command="${1}"; shift
options="$@"

## Options
inputDirectory='~/Videos' #/home/public/Videos/TV/Sonarr
outputDirectory='' #/home/public/Videos/TV/Sonarr
tmpDirectory='/tmp'
logFile='~/encoding.results'
dryRun='false'
pidLocation='~/plex-encoding.pid'
threadCount=4 # 0 is unlimited
audioCodec='aac'
videoCodec='libx264'
videoPreset='fast' # ultrafast, superfast, veryfast, fast, medium, slow, slower, veryslow, placebo
videoProfile='baseline'
videoQuality=18 # 1-50, lower is better quailty
videoTune='' # animation, fastdecode, film, grain, stillimage, zerolatency
subtitlesImageCodec='copy' # dvbsub, dvdsub
subtitlesTextCodec='copy' # srt, ass
bitratePerAudioChannel=96 # 64 is default
outputExtension='.mkv'
sortBy='size' # date, size, reverse-date, reverse-size
metadataCodecName='ENCODER-CODEC'
metadataAudioBitRate='ENCODER-BIT-RATE'
metadataVideoPreset='ENCODER-PRESET'
metadataVideoProfile='ENCODER-PROFILE'
metadataVideoQuality='ENCODER-QUALITY'
metadataVideoTune='ENCODER-TUNE'
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
	echo "'$path' '$command' --audio '${audioCodec}' --audio-bitrate '${bitratePerAudioChannel}' $(if [ "$dryRun" = true ]; then echo '--dry '; fi) --ext '${outputExtension}' --input '${inputDirectory}' --output '${outputDirectory}' --log '${logFile}' --pid '${pidLocation}'  --sort '${sortBy}' --subtitle-image '${subtitlesImageCodec}' --subtitle-text '${subtitlesTextCodec}' --thread '${threadCount}' --tmp '${tmpDirectory}' --video '${videoCodec}' --video-preset '${videoPreset}' --video-profile '${videoProfile}' --video-quality '${videoQuality}' --video-tune '${videoTune}'"
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

getPresetComplexityOrder() {
	local videoPreset="${1,,}"
	case "${videoPreset}" in
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

getProfileComplexityOrder() {
	local videoProfile="${1,,}"
	case "${videoProfile}" in
		baseline ) echo '1';;
		main ) echo '2';; 
		high ) echo '3';;
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


	if [[ -n "${audioCodec}" && "${audioCodec,,}" != "copy" ]]; then
		for stream in $(seq 0 1 ${streamCount}); do
			probeResult="$(ffprobe -i "${inputFile}" -loglevel error -show_streams -select_streams a:${stream})"
			codecName="$(echo "${probeResult}" | grep -o "^TAG:${metadataCodecName}=.*$" | grep -o '[^=]*$')"
			if [[ -z "${codecName}" ]]; then
				codecName="$(echo "${probeResult}" | grep -o '^codec_name=.*$' | grep -o '[^=]*$')"
			fi
			channelCount="$(echo "${probeResult}" | grep -o '^channels=.*$' | grep -o '[^=]*$')"
			if [[ -z "$channelCount" ]]; then
				channelCount=2
			fi
			oldBitRate="$(echo "${probeResult}" | grep -o "^TAG:${metadataAudioBitRate}=.*$" | grep -o '[^=]*$')"
			if [[ -z "${oldBitRate}" || "${oldBitRate}" = "N/A" ]]; then
				oldBitRate="$(echo "${probeResult}" | grep -o '^bit_rate=.*$' | grep -o '[^=]*$')"
			fi
			if [[ -z "${oldBitRate}" || "${oldBitRate}" = "N/A" || "${oldBitRate}" = "0" ]]; then
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
			if [[ "${wantedBitRate}" -gt "${oldBitRate}" ]]; then
				wantedBitRate="${oldBitRate}"
			fi
			if [[ -n "${codecName}" ]]; then
				normalizedOldCodecName="$(normalizeAudioCodec "${codecName}")"
				normalizedNewCodecName="$(normalizeAudioCodec "${audioCodec}")"
				if [[ "${normalizedOldCodecName}" = "${normalizedNewCodecName}" && "${oldBitRate}" -le "${wantedBitRate}" ]]; then
					audioEncoding="${audioEncoding} -c:a:${stream} copy -metadata:s:a:${stream} ${metadataCodecName}=${codecName}"
				else
					audioEncoding="${audioEncoding} -c:a:${stream} ${audioCodec} -b:a:${stream} ${wantedBitRate}k -metadata:s:a:${stream} ${metadataAudioBitRate}=$(( $wantedBitRate * 1024 )) -metadata:s:a:${stream} ${metadataCodecName}=${audioCodec}"
				fi
			fi
		done
	fi
	echo "${audioEncoding}"
}

getVideoEncodingSettings() {
	local inputFile="${1}"

	local videoEncoding=""
	local streamCount="$(ffprobe "${inputFile}" -loglevel error -select_streams v -show_entries stream=index -of csv=p=0 | wc -l)"
	local probeResult=''
	local stream=0
	local newCodec=''
	local newPreset=''
	local newProfile=''
	local newQuality=''
	local newTune=''
	local newPresetComplexity=''
	local newProfileComplexity=''
	local oldCodec=''
	local oldPreset=''
	local oldProfile=''
	local oldQuality=''
	local oldTune=''
	local oldPresetComplexity=''
	local oldProfileComplexity=''

	
	if [[ -n "${newCodec}" && "${newCodec,,}" != "copy" ]]; then
		for stream in $(seq 0 1 ${streamCount}); do
			probeResult="$(ffprobe -i "${inputFile}" -loglevel error -show_streams -select_streams v:${stream})"
			newCodec="${videoCodec}"
			newPreset="${videoPreset}"
			newProfile="${videoProfile}"
			newQuality="${videoQuality}"
			newTune="${videoTune}"
			newPresetComplexity="$(getPresetComplexityOrder "${newPreset}")"
			newProfileComplexity="$(getProfileComplexityOrder "${newProfile}")"
			oldCodec="$(echo "${probeResult}" | grep -o "^TAG:${metadataCodecName}=.*$" | grep -o '[^=]*$')"
			if [[ -z "${oldCodec}" ]]; then
				oldCodec="$(echo "${probeResult}" | grep -o '^codec_name=.*$' | grep -o '[^=]*$')"
			fi
			oldPreset="$(echo "${probeResult}" | grep -o "^TAG:${metadataVideoPreset}=.*$" | grep -o '[^=]*$')"
			oldProfile="$(echo "${probeResult}" | grep -o "^TAG:${metadataVideoProfile}=.*$" | grep -o '[^=]*$')"
			oldQuality="$(echo "${probeResult}" | grep -o "^TAG:${metadataVideoQuality}=.*$" | grep -o '[^=]*$')"
			oldTune="$(echo "${probeResult}" | grep -o "^TAG:${metadataVideoTune}=.*$" | grep -o '[^=]*$')"
			oldPresetComplexity="$(getPresetComplexityOrder "${oldPreset}")"
			oldProfileComplexity="$(getProfileComplexityOrder "${oldProfile}")"
			
			if [[ -z "${oldQuality}" ]]; then
				oldQuality=0
			fi
			if [[ "${oldQuality}" -gt "${videoQuality}" ]]; then
				newQuality="${oldQuality}"
			fi
			if  [[ -z "${newTune}" ]]; then
				newTune="${oldTune}"
			fi 
			if [[ -n "${oldCodec}" ]]; then
				normalizedOldCodecName="$(normalizeVideoCodec "${oldCodec}")"
				normalizedNewCodecName="$(normalizeVideoCodec "${newCodec}")"
				if [[ "${normalizedOldCodecName}" = "${normalizedNewCodecName}" && "${oldPresetComplexity}" -ge "${newPresetComplexity}" && "${oldQuality}" -ge "${newQuality}" ]] || ([[ "${normalizedOldCodecName}" = "${normalizedNewCodecName}" || "${normalizedOldCodecName}" = 'h264' || "${normalizedOldCodecName}" = 'hevc' ]] && [ "${newPreset}" = 'ultrafast' ]); then
					videoEncoding="${videoEncoding} -c:v:${stream} copy -metadata:s:v:${stream} ${metadataCodecName}=${oldCodec}"
				else
					videoEncoding="${videoEncoding} -c:v:${stream} ${newCodec} -metadata:s:v:${stream} ${metadataCodecName}=${newCodec}"
					if [[ -n "${newPreset}" ]]; then
						videoEncoding="${videoEncoding} -preset:v:${stream} ${newPreset} -metadata:s:v:${stream} ${metadataVideoPreset}=${newPreset}"
					fi
					if [[ -n "${newQuality}" ]]; then
						videoEncoding="${videoEncoding} -crf:v:${stream} ${newQuality} -metadata:s:v:${stream} ${metadataVideoQuality}=${newQuality}"
					fi
					if [[ -n "${videoProfile}" ]]; then
						videoEncoding="${videoEncoding} -profile:v:${stream} ${videoProfile} -metadata:s:v:${stream} ${metadataVideoProfile}=${videoProfile}"
					fi
					if [[ -n "${newTune}" ]]; then
						videoEncoding="${videoEncoding} -tune:v:${newTune} -metadata:s:v:${stream} ${metadataVideoTune}=${newTune}"
					fi
				fi
			fi
		done
	fi
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

	if ([[ -n "${subtitlesImageCodec}" && "${subtitlesImageCodec,,}" != "copy" ]]) || ([[ -n "${subtitlesTextCodec}" && "${subtitlesTextCodec,,}" != "copy" ]]); then
		for stream in $(seq 0 1 ${streamCount}); do
			probeResult="$(ffprobe -i "${inputFile}" -loglevel error -show_streams -select_streams s:${stream})"
			codecName="$(echo "${probeResult}" | grep -o "^TAG:${metadataCodecName}=.*$" | grep -o '[^=]*$')"
			if [[ -z "${codecName}" ]]; then
				codecName="$(echo "${probeResult}" | grep -o '^codec_name=.*$' | grep -o '[^=]*$')"
			fi
			if [[ -n "${codecName}" ]]; then
				normalizedOldCodecName="$(normalizeSubtitleCodec "${codecName}")"
				codecType="$(getSubtitleEncodingType "${codecName}")"
				if [[ "${codecType}" = "image" ]]; then
					normalizedNewCodecName="$(normalizeSubtitleCodec "${subtitlesImageCodec}")"
					if [[ "${normalizedOldCodecName}" = "${normalizedNewCodecName}" || "${subtitlesImageCodec,,}" = "copy" ]]; then
						subtitleEncoding="${subtitleEncoding} -c:s:${stream} copy -metadata:s:s:${stream} ${metadataCodecName}=${codecName}"
					else
						subtitleEncoding="${subtitleEncoding} -c:s:${stream} ${subtitlesImageCodec} -metadata:s:s:${stream} ${metadataCodecName}=${subtitlesImageCodec}"
					fi
				else
					normalizedNewCodecName="$(normalizeSubtitleCodec "${subtitlesTextCodec}")"
					if [[ "${normalizedOldCodecName}" = "${normalizedNewCodecName}" || "${subtitlesTextCodec,,}" = "copy" ]]; then
						subtitleEncoding="${subtitleEncoding} -c:s:${stream} copy -metadata:s:s:${stream} ${metadataCodecName}=${codecName}"
					else
						subtitleEncoding="${subtitleEncoding} -c:s:${stream} ${subtitlesTextCodec} -metadata:s:s:${stream} ${metadataCodecName}=${subtitlesTextCodec}"
					fi
				fi
			fi
		done
	fi
	echo "${subtitleEncoding}"
}

assembleArguments() {
	local inputFile="${1}"
	local outputFile="${2}"

	local videoArguments=" $(getVideoEncodingSettings "${inputFile}")"
	local audioArguments=" $(getAudioEncodingSettings "${inputFile}")"
	local subtitleArguments=" $(getSubtitleEncodingSettings "${inputFile}")"
	
	echo "-i '$(echo "${inputFile}" | sed -e "s/'/'\"'\"'/g")' -map 0 ${videoArguments} ${audioArguments} ${subtitleArguments} -threads ${threadCount} '$(echo "${outputFile}" | sed -e "s/'/'\"'\"'/g")'"
}

lockFile() {
	local inputFile="${1}"
	local pid="${2}"
	local lockedPid=''
	if [[ -f "${inputFile}${lockfileExtension}" ]]; then
		if [[ "$(isPidRunning "$(cat "${inputFile}${lockfileExtension}")")" = 'false' ]]; then
			echo "${pid}" > "${inputFile}${lockfileExtension}"
		fi
	else
		echo "${pid}" > "${inputFile}${lockfileExtension}"
	fi
	
	if [[ "$(cat "${inputFile}${lockfileExtension}")" = "${pid}" ]]; then
		echo 'true'
	else
		echo 'false'
	fi
}

unlockFile() {
	local inputFile="${1}"
	local pid="${2}"
	local lockedPid=''
	if [[ -f "${inputFile}${lockfileExtension}" ]]; then
		if [[ "$(cat "${inputFile}${lockfileExtension}")" = "${pid}" ]]; then
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
	if [[ "${arguments}" =~ .*-c:v:0.* ]] \
		&& [[ "${arguments}" =~ .*-c:v:[0-9]+' '*"${videoCodec}".* \
			|| "${arguments}" =~ .*-c:a:[0-9]+' '*"${audioCodec}".* 
			|| "${arguments}" =~ .*-c:s:[0-9]+' '*"${subtitlesImageCodec}".* \
			|| "${arguments}" =~ .*-c:s:[0-9]+' '*"${subtitlesTextCodec}".* ]]; then
		
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
	
	if [[ "$dryRun" = "true" ]]; then
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
		if [[ "${hasCodecChanges}" = 'false' ]]; then
			trace "Not processing file '${inputFile}', as no changes would be made."
		elif [[ "${hasCodecChanges}" = 'conflict' ]]; then
			info "Cannot achieve lock on file '${inputFile}', Skipping."
		elif [[ -f "${tmpFile}" && "${convertErrorCode}" = "0" && -n "${finalSize}" && "${finalSize}" -gt 0 && -n "${originalSize}" && "$((${originalSize}/${finalSize}))" -lt 1000 ]]; then
			if [[ "$(echo "${inputFile}" | sed 's/\(.*\)\..*/\1/')" = "$(echo "${outputFile}" | sed 's/\(.*\)\..*/\1/')" ]]; then
				rm "${inputFile}"
			fi
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
	local outputDirectory="${3}"
	local pid="${4}"
	local inputDirectoryLength="$(echo "${inputDirectory}" | wc -c)"
	local filePath=''
	local fileNameWithExt=''
	local currentExt=''
	local tmpFile=''
	local outputFile=''
	local inputFile=''
	local sortingType="$( if [[ "${sortBy^^}" =~ ^.*'DATE'$ ]]; then echo '%T@ %p\n'; else echo '%s %p\n'; fi )"
	local sortingOrder="$( if [[ "${sortBy^^}" =~ ^'REVERSE'.*$ ]]; then echo ' -n'; else echo '-rn'; fi )"
	local allInputFiles="$(find "${inputDirectory}" -type f -printf "${sortingType}" | sort ${sortingOrder} | awk '!($1="")' | sed 's/^ *//g' | xargs -d "\n" file -N -i | sed -n 's!: video/[^:]*$!!p')"
	local fileCount="$(echo "${allInputFiles}" | wc -l)"
	
	info "Processing ${fileCount} file"
	IFS=$'\n'
	for inputFile in ${allInputFiles[@]}; do
		if [[ "${pid}" != "$(cat "${pidLocation}")" ]]; then
			info "PID mismatch; Stopping"
			break
		fi

		filePath="$(echo "${inputFile}" | sed 's/\(.*\)\..*/\1/')"
		fileNameWithExt="$(basename "${inputFile}")"
		currentExt="${fileNameWithExt##*.}"
		if [[ "${currentExt}" != "part" ]]; then
			tmpFile="${tmpDirectory}/$(basename "${filePath}")${outputExtension}"
			if [[ -f "${tmpFile}" ]]; then
				rm -f "${tmpFile}"
			fi
			if [[ -z "${outputDirectory}" ]]; then
				outputFile="${filePath}${outputExtension}"
			else
				outputFile="${outputDirectory}${filePath:${inputDirectoryLength}}${outputExtension}"
			fi
			if [[ -f "${outputFile}" && "${inputFile}" != "${outputFile}" ]]; then
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

	if [[ "$(isRunning)" = "true" ]]; then
		echo "Daemon is already running"
	else
		echo "Starting On Local Process"
		pid="$$"
		echo "${pid}" > "${pidLocation}"
		info "$(getCommand "$command")" >> "${logFile}"
		mkdir -p "${tmpDirectory}/${pid}"
		convertAll "${inputDirectory}" "${tmpDirectory}/${pid}" "${outputDirectory}" "${pid}" >> "${logFile}"
	fi
}

startDaemon() {
	local var=''

	if [[ "$(isRunning)" = "true" ]]; then
		echo "Daemon is already running"
	else
		echo "Starting Daemon"
		vars="$(getCommand "start-local")"
		eval "nohup $vars >/dev/null 2>&1 &"
	fi
}

isPidRunning() {
	local pid="${1}"
	if [[ -n "${pid}" ]]; then
		isRunning="$(ps ax | awk '{print $1}' | grep "${pid}")"
		if [[ -n "$isRunning" ]]; then
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

	if [[ -f "${pidLocation}" ]]; then
		pid="$(cat "${pidLocation}" | awk 'NR==1{print $1}')"
		if [[ "$(isPidRunning "${pid}")" = 'true' ]]; then
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
	if [[ "$(isRunning)" = "true" ]]; then
		echo "-1" >> "${pidLocation}"
	else
		echo "Daemon is not running"
	fi
}

runCommand() {
	local command="${1}"
	
	if [[ "$(getPresetComplexityOrder ${videoPreset})" -lt 1 ]]; then
		echo "--video-preset is an invalid value"
		command="badVariable"
	fi
	
	if [[ "$command" = "active" ]]; then
		echo "$(isRunning)"
	elif [[ "$command" = "start-local" ]]; then
		echo "$(getCommand "$command")"
		startLocal
	elif [[ "$command" = "start" ]]; then
		echo "$(getCommand "$command")"
		startDaemon
	elif [[ "$command" = "output" ]]; then
		echo "$(tail -n 1000 "${logFile}")"
	elif [[ "$command" = "stop" ]]; then
		echo "$(getCommand "$command")"
		echo "$(stopProcess)"
	else
		echo "$(getCommand "${1}")"
		echo "Usage \"$0 [active|start|start-local|output|stop] [--audio audioCodec aac] [--audio-bitrate bitratePerAudioChannel 96] [--dry] [--ext outputExtension .mp4] [--input inputDirectory ~/Video] [--output outputDirectory ~/ProcessedVideo] [--log logFile ~/encoding.results] [--pid pidFile ~/plex-encoding.pid] [--sort sortBy date|size|reverse-date|reverse-size] [--subtitle-image subtitlesImageCodec dvbsub] [--subtitle-text subtitlesTextCodec srt] [--thread threadCount 3] [--tmp tmpDirectory /tmp] [--video videoCodec libx264] [--video-preset ultrafast|superfast|veryfast|fast|medium|slow|slower|veryslow|placebo] [--video-profile videoProfile baseline|main|high ] [--video-quality videoQuality 1-50] [--video-tune animation|fastdecode|film|grain|stillimage|zerolatency]"
		exit 1
	fi
}

while true; do
	case "${1}" in
		--audio ) audioCodec="${2}"; shift 2;;
		--audio-bitrate ) bitratePerAudioChannel="${2}"; shift 2;;
		--dry ) dryRun="true"; shift;;
		--ext ) outputExtension="${2}"; shift 2;;
		--input ) inputDirectory="${2}"; shift 2;;
		--log ) logFile="${2}"; shift 2;;
		--output ) outputDirectory="${2}"; shift 2;;
		--pid ) pidLocation="${2}"; shift 2;;
		--sort ) sortBy="${2}"; shift 2;;
		--subtitle-image ) subtitlesImageCodec="${2}"; shift 2;;
		--subtitle-text ) subtitlesTextCodec="${2}"; shift 2;;
		--thread ) threadCount="${2}"; shift 2;;
		--tmp ) tmpDirectory="${2}"; shift 2;;
		--video ) videoCodec="${2}"; shift 2;;
		--video-preset ) videoPreset="${2}"; shift 2;;
		--video-profile ) videoProfile="${2}"; shift 2;;
		--video-quality ) videoQuality="${2}"; shift 2;;
		--video-tune ) videoTune="${2}"; shift 2;;
		-- ) shift; break;;
		* ) break;;
	esac
done

if [[ "${outputDirectory}" = "${inputDirectory}" ]]; then
	outputDirectory=''
fi

runCommand "$command"
