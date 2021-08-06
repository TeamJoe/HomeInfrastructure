#!/bin/bash

#-----------------
# Configurable Default Options
#-----------------

inputDirectory='~/Videos' #/home/public/Videos/TV/Sonarr
outputDirectory=''        #/home/public/Videos/TV/Sonarr
tmpDirectory='/tmp'
logFile='~/encoding.results'
dryRun='false'
forceRun='false'
metadataRun='false'
pidLocation='~/plex-encoding.pid'
threadCount=4 # 0 is unlimited
audioCodec='aac'
audioUpdateMethod='convert' # convert, strip
audioExtension='.mp3,.aac,.ac3' # comma list of audio extensions
videoCodec='libx265'
videoUpdateMethod='convert' # convert, strip
videoPreset='fast'  # ultrafast, superfast, veryfast, fast, medium, slow, slower, veryslow, placebo
videoProfile='main' # For x264 baseline, main, high | For x265 main, high
videoPixelFormat='yuv420p,yuv420p10le'
videoPixelFormatExclusionOrder='depth,channel,compression,bit,format'
videoPixelFormatPreferenceOrder='depth,channel,compression,bit,format'
videoQuality=20 # 1-50, lower is better quailty
videoLevel='4.1'
videoFrameRate='copy'  # Any Value, NTSC (29.97), PAL (25), FILM (24), NTSC_FILM (23.97)
videoTune='fastdecode' # animation, fastdecode, film, grain, stillimage, zerolatency
subtitlesUpdateMethod='strip' # convert, strip
subtitleCodec='srt' # Comma list of allowed formats
subtitleExtension='.srt' # Comma list of subtitle extensions
bitratePerAudioChannel=98304 # 65536 is default
outputExtension='.mkv'
sortBy='size' # date, size, reverse-date, reverse-size

#-----------------
# Input Values
#-----------------

path="${0}"
command="${1}"; shift
options="${@}"

#-----------------
# Non-Configurable Variables
#-----------------

additionalParameters=''
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
allPixelFormats="$(ffmpeg -pix_fmts -loglevel error)"

#-----------------
# Input Value Handling
#-----------------

additionalParameters=''
while true; do
  case "${1}" in
    --audio) audioCodec="${2}"; shift 2;;
    --audio-bitrate) bitratePerAudioChannel="${2}"; shift 2;;
    --audio-extension) audioExtension="${2}"; shift 2;;
    --audio-update) audioUpdateMethod="${2}"; shift 2;;
    --dry) dryRun="true"; shift;;
    --ext) outputExtension="${2}"; shift 2;;
    --force) forceRun="true"; shift;;
    --input) inputDirectory="${2}"; shift 2;;
    --log) logFile="${2}"; shift 2;;
    --metadata) metadataRun="true"; shift;;
    --output) outputDirectory="${2}"; shift 2;;
    --pid) pidLocation="${2}"; shift 2;;
    --sort) sortBy="${2}"; shift 2;;
    --subtitle) subtitleCodec="${2}"; shift 2;;
    --subtitle-extension) subtitleExtension="${2}"; shift 2;;
    --subtitle-update) subtitlesUpdateMethod="${2}"; shift 2;;
    --thread) threadCount="${2}"; shift 2;;
    --tmp) tmpDirectory="${2}"; shift 2;;
    --video) videoCodec="${2}"; shift 2;;
    --video-level) videoLevel="${2}"; shift 2;;
    --video-pixel) videoPixelFormat="${2}"; shift 2;;
    --video-pixel-exclusion) videoPixelFormatExclusionOrder="${2}"; shift 2;;
    --video-pixel-preference) videoPixelFormatPreferenceOrder="${2}"; shift 2;;
    --video-preset) videoPreset="${2}"; shift 2;;
    --video-profile) videoProfile="${2}"; shift 2;;
    --video-quality) videoQuality="${2}"; shift 2;;
    --video-rate) videoFrameRate="${2}"; shift 2;;
    --video-tune) videoTune="${2}"; shift 2;;
    --video-update) videoUpdateMethod="${2}"; shift 2;;
    --) shift; additionalParameters="${additionalParameters} ${@}"; break;;
    *)
      if [[ $(echo "${@}" | wc -c) -le 1 ]]; then
        break;
      else
        additionalParameters="${additionalParameters} ${1}"; shift
      fi
    ;;
  esac
done

if [[ "${outputDirectory}" == "${inputDirectory}" ]]; then
  outputDirectory=''
fi

getCommand() {
  local command="${1}"
  echo "'${path}' '${command}'" \
    "--audio '${audioCodec}'" \
    "--audio-bitrate '${bitratePerAudioChannel}'" \
    "--audio-extension '${audioExtension}'" \
    "--audio-update '${audioUpdateMethod}'" \
    "$(if [ "${dryRun}" = true ]; then echo '--dry'; fi)" \
    "--ext '${outputExtension}'" \
    "$(if [ "${forceRun}" = true ]; then echo '--force'; fi)" \
    "--input '${inputDirectory}'" \
    "--log '${logFile}'" \
    "$(if [ "${metadataRun}" = true ]; then echo '--metadata'; fi)" \
    "--output '${outputDirectory}'" \
    "--pid '${pidLocation}'" \
    "--sort '${sortBy}'" \
    "--subtitle '${subtitleCodec}'" \
    "--subtitle-extension '${subtitleExtension}'" \
    "--subtitle-update '${subtitlesUpdateMethod}'" \
    "--thread '${threadCount}'" \
    "--tmp '${tmpDirectory}'" \
    "--video '${videoCodec}'" \
    "--video-level '${videoLevel}'" \
    "--video-pixel '${videoPixelFormat}'" \
    "--video-pixel-exclusion '${videoPixelFormatExclusionOrder}'" \
    "--video-pixel-preference '${videoPixelFormatPreferenceOrder}'" \
    "--video-preset '${videoPreset}'" \
    "--video-profile '${videoProfile}'" \
    "--video-quality '${videoQuality}'" \
    "--video-rate '${videoFrameRate}'" \
    "--video-tune '${videoTune}'" \
    "--video-update '${videoUpdateMethod}'"
}

getUsage() {
  echo "Usage \"$0 [active|start|start-local|output|stop]" \
    "[--audio Codec to use when processing audio aac]" \
    "[--audio-bitrate Bit rate per an audio channel {98304}]" \
    "[--audio-extension List of audio extensions to read {.mp3,.acc,.ac3}]"\
    "[--audio-update Method to use for updating audio {strip|convert}]" \
    "[--dry Will out what commands it will execute without modifying anything]" \
    "[--ext The extension of the output file {.mkv}]" \
    "[--force Will always convert, even if codecs matches]" \
    "[--input Directory of files to process {~/Video}]" \
    "[--output Output directory of the processed files, blank will cause replacement {~/ProcessedVideo}]" \
    "[--log Location of where to output the logs {~/encoding.results}]" \
    "[--metadata Will allow convert files to update metadata]" \
    "[--pid Location of pid file {~/plex-encoding.pid}]" \
    "[--sort What order to process the files in {date|size|reverse-date|reverse-size}]" \
    "[--subtitle List of allowed subtitle formats {srt,ass}]" \
    "[--subtitle-extension List of subtitle extensions to read {.srt,.ass}]"\
    "[--subtitle-update Method to use for updating subtitles {strip|convert}]" \
    "[--thread Thread to use while processing {3}]" \
    "[--tmp tmpDirectory Temporary directory to store processing video files {/tmp}]" \
    "[--video videoCodec Video codecs to use {libx264|libx265}]" \
    "[--video-level Maximum Allowed Video Level {4.1}]" \
    "[--video-pixel List of allowed pixel formats {yuv420p,yuv420p10le}]" \
    "[--video-pixel-exclusion videoPixelFormatExclusionOrder {depth,channel,compression,bit,format}]" \
    "[--video-pixel-preference videoPixelFormatPreferenceOrder {depth,channel,compression,bit,format}]" \
    "[--video-preset The preset to use when processing the video {ultrafast|superfast|veryfast|fast|medium|slow|slower|veryslow|placebo}]" \
    "[--video-profile The profile to use when processing the video {baseline|main|high}]" \
    "[--video-quality The quality to use when processing the video {1-50}]" \
    "[--video-rate The frame rate to use when processing the file {any_faction|ntsc|ntsc_film|pal|film}]" \
    "[--video-tune The tune parameter to use when processing the file {animation|fastdecode|film|grain|stillimage|zerolatency}]" \
    "[--video-update Method to use for updating video {strip|convert}]"
}

#-----------------
# Logging
#-----------------

error() {
  log "[ERROR] ${@}"
}

warn() {
  log "[WARN] ${@}"
}

info() {
  log "[INFO] ${@}"
}

debug() {
  log "[DEBUG] ${@}"
}

trace() {
  log "[TRACE] ${@}"
}

log() {
  echo "[$(getTime)] ${@}"
}

getTime() {
  echo "$(date +%FT%TZ)"
}

#-----------------
# File and Folder Handling
#-----------------

getExtension() {
  local fileNameWithExt="$(basename "${1}")"
  echo "${fileNameWithExt##*.}"
}

getFileName() {
  local fileNameWithExt="$(basename "${1}")"
  echo "$(echo "${fileNameWithExt}" | sed 's/\(.*\)\..*/\1/')"
}

normalizeDirectory() {
  if [[ "${1: -1}" == '/' ]]; then
    echo "${1::-1}"
  else
    echo "${1}"
  fi
}

getDirectory() {
  local directory="${1}"
  if [[ "${directory: -1}" != '/' && ! -d "${directory}" ]]; then
    directory="$(dirname "${directory}")"
  fi
  echo "$(normalizeDirectory "${directory}")"
}

#-----------------
# File Locking
# -----------------

