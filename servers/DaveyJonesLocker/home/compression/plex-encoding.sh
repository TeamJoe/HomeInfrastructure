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
forceRun='false'
metadataRun='false'
pidLocation='~/plex-encoding.pid'
threadCount=4 # 0 is unlimited
audioCodec='aac'
videoCodec='libx264'
videoPreset='fast' # ultrafast, superfast, veryfast, fast, medium, slow, slower, veryslow, placebo
videoProfile='main' # For x264 baseline, main, high | For x265 main, high
videoPixelFormat='yuv420p' 
videoQuality=18 # 1-50, lower is better quailty
videoLevel='4.0'
videoFrameRate='copy' # Any Value, NTSC (29.97), PAL (25), FILM (24), NTSC_FILM (23.97)
videoTune='fastdecode' # animation, fastdecode, film, grain, stillimage, zerolatency
subtitles=strip
subtitlesAllowed='srt'
subtitlesImageCodec='copy' # dvbsub, dvdsub
subtitlesTextCodec='copy' # srt, ass
bitratePerAudioChannel=98304 # 65536 is default
outputExtension='.mkv'
sortBy='size' # date, size, reverse-date, reverse-size
metadataTitle='title'
metadataLanguage='language'
metadataCodecName='ENCODER-CODEC'
metadataAudioBitRate='ENCODER-BIT-RATE'
metadataVideoLevel='ENCODER-LEVEL'
metadataVideoPixelFormat='ENCODER-PIXEL-FORMAT'
metadataVideoFrameRate='ENCODER-FRAME-RATE'
metadataVideoPreset='ENCODER-PRESET'
metadataVideoProfile='ENCODER-PROFILE'
metadataVideoQuality='ENCODER-QUALITY'
metadataVideoTune='ENCODER-TUNE'
lockfileExtension='.compression.lock.pid'

inputFileList=''

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

divide() {
	local numerator="${1}"
	local denominator="${2}"
	local precision="${3:-0}" # Between 0 and 17, for small denominators, less for larger denominators
	local rounding="${4:-halfup}" # halfup, halfdown, floor, ceil
	rounding="${rounding,,}"
	local quotient="$(( "${numerator}" / "${denominator}" ))"
	local remainder="$(( "${numerator}" % "${denominator}" ))"
	local precisionQuotient="$(( (( 10 ** "${precision}" ) * ( "${remainder}" ) ) / "${denominator}" ))"
	local precisionRemainder="$(( (( 10 ** "${precision}" ) * ( "${remainder}" ) ) % "${denominator}" ))"
	
	if [[ "${rounding::4}" = 'half' ]]; then
		if [[ "${precisionRemainder}" -gt '0' ]]; then
			local roundingQuotient="$(( "${denominator}" / "${precisionRemainder}" ))"
			local roundingRemainder="$(( "${denominator}" % "${precisionRemainder}" ))"
			if [[ "${roundingQuotient}" -lt '2' ]]; then
				precisionQuotient="$(( "${precisionQuotient}" + 1 ))"
			elif [[ "${roundingQuotient}" -eq '2' && "${roundingRemainder}" -eq '0' ]]; then
				if [[ "${rounding}" = 'half' || "${rounding}" = 'halfup' || "${rounding}" = 'half-up' ]]; then
					precisionQuotient="$(( "${precisionQuotient}" + 1 ))"
				fi
			fi
		fi
	elif [[ "${rounding}" = 'ceil' || "${rounding}" = 'ceiling' ]]; then
		if [[ "${precisionRemainder}" -gt '0' ]]; then
			precisionQuotient="$(( "${precisionQuotient}" + 1 ))"
		fi
	fi
	
	if [[ "${precisionQuotient}" -ge "$(( 10 ** "${precision}" ))" ]]; then
		quotient="$(( "${quotient}" + 1 ))"
		precisionQuotient='0'
	fi
	
	if [[ "${precision}" -eq 0 ]]; then
		echo "$(printf "%d" "${quotient}")"
	else
		echo "$(printf "%d.%0${precision}d" "${quotient}" "${precisionQuotient}")"
	fi
}

getCommand() {
	local command="${1}"
	echo "'${path}' '${command}' --audio '${audioCodec}' --audio-bitrate '${bitratePerAudioChannel}'$(if [ "${dryRun}" = true ]; then echo ' --dry'; fi) --ext '${outputExtension}'$(if [ "${forceRun}" = true ]; then echo ' --force'; fi) --input '${inputDirectory}' --output '${outputDirectory}' --log '${logFile}'$(if [ "${metadataRun}" = true ]; then echo ' --metadata'; fi) --pid '${pidLocation}'  --sort '${sortBy}' --subtitle-image '${subtitlesImageCodec}' --subtitle-text '${subtitlesTextCodec}' --thread '${threadCount}' --tmp '${tmpDirectory}' --video '${videoCodec}' --video-level '${videoLevel}' --video-pixel '${videoPixelFormat}' --video-preset '${videoPreset}' --video-profile '${videoProfile}' --video-quality '${videoQuality}' --video-rate '${videoFrameRate}' --video-tune '${videoTune}'"
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

normalizeVideoProfileComplexity() {
	local videoProfile="${1,,}"
	if [[ "${videoProfile}" =~ .*baseline.* ]]; then
		echo "baseline"
	elif [[ "${videoProfile}" =~ .*main.* ]]; then
		if [[ "${videoProfile}" =~ .*10.* ]]; then
			echo "main10"
		elif [[ "${videoProfile}" =~ .*12.* ]]; then
			echo "main12"
		else
			echo "main"
		fi
	elif [[ "${videoProfile}" =~ .*high.* ]]; then
		if [[ "${videoProfile}" =~ .*10.* ]]; then
			echo "high10"
		elif [[ "${videoProfile}" =~ .*12.* ]]; then
			echo "high12"
		else
			echo "high"
		fi
	else
		echo "${videoProfile}"
	fi
}

normalizeFrameRate() {
	local frameRate="${1,,}"
	if [[ "${frameRate}" = '30000/1001' || "${frameRate}" = '29.9' || "${frameRate}" = '29.97' || "${frameRate}" = '29.970' ]]; then
		echo "ntsc"
	elif [[ "${frameRate}" = '25/1' || "${frameRate}" = '25.0' || "${frameRate}" = '25' ]]; then
		echo "pal"
	elif [[ "${frameRate}" = '24/1' || "${frameRate}" = '24.0' || "${frameRate}" = '24' ]]; then
		echo "film"
	elif [[ "${frameRate}" = '24000/1001' || "${frameRate}" = '2997/125' || "${frameRate}" = '23.9' || "${frameRate}" = '23.97' || "${frameRate}" = '23.976' ]]; then
		echo "ntsc_film"
	elif [[ -z "${frameRate}" || "${frameRate}" = 'copy' || "${frameRate}" = 'source' ]]; then
		echo "source_fps"
	elif [[ "${frameRate: -2}" = '/1' || "${frameRate: -2}" = '.0' ]]; then
		echo "${frameRate::-2}"
	elif [[ "${frameRate}" != "$( echo "${frameRate}" | sed 's/.*\///' )" ]]; then
		local fraction="$(divide "$( echo "${frameRate}" | sed 's/.*\///' )" "$( echo "${frameRate}" | sed 's/\.*///' )" '2' 'floor')"
		if [[ "${fraction}" = '29.96' || "${fraction}" = '29.97' || "${fraction}" = '29.98' ]]; then
			echo "ntsc"
		elif [[ "${fraction}" = '23.96' || "${fraction}" = '23.97' || "${fraction}" = '23.98' ]]; then
			echo "ntsc_film"
		else
			echo "${frameRate}"
		fi
	else
		echo "${frameRate}"
	fi
}

normalizeLanguageFullName() {
	local language="${1,,}"
	case "${language}" in
		en | eng | english ) echo 'English';;
		jp | jpn | japanese ) echo 'Japanese';; 
		ru | rus | russian ) echo 'Russian';;
		* ) echo 'unknown';;
	esac
}

normalizeLanguage() {
	local language="${1,,}"
	case "${language}" in
		en | eng | english ) echo 'eng';;
		jp | jpn | japanese ) echo 'jpn';; 
		ru | rus | russian ) echo 'rus';;
		* ) echo 'unknown';;
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
		main10 ) echo '4';;
		high10 ) echo '5';;
		main12 ) echo '6';;
		high12 ) echo '7';;
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

getValue() {
	local id="${1}"
	local stream="${2}"
	
	echo "$(echo "${stream}" | grep -o "^${id}=.*$" | grep -o '[^=]*$')"
}

getMetadata() {
	local id="${1}"
	local stream="${2}"
	
	echo "$(getValue "TAG:${id}" "${stream}")"
}

getCodecFromStream() {
	local stream="${1}"
	
	local oldCodec="$(getMetadata "${metadataCodecName}" "${stream}")"
	if [[ -z "${oldCodec}" ]]; then
		oldCodec="$(getValue 'codec_name' "${stream}")"
	fi
	
	echo "${oldCodec}"
}