lockFile() {
  local inputFile="${1}"
  local pid="${2}"
  local lockedPid=''
  if [[ -f "${inputFile}${lockfileExtension}" ]]; then
    if [[ "$(isPidRunning "$(cat "${inputFile}${lockfileExtension}")")" == 'false' ]]; then
      echo "${pid}" >"${inputFile}${lockfileExtension}"
    fi
  else
    echo "${pid}" >"${inputFile}${lockfileExtension}"
  fi

  if [[ "$(cat "${inputFile}${lockfileExtension}")" == "${pid}" ]]; then
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
    if [[ "$(cat "${inputFile}${lockfileExtension}")" == "${pid}" ]]; then
      rm -f "${inputFile}${lockfileExtension}"
    fi
  fi
}

#-----------------
# List Functions
#-----------------

getFirst() {
  local list="${1}"
  local delimiter="${2}"

  if [[ -n "${delimiter}" ]]; then
    echo "$(echo "${list}" | sed "s/${delimiter}/\\n/g" | awk 'NR==1{print}')"
  else
    echo "$(echo "${list}" | awk 'NR==1{print}')"
  fi
}

doesContain() {
  local value="${1}"
  local list="${2}"
  local delimiter="${3}"
  local listValue=''

  if [[ -n "${delimiter}" ]]; then
    list="$(echo "${list}" | sed "s/${delimiter}/\\n/g")"
  fi

  IFS=$'\n'
  for listValue in ${list}; do
    if [[ "${value}" == "${listValue}" ]]; then
      break
    fi
  done

  if [[ "${value}" == "${listValue}" ]]; then
    echo 'true'
  fi
}

forEach() {
  local list="${1}"
  local delimiter="${2}"
  local action="${3}"
  local value=''
  local newList=''
  local newValue=''

  if [[ -n "${delimiter}" ]]; then
    list="$(echo "${list}" | sed "s/${delimiter}/\\n/g")"
  fi

  IFS=$'\n'
  for value in ${list}; do
    newValue="$(${action} ${listValue})"
    if [[ -n "${newValue}" ]]; then
      if [[ -n "${newList}" ]]; then
        newList="${newList}${delimiter}$(${action} ${listValue})"
      else
        newList="$(${action} ${listValue})"
      fi
    fi
  done

  echo "${newList}"
}

#-----------------
# Mathematics
#-----------------

divide() {
  local numerator="${1}"
  local denominator="${2}"
  local precision="${3:-0}"     # Between 0 and 17, for small denominators, less for larger denominators
  local rounding="${4:-halfup}" # halfup, halfdown, floor, ceil
  rounding="${rounding,,}"
  local quotient="$(("${numerator}" / "${denominator}"))"
  local remainder="$(("${numerator}" % "${denominator}"))"
  local precisionQuotient="$(( ( (10 ** "${precision}") * ("${remainder}")) / "${denominator}"))"
  local precisionRemainder="$(( ( (10 ** "${precision}") * ("${remainder}")) % "${denominator}"))"

  if [[ "${rounding::4}" == 'half' ]]; then
    if [[ "${precisionRemainder}" -gt '0' ]]; then
      local roundingQuotient="$(("${denominator}" / "${precisionRemainder}"))"
      local roundingRemainder="$(("${denominator}" % "${precisionRemainder}"))"
      if [[ "${roundingQuotient}" -lt '2' ]]; then
        precisionQuotient="$(("${precisionQuotient}" + 1))"
      elif [[ "${roundingQuotient}" -eq '2' && "${roundingRemainder}" -eq '0' ]]; then
        if [[ "${rounding}" == 'half' || "${rounding}" == 'halfup' || "${rounding}" == 'half-up' ]]; then
          precisionQuotient="$(("${precisionQuotient}" + 1))"
        fi
      fi
    fi
  elif [[ "${rounding}" == 'ceil' || "${rounding}" == 'ceiling' ]]; then
    if [[ "${precisionRemainder}" -gt '0' ]]; then
      precisionQuotient="$(("${precisionQuotient}" + 1))"
    fi
  fi

  if [[ "${precisionQuotient}" -ge "$((10 ** "${precision}"))" ]]; then
    quotient="$(("${quotient}" + 1))"
    precisionQuotient='0'
  fi

  if [[ "${precision}" -eq 0 ]]; then
    echo "$(printf "%d" "${quotient}")"
  else
    echo "$(printf "%d.%0${precision}d" "${quotient}" "${precisionQuotient}")"
  fi
}

doComparison() {
  local value1="${1}"
  local comparison="${2,,}"
  local value2="${3}"

  if [[ "${comparison}" == 'eq' ]]; then
    if [[ "${value1}" -eq "${value2}" ]]; then
      echo 'true'
    fi
  elif [[ "${comparison}" == 'ne' ]]; then
    if [[ "${value1}" -ne "${value2}" ]]; then
      echo 'true'
    fi
  elif [[ "${comparison}" == 'gt' ]]; then
    if [[ "${value1}" -gt "${value2}" ]]; then
      echo 'true'
    fi
  elif [[ "${comparison}" == 'ge' ]]; then
    if [[ "${value1}" -ge "${value2}" ]]; then
      echo 'true'
    fi
  elif [[ "${comparison}" == 'lt' ]]; then
    if [[ "${value1}" -lt "${value2}" ]]; then
      echo 'true'
    fi
  elif [[ "${comparison}" == 'le' ]]; then
    if [[ "${value1}" -le "${value2}" ]]; then
      echo 'true'
    fi
  elif [[ "${comparison}" == '==' ]]; then
    if [[ "${value1}" == "${value2}" ]]; then
      echo 'true'
    fi
  elif [[ "${comparison}" == '=' ]]; then
    if [[ "${value1}" == "${value2}" ]]; then
      echo 'true'
    fi
  elif [[ "${comparison}" == '!=' ]]; then
    if [[ "${value1}" != "${value2}" ]]; then
      echo 'true'
    fi
  elif [[ "${comparison}" == '<>' ]]; then
    if [[ "${value1}" != "${value2}" ]]; then
      echo 'true'
    fi
  elif [[ "${comparison}" == '!' ]]; then
    if [[ "${value1}" != "${value2}" ]]; then
      echo 'true'
    fi
  elif [[ "${comparison}" == '<=' ]]; then
    if [[ "${value1}" -le "${value2}" ]]; then
      echo 'true'
    fi
  elif [[ "${comparison}" == '=<' ]]; then
    if [[ "${value1}" -le "${value2}" ]]; then
      echo 'true'
    fi
  elif [[ "${comparison}" == '<' ]]; then
    if [[ "${value1}" -lt "${value2}" ]]; then
      echo 'true'
    fi
  elif [[ "${comparison}" == '>=' ]]; then
    if [[ "${value1}" -ge "${value2}" ]]; then
      echo 'true'
    fi
  elif [[ "${comparison}" == '=>' ]]; then
    if [[ "${value1}" -ge "${value2}" ]]; then
      echo 'true'
    fi
  elif [[ "${comparison}" == '>' ]]; then
    if [[ "${value1}" -gt "${value2}" ]]; then
      echo 'true'
    fi
  fi
}

#-----------------
# Value Normalization
#-----------------

normalizeAudioCodec() {
  local codecName="${1,,}"
  case "${codecName}" in
  libfdk_aac | aac | aac_fixed) echo 'aac' ;;
  libfdk_ac3 | ac3 | ac3_fixed) echo 'ac3' ;;
  *) echo "${codecName}" ;;
  esac
}

normalizeVideoCodec() {
  local codecName="${1,,}"
  case "${codecName}" in
  libx265 | h265 | x265 | hevc | hevc_v4l2m2m | hevc_vaapi) echo 'hevc' ;;
  libx264 | h264 | x264 | libx264rgb | h264_v4l2m2m | h264_vaapi | h264_omx) echo 'h264' ;;
  *) echo "${codecName}" ;;
  esac
}

normalizeSubtitleCodec() {
  local codecName="${1,,}"
  case "${codecName}" in
  subrip | srt) echo 'subrip' ;;
  dvbsub | dvb_subtitle) echo 'dvbsub' ;;
  dvdsub | dvd_subtitle) echo 'dvdsub' ;;
  pgssub | hdmv_pgs_subtitle) echo 'pgssub' ;;
  cc_dec | eia_608) echo 'cc_dec' ;;
  libzvbi_teletextdec | dvb_teletext) echo 'libzvbi_teletextdec' ;;
  ssa | ass) echo 'ass' ;;
  *) echo "${codecName}" ;;
  esac
}

normalizeVideoProfileComplexity() {
  local videoProfile="${1,,}"
  if [[ "${videoProfile}" =~ .*baseline.* ]]; then
    echo "baseline"
  elif [[ "${videoProfile}" =~ .*main.* ]]; then
    echo "main"
  elif [[ "${videoProfile}" =~ .*high.* ]]; then
    echo "high"
  else
    echo "${videoProfile}"
  fi
}