getAudioBitRateFromStream() {
	local stream="${1}"
	
	local oldBitRate="$(getMetadata "${metadataAudioBitRate}" "${stream}")"
	if [[ -z "${oldBitRate}" || "${oldBitRate}" = 'N/A' ]]; then
		oldBitRate="$(getValue 'bit_rate' "${stream}")"
	fi
	if [[ -z "${oldBitRate}" || "${oldBitRate}" = 'N/A' ]]; then
		oldBitRate="$(getMetadata 'BPS' "${stream}")"
	fi
	if [[ -z "${oldBitRate}" || "${oldBitRate}" = 'N/A' || "${oldBitRate}" = '0' ]]; then
		oldBitRate=''
	fi
	if [[ "${oldBitRate^^}" =~ .*K$ ]]; then
		oldBitRate="$(( "${oldBitRate::-1}" * 1024 ))"
	elif [[ "${oldBitRate^^}" =~ .*M$ ]]; then
		oldBitRate="$(( "${oldBitRate::-1}" * 1024 * 1024 ))"
	fi
	
	echo "${oldBitRate}"
}

getVideoLevelFromStream() {
	local stream="${1}"
	
	local oldLevel="$(getMetadata "${metadataVideoLevel}" "${stream}")"
	if [[ -z "${oldLevel}" ]]; then
		oldLevel="$(getValue 'level' "${stream}")"
	fi
	
	# Not sure why 3, but wc -c is off by 1
	if [[ -z "$(echo "${oldLevel}" | grep '\.')" ]]; then
		if [[ "${oldLevel}" -ge 10 ]]; then
			oldLevel="${oldLevel::-1}.${oldLevel: -1}"
		elif [[ "${oldLevel}" -ge 1 ]]; then
			oldLevel="0.${oldLevel}"
		fi
	fi
	
	echo "${oldLevel}"
}

getVideoPixelFormatFromStream() {
	local stream="${1}"
	
	local oldFormat="$(getMetadata "${metadataVideoPixelFormat}" "${stream}")"
	if [[ -z "${oldFormat}" ]]; then
		oldFormat="$(getValue 'pix_fmt' "${stream}")"
	fi
	
	echo "${oldFormat}"
}

getVideoFrameRateFromStream() {
	local stream="${1}"
	
	local oldRate="$(getMetadata "${metadataVideoFrameRate}" "${stream}")"
	if [[ -z "${oldRate}" ]]; then
		oldRate="$(getValue 'r_frame_rate' "${stream}")"
	fi
	
	echo "${oldRate}"
}

getVideoProfileFromStream() {
	local stream="${1}"
	
	local oldProfile="$(getMetadata "${metadataVideoProfile}" "${stream}")"
	if [[ -z "${oldProfile}" ]]; then
		oldProfile="$(getValue 'profile' "${stream}")"
	fi
	
	echo "${oldProfile}"
}

getInputFiles() {
	local inputFile="${1}"
	local inputFilePath="$(echo "${inputFile}" | sed 's/\(.*\)\..*/\1/')"
	local inputDirectory="$(dirname "${inputFile}")"
	local inputFileName="$(echo "$(basename "${inputFile}")" | sed 's/\(.*\)\..*/\1/')"
	
	local subtitleExt=''
	local fileName=''
	
	echo "${inputFile}"
	for subtitleExt in $( echo "${subtitlesAllowed}" | sed 's/,/\n/g' ); do
		for fileName in $( find "${inputDirectory}" -type f -name "${inputFileName}.*.${subtitleExt}" ); do
			echo "${fileName}"
		done
	done

}

getChapterSettings() {
	local inputFile="${1}"
	
	local chapterEncoding=''
	local chapterList="$(ffprobe "${inputFile}" -loglevel error -show_chapters)"
	local chapterCount="$(echo "${chapterList}" | grep -o '\[CHAPTER\]' | wc -l)"
	local probeResult=''
	local chapter=0
	local oldTitle=''
	
	if [[ "${chapterCount}" -gt 0 ]]; then
		chapterEncoding="${chapterEncoding} -map_chapters 0"
		for chapter in $(seq 0 1 ${chapterCount}); do
			probeResult="$(echo "${chapterList}" | awk "/\[CHAPTER\]/{f=f+1} f==$((${chapter} + 1)){print;}" )"
			oldTitle="$(getMetadata "${metadataTitle}" "${probeResult}")"
			
			if [[ -n "${oldTitle}" ]]; then
				chapterEncoding="${chapterEncoding} -metadata:c:${chapter} '${metadataTitle}=${oldTitle}'"
			fi
		done
	fi
	echo "${chapterEncoding}"
}