normalizeFrameRate() {
  local frameRate="${1,,}"
  if [[ "${frameRate}" == '30000/1001' || "${frameRate}" == '29.9' || "${frameRate}" == '29.97' || "${frameRate}" == '29.970' ]]; then
    echo "ntsc"
  elif [[ "${frameRate}" == '25/1' || "${frameRate}" == '25.0' || "${frameRate}" == '25' ]]; then
    echo "pal"
  elif [[ "${frameRate}" == '24/1' || "${frameRate}" == '24.0' || "${frameRate}" == '24' ]]; then
    echo "film"
  elif [[ "${frameRate}" == '24000/1001' || "${frameRate}" == '2997/125' || "${frameRate}" == '23.9' || "${frameRate}" == '23.97' || "${frameRate}" == '23.976' ]]; then
    echo "ntsc_film"
  elif [[ -z "${frameRate}" || "${frameRate}" == 'copy' || "${frameRate}" == 'source' ]]; then
    echo "source_fps"
  elif [[ "${frameRate: -2}" == '/1' || "${frameRate: -2}" == '.0' ]]; then
    echo "${frameRate::-2}"
  elif [[ "${frameRate}" != "$(echo "${frameRate}" | sed 's/.*\///')" ]]; then
    local fraction="$(divide "$(echo "${frameRate}" | sed 's/.*\///')" "$(echo "${frameRate}" | sed 's/\.*///')" '2' 'floor')"
    if [[ "${fraction}" == '29.96' || "${fraction}" == '29.97' || "${fraction}" == '29.98' ]]; then
      echo "ntsc"
    elif [[ "${fraction}" == '23.96' || "${fraction}" == '23.97' || "${fraction}" == '23.98' ]]; then
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
  en | eng | english) echo 'English' ;;
  jp | jpn | japanese) echo 'Japanese' ;;
  ru | rus | russian) echo 'Russian' ;;
  *) echo 'unknown' ;;
  esac
}

normalizeLanguage() {
  local language="${1,,}"
  case "${language}" in
  en | eng | english) echo 'eng' ;;
  jp | jpn | japanese) echo 'jpn' ;;
  ru | rus | russian) echo 'rus' ;;
  *) echo 'unknown' ;;
  esac
}

#-----------------
# Value Transformation
#-----------------

getChannelNaming() {
  local channelCount="${1}"
  case "${channelCount,,}" in
    1 | '1.0' | mono) echo 'Mono';;
    2 | '2.0' | stereo) echo 'Stereo';;
    3 | '2.1') echo '2.1';;
    4 | '4.0') echo '4.0';;
    5 | '4.1') echo '4.1';;
    6 | '5.1') echo '5.1';;
    8 | '7.1') echo '7.1';;
    9 | '7.2') echo '7.2';;
    10 | '9.1') echo '9.1';;
    11 | '9.2') echo '9.2';;
  esac
}

getColorFormat() {
  local pixelFormat="${1,,}"
  case "${pixelFormat}" in
    monow | monob) echo 'gray' ;;
    rgb4 | rgb4_byte | bgr4 | bgr4_byte) echo 'rgb' ;;
    rgb8 | bgr8) echo 'rgb' ;;
    bayer_bggr8 | bayer_rggb8 | bayer_gbrg8 | bayer_grbg8) echo 'bayer' ;;
    gray) echo 'gray' ;;
    ya8) echo 'ya' ;;
    pal8) echo 'pal' ;;
    rgb24 | bgr24 | rgb0 | bgr0 | '0rgb' | '0bgr' | gbrp) echo 'rgb' ;;
    argb | abgr | rgba | bgra | gbrap) echo 'rgb' ;;
    rgb555be | rgb555le | bgr555be | bgr555le) echo 'rgb' ;;
    rgb565be | rgb565le | bgr565be | bgr565le) echo 'rgb' ;;
    rgb444be | rgb444le | bgr444be | bgr444le) echo 'rgb' ;;
    nv12 | nv21) echo 'nv' ;;
    nv16) echo 'nv' ;;
    nv20le | nv20be) echo 'nv' ;;
    nv24 | nv42) echo 'nv' ;;
    p010le | p010be) echo 'p01' ;;
    p016le | p016be) echo 'p01' ;;
    yuv410p) echo 'yuv' ;;
    yuv411p | yuvj411p | uyyvyy411) echo 'yuv' ;;
    yuv420p | yuvj420p) echo 'yuv' ;;
    yuv422p | yuyv422 | yuvj422p | uyvy422 | yvyu422) echo 'yuv' ;;
    yuv440p | yuvj440p) echo 'yuv' ;;
    yuv444p | yuvj444p) echo 'yuv' ;;
    yuva420p) echo 'yuv' ;;
    yuva422p) echo 'yuv' ;;
    yuva440p) echo 'yuv' ;;
    yuva444p) echo 'yuv' ;;
    gray9be | gray9le) echo 'gray' ;;
    gbrp9be | gbrp9le) echo 'rgb' ;;
    yuv420p9be | yuv420p9le) echo 'yuv' ;;
    yuv422p9be | yuv422p9le) echo 'yuv' ;;
    yuv440p9be | yuv440p9le) echo 'yuv' ;;
    yuv444p9be | yuv444p9le) echo 'yuv' ;;
    yuva420p9be | yuva420p9le) echo 'yuv' ;;
    yuva422p9be | yuva422p9be) echo 'yuv' ;;
    yuva440p9be | yuva440p9le) echo 'yuv' ;;
    yuva444p9be | yuva444p9be) echo 'yuv' ;;
    gray10be | gray10le) echo 'rgb' ;;
    gbrp10be | gbrp10le) echo 'rgb' ;;
    gbrap10be | gbrap10le) echo 'rgb' ;;
    yuv420p10be | yuv420p10le) echo 'yuv' ;;
    yuv422p10be | yuv422p10le) echo 'yuv' ;;
    yuv440p10le | yuv440p10be) echo 'yuv' ;;
    yuv444p10be | yuv444p10le) echo 'yuv' ;;
    yuva420p10be | yuva420p10le) echo 'yuv' ;;
    yuva422p10be | yuva422p10be) echo 'yuv' ;;
    yuva440p10be | yuva440p10be) echo 'yuv' ;;
    yuva444p10be | yuva444p10be) echo 'yuv' ;;
    gray12be | gray12le) echo 'gray' ;;
    xyz12le | xyz12be | gbrp12be | gbrp12le) echo 'rgb' ;;
    gbrap12be | gbrap12le) echo 'rgb' ;;
    yuv420p12be | yuv420p12le) echo 'yuv' ;;
    yuv422p12be | yuv422p12le) echo 'yuv' ;;
    yuv440p12le | yuv440p12be) echo 'yuv' ;;
    yuv444p12be | yuv444p12le) echo 'yuv' ;;
    yuva420p12be | yuva420p12le) echo 'yuv' ;;
    yuva422p12be | yuva422p12le) echo 'yuv' ;;
    yuva440p12be | yuva440p12le) echo 'yuv' ;;
    yuva444p12be | yuva444p12le) echo 'yuv' ;;
    gray14be | gray14le) echo 'gray' ;;
    gbrp14be | gbrp14le) echo 'rgb' ;;
    yuv420p14be | yuv420p14le) echo 'yuv' ;;
    yuv422p14be | yuv422p14le) echo 'yuv' ;;
    yuv440p14be | yuv440p14le) echo 'yuv' ;;
    yuv444p14be | yuv444p14le) echo 'yuv' ;;
    ya16be | ya16le) echo 'ya' ;;
    rgb48be | rgb48le | bgr48be | bgr48le) echo 'rgb' ;;
    rgba64be | rgba64le | bgra64be | bgra64le) echo 'rgb' ;;
    gbrp16be | gbrp16le) echo 'rgb' ;;
    bayer_bggr16le | bayer_bggr16be | bayer_rggb16le | bayer_rggb16be | bayer_gbrg16le | bayer_gbrg16be | bayer_grbg16le | bayer_grbg16be) echo 'bayer' ;;
    yuv420p16le | yuv420p16be) echo 'yuv' ;;
    yuv422p16le | yuv422p16le) echo 'yuv' ;;
    yuv440p16le | yuv440p16be) echo 'yuv' ;;
    yuv444p16le | yuv444p16le) echo 'yuv' ;;
    yuva420p16be | yuva420p16le) echo 'yuv' ;;
    yuva422p16be | yuva422p16be) echo 'yuv' ;;
    ayuv64le | ayuv64be | yuva444p16be | yuva444p16be) echo 'yuv' ;;
    grayf32be | grayf32le) echo 'gray' ;;
    gbrpf32be | gbrpf32le) echo 'rgb' ;;
    gbrapf32be | gbrapf32le) echo 'rgb' ;;
    *) echo '-1' ;;
  esac
}