getAudioEncodingSettings() {
	local inputFile="${1}"

	local audioEncoding=""
	local streamList="$(ffprobe "${inputFile}" -loglevel error -show_streams -select_streams a)"
	local streamCount="$(echo "${streamList}" | grep -o '\[STREAM\]' | wc -l)"
	local probeResult=''
	local stream=0
	local duration=''
	local oldTitle=''
	local oldLanguage=''
	local oldCodec=''
	local oldChannelCount=''
	local oldBitRate=''
	local newCodec=''
	local newChannelCount=''
	local newBitRate=''
	local wantedBitRate=''
	local normalizedOldCodecName=''
	local normalizedNewCodecName=''

	for stream in $( seq 0 1 $(( ${streamCount} - 1 )) ); do
		probeResult="$(echo "${streamList}" | awk "/\[STREAM\]/{f=f+1} f==$((${stream} + 1)){print;}" )"
		newCodec="${audioCodec}"
		newChannelCount='2'
		newBitRate="$(( ${newChannelCount} * ${bitratePerAudioChannel} ))"
		oldCodec="$(getCodecFromStream "${probeResult}")"
		duration="$(getMetadata 'DURATION' "${probeResult}")"
		oldTitle="$(getMetadata "${metadataTitle}" "${probeResult}")"
		oldLanguage="$(getMetadata "${metadataLanguage}" "${probeResult}")"
		oldChannelCount="$(getValue 'channels' "${probeResult}")"
		if [[ -z "${oldChannelCount}" ]]; then
			oldChannelCount='2'
		fi
		oldBitRate="$(getAudioBitRateFromStream "${probeResult}")"
		
		if [[ "${newChannelCount}" != "${oldChannelCount}" ]]; then
			newChannelCount="${oldChannelCount}"
			newBitRate="$(( ${newChannelCount} * ${bitratePerAudioChannel} ))"
		fi
		
		if [[ -n "${oldBitRate}" && "${newBitRate}" -gt "${oldBitRate}" ]]; then
			newBitRate="${oldBitRate}"
		fi
		if [[ -n "${oldCodec}" && "${duration}" != '00:00:00.000000000' ]]; then
			normalizedOldCodecName="$(normalizeAudioCodec "${oldCodec}")"
			normalizedNewCodecName="$(normalizeAudioCodec "${newCodec}")"
			if [[ -z "${newCodec}" || "${newCodec,,}" = "copy" ]] || ([[ "${forceRun}" = 'false' && "${normalizedOldCodecName}" = "${normalizedNewCodecName}" ]] && [[ -z "${oldBitRate}" || "${oldBitRate}" -le "${newBitRate}" ]]); then
				audioEncoding="${audioEncoding} -map 0:a:${stream}"
				audioEncoding="${audioEncoding} -codec:a:${stream} copy -metadata:s:a:${stream} '${metadataCodecName}=${oldCodec}'"
				if [[ -n "${oldBitRate}" ]]; then
					audioEncoding="${audioEncoding} -metadata:s:a:${stream} '${metadataAudioBitRate}=${oldBitRate}'"
				fi
			else
				audioEncoding="${audioEncoding} -map 0:a:${stream}"
				audioEncoding="${audioEncoding} -codec:a:${stream} ${newCodec} -metadata:s:a:${stream} '${metadataCodecName}=${newCodec}'"
				if [[ -n "${newBitRate}" ]]; then
					audioEncoding="${audioEncoding} -b:a:${stream} ${newBitRate} -metadata:s:a:${stream} '${metadataAudioBitRate}=${newBitRate}'"
				fi
			fi
			if [[ -n "${oldTitle}" ]]; then
				audioEncoding="${audioEncoding} -metadata:s:a:${stream} '${metadataTitle}=${oldTitle}'"
			fi
			if [[ -n "${oldLanguage}" ]]; then
				audioEncoding="${audioEncoding} -metadata:s:a:${stream} '${metadataLanguage}=${oldLanguage}'"
			fi
		fi
	done
	echo "${audioEncoding}"
}