getColorDepth() {
  local pixelFormat="${1,,}"
  local pixelFormat="${1,,}"
  case "${pixelFormat}" in
    monow | monob) echo '1' ;;
    rgb4 | rgb4_byte | bgr4 | bgr4_byte) echo '2' ;;
    rgb8 | bgr8) echo '3' ;;
    bayer_bggr8 | bayer_rggb8 | bayer_gbrg8 | bayer_grbg8) echo '3' ;;
    gray) echo '8' ;;
    ya8) echo '8' ;;
    pal8) echo '8' ;;
    rgb24 | bgr24 | rgb0 | bgr0 | '0rgb' | '0bgr' | gbrp) echo '8' ;;
    argb | abgr | rgba | bgra | gbrap) echo '8' ;;
    rgb555be | rgb555le | bgr555be | bgr555le) echo '8' ;;
    rgb565be | rgb565le | bgr565be | bgr565le) echo '8' ;;
    rgb444be | rgb444le | bgr444be | bgr444le) echo '8' ;;
    nv12 | nv21) echo '8' ;;
    nv16) echo '8' ;;
    nv20le | nv20be) echo '8' ;;
    nv24 | nv42) echo '8' ;;
    p010le | p010be) echo '8' ;;
    p016le | p016be) echo '8' ;;
    yuv410p) echo '8' ;;
    yuv411p | yuvj411p | uyyvyy411) echo '8' ;;
    yuv420p | yuvj420p) echo '8' ;;
    yuv422p | yuyv422 | yuvj422p | uyvy422 | yvyu422) echo '8' ;;
    yuv440p | yuvj440p) echo '8' ;;
    yuv444p | yuvj444p) echo '8' ;;
    yuva420p) echo '8' ;;
    yuva422p) echo '8' ;;
    yuva440p) echo '8' ;;
    yuva444p) echo '8' ;;
    gray9be | gray9le) echo '9' ;;
    gbrp9be | gbrp9le) echo '9' ;;
    yuv420p9be | yuv420p9le) echo '9' ;;
    yuv422p9be | yuv422p9le) echo '9' ;;
    yuv440p9be | yuv440p9le) echo '9' ;;
    yuv444p9be | yuv444p9le) echo '9' ;;
    yuva420p9be | yuva420p9le) echo '9' ;;
    yuva422p9be | yuva422p9be) echo '9' ;;
    yuva440p9be | yuva440p9le) echo '9' ;;
    yuva444p9be | yuva444p9be) echo '9' ;;
    gray10be | gray10le) echo '10' ;;
    gbrp10be | gbrp10le) echo '10' ;;
    gbrap10be | gbrap10le) echo '10' ;;
    yuv420p10be | yuv420p10le) echo '10' ;;
    yuv422p10be | yuv422p10le) echo '10' ;;
    yuv440p10le | yuv440p10be) echo '10' ;;
    yuv444p10be | yuv444p10le) echo '10' ;;
    yuva420p10be | yuva420p10le) echo '10' ;;
    yuva422p10be | yuva422p10be) echo '10' ;;
    yuva440p10be | yuva440p10be) echo '10' ;;
    yuva444p10be | yuva444p10be) echo '10' ;;
    gray12be | gray12le) echo '12' ;;
    xyz12le | xyz12be | gbrp12be | gbrp12le) echo '12' ;;
    gbrap12be | gbrap12le) echo '12' ;;
    yuv420p12be | yuv420p12le) echo '12' ;;
    yuv422p12be | yuv422p12le) echo '12' ;;
    yuv440p12le | yuv440p12be) echo '12' ;;
    yuv444p12be | yuv444p12le) echo '12' ;;
    yuva420p12be | yuva420p12le) echo '12' ;;
    yuva422p12be | yuva422p12le) echo '12' ;;
    yuva440p12be | yuva440p12le) echo '12' ;;
    yuva444p12be | yuva444p12le) echo '12' ;;
    gray14be | gray14le) echo '14' ;;
    gbrp14be | gbrp14le) echo '14' ;;
    yuv420p14be | yuv420p14le) echo '14' ;;
    yuv422p14be | yuv422p14le) echo '14' ;;
    yuv440p14be | yuv440p14le) echo '14' ;;
    yuv444p14be | yuv444p14le) echo '14' ;;
    ya16be | ya16le) echo '16' ;;
    rgb48be | rgb48le | bgr48be | bgr48le) echo '16' ;;
    rgba64be | rgba64le | bgra64be | bgra64le) echo '16' ;;
    gbrp16be | gbrp16le) echo '16' ;;
    bayer_bggr16le | bayer_bggr16be | bayer_rggb16le | bayer_rggb16be | bayer_gbrg16le | bayer_gbrg16be | bayer_grbg16le | bayer_grbg16be) echo '16' ;;
    yuv420p16le | yuv420p16be) echo '16' ;;
    yuv422p16le | yuv422p16le) echo '16' ;;
    yuv440p16le | yuv440p16be) echo '16' ;;
    yuv444p16le | yuv444p16le) echo '16' ;;
    yuva420p16be | yuva420p16le) echo '16' ;;
    yuva422p16be | yuva422p16be) echo '16' ;;
    ayuv64le | ayuv64be | yuva444p16be | yuva444p16be) echo '16' ;;
    grayf32be | grayf32le) echo '32' ;;
    gbrpf32be | gbrpf32le) echo '32' ;;
    gbrapf32be | gbrapf32le) echo '32' ;;
    *) echo '-1' ;;
  esac
}

getColorCompression() {
  local pixelFormat="${1,,}"
  case "${pixelFormat}" in
    monow | monob) echo '444' ;;
    rgb4 | rgb4_byte | bgr4 | bgr4_byte) echo '444' ;;
    rgb8 | bgr8) echo '444' ;;
    bayer_bggr8 | bayer_rggb8 | bayer_gbrg8 | bayer_grbg8) echo '444' ;;
    gray) echo '444' ;;
    ya8) echo '444' ;;
    pal8) echo '444' ;;
    rgb24 | bgr24 | rgb0 | bgr0 | '0rgb' | '0bgr' | gbrp) echo '444' ;;
    argb | abgr | rgba | bgra | gbrap) echo '444' ;;
    rgb555be | rgb555le | bgr555be | bgr555le) echo '420' ;;
    rgb565be | rgb565le | bgr565be | bgr565le) echo '422' ;;
    rgb444be | rgb444le | bgr444be | bgr444le) echo '444' ;;
    nv12 | nv21) echo '420' ;;
    nv16) echo '422' ;;
    nv20le | nv20be) echo '442' ;;
    nv24 | nv42) echo '444' ;;
    p010le | p010be) echo '420' ;;
    p016le | p016be) echo '444' ;;
    yuv410p) echo '410' ;;
    yuv411p | yuvj411p | uyyvyy411) echo '411' ;;
    yuv420p | yuvj420p) echo '420' ;;
    yuv422p | yuyv422 | yuvj422p | uyvy422 | yvyu422) echo '422' ;;
    yuv440p | yuvj440p) echo '440' ;;
    yuv444p | yuvj444p) echo '444' ;;
    yuva420p) echo '420' ;;
    yuva422p) echo '422' ;;
    yuva440p) echo '440' ;;
    yuva444p) echo '444' ;;
    gray9be | gray9le) echo '444' ;;
    gbrp9be | gbrp9le) echo '444' ;;
    yuv420p9be | yuv420p9le) echo '420' ;;
    yuv422p9be | yuv422p9le) echo '422' ;;
    yuv440p9be | yuv440p9le) echo '440' ;;
    yuv444p9be | yuv444p9le) echo '444' ;;
    yuva420p9be | yuva420p9le) echo '420' ;;
    yuva422p9be | yuva422p9be) echo '422' ;;
    yuva440p9be | yuva440p9le) echo '440' ;;
    yuva444p9be | yuva444p9be) echo '444' ;;
    gray10be | gray10le) echo '444' ;;
    gbrp10be | gbrp10le) echo '444' ;;
    gbrap10be | gbrap10le) echo '444' ;;
    yuv420p10be | yuv420p10le) echo '420' ;;
    yuv422p10be | yuv422p10le) echo '422' ;;
    yuv440p10le | yuv440p10be) echo '440' ;;
    yuv444p10be | yuv444p10le) echo '444' ;;
    yuva420p10be | yuva420p10le) echo '420' ;;
    yuva422p10be | yuva422p10be) echo '422' ;;
    yuva440p10be | yuva440p10be) echo '440' ;;
    yuva444p10be | yuva444p10be) echo '444' ;;
    gray12be | gray12le) echo '444' ;;
    xyz12le | xyz12be | gbrp12be | gbrp12le) echo '444' ;;
    gbrap12be | gbrap12le) echo '444' ;;
    yuv420p12be | yuv420p12le) echo '420' ;;
    yuv422p12be | yuv422p12le) echo '422' ;;
    yuv440p12le | yuv440p12be) echo '440' ;;
    yuv444p12be | yuv444p12le) echo '444' ;;
    yuva420p12be | yuva420p12le) echo '420' ;;
    yuva422p12be | yuva422p12le) echo '422' ;;
    yuva440p12be | yuva440p12le) echo '440' ;;
    yuva444p12be | yuva444p12le) echo '444' ;;
    gray14be | gray14le) echo '444' ;;
    gbrp14be | gbrp14le) echo '444' ;;
    yuv420p14be | yuv420p14le) echo '420' ;;
    yuv422p14be | yuv422p14le) echo '422' ;;
    yuv440p14be | yuv440p14le) echo '440' ;;
    yuv444p14be | yuv444p14le) echo '444' ;;
    ya16be | ya16le) echo '444' ;;
    rgb48be | rgb48le | bgr48be | bgr48le) echo '444' ;;
    rgba64be | rgba64le | bgra64be | bgra64le) echo '444' ;;
    gbrp16be | gbrp16le) echo '444' ;;
    bayer_bggr16le | bayer_bggr16be | bayer_rggb16le | bayer_rggb16be | bayer_gbrg16le | bayer_gbrg16be | bayer_grbg16le | bayer_grbg16be) echo '444' ;;
    yuv420p16le | yuv420p16be) echo '420' ;;
    yuv422p16le | yuv422p16le) echo '422' ;;
    yuv440p16le | yuv440p16be) echo '440' ;;
    yuv444p16le | yuv444p16le) echo '444' ;;
    yuva420p16be | yuva420p16le) echo '420' ;;
    yuva422p16be | yuva422p16be) echo '422' ;;
    ayuv64le | ayuv64be | yuva444p16be | yuva444p16be) echo '444' ;;
    grayf32be | grayf32le) echo '444' ;;
    gbrpf32be | gbrpf32le) echo '444' ;;
    gbrapf32be | gbrapf32le) echo '444' ;;
    *) echo '-1' ;;
  esac
}

getColorChannelCount() {
  local pixelFormat="${1,,}"
  local channel="$(echo "${allPixelFormats}" | grep " ${pixelFormat} " | awk '{print $3}')"
  if [[ -z "${channel}" ]]; then
    echo '-1'
  else
    echo "${channel}"
  fi
}

getColorBitCount() {
  local pixelFormat="${1,,}"
  local bits="$(echo "${allPixelFormats}" | grep " ${pixelFormat} " | awk '{print $4}')"
  if [[ -z "${bits}" ]]; then
    echo '-1'
  else
    echo "${bits}"
  fi
}