getVideoEncodingSettings() {
	local inputFile="${1}"

	local videoEncoding=""
	local streamList="$(ffprobe "${inputFile}" -loglevel error -show_streams -select_streams v)"
	local streamCount="$(echo "${streamList}" | grep -o '\[STREAM\]' | wc -l)"
	local probeResult=''
	local stream=0
	local newCodec=''
	local newLevel=''
	local newPixelFormat=''
	local newFrameRate=''
	local newPreset=''
	local newProfile=''
	local newQuality=''
	local newTune=''
	local newPresetComplexity=''
	local newProfileComplexity=''
	local duration=''
	local oldTitle=''
	local oldLanguage=''
	local oldCodec=''
	local oldLevel=''
	local oldPixelFormat=''
	local oldFrameRate=''
	local oldPreset=''
	local oldProfile=''
	local oldQuality=''
	local oldTune=''
	local oldPresetComplexity=''
	local oldProfileComplexity=''
	local normalizedOldCodecName=''
	local normalizedNewCodecName=''
	local normalizedOldVideoProfile=''
	local normalizedNewVideoProfile=''
	local normalizedOldFrameRate=''
	local normalizedNewFrameRate=''

	for stream in $( seq 0 1 $(( ${streamCount} - 1 )) ); do
		probeResult="$(echo "${streamList}" | awk "/\[STREAM\]/{f=f+1} f==$((${stream} + 1)){print;}" )"
		newCodec="${videoCodec}"
		newLevel="${videoLevel}"
		newPixelFormat="${videoPixelFormat}"
		newFrameRate="${videoFrameRate}"
		newPreset="${videoPreset}"
		newProfile="${videoProfile}"
		newQuality="${videoQuality}"
		newTune="${videoTune}"
		newPresetComplexity="$(getPresetComplexityOrder "${newPreset}")"
		normalizedNewVideoProfile="$(normalizeVideoProfileComplexity "${newProfile}")"
		normalizedNewFrameRate="$(normalizeFrameRate "${newFrameRate}")"
		newProfileComplexity="$(getProfileComplexityOrder "${normalizedNewVideoProfile}")"
		oldCodec="$(getCodecFromStream "${probeResult}")"
		duration="$(getMetadata 'DURATION' "${probeResult}")"
		oldTitle="$(getMetadata "${metadataTitle}" "${probeResult}")"
		oldLanguage="$(getMetadata "${metadataLanguage}" "${probeResult}")"
		oldLevel="$(getVideoLevelFromStream "${probeResult}")"
		oldPixelFormat="$(getVideoPixelFormatFromStream "${probeResult}")"
		oldFrameRate="$(getVideoFrameRateFromStream "${probeResult}")"
		normalizedOldFrameRate="$(normalizeFrameRate "${oldFrameRate}")"
		oldPreset="$(getMetadata "${metadataVideoPreset}" "${probeResult}")"
		oldProfile="$(getVideoProfileFromStream "${probeResult}")"
		oldQuality="$(getMetadata "${metadataVideoQuality}" "${probeResult}")"
		oldTune="$(getMetadata "${metadataVideoTune}" "${probeResult}" )"
		oldPresetComplexity="$(getPresetComplexityOrder "${oldPreset}")"
		normalizedOldVideoProfile="$(normalizeVideoProfileComplexity "${oldProfile}")"
		oldProfileComplexity="$(getProfileComplexityOrder "${normalizedOldVideoProfile}")"
		
		if [[ -z "${newLevel}" || "${newLevel}" == 'copy' ]]; then
			newLevel="${oldLevel}"
		elif [[ -n "${oldLevel}" && "${oldLevel}" != '0' && "$( echo "${oldLevel}" | sed 's/\.//' )" -gt '0' && "$( echo "${newLevel}" | sed 's/\.//' )" -gt "$( echo "${oldLevel}" | sed 's/\.//' )" ]]; then
			newLevel="${oldLevel}"
		fi
		if [[ -z "${newPixelFormat}" || "${newPixelFormat}" == 'copy' ]]; then
			newPixelFormat="${oldPixelFormat}"
		fi
		if [[ -z "${oldQuality}" ]]; then
			oldQuality=0
		fi
		if [[ "${oldQuality}" -gt "${newQuality}" ]]; then
			newQuality="${oldQuality}"
		fi
		if  [[ -z "${newTune}" ]]; then
			newTune="${oldTune}"
		fi 
		if [[ -n "${oldCodec}" && "${duration}" != '00:00:00.000000000' ]]; then
			normalizedOldCodecName="$(normalizeVideoCodec "${oldCodec}")"
			normalizedNewCodecName="$(normalizeVideoCodec "${newCodec}")"
			if [[ -z "${newCodec}" || "${newCodec,,}" = "copy" ]] || [[ "${forceRun}" = 'false' && "${normalizedOldCodecName}" = "${normalizedNewCodecName}" && "${oldPresetComplexity}" -ge "${newPresetComplexity}" && "${oldQuality}" -ge "${newQuality}" ]] || ([ "${forceRun}" = 'false' ] && [[ "${normalizedOldCodecName}" = "${normalizedNewCodecName}" || "${normalizedOldCodecName}" = 'h264' || "${normalizedOldCodecName}" = 'hevc' ]] && [ "${newPreset}" = 'ultrafast' ]); then
				videoEncoding="${videoEncoding} -map 0:v:${stream}"
				videoEncoding="${videoEncoding} -codec:v:${stream} copy -metadata:s:v:${stream} '${metadataCodecName}=${oldCodec}'"
				if [[ -n "${oldLevel}" ]]; then
					videoEncoding="${videoEncoding} -metadata:s:v:${stream} '${metadataVideoLevel}=${oldLevel}'"
				fi
				if [[ -n "${oldPixelFormat}" ]]; then
					videoEncoding="${videoEncoding} -metadata:s:v:${stream} '${metadataVideoPixelFormat}=${oldPixelFormat}'"
				fi
				if [[ -n "${normalizedOldFrameRate}" && "${normalizedOldFrameRate}" != 'source_fps' ]]; then
					videoEncoding="${videoEncoding} -metadata:s:v:${stream} '${metadataVideoFrameRate}=${normalizedOldFrameRate}'"
				fi
				if [[ -n "${oldPreset}" ]]; then
					videoEncoding="${videoEncoding} -metadata:s:v:${stream} '${metadataVideoPreset}=${oldPreset}'"
				fi
				if [[ -n "${oldQuality}" ]]; then
					videoEncoding="${videoEncoding} -metadata:s:v:${stream} '${metadataVideoQuality}=${oldQuality}'"
				fi
				if [[ -n "${oldProfile}" ]]; then
					videoEncoding="${videoEncoding} -metadata:s:v:${stream} '${metadataVideoProfile}=${oldProfile}'"
				fi
				if [[ -n "${oldTune}" ]]; then
					videoEncoding="${videoEncoding} -metadata:s:v:${stream} '${metadataVideoTune}=${oldTune}'"
				fi
			else
				videoEncoding="${videoEncoding} -map 0:v:${stream}"
				videoEncoding="${videoEncoding} -codec:v:${stream} ${newCodec} -metadata:s:v:${stream} '${metadataCodecName}=${newCodec}'"
				if [[ -n "${newLevel}" ]]; then
					videoEncoding="${videoEncoding} -level:v:${stream} ${newLevel} -metadata:s:v:${stream} '${metadataVideoLevel}=${newLevel}'"
				fi
				if [[ -n "${newPixelFormat}" ]]; then
					videoEncoding="${videoEncoding} -pix_fmt:v:${stream} ${newPixelFormat} -metadata:s:v:${stream} '${metadataVideoPixelFormat}=${newPixelFormat}'"
				fi
				if [[ "${normalizedNewFrameRate}" = 'source_fps' || "${normalizedNewFrameRate}" = "${normalizedOldFrameRate}" ]]; then
					if [[ -n "${normalizedOldFrameRate}" && "${normalizedOldFrameRate}" != 'source_fps' ]]; then
						videoEncoding="${videoEncoding} -metadata:s:v:${stream} '${metadataVideoFrameRate}=${normalizedOldFrameRate}'"
					fi
				elif [[ -n "${normalizedNewFrameRate}" ]]; then
					videoEncoding="${videoEncoding} -vf:v:${stream} 'fps=fps=${normalizedNewFrameRate}:round=near' -metadata:s:v:${stream} '${metadataVideoFrameRate}=${normalizedNewFrameRate}'"
				fi
				if [[ -n "${newPreset}" ]]; then
					videoEncoding="${videoEncoding} -preset:v:${stream} ${newPreset} -metadata:s:v:${stream} '${metadataVideoPreset}=${newPreset}'"
				fi
				if [[ -n "${newQuality}" ]]; then
					videoEncoding="${videoEncoding} -crf:v:${stream} ${newQuality} -metadata:s:v:${stream} '${metadataVideoQuality}=${newQuality}'"
				fi
				if [[ -n "${newProfile}" ]]; then
					videoEncoding="${videoEncoding} -profile:v:${stream} ${newProfile} -metadata:s:v:${stream} '${metadataVideoProfile}=${newProfile}'"
				fi
				if [[ -n "${newTune}" ]]; then
					videoEncoding="${videoEncoding} -tune:v:${stream} ${newTune} -metadata:s:v:${stream} '${metadataVideoTune}=${newTune}'"
				fi
			fi
			if [[ -n "${oldTitle}" ]]; then
				videoEncoding="${videoEncoding} -metadata:s:v:${stream} '${metadataTitle}=${oldTitle}'"
			fi
			if [[ -n "${oldLanguage}" ]]; then
				videoEncoding="${videoEncoding} -metadata:s:v:${stream} '${metadataLanguage}=${oldLanguage}'"
			fi
		fi
	done
	echo "${videoEncoding}"
}

getSubtitleEncodingSettings() {
	local inputFile="${1}"
	local inputFilePath="$(echo "${inputFile}" | sed 's/\(.*\)\..*/\1/')"

	local subtitleEncoding=""
	local streamList="$(ffprobe "${inputFile}" -loglevel error -show_streams -select_streams s)"
	local streamCount="$(echo "${streamList}" | grep -o '\[STREAM\]' | wc -l)"
	local probeResult=''
	local stream=0
	local duration=''
	local oldTitle=''
	local oldLanguage=''
	local oldCodec=''
	local oldCodecType=''
	local newCodec=''
	local normalizedOldCodecName=''
	local normalizedNewCodecName=''
	local index='0'

	for stream in $( seq 0 1 $(( ${streamCount} - 1 )) ); do
		probeResult="$(echo "${streamList}" | awk "/\[STREAM\]/{f=f+1} f==$((${stream} + 1)){print;}" )"
		oldCodec="$(getCodecFromStream "${probeResult}")"
		duration="$(getMetadata 'DURATION' "${probeResult}")"
		oldTitle="$(getMetadata "${metadataTitle}" "${probeResult}")"
		oldLanguage="$(getMetadata "${metadataLanguage}" "${probeResult}")"
		if [[ "${subtitles}" = 'strip' ]]; then
			normalizedOldCodecName="$(normalizeSubtitleCodec "${oldCodec}")"
			IFS=$'\n'
			for newCodec in $( echo "${subtitlesAllowed}" | sed 's/,/\n/g' ); do
				normalizedNewCodecName="$(normalizeSubtitleCodec "${newCodec}")"
				if [[ "${normalizedOldCodecName}" = "${normalizedNewCodecName}" ]]; then
					break
				fi
			done
			
			if [[ "${normalizedOldCodecName}" != "${normalizedNewCodecName}" ]]; then
				oldCodec=''
			fi
		fi
		if [[ -n "${oldCodec}" && "${duration}" != '00:00:00.000000000' ]]; then
			normalizedOldCodecName="$(normalizeSubtitleCodec "${oldCodec}")"
			oldCodecType="$(getSubtitleEncodingType "${oldCodec}")"
			if [[ "${oldCodecType}" = "image" ]]; then
				newCodec="${subtitlesImageCodec}"
			else
				newCodec="${subtitlesTextCodec}"
			fi
			normalizedNewCodecName="$(normalizeSubtitleCodec "${newCodec}")"
				
			if [[ -z "${newCodec}" || "${newCodec,,}" = "copy" ]] || [[ "${forceRun}" = 'false' && "${normalizedOldCodecName}" = "${normalizedNewCodecName}" ]]; then
				subtitleEncoding="${subtitleEncoding} -map 0:s:${stream}"
				subtitleEncoding="${subtitleEncoding} -codec:s:${index} copy -metadata:s:s:${index} '${metadataCodecName}=${oldCodec}'"
			else
				subtitleEncoding="${subtitleEncoding} -map 0:s:${stream}"
				subtitleEncoding="${subtitleEncoding} -codec:s:${index} ${newCodec} -metadata:s:s:${index} '${metadataCodecName}=${newCodec}'"
			fi
			if [[ -n "${oldTitle}" ]]; then
				subtitleEncoding="${subtitleEncoding} -metadata:s:s:${index} '${metadataTitle}=${oldTitle}'"
			fi
			if [[ -n "${oldLanguage}" ]]; then
				subtitleEncoding="${subtitleEncoding} -metadata:s:s:${index} '${metadataLanguage}=${oldLanguage}'"
			fi
			index="$(( "${index}" + 1 ))"
		fi
	done
	
	local fileCount='0'
	local language=''
	local fileName=''
	local fileExt=''
	local fileFromList=''
	
	IFS=$'\n'
	for fileFromList in $(getInputFiles "${inputFile}"); do
		fileName="$(basename -- "${fileFromList}")"
		fileExt="${fileName##*.}"
		normalizedOldCodecName="$(normalizeSubtitleCodec "${fileExt}")"
		for newCodec in $( echo "${subtitlesAllowed}" | sed 's/,/\n/g' ); do
			normalizedNewCodecName="$(normalizeSubtitleCodec "${newCodec}")"
			if [[ "${normalizedOldCodecName}" = "${normalizedNewCodecName}" ]]; then
				break
			fi
		done
		
		if [[ "${normalizedOldCodecName}" = "${normalizedNewCodecName}" ]]; then
			language="${fileFromList:$(echo "${inputFilePath}" | wc -c)}"
			language="${language::-$(echo "${fileExt}" | wc -c)}"
			language="$(normalizeLanguage "${language}")"
			
			subtitleEncoding="${subtitleEncoding} -map ${fileCount}:s:0 -codec:s:${index} ${newCodec}  -metadata:s:s:${index} '${metadataCodecName}=${newCodec}'"
			if [[ "${language}" != 'unknown' ]]; then
				subtitleEncoding="${subtitleEncoding} -metadata:s:s:${index} '${metadataTitle}=$(normalizeLanguageFullName "${language}")' -metadata:s:s:${index} '${metadataLanguage}=${language}'"
			fi
			index="$(( "${index}" + 1 ))"
		fi
		fileCount="$(( "${fileCount}" + 1 ))"
	done
	
	echo "${subtitleEncoding}"
}