findPixelFormatMostApplicableFromList() {
  local function="${1}"
  local comparison="${2}"
  local newPixelFormatList="${3,,}"
  local newPixelFormat=''
  local newPixelValue=''
  local currentValue=''
  local newList=''
  local hasCopy=''

  IFS=$'\n'
  for newPixelFormat in $(echo "${newPixelFormatList}" | sed 's/,/\n/g'); do
    newPixelValue="$(${function} "${newPixelFormat}")"
    if [[ "${newPixelFormat}" == 'copy' ]]; then
      hasCopy="copy"
    elif [[ -z "${currentValue}" ]]; then
      newList="${newPixelFormat}"
      currentValue="${newPixelValue}"
    elif [[ "${currentValue}" == "${newPixelValue}" ]]; then
      newList="${newList},${newPixelFormat}"
    elif [[ "${newPixelValue}" != '-1' && 'true' == "$(doComparison "${newPixelValue}" "${comparison}" "${currentValue}")" ]]; then
      newList="${newPixelFormat}"
      currentValue="${newPixelValue}"
    fi
  done

  if [[ -n "${newList}" && -n "${hasCopy}" ]]; then
    echo "$(echo "${newList},${hasCopy}" | sed 's/,/\n/g')"
  elif [[ -n "${newList}" ]]; then
    echo "$(echo "${newList}" | sed 's/,/\n/g')"
  else
    echo "${hasCopy}"
  fi
}

findPixelFormatAdequateFromList() {
  local function="${1}"
  local oldPixelFormat="${2,,}"
  local comparison="${3}"
  local newPixelFormatList="${4,,}"
  local oldPixelValue="$(${function} "${oldPixelFormat}")"
  local newPixelFormat=''
  local newPixelValue=''
  local newList=''

  IFS=$'\n'
  for newPixelFormat in $(echo "${newPixelFormatList}" | sed 's/,/\n/g'); do
    newPixelValue="$(${function} "${newPixelFormat}")"
    if [[ "${newPixelFormat}" == 'copy' ]]; then
      echo "${newPixelFormat}"
    elif [[ "${newPixelValue}" != '-1' && 'true' == "$(doComparison "${oldPixelValue}" "${comparison}" "${newPixelValue}")" ]]; then
      echo "${newPixelFormat}"
    fi
  done
}

findPixelFormat() {
  local oldPixelFormat="${1,,}"
  local videoPixelFormat="${2,,}"
  local newPixelFormat=''
  local newPixelFormatOrder=''
  local formatFunction=''

  if [[ "$(doesContain "${oldPixelFormat}" "${videoPixelFormat,,}" ',')" == 'true' ]]; then
    newPixelFormat="$(echo "${videoPixelFormat}" | sed 's/,/\n/g')"
    for newPixelFormatOrder in $(echo "${videoPixelFormatExclusionOrder}" | sed 's/,/\n/g'); do
      case "${newPixelFormatOrder,,}" in
        depth) formatFunction='getColorDepth' ;;
        channel) formatFunction='getColorChannelCount' ;;
        compression) formatFunction='getColorCompression' ;;
        bit) formatFunction='getColorBitCount' ;;
        format) formatFunction='getColorFormat' ;;
        *) formatFunction='' ;;
      esac
      if [[ -n "${formatFunction}" ]]; then
        if [[ "${formatFunction}" == 'getColorFormat' ]]; then
          formatFunction="$(findPixelFormatAdequateFromList "${formatFunction}" "${oldPixelFormat}" "==" "${newPixelFormat}")"
        else
          formatFunction="$(findPixelFormatAdequateFromList "${formatFunction}" "${oldPixelFormat}" "<=" "${newPixelFormat}")"
        fi
        if [[ -n "${formatFunction}" ]]; then
          newPixelFormat="${formatFunction}"
        fi
      fi
    done

    for newPixelFormatOrder in $(echo "${videoPixelFormatPreferenceOrder}" | sed 's/,/\n/g'); do
      case "${newPixelFormatOrder,,}" in
        depth) formatFunction='getColorDepth' ;;
        channel) formatFunction='getColorChannelCount' ;;
        compression) formatFunction='getColorCompression' ;;
        bit) formatFunction='getColorBitCount' ;;
        format) formatFunction='getColorFormat' ;;
        *) formatFunction='' ;;
      esac
      if [[ -n "${formatFunction}" ]]; then
        if [[ "${formatFunction}" == 'getColorFormat' ]]; then
          formatFunction="$(findPixelFormatMostApplicableFromList "${formatFunction}" "==" "${newPixelFormat}")"
        else
          formatFunction="$(findPixelFormatMostApplicableFromList "${formatFunction}" "<" "${newPixelFormat}")"
        fi
        if [[ -n "${formatFunction}" ]]; then
          newPixelFormat="${formatFunction}"
        fi
      fi
    done
  fi

  if [[ -n "${newPixelFormat}" ]]; then
    echo "$(getFirst "${newPixelFormat}" ',')"
  else
    echo "$(getFirst "${videoPixelFormat}" ',')"
  fi
}

getPresetComplexityOrder() {
  local videoPreset="${1,,}"
  case "${videoPreset}" in
    ultrafast) echo '1' ;;
    superfast) echo '2' ;;
    veryfast) echo '3' ;;
    fast) echo '4' ;;
    medium) echo '5' ;;
    slow) echo '6' ;;
    slower) echo '7' ;;
    veryslow) echo '8' ;;
    placebo) echo '9' ;;
    *) echo '1' ;; # Assume Ultrafast
  esac
}

getProfileComplexityOrder() {
  local videoProfile="${1,,}"
  case "${videoProfile::4}" in
    base) echo '1' ;;
    main) echo '2' ;;
    high) echo '3' ;;
    *) echo '-1' ;;
  esac
}

getSubtitleEncodingType() {
  local codecName="${1,,}"
  case "${codecName}" in
    dvbsub) echo 'image' ;;
    dvdsub) echo 'image' ;;
    pgssub) echo 'image' ;;
    xsub) echo 'image' ;;
    arib_caption) echo 'text' ;;
    ass) echo 'text' ;;
    cc_dec) echo 'text' ;;
    hdmv_text_subtitle) echo 'text' ;;
    jacosub) echo 'text' ;;
    libzvbi_teletextdec) echo 'text' ;;
    microdvd) echo 'text' ;;
    mov_text) echo 'text' ;;
    mpl2) echo 'text' ;;
    realtext) echo 'text' ;;
    sami) echo 'text' ;;
    stl) echo 'text' ;;
    subrip) echo 'text' ;;
    subviewer) echo 'text' ;;
    text) echo 'text' ;;
    ttml) echo 'text' ;;
    vplayer) echo 'text' ;;
    webvtt) echo 'text' ;;
    *) echo 'unknown' ;;
  esac
}

getProfileValue() {
  local encoder="$(normalizeVideoCodec "${1,,}")"
  local profile="$(normalizeVideoProfileComplexity "${2,,}")"
  local colorDepth="$(getColorDepth "${3,,}")"
  local colorCompression"$(getColorCompression "${3,,}")"

  if [[ "${encoder}" == 'hevc' ]]; then
    if [[ "${profile}" == 'main' ]]; then
      if [[ "${colorDepth}" -le 8 ]]; then
        if [[ "${colorCompression}" -ge 444 ]]; then
          echo 'main444-8'
        else
          echo 'main'
        fi
      elif [[ "${colorDepth}" -le 10 ]]; then
        if [[ "${colorCompression}" -ge 444 ]]; then
          echo 'main444-10'
        elif [[ "${colorCompression}" -ge 422 ]]; then
          echo 'main422-10'
        else
          echo 'main10'
        fi
      else
        if [[ "${colorCompression}" -ge 444 ]]; then
          echo 'main444-12'
        elif [[ "${colorCompression}" -ge 422 ]]; then
          echo 'main422-12'
        else
          echo 'main12'
        fi
      fi
    elif [[ "${profile}" == 'high' ]]; then
      echo 'high'
    else
      echo "${2,,}"
    fi
  elif [[ "${encoder}" == 'h264' ]]; then
    if [[ "${profile}" == 'high' ]]; then
      echo 'high'
    elif [[ "${profile}" == 'main' ]]; then
      echo 'main'
    else
      echo 'baseline'
    fi
  else
    echo "${2,,}"
  fi
}

#-----------------
# Value Retrieval
#-----------------

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
  if [[ -z "${oldBitRate}" || "${oldBitRate}" == 'N/A' ]]; then
    oldBitRate="$(getValue 'bit_rate' "${stream}")"
  fi
  if [[ -z "${oldBitRate}" || "${oldBitRate}" == 'N/A' ]]; then
    oldBitRate="$(getMetadata 'BPS' "${stream}")"
  fi
  if [[ -z "${oldBitRate}" || "${oldBitRate}" == 'N/A' || "${oldBitRate}" == '0' ]]; then
    oldBitRate=''
  fi
  if [[ "${oldBitRate^^}" =~ .*K$ ]]; then
    oldBitRate="$(("${oldBitRate::-1}" * 1024))"
  elif [[ "${oldBitRate^^}" =~ .*M$ ]]; then
    oldBitRate="$(("${oldBitRate::-1}" * 1024 * 1024))"
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

getLanguage() {
  local fileName="${1}"
  local stream="${2}"
  local language="$(getMetadata "${metadataLanguage}" "${stream}")"
  if [[ -z "${language}" ]]; then
    IFS=$'\n'
    for language in $(echo "${fileName}" | sed 's/\./\n/g'); do
      language="$(normalizeLanguage "${language}")"
      if [[ "${language}" != 'unknown' ]]; then
        break
      fi
    done
  fi
  echo "${language}"
}