assembleArguments() {
	local inputFile="${1}"
	local outputFile="${2}"
	local arguments=''

	local chapterArguments="$(getChapterSettings "${inputFile}")"
	local videoArguments="$(getVideoEncodingSettings "${inputFile}")"
	local audioArguments="$(getAudioEncodingSettings "${inputFile}")"
	local subtitleArguments="$(getSubtitleEncodingSettings "${inputFile}")"
	
	local fileFromList=''
	
	IFS=$'\n'
	for fileFromList in $(getInputFiles "${inputFile}"); do
		arguments="${arguments} -i '$(echo "${fileFromList}" | sed -e "s/'/'\"'\"'/g")'"
	done
	
	arguments="${arguments} -map_metadata -1 ${chapterArguments} ${videoArguments} ${audioArguments} ${subtitleArguments} -threads ${threadCount} '$(echo "${outputFile}" | sed -e "s/'/'\"'\"'/g")'"
	
	echo "${arguments}"
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
	if [[ "${arguments}" =~ .*-codec:v:0.* ]]; then
		if [[ "${metadataRun}" = 'true' \
			|| "${arguments}" =~ .*-codec:v:[0-9]+' '*"${videoCodec}".* \
			|| "${arguments}" =~ .*-codec:a:[0-9]+' '*"${audioCodec}".* 
			|| "${arguments}" =~ .*-codec:s:[0-9]+' '*"${subtitlesImageCodec}".* \
			|| "${arguments}" =~ .*-codec:s:[0-9]+' '*"${subtitlesTextCodec}".* ]]; then
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
				local fileFromList=''
				IFS=$'\n'
				for fileFromList in $(getInputFiles "${inputFile}"); do
					rm "${fileFromList}"
				done
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
		echo "Usage \"$0 [active|start|start-local|output|stop] [--audio audioCodec aac] [--audio-bitrate bitratePerAudioChannel 96] [--dry] [--ext outputExtension .mp4] [--force] [--input inputDirectory ~/Video] [--output outputDirectory ~/ProcessedVideo] [--log logFile ~/encoding.results] [--metadata] [--pid pidFile ~/plex-encoding.pid] [--sort sortBy date|size|reverse-date|reverse-size] [--subtitle-image subtitlesImageCodec dvbsub] [--subtitle-text subtitlesTextCodec srt] [--thread threadCount 3] [--tmp tmpDirectory /tmp] [--video videoCodec libx264] [--video-level videoLevel 4.0] [ --video-pixel videoPixelFormat yuv420p] [--video-preset ultrafast|superfast|veryfast|fast|medium|slow|slower|veryslow|placebo] [--video-profile videoProfile baseline|main|high ] [--video-quality videoQuality 1-50] [--video-rate videoFrameRate copy] [--video-tune animation|fastdecode|film|grain|stillimage|zerolatency]"
		exit 1
	fi
}

while true; do
	case "${1}" in
		--audio ) audioCodec="${2}"; shift 2;;
		--audio-bitrate ) bitratePerAudioChannel="${2}"; shift 2;;
		--dry ) dryRun="true"; shift;;
		--ext ) outputExtension="${2}"; shift 2;;
		--force ) forceRun="true"; shift;;
		--input ) inputDirectory="${2}"; shift 2;;
		--log ) logFile="${2}"; shift 2;;
		--metadata ) metadataRun="true"; shift;;
		--output ) outputDirectory="${2}"; shift 2;;
		--pid ) pidLocation="${2}"; shift 2;;
		--sort ) sortBy="${2}"; shift 2;;
		--subtitle-image ) subtitlesImageCodec="${2}"; shift 2;;
		--subtitle-text ) subtitlesTextCodec="${2}"; shift 2;;
		--thread ) threadCount="${2}"; shift 2;;
		--tmp ) tmpDirectory="${2}"; shift 2;;
		--video ) videoCodec="${2}"; shift 2;;
		--video-level ) videoLevel="${2}"; shift 2;;
		--video-pixel ) videoPixelFormat="${2}"; shift 2;;
		--video-preset ) videoPreset="${2}"; shift 2;;
		--video-profile ) videoProfile="${2}"; shift 2;;
		--video-quality ) videoQuality="${2}"; shift 2;;
		--video-rate ) videoFrameRate="${2}"; shift 2;;
		--video-tune ) videoTune="${2}"; shift 2;;
		-- ) shift; break;;
		* ) break;;
	esac
done

if [[ "${outputDirectory}" = "${inputDirectory}" ]]; then
	outputDirectory=''
fi

runCommand "$command"