getInputFiles() {
  local inputFile="${1}"
  local inputDirectory="$(getDirectory "${inputFile}")"
  local inputFileName="$(getFileName "${inputFile}")"

  local fileExt=''
  local fileName=''

  echo "${inputFile}"
  IFS=$'\n'
  for fileExt in $(echo "${audioExtension}" | sed 's/,/\n/g'); do
    for fileName in $(find "${inputDirectory}" -type f -name "${inputFileName}*${fileExt}"); do
      echo "${fileName}"
    done
  done
  for fileExt in $(echo "${subtitleExtension}" | sed 's/,/\n/g'); do
    for fileName in $(find "${inputDirectory}" -type f -name "${inputFileName}*${fileExt}"); do
      echo "${fileName}"
    done
  done
}

#-----------------
# FFMpeg Argument Processing
#-----------------

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
      probeResult="$(echo "${chapterList}" | awk "/\[CHAPTER\]/{f=f+1} f==$((${chapter} + 1)){print;}")"
      oldTitle="$(getMetadata "${metadataTitle}" "${probeResult}")"

      if [[ -n "${oldTitle}" ]]; then
        chapterEncoding="${chapterEncoding} -metadata:c:${chapter} '${metadataTitle}=${oldTitle}'"
      fi
    done
  fi
  echo "${chapterEncoding}"
}

getAudioEncodingSettings() {
  local baseFile="${1}"
  local allFiles="$(getInputFiles "${baseFile}")"
  local fileCount='0'
  local index='0'
  local inputFile=''

  IFS=$'\n'
  for inputFile in ${allFiles}; do
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

    for stream in $(seq 0 1 $((${streamCount} - 1))); do
      probeResult="$(echo "${streamList}" | awk "/\[STREAM\]/{f=f+1} f==$((${stream} + 1)){print;}")"
      newCodec=''
      newChannelCount='2'
      oldCodec="$(getCodecFromStream "${probeResult}")"
      duration="$(getMetadata 'DURATION' "${probeResult}")"
      oldTitle="$(getMetadata "${metadataTitle}" "${probeResult}")"
      oldLanguage="$(getLanguage "${inputFileName}" "${probeResult}")"
      oldChannelCount="$(getValue 'channels' "${probeResult}")"
      if [[ -z "${oldChannelCount}" ]]; then
        oldChannelCount='2'
      fi
      oldBitRate="$(getAudioBitRateFromStream "${probeResult}")"

      if [[ "${audioUpdateMethod}" == 'strip' && "$(doesContain "$(normalizeAudioCodec "${oldCodec}")" "$(forEach "${audioCodec}" ',' 'normalizeAudioCodec')" ',')" != 'true' ]]; then
        oldCodec=''
      fi

      if [[ -n "${oldCodec}" && "${duration}" != '00:00:00.000000000' ]]; then
        normalizedOldCodecName="$(normalizeAudioCodec "${oldCodec}")"

        IFS=$'\n'
        for newCodec in $(echo "${audioCodec}" | sed 's/,/\n/g'); do
          normalizedNewCodecName="$(normalizeAudioCodec "${newCodec}")"
          if [[ "${normalizedOldCodecName}" == "${normalizedNewCodecName}" ]]; then
            break
          fi
        done

        if [[ "${normalizedOldCodecName}" != "${normalizedNewCodecName}" ]]; then
          newCodec="$(getFirst "${audioCodec}" ',')"
          normalizedNewCodecName="$(normalizeAudioCodec "${newCodec}")"
        fi

        if [[ "${newChannelCount}" != "${oldChannelCount}" ]]; then
          newChannelCount="${oldChannelCount}"
        fi
        newBitRate="$((${newChannelCount} * ${bitratePerAudioChannel}))"

        if [[ -n "${oldBitRate}" && "${newBitRate}" -gt "${oldBitRate}" ]]; then
          newBitRate="${oldBitRate}"
        fi

        if [[ -z "${newCodec}" || "${newCodec,,}" == "copy" ]] || ([[ "${forceRun}" == 'false' && "${normalizedOldCodecName}" == "${normalizedNewCodecName}" ]] && [[ -z "${oldBitRate}" || "${oldBitRate}" -le "${newBitRate}" ]]); then
          audioEncoding="${audioEncoding} -map ${fileCount}:a:${stream}"
          audioEncoding="${audioEncoding} -codec:a:${index} copy -metadata:s:a:${index} '${metadataCodecName}=${oldCodec}'"
          if [[ -n "${oldBitRate}" ]]; then
            audioEncoding="${audioEncoding} -metadata:s:a:${index} '${metadataAudioBitRate}=${oldBitRate}'"
          fi
        else
          audioEncoding="${audioEncoding} -map ${fileCount}:a:${stream}"
          audioEncoding="${audioEncoding} -codec:a:${index} ${newCodec} -metadata:s:a:${index} '${metadataCodecName}=${newCodec}'"
          if [[ -n "${newBitRate}" ]]; then
            audioEncoding="${audioEncoding} -b:a:${index} ${newBitRate} -metadata:s:a:${index} '${metadataAudioBitRate}=${newBitRate}'"
          fi
        fi
        if [[ "$(normalizeLanguageFullName "${oldLanguage}")" != 'unknown' ]]; then
          audioEncoding="${audioEncoding} -metadata:s:a:${index} '${metadataTitle}=$(normalizeLanguageFullName "${oldLanguage}") ($(getChannelNaming "${oldChannelCount}"))'"
        elif [[ -n "${oldTitle}" ]]; then
          audioEncoding="${audioEncoding} -metadata:s:a:${index} '${metadataTitle}=${oldTitle}'"
        fi
        if [[ -n "${oldLanguage}" ]]; then
          audioEncoding="${audioEncoding} -metadata:s:a:${index} '${metadataLanguage}=${oldLanguage}'"
        fi
        index="$(("${index}" + 1))"
      fi
    done
    fileCount="$(("${fileCount}" + 1))"
  done
  echo "${audioEncoding}"
}

getVideoEncodingSettings() {
  local fileCount='0'
  local index='0'

  local inputFile="${1}"
  local inputFileName="$(getFileName "${inputFile}")"

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
  local index='0'

  for stream in $(seq 0 1 $((${streamCount} - 1))); do
    probeResult="$(echo "${streamList}" | awk "/\[STREAM\]/{f=f+1} f==$((${stream} + 1)){print;}")"
    newCodec=''
    newLevel="${videoLevel}"
    newPixelFormat="${videoPixelFormat}"
    newFrameRate="${videoFrameRate}"
    newPreset="${videoPreset}"
    newProfile="${videoProfile}"
    newQuality="${videoQuality}"
    newTune="${videoTune}"
    oldCodec="$(getCodecFromStream "${probeResult}")"
    duration="$(getMetadata 'DURATION' "${probeResult}")"
    oldTitle="$(getMetadata "${metadataTitle}" "${probeResult}")"
    oldLanguage="$(getLanguage "${inputFileName}" "${probeResult}")"
    oldLevel="$(getVideoLevelFromStream "${probeResult}")"
    oldPixelFormat="$(getVideoPixelFormatFromStream "${probeResult}")"
    oldFrameRate="$(getVideoFrameRateFromStream "${probeResult}")"
    oldPreset="$(getMetadata "${metadataVideoPreset}" "${probeResult}")"
    oldProfile="$(getVideoProfileFromStream "${probeResult}")"
    oldQuality="$(getMetadata "${metadataVideoQuality}" "${probeResult}")"
    oldTune="$(getMetadata "${metadataVideoTune}" "${probeResult}")"

    # Calculated Values
    normalizedOldFrameRate="$(normalizeFrameRate "${oldFrameRate}")"
    normalizedNewFrameRate="$(normalizeFrameRate "${newFrameRate}")"
    normalizedOldVideoProfile="$(normalizeVideoProfileComplexity "${oldProfile}")"
    normalizedNewVideoProfile="$(normalizeVideoProfileComplexity "${newProfile}")"
    oldPresetComplexity="$(getPresetComplexityOrder "${oldPreset}")"
    newPresetComplexity="$(getPresetComplexityOrder "${newPreset}")"
    oldProfileComplexity="$(getProfileComplexityOrder "${normalizedOldVideoProfile}")"
    newProfileComplexity="$(getProfileComplexityOrder "${normalizedNewVideoProfile}")"

    if [[ "${videoUpdateMethod}" == 'strip' && "$(doesContain "$(normalizeVideoCodec "${oldCodec}")" "$(forEach "${videoCodec}" ',' 'normalizeVideoCodec')" ',')" != 'true' ]]; then
      oldCodec=''
    fi

    if [[ -n "${oldCodec}" && "${duration}" != '00:00:00.000000000' ]]; then
      normalizedOldCodecName="$(normalizeVideoCodec "${oldCodec}")"

      IFS=$'\n'
      for newCodec in $(echo "${videoCodec}" | sed 's/,/\n/g'); do
        normalizedNewCodecName="$(normalizeVideoCodec "${newCodec}")"
        if [[ "${normalizedOldCodecName}" == "${normalizedNewCodecName}" ]]; then
          break
        fi
      done

      if [[ "${normalizedOldCodecName}" != "${normalizedNewCodecName}" ]]; then
        newCodec="$(getFirst "${videoCodec}" ',')"
        normalizedNewCodecName="$(normalizeVideoCodec "${newCodec}")"
      fi

      if [[ -z "${newProfile}" || "${newProfile,,}" == "copy" ]]; then
        newProfile="${oldProfile}"
      fi
      if [[ -z "${newLevel}" || "${newLevel}" == 'copy' ]]; then
        newLevel="${oldLevel}"
      elif [[ -n "${oldLevel}" && "${oldLevel}" != '0' && "$(echo "${oldLevel}" | sed 's/\.//')" -gt '0' && "$(echo "${newLevel}" | sed 's/\.//')" -gt "$(echo "${oldLevel}" | sed 's/\.//')" ]]; then
        newLevel="${oldLevel}"
      fi
      if [[ -z "${newPixelFormat}" || "${newPixelFormat}" == 'copy' ]]; then
        newPixelFormat="${oldPixelFormat}"
      elif [[ -n "$(echo "${newPixelFormat}" | grep -o ',')" ]]; then
        newPixelFormat="$(findPixelFormat "${oldPixelFormat}" "${newPixelFormat}")"
      fi
      if [[ -z "${oldQuality}" ]]; then
        oldQuality=0
      fi
      if [[ -z "${newQuality}" || "${newQuality}" == 'copy' ]]; then
        newQuality="${oldQuality}"
      elif [[ "${oldQuality}" -gt "${newQuality}" ]]; then
        newQuality="${oldQuality}"
      fi
      if [[ -z "${newTune}" ]]; then
        newTune="${oldTune}"
      fi

      oldProfile="$(getProfileValue "${oldCodec}" "${normalizedOldVideoProfile}" "${oldPixelFormat}")"
      if [[ -z "${newCodec}" || "${newCodec,,}" == "copy" ]]; then
        newProfile="$(getProfileValue "${oldCodec}" "${normalizedNewVideoProfile}" "${newPixelFormat}")"
      else
        newProfile="$(getProfileValue "${newCodec}" "${normalizedNewVideoProfile}" "${newPixelFormat}")"
      fi

      if [[ -z "${newCodec}" || "${newCodec,,}" == "copy" ]] ||
        [[ "${forceRun}" == 'false' && "${normalizedOldCodecName}" == "${normalizedNewCodecName}" && "${oldPresetComplexity}" -ge "${newPresetComplexity}" && "${oldQuality}" -ge "${newQuality}" && "${newPixelFormat}" == "${oldPixelFormat}" ]]; then
        videoEncoding="${videoEncoding} -map ${fileCount}:v:${stream}"
        videoEncoding="${videoEncoding} -codec:v:${index} copy -metadata:s:v:${index} '${metadataCodecName}=${oldCodec}'"
        if [[ -n "${oldLevel}" ]]; then
          videoEncoding="${videoEncoding} -metadata:s:v:${index} '${metadataVideoLevel}=${oldLevel}'"
        fi
        if [[ -n "${oldPixelFormat}" ]]; then
          videoEncoding="${videoEncoding} -metadata:s:v:${index} '${metadataVideoPixelFormat}=${oldPixelFormat}'"
        fi
        if [[ -n "${normalizedOldFrameRate}" && "${normalizedOldFrameRate}" != 'source_fps' ]]; then
          videoEncoding="${videoEncoding} -metadata:s:v:${index} '${metadataVideoFrameRate}=${normalizedOldFrameRate}'"
        fi
        if [[ -n "${oldPreset}" ]]; then
          videoEncoding="${videoEncoding} -metadata:s:v:${index} '${metadataVideoPreset}=${oldPreset}'"
        fi
        if [[ -n "${oldQuality}" ]]; then
          videoEncoding="${videoEncoding} -metadata:s:v:${index} '${metadataVideoQuality}=${oldQuality}'"
        fi
        if [[ -n "${oldProfile}" ]]; then
          videoEncoding="${videoEncoding} -metadata:s:v:${index} '${metadataVideoProfile}=${oldProfile}'"
        fi
        if [[ -n "${oldTune}" ]]; then
          videoEncoding="${videoEncoding} -metadata:s:v:${index} '${metadataVideoTune}=${oldTune}'"
        fi
      else
        videoEncoding="${videoEncoding} -map ${fileCount}:v:${stream}"
        videoEncoding="${videoEncoding} -codec:v:${index} ${newCodec} -metadata:s:v:${index} '${metadataCodecName}=${newCodec}'"
        if [[ -n "${newLevel}" ]]; then
          videoEncoding="${videoEncoding} -level:v:${index} ${newLevel} -metadata:s:v:${index} '${metadataVideoLevel}=${newLevel}'"
        fi
        if [[ -n "${newPixelFormat}" ]]; then
          videoEncoding="${videoEncoding} -pix_fmt:v:${index} ${newPixelFormat} -metadata:s:v:${index} '${metadataVideoPixelFormat}=${newPixelFormat}'"
        fi
        if [[ "${normalizedNewFrameRate}" == 'source_fps' || "${normalizedNewFrameRate}" == "${normalizedOldFrameRate}" ]]; then
          if [[ -n "${normalizedOldFrameRate}" && "${normalizedOldFrameRate}" != 'source_fps' ]]; then
            videoEncoding="${videoEncoding} -metadata:s:v:${index} '${metadataVideoFrameRate}=${normalizedOldFrameRate}'"
          fi
        elif [[ -n "${normalizedNewFrameRate}" ]]; then
          videoEncoding="${videoEncoding} -vf:v:${index} 'fps=fps=${normalizedNewFrameRate}:round=near' -metadata:s:v:${index} '${metadataVideoFrameRate}=${normalizedNewFrameRate}'"
        fi
        if [[ -n "${newPreset}" ]]; then
          videoEncoding="${videoEncoding} -preset:v:${index} ${newPreset} -metadata:s:v:${index} '${metadataVideoPreset}=${newPreset}'"
        fi
        if [[ -n "${newQuality}" ]]; then
          videoEncoding="${videoEncoding} -crf:v:${index} ${newQuality} -metadata:s:v:${index} '${metadataVideoQuality}=${newQuality}'"
        fi
        if [[ -n "${newProfile}" ]]; then
          videoEncoding="${videoEncoding} -profile:v:${index} ${newProfile} -metadata:s:v:${index} '${metadataVideoProfile}=${newProfile}'"
        fi
        if [[ -n "${newTune}" ]]; then
          videoEncoding="${videoEncoding} -tune:v:${index} ${newTune} -metadata:s:v:${index} '${metadataVideoTune}=${newTune}'"
        fi
      fi
      if [[ "${streamCount}" -gt 1 ]]; then
        if [[ -n "${oldTitle}" ]]; then
          videoEncoding="${videoEncoding} -metadata:s:v:${index} '${metadataTitle}=${oldTitle}'"
        fi
        if [[ -n "${oldLanguage}" ]]; then
          if [[ -z "${oldTitle}" && "$(normalizeLanguageFullName "${oldLanguage}")" != 'unknown' ]]; then
            videoEncoding="${videoEncoding} -metadata:s:v:${index} '${metadataTitle}=$(normalizeLanguageFullName "${oldLanguage}")'"
          fi
          videoEncoding="${videoEncoding} -metadata:s:v:${index} '${metadataLanguage}=${oldLanguage}'"
        fi
      fi
      index="$(("${index}" + 1))"
    fi
  done
  echo "${videoEncoding}"
}

getSubtitleEncodingSettings() {
  local baseFile="${1}"
  local allFiles="$(getInputFiles "${baseFile}")"
  local fileCount='0'
  local index='0'
  local inputFile=''

  IFS=$'\n'
  for inputFile in ${allFiles}; do
    local inputFileName="$(getFileName "${inputFile}")"
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
    local newCodecType=''
    local normalizedOldCodecName=''
    local normalizedNewCodecName=''

    for stream in $(seq 0 1 $((${streamCount} - 1))); do
      probeResult="$(echo "${streamList}" | awk "/\[STREAM\]/{f=f+1} f==$((${stream} + 1)){print;}")"
      oldCodec="$(getCodecFromStream "${probeResult}")"
      duration="$(getMetadata 'DURATION' "${probeResult}")"
      oldTitle="$(getMetadata "${metadataTitle}" "${probeResult}")"
      oldLanguage="$(getLanguage "${inputFileName}" "${probeResult}")"

      if [[ "${subtitlesUpdateMethod}" == 'strip' && "$(doesContain "$(normalizeSubtitleCodec "${oldCodec}")" "$(forEach "${newCodec}" ',' 'normalizeSubtitleCodec')" ',')" != 'true' ]]; then
        oldCodec=''
      fi

      if [[ -n "${oldCodec}" && "${duration}" != '00:00:00.000000000' ]]; then
        normalizedOldCodecName="$(normalizeSubtitleCodec "${oldCodec}")"

        IFS=$'\n'
        for newCodec in $(echo "${subtitleCodec}" | sed 's/,/\n/g'); do
          normalizedNewCodecName="$(normalizeSubtitleCodec "${newCodec}")"
          if [[ "${normalizedOldCodecName}" == "${normalizedNewCodecName}" ]]; then
            break
          fi
        done

        if [[ "${normalizedOldCodecName}" != "${normalizedNewCodecName}" ]]; then
          oldCodecType="$(getSubtitleEncodingType "${normalizedOldCodecName}")"
          for newCodec in $(echo "${subtitleCodec}" | sed 's/,/\n/g'); do
            normalizedNewCodecName="$(normalizeSubtitleCodec "${newCodec}")"
            newCodecType="$(getSubtitleEncodingType "${normalizedNewCodecName}")"
            if [[ "${oldCodecType}" == "${newCodecType}" ]]; then
              break
            fi
          done
        fi

        if [[ "${oldCodecType}" != "${newCodecType}" ]]; then
          newCodec='copy'
        fi

        if [[ -z "${newCodec}" || "${newCodec,,}" == "copy" ]] || [[ "${forceRun}" == 'false' && "${normalizedOldCodecName}" == "${normalizedNewCodecName}" ]]; then
          subtitleEncoding="${subtitleEncoding} -map ${fileCount}:s:${stream}"
          subtitleEncoding="${subtitleEncoding} -codec:s:${index} copy -metadata:s:s:${index} '${metadataCodecName}=${oldCodec}'"
        else
          subtitleEncoding="${subtitleEncoding} -map ${fileCount}:s:${stream}"
          subtitleEncoding="${subtitleEncoding} -codec:s:${index} ${newCodec} -metadata:s:s:${index} '${metadataCodecName}=${newCodec}'"
        fi
        if [[ -n "${oldTitle}" ]]; then
          subtitleEncoding="${subtitleEncoding} -metadata:s:s:${index} '${metadataTitle}=${oldTitle}'"
        fi
        if [[ -n "${oldLanguage}" ]]; then
          if [[ -z "${oldTitle}" && "$(normalizeLanguageFullName "${oldLanguage}")" != 'unknown' ]]; then
            subtitleEncoding="${subtitleEncoding} -metadata:s:s:${index} '${metadataTitle}=$(normalizeLanguageFullName "${oldLanguage}")'"
          fi
          subtitleEncoding="${subtitleEncoding} -metadata:s:s:${index} '${metadataLanguage}=${oldLanguage}'"
        fi
        index="$(("${index}" + 1))"
      fi
    done
    fileCount="$(("${fileCount}" + 1))"
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

hasChanges() {
  local arguments="${1}"
  local inputFile="${2}"

  if [[ -n "$(echo "${arguments}" | gawk 'match($0, /^.*(-codec:[vas]:[0-9]+[[:space:]]+([^c]|c[^o]|co[^p]|cop[^y]|copy[^[:space:]])).*$/, m) { print m[1]; }')" ]]; then
    echo 'true'
  elif [[ "$(echo "${arguments}" | grep -o "[[:blank:]]-i[[:blank:]]'[^']*'" | wc -l)" -gt 1 ]]; then
    echo 'true'
  else
    local streamList="$(ffprobe "${inputFile}" -loglevel error -show_streams)"
    local streamCount="$(echo "${streamList}" | grep -o '\[STREAM\]' | wc -l)"
    if [[ "$(echo "${arguments}" | grep -o ' -codec:[vas]:[0-9]* ' | wc -l)" -ne "${streamCount}" ]]; then
      echo 'true'
    else
      echo 'false'
    fi
  fi
}

#-----------------
# Conversion Processing
# -----------------

convert() {
  local inputFile="${1}"
  local outputFile="${2}"
  local pid="${3}"

  local arguments="$(assembleArguments "${inputFile}" "${outputFile}")"

  debug "ffmpeg ${arguments}"
  if [[ "${arguments}" =~ .*-codec:v:0.* ]]; then
    if [[ "${metadataRun}" == 'true' || "$(hasChanges "${arguments}" "${inputFile}")" == 'true' ]]; then
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

  if [[ "$dryRun" == "true" ]]; then
    finalSize="$(ls -al "${inputFile}" | awk '{print $5}')"
    debug "convert \"${inputFile}\" \"${tmpFile}\" \"${pid}\""
    debug "ffmpeg $(assembleArguments "${inputFile}" "${outputFile}")"
    if [[ "$(hasChanges "$(assembleArguments "${inputFile}" "${outputFile}")" "${outputFile}")" == 'true' ]]; then
      debug "Has Changes; Will Convert"
    else
      debug "No Changes detected; Will not convert"
    fi
    if [[ "$(echo "${inputFile}" | sed 's/\(.*\)\..*/\1/')" == "$(echo "${outputFile}" | sed 's/\(.*\)\..*/\1/')" ]]; then
      local fileFromList=''
      IFS=$'\n'
      for fileFromList in $(getInputFiles "${inputFile}"); do
        debug "rm ${fileFromList}"
      done
    fi
    debug "mv \"$tmpFile\" \"${outputFile}\""
    debug "chown \"${owner}:${group}\" -v \"${outputFile}\""
    debug "chmod \"${mod}\" -v \"${outputFile}\""
    debug "File '${inputFile}' reduced to $((${finalSize} / 1024 / 1204))MiB from original size $((${originalSize} / 1024 / 1204))MiB"
  else
    convert "${inputFile}" "${tmpFile}" "${pid}"
    finalSize="$(ls -al "${tmpFile}" | awk '{print $5}')"
    if [[ "${hasCodecChanges}" == 'false' ]]; then
      trace "Not processing file '${inputFile}', as no changes would be made."
    elif [[ "${hasCodecChanges}" == 'conflict' ]]; then
      info "Cannot achieve lock on file '${inputFile}', Skipping."
    elif [[ -f "${tmpFile}" && "${convertErrorCode}" == "0" && -n "${finalSize}" && "${finalSize}" -gt 0 && -n "${originalSize}" && "$((${originalSize} / ${finalSize}))" -lt 1000 ]]; then
      if [[ "$(echo "${inputFile}" | sed 's/\(.*\)\..*/\1/')" == "$(echo "${outputFile}" | sed 's/\(.*\)\..*/\1/')" ]]; then
        local fileFromList=''
        IFS=$'\n'
        for fileFromList in $(getInputFiles "${inputFile}"); do
          rm "${fileFromList}"
        done
      fi
      mv "${tmpFile}" "${outputFile}"
      chown "${owner}:${group}" "${outputFile}"
      chmod "${mod}" "${outputFile}"
      trace "File '${inputFile}' reduced to $((${finalSize} / 1024 / 1204))MiB from original size $((${originalSize} / 1024 / 1204))MiB"
    else
      warn "Failed to compress '${inputFile}'. Exit Code '${convertErrorCode}' Final Size '${finalSize}' Original Size '${originalSize}'"
      rm "${tmpFile}"
    fi
  fi
}

convertAll() {
  local inputDirectory="$(normalizeDirectory "${1}")"
  local tmpDirectory="$(normalizeDirectory "${2}")"
  local outputDirectory="$(normalizeDirectory "${3}")"
  local pid="${4}"
  local inputDirectoryLength="$(echo "${inputDirectory}" | wc -c)"
  local currentDirectory=''
  local currentFileName=''
  local currentExt=''
  local tmpFile=''
  local outputFile=''
  local inputFile=''
  local sortingType="$(if [[ "${sortBy^^}" =~ ^.*'DATE'$ ]]; then echo '%T@ %p\n'; else echo '%s %p\n'; fi)"
  local sortingOrder="$(if [[ "${sortBy^^}" =~ ^'REVERSE'.*$ ]]; then echo ' -n'; else echo '-rn'; fi)"
  local allInputFiles="$(find "${inputDirectory}" -type f -printf "${sortingType}" | sort ${sortingOrder} | awk '!($1="")' | sed 's/^ *//g' | xargs -d "\n" file -N -i | sed -n 's!: video/[^:]*$!!p')"
  local fileCount="$(echo "${allInputFiles}" | wc -l)"

  info "Processing ${fileCount} file"
  IFS=$'\n'
  for inputFile in ${allInputFiles[@]}; do
    if [[ -n "${pidLocation}" && "${pid}" != "$(cat "${pidLocation}")" ]]; then
      info "PID mismatch; Stopping"
      break
    fi

    currentDirectory="$(getDirectory "${inputFile}")"
    currentFileName="$(getFileName "${inputFile}")"
    currentExt="$(getExtension "${inputFile}")"
    if [[ "${currentExt}" != "part" ]]; then
      tmpFile="${tmpDirectory}/${currentFileName}${outputExtension}"
      if [[ -f "${tmpFile}" ]]; then
        rm -f "${tmpFile}"
      fi
      if [[ -z "${outputDirectory}" ]]; then
        outputFile="${currentDirectory}/${currentFileName}${outputExtension}"
      else
        outputFile="${outputDirectory}${currentDirectory:${inputDirectoryLength}}/${currentFileName}${outputExtension}"
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

#-----------------
# Basic Commands
# -----------------

startLocal() {
  local pid=''

  if [[ "$(isRunning)" == "true" ]]; then
    echo "Daemon is already running"
  else
    echo "Starting On Local Process"
    pid="$$"
    if [[ -n "${pidLocation}" ]]; then
      echo "${pid}" > "${pidLocation}"
    fi
    if [[ -n "${logFile}" ]]; then
      info "$(getCommand "$command")" >> "${logFile}"
    else
      info "$(getCommand "$command")"
    fi
    mkdir -p "${tmpDirectory}/${pid}"

    if [[ -n "${logFile}" ]]; then
      convertAll "${inputDirectory}" "${tmpDirectory}/${pid}" "${outputDirectory}" "${pid}" >> "${logFile}"
    else
      convertAll "${inputDirectory}" "${tmpDirectory}/${pid}" "${outputDirectory}" "${pid}"
    fi
  fi
}

startDaemon() {
  local var=''

  if [[ "$(isRunning)" == "true" ]]; then
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

  if [[ -z "${pidLocation}" ]]; then
    echo 'unknown'
  elif [[ -f "${pidLocation}" ]]; then
    pid="$(getFirst "$(cat "${pidLocation}")" '')"
    if [[ "$(isPidRunning "${pid}")" == 'true' ]]; then
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
  if [[ "$(isRunning)" == "true" ]]; then
    echo "-1" >> "${pidLocation}"
  else
    echo "Daemon is not running"
  fi
}

runCommand() {
  local command="${1}"

  if [[ -n "${additionalParameters}" ]]; then
    warn "Unused Values: ${additionalParameters}"
  fi
  if [[ "$(getPresetComplexityOrder "${videoPreset}")" -lt 1 ]]; then
    error "--video-preset is an invalid value"
    command="badVariable"
  fi

  if [[ "${command}" == "active" ]]; then
    echo "$(isRunning)"
  elif [[ "${command}" == "start-local" ]]; then
    info "$(getCommand "${command}")"
    startLocal
  elif [[ "${command}" == "start" ]]; then
    info "$(getCommand "${command}")"
    startDaemon
  elif [[ "${command}" == "output" ]]; then
    echo "$(tail -n 1000 "${logFile}")"
  elif [[ "${command}" == "stop" ]]; then
    info "$(getCommand "${command}")"
    info "$(stopProcess)"
  else
    info "$(getCommand "${1}")"
    info "$(getUsage)"
    exit 1
  fi
}

runCommand "${command}"