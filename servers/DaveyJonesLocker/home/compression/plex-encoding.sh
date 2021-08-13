#!/bin/bash

#-----------------
# Configurable Default Options
#-----------------

inputDirectory="${HOME}/Videos" #/home/public/Videos/TV/Sonarr
outputDirectory=''        #/home/public/Videos/TV/Sonarr
tmpDirectory='/tmp'
logLevel='ALL'
logFile="${HOME}/encoding.results"
dryRun='false'
forceRun='false'
metadataRun='false'
deleteMetadata='false'
pidLocation="${HOME}/plex-encoding.pid"
threadCount=4 # 0 is unlimited
audioCodec='aac'
audioUpdateMethod='convert'     # convert, export, delete
audioImportExtension='.mp3,.aac,.ac3' # comma list of audio extensions
# shellcheck disable=SC2016
audioExportExtension='.${title}.${stream}.${language}'
deleteInputFiles='false'
fileIgnoreRegex='.*\/(Downloads?|Uploads?|Imports?|To Import|Music)\/.*'
videoCodec='libx265'        # libx264, libx265
videoUpdateMethod='convert' # convert, export, delete
videoPreset='fast'          # ultrafast, superfast, veryfast, fast, medium, slow, slower, veryslow, placebo
videoProfile='high'         # For x264 baseline, main, high | For x265 main, high
videoPixelFormat='yuv420p,yuv420p10le'
videoPixelFormatExclusionOrder='depth,channel,compression,bit,format'
videoPixelFormatPreferenceOrder='depth,channel,compression,bit,format'
videoQuality=20               # 1-50, lower is better quailty
videoLevel='4.1'              # 1.0 to 6.1
videoFrameRate='copy'         # Any Fraction, copy, NTSC (29.97), PAL (25), FILM (24), NTSC_FILM (23.97)
videoTune='fastdecode'        # animation, fastdecode, film, grain, stillimage, zerolatency
# shellcheck disable=SC2016
videoExportExtension='.${title}.${stream}.${language}'
subtitlesUpdateMethod='export' # convert, export, delete
subtitleCodec='srt'           # Comma list of allowed formats
subtitleImportExtension='.srt'      # Comma list of subtitle extensions
# shellcheck disable=SC2016
subtitleExportExtension='.${title}.${stream}.${language}'
bitratePerAudioChannel=98304  # 65536 is default
videoOutputExtension='.mkv'
sortBy='size' # date, name, size, reverse-date, reverse-name, reverse-size

#-----------------
# Input Values
#-----------------

path="${0}"
command="${1}"; shift
options="${*}"

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

passedParameters=''
additionalParameters=''
while true; do
  case "${1}" in
    --audio) audioCodec="${2}"; shift 2 ;;
    --audio-bitrate) bitratePerAudioChannel="${2}"; shift 2 ;;
    --audio-export-extension) audioExportExtension="${2}"; shift 2 ;;
    --audio-import-extension) audioImportExtension="${2}"; shift 2 ;;
    --audio-update) audioUpdateMethod="${2}"; shift 2 ;;
    --delete-input) deleteInputFiles='true'; shift ;;
    --delete-metadata) deleteMetadata='true'; shift ;;
    --dry) dryRun='true'; shift ;;
    --ext) videoOutputExtension="${2}"; shift 2 ;;
    --force) forceRun='true'; shift ;;
    --ignore) fileIgnoreRegex="${2}"; shift 2 ;;
    --input) inputDirectory="${2}"; shift 2 ;;
    --log) logFile="${2}"; shift 2 ;;
    --log-level) logLevel="${2}"; shift 2 ;;
    --metadata) metadataRun='true'; shift ;;
    --output) outputDirectory="${2}"; shift 2 ;;
    --pid) pidLocation="${2}"; shift 2 ;;
    --sort) sortBy="${2}"; shift 2 ;;
    --subtitle) subtitleCodec="${2}"; shift 2 ;;
    --subtitle-export-extension) subtitleExportExtension="${2}"; shift 2 ;;
    --subtitle-import-extension) subtitleImportExtension="${2}"; shift 2 ;;
    --subtitle-update) subtitlesUpdateMethod="${2}"; shift 2 ;;
    --thread) threadCount="${2}"; shift 2 ;;
    --tmp) tmpDirectory="${2}"; shift 2 ;;
    --video) videoCodec="${2}"; shift 2 ;;
    --video-export-extension) videoExportExtension="${2}"; shift 2 ;;
    --video-level) videoLevel="${2}"; shift 2 ;;
    --video-pixel) videoPixelFormat="${2}"; shift 2 ;;
    --video-pixel-exclusion) videoPixelFormatExclusionOrder="${2}"; shift 2 ;;
    --video-pixel-preference) videoPixelFormatPreferenceOrder="${2}"; shift 2 ;;
    --video-preset) videoPreset="${2}"; shift 2 ;;
    --video-profile) videoProfile="${2}"; shift 2 ;;
    --video-quality) videoQuality="${2}"; shift 2 ;;
    --video-rate) videoFrameRate="${2}"; shift 2 ;;
    --video-tune) videoTune="${2}"; shift 2 ;;
    --video-update) videoUpdateMethod="${2}"; shift 2 ;;
    --) shift; passedParameters="${*}"; break ;;
    *) if [[ "${#@}" -le 1 ]]; then break; else additionalParameters="${additionalParameters} ${1}"; shift; fi ;;
  esac
done

if [[ "${outputDirectory}" == "${inputDirectory}" ]]; then
  outputDirectory=''
fi

case "${logLevel^^}" in
  NONE) logLevelValue=0 ;;
  ERROR) logLevelValue=1 ;;
  WARN) logLevelValue=2 ;;
  INFO) logLevelValue=3 ;;
  DEBUG) logLevelValue=4 ;;
  TRACE) logLevelValue=5 ;;
  ALL) logLevelValue=6 ;;
  *) logLevelValue=6 ;;
esac

shopt -s expand_aliases
# shellcheck disable=SC2139
alias getSubtitleExportExtension="echo \"${subtitleExportExtension}\" | regex 's/\//|/g'"
# shellcheck disable=SC2139
alias getVideoExportExtension="echo \"${videoExportExtension}\" | regex 's/\//|/g'"
# shellcheck disable=SC2139
alias getAudioExportExtension="echo \"${audioExportExtension}\" | regex 's/\//|/g'"

getCommand() {
  local command="${1^^}"
  echo "'${path}' '${command}'" \
    "--audio '${audioCodec}'" \
    "--audio-bitrate '${bitratePerAudioChannel}'" \
    "--audio-export-extension '${audioExportExtension}'" \
    "--audio-import-extension '${audioImportExtension}'" \
    "--audio-update '${audioUpdateMethod}'" \
    "$(if [ "${deleteInputFiles}" = true ]; then echo '--delete-input'; fi)" \
    "$(if [ "${deleteMetadata}" = true ]; then echo '--delete-metadata'; fi)" \
    "$(if [ "${dryRun}" = true ]; then echo '--dry'; fi)" \
    "--ext '${videoOutputExtension}'" \
    "$(if [ "${forceRun}" = true ]; then echo '--force'; fi)" \
    "--ignore '${fileIgnoreRegex}'" \
    "--input '${inputDirectory}'" \
    "--log '${logFile}'" \
    "--log-level '${logLevel}'" \
    "$(if [ "${metadataRun}" = true ]; then echo '--metadata'; fi)" \
    "--output '${outputDirectory}'" \
    "--pid '${pidLocation}'" \
    "--sort '${sortBy}'" \
    "--subtitle '${subtitleCodec}'" \
    "--subtitle-export-extension '${subtitleExportExtension}'" \
    "--subtitle-import-extension '${subtitleImportExtension}'" \
    "--subtitle-update '${subtitlesUpdateMethod}'" \
    "--thread '${threadCount}'" \
    "--tmp '${tmpDirectory}'" \
    "--video '${videoCodec}'" \
    "--video-export-extension '${videoExportExtension}'" \
    "--video-level '${videoLevel}'" \
    "--video-pixel '${videoPixelFormat}'" \
    "--video-pixel-exclusion '${videoPixelFormatExclusionOrder}'" \
    "--video-pixel-preference '${videoPixelFormatPreferenceOrder}'" \
    "--video-preset '${videoPreset}'" \
    "--video-profile '${videoProfile}'" \
    "--video-quality '${videoQuality}'" \
    "--video-rate '${videoFrameRate}'" \
    "--video-tune '${videoTune}'" \
    "--video-update '${videoUpdateMethod}'" \
    "${additionalParameters[*]} -- ${passedParameters[*]}"
}

getUsage() {
  echo "Usage \"$0 [active|start|start-local|output-[error|warn|info|debug|trace|all]|stop]" \
    "[--audio List of allowed audio codecs {aac,mp3}}]" \
    "[--audio-bitrate Bit rate per an audio channel {98304}]" \
    "[--audio-export-extension Audio extension to export to when run in export mode {.audio}]" \
    "[--audio-import-extension List of audio extensions to read {.mp3,.acc,.ac3}]" \
    "[--audio-update Method to use for updating audio {convert|export|delete}]" \
    "[--delete-input Will delete input files after convert. Note video file always deletes if input and output are the same location]" \
    "[--delete-metadata Will remove old metadata from the files]" \
    "[--dry Will output what commands it will execute without modifying anything]" \
    "[--ext The extension of the output file {copy|.mp4|.mkv}]" \
    "[--force Will always convert, even if codecs matches]" \
    "[--ignore Regex match of file names with directory to ignore {.*\/(Downloads?|Uploads?|Imports?|To Import|Music)\/.*}]" \
    "[--input Directory of files to process {~/Video}]" \
    "[--output Output directory of the processed files, blank will cause replacement {~/ProcessedVideo}]" \
    "[--log Location of where to output the logs {~/encoding.results}]" \
    "[--log-level The level which to log {ALL|TRACE|DEBUG|INFO|WARN|ERROR|NONE}]" \
    "[--metadata Will always update files in order to update metadata]" \
    "[--pid Location of pid file {~/plex-encoding.pid}]" \
    "[--sort What order to process the files in {date|size|reverse-date|reverse-size}]" \
    "[--subtitle List of allowed subtitle codecs {srt,ass}]" \
    "[--subtitle-export-extension Subtitle extension to export to when run in export mode {.subtitles}]" \
    "[--subtitle-import-extension List of subtitle extensions to read {.srt,.ass}]" \
    "[--subtitle-update Method to use for updating subtitles {convert|export|delete}]" \
    "[--thread Thread to use while processing {3}]" \
    "[--tmp tmpDirectory Temporary directory to store processing video files {/tmp}]" \
    "[--video videoCodec List of allowed video codecs {libx264,libx265}]" \
    "[--video-export-extension Video extension to export to when run in export mode {.video}]" \
    "[--video-level Maximum Allowed Video Level {4.1}]" \
    "[--video-pixel List of allowed pixel formats {yuv420p,yuv420p10le}]" \
    "[--video-pixel-exclusion videoPixelFormatExclusionOrder {depth,channel,compression,bit,format}]" \
    "[--video-pixel-preference videoPixelFormatPreferenceOrder {depth,channel,compression,bit,format}]" \
    "[--video-preset The preset to use when processing the video {ultrafast|superfast|veryfast|fast|medium|slow|slower|veryslow|placebo}]" \
    "[--video-profile The profile to use when processing the video {baseline|main|high}]" \
    "[--video-quality The quality to use when processing the video {1-50}]" \
    "[--video-rate The frame rate to use when processing the file {any_faction|ntsc|ntsc_film|pal|film}]" \
    "[--video-tune The tune parameter to use when processing the file {animation|fastdecode|film|grain|stillimage|zerolatency}]" \
    "[--video-update Method to use for updating video {convert|export|delete}]"
}

#-----------------
# Logging
#-----------------

error() {
  if [[ "${logLevelValue}" -ge 1 ]]; then
    log "[ERROR] ${*}"
  fi
}

warn() {
  if [[ "${logLevelValue}" -ge 2 ]]; then
    log "[WARN] ${*}"
  fi
}

info() {
  if [[ "${logLevelValue}" -ge 3 ]]; then
    log "[INFO] ${*}"
  fi
}

debug() {
  if [[ "${logLevelValue}" -ge 4 ]]; then
    log "[DEBUG] ${*}"
  fi
}

trace() {
  if [[ "${logLevelValue}" -ge 5 ]]; then
    log "[TRACE] ${*}"
  fi
}

log() {
  if [[ -n "${logFile}" ]]; then
    echo "[$(getTime)] ${*}" >> "${logFile}"
  else
    echo "[$(getTime)] ${*}"
  fi
}

getTime() {
  date +%FT%TZ
}

#-----------------
# File and Folder Handling
#-----------------

getExtension() {
  local fileNameWithExt=''
  fileNameWithExt="$(basename "${1}")"

  echo "${fileNameWithExt##*.}"
}

getFileName() {
  local fileNameWithExt=''
  fileNameWithExt="$(basename "${1}")"

  echo "${fileNameWithExt}" | sed 's/\(.*\)\..*/\1/'
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
  normalizeDirectory "${directory}"
}

#-----------------
# File Locking
# -----------------

lockFile() {
  local inputFile="${1}"
  local pid="${2}"

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

  if [[ -f "${inputFile}${lockfileExtension}" ]]; then
    if [[ "$(cat "${inputFile}${lockfileExtension}")" == "${pid}" ]]; then
      rm -f "${inputFile}${lockfileExtension}"
    fi
  fi
}

#-----------------
# List Functions
#-----------------

getListFirstValue() {
  local list="${1}"
  local delimiter="${2}"

  if [[ -n "${delimiter}" ]]; then
    echo "${list}" | sed "s/${delimiter}/\\n/g" | awk 'NR==1{print}'
  else
    echo "${list}" | awk 'NR==1{print}'
  fi
}

getListFirstMatch() {
  local value="${1}"
  local list="${2}"
  local delimiter="${3}"
  local normalizer="${4:-echo}"
  local default="${5}"
  local normalValue=''
  local listValue=''

  normalValue="$(${normalizer} "${value}")"

  if [[ -n "${delimiter}" ]]; then
    list="$(echo "${list}" | sed "s/${delimiter}/\\n/g")"
  fi

  IFS=$'\n'
  for listValue in ${list}; do
    listValue="$(${normalizer} "${listValue}")"
    if [[ "${normalValue}" == "${listValue}" ]]; then
      break
    fi
  done

  if [[ "${normalValue}" == "${listValue}" ]]; then
    echo "${value}"
  else
    echo "${default}"
  fi
}

doesListContain() {
  if [[ -n "$(getListFirstMatch "${1}" "${2}" "${3}" "${4}" '')" ]]; then
    echo 'true'
  fi
}

forEach() {
  local list="${1}"
  local delimiter="${2}"
  local normalizer="${3}"
  local value=''
  local newList=''
  local newValue=''

  if [[ -n "${delimiter}" ]]; then
    list="$(echo "${list}" | sed "s/${delimiter}/\\n/g")"
  fi

  IFS=$'\n'
  for value in ${list}; do
    newValue="$(${normalizer} "${listValue}")"
    if [[ -n "${newValue}" ]]; then
      if [[ -n "${newList}" ]]; then
        newList="${newList}${delimiter}$(${normalizer} "${listValue}")"
      else
        newList="$(${normalizer} "${listValue}")"
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

  local quotient="$((numerator / denominator))"
  local remainder="$((numerator % denominator))"
  local precisionQuotient="$(( ( (10 ** precision) * (remainder)) / denominator))"
  local precisionRemainder="$(( ( (10 ** precision) * (remainder)) % denominator))"

  if [[ "${rounding::4}" == 'half' ]]; then
    if [[ "${precisionRemainder}" -gt '0' ]]; then
      local roundingQuotient="$((denominator / precisionRemainder))"
      local roundingRemainder="$((denominator % precisionRemainder))"
      if [[ "${roundingQuotient}" -lt '2' ]]; then
        precisionQuotient="$((precisionQuotient + 1))"
      elif [[ "${roundingQuotient}" -eq '2' && "${roundingRemainder}" -eq '0' ]]; then
        if [[ "${rounding}" == 'half' || "${rounding}" == 'halfup' || "${rounding}" == 'half-up' ]]; then
          precisionQuotient="$((precisionQuotient + 1))"
        fi
      fi
    fi
  elif [[ "${rounding}" == 'ceil' || "${rounding}" == 'ceiling' ]]; then
    if [[ "${precisionRemainder}" -gt '0' ]]; then
      precisionQuotient="$((precisionQuotient + 1))"
    fi
  fi

  if [[ "${precisionQuotient}" -ge "$((10 ** "${precision}"))" ]]; then
    quotient="$((quotient + 1))"
    precisionQuotient='0'
  fi

  if [[ "${precision}" -eq 0 ]]; then
    printf "%d" "${quotient}"
  else
    printf "%d.%0${precision}d" "${quotient}" "${precisionQuotient}"
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
# RegEx Functions
#-----------------

regexFind() {
  local regex="${1}"
  local value="${2}"

  if [[ -p /dev/stdin ]]; then
    cat - | grep -oE "${regex}"
  else
    echo "${value}" | grep -oE "${regex}"
  fi
}

regexFindMultiline() {
  local regex="${1}"
  local value="${2}"

  if [[ -p /dev/stdin ]]; then
    cat - | tr -d '\r' | tr '\n' '\r' | grep -oE "${regex}" | tr '\r' '\n'
  else
    echo "${value}" | tr -d '\r' | tr '\n' '\r' | grep -oE "${regex}" | tr '\r' '\n'
  fi
}

regexCount() {
  local regex="${1}"
  local value="${2}"

  if [[ -p /dev/stdin ]]; then
    value="$(cat - | regexFind "${regex}")"
  else
    value="$(regexFind "${regex}" "${value}")"
  fi

  if [[ -n "${value}" ]]; then
    echo "${value}" | wc -l
  else
    echo '0'
  fi
}

regexCountMultiline() {
  local regex="${1}"
  local value="${2}"

  if [[ -p /dev/stdin ]]; then
    value="$(cat - | regexFindMultiline "${regex}")"
  else
    value="$(regexFindMultiline "${regex}" "${value}")"
  fi

  if [[ -n "${value}" ]]; then
    echo "${value}" | wc -l
  else
    echo '0'
  fi
}

regex() {
  local regex="${1}"
  local value="${2}"

  if [[ -p /dev/stdin ]]; then
    cat - | sed -E "${regex}"
  else
    echo "${value}" | sed -E "${regex}"
  fi
}

regexMultiline() {
  local regex="${1}"
  local value="${2}"

  if [[ -p /dev/stdin ]]; then
    cat - | tr -d '\r' | tr '\n' '\r' | sed -E "${regex}" | tr '\r' '\n'
  else
    echo "${value}" | tr -d '\r' | tr '\n' '\r' | sed -E "${regex}" | tr '\r' '\n'
  fi
}

trim() {
  local value="${1}"
  local trimChar="${2:-\s}"

  if [[ -p /dev/stdin ]]; then
    cat - | regexMultiline "${regex}"
  else
    regexMultiline "s/(^${trimChar}+|${trimChar}+$)//g" "${value}"
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

getCodecAudioExtension() {
  local codecName="${1,,}"
  case "$(normalizeVideoCodec "${codecName}")" in
    aac ) echo '.aac' ;;
    ac3 ) echo '.ac3' ;;
    mp3 ) echo '.mp3' ;;
    *) echo '.aac' ;;
  esac
}

normalizeVideoCodec() {
  local codecName="${1,,}"
  case "${codecName}" in
    libx265 | h265 | x265 | hevc | hevc_v4l2m2m | hevc_vaapi | hevc_nvenc) echo 'hevc' ;;
    libx264 | h264 | x264 | libx264rgb | h264_v4l2m2m | h264_vaapi | h264_omx | h264_nvenc) echo 'h264' ;;
    *) echo "${codecName}" ;;
  esac
}

getCodecVideoExtension() {
  local codecName="${1,,}"
  case "$(normalizeVideoCodec "${codecName}")" in
    hevc | h264 ) echo '.mkv' ;;
    *) echo '.mkv' ;;
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

getCodecSubtitleExtension() {
  local codecName="${1,,}"
  case "$(normalizeSubtitleCodec "${codecName}")" in
    subrip ) echo '.srt' ;;
    dvbsub ) echo '.sub' ;;
    dvdsub ) echo '.sub' ;;
    pgssub ) echo '.sub' ;;
    cc_dec ) echo '.sub' ;;
    libzvbi_teletextdec) echo '.sub' ;;
    ass) echo 'ass' ;;
    *) echo '.sub' ;;
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
  local fraction=''

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
  elif [[ "$(regexCount '/' "${frameRate}")" -eq 1 ]]; then
    fraction="$(divide "$(regex 's/\/.*//' "${frameRate}")" "$(regex 's/.*\///' "${frameRate}")" '2' 'floor')"
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
  language="$(echo "${language}" | awk '{print $1}')"
  case "${language}" in
    ar | ara | arb | arabic) echo 'Arabic' ;;
    bn | ben | bengali) echo 'Bengali' ;;
    cmn | zho-cmn | mandarin) echo 'Mandarin' ;;
    de | ger | deu | german) echo 'German' ;;
    en | eng | english | american) echo 'English' ;;
    es | spa | spanish) echo 'Spanish' ;;
    fr | fre | fra | french) echo 'French' ;;
    hi | hin | hindi) echo 'Hindi' ;;
    hr | hrv | croatian) echo 'Croatian' ;;
    in | ind | indonesian) echo 'Indonesian' ;;
    it | ita | italian) echo 'Italian' ;;
    jp | jpn | japanese) echo 'Japanese' ;;
    ko | kor | korean) echo 'Korean' ;;
    pt | por | portuguese) echo 'Portuguese' ;;
    ru | rus | russian) echo 'Russian' ;;
    ro | ron | rum | romanian) echo 'Romanian' ;;
    zh | chi | zho | chinese) echo 'Chinese' ;;
    *) echo 'Undetermined' ;;
  esac
}

normalizeLanguage() {
  local language="${1,,}"
  language="$(echo "${language}" | awk '{print $1}')"
  case "${language}" in
    ar | ara | arb | arabic) echo 'ara' ;;
    bn | ben | bengali) echo 'ben' ;;
    cmn | zho-cmn | mandarin) echo 'cmn' ;;
    de | ger | deu | german) echo 'deu' ;;
    en | eng | english | american) echo 'eng' ;;
    es | spa | spanish) echo 'spa' ;;
    fr | fre | fra | french) echo 'fra' ;;
    hi | hin | hindi) echo 'hin' ;;
    hr | hrv | croatian) echo 'hrv' ;;
    in | ind | indonesian) echo 'ind' ;;
    it | ita | italian) echo 'ita' ;;
    jp | jpn | japanese) echo 'jpn' ;;
    ko | kor | korean) echo 'kor' ;;
    pt | por | portuguese) echo 'por' ;;
    ru | rus | russian) echo 'rus' ;;
    ro | ron | rum | romanian) echo 'ron' ;;
    zh | chi | zho | chinese) echo 'zho' ;;
    *) echo 'und' ;;
  esac
}

normalizeVideoLevel() {
  local level="${1,,}"
  if [[ -n "${level}" ]]; then
    if [[ "${level}" == '1b' ]]; then
      level='10'
    elif [[ "$(regexCount '\.' "${level}")" -gt 0 ]]; then
      level="$(regex 's/\.//' "${level}")"
    elif [[ "${level}" -lt 10 ]]; then
      level="$((level * 10))"
    fi
  fi

  if [[ -n "${level}" && "${level}" -ge 10 ]]; then
    echo "${level}"
  fi
}

#-----------------
# Value Transformation
#-----------------

getChannelNaming() {
  local channelCount="${1}"
  case "${channelCount,,}" in
    1 | '1.0' | mono) echo 'Mono' ;;
    2 | '2.0' | stereo) echo 'Stereo' ;;
    3 | '2.1') echo '2.1' ;;
    4 | '4.0') echo '4.0' ;;
    5 | '4.1') echo '4.1' ;;
    6 | '5.1') echo '5.1' ;;
    8 | '7.1') echo '7.1' ;;
    9 | '7.2') echo '7.2' ;;
    10 | '9.1') echo '9.1' ;;
    11 | '9.2') echo '9.2' ;;
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
    nv20be | nv20le) echo 'nv' ;;
    nv24 | nv42) echo 'nv' ;;
    p010be | p010le) echo 'p01' ;;
    p016be | p016le) echo 'p01' ;;
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
    yuva422p9be | yuva422p9le) echo 'yuv' ;;
    yuva440p9be | yuva440p9le) echo 'yuv' ;;
    yuva444p9be | yuva444p9le) echo 'yuv' ;;
    gray10be | gray10le) echo 'rgb' ;;
    gbrp10be | gbrp10le) echo 'rgb' ;;
    gbrap10be | gbrap10le) echo 'rgb' ;;
    yuv420p10be | yuv420p10le) echo 'yuv' ;;
    yuv422p10be | yuv422p10le) echo 'yuv' ;;
    yuv440p10be | yuv440p10le) echo 'yuv' ;;
    yuv444p10be | yuv444p10le) echo 'yuv' ;;
    yuva420p10be | yuva420p10le) echo 'yuv' ;;
    yuva422p10be | yuva422p10le) echo 'yuv' ;;
    yuva440p10be | yuva440p10le) echo 'yuv' ;;
    yuva444p10be | yuva444p10le) echo 'yuv' ;;
    gray12be | gray12le) echo 'gray' ;;
    xyz12be | xyz12le | gbrp12be | gbrp12le) echo 'rgb' ;;
    gbrap12be | gbrap12le) echo 'rgb' ;;
    yuv420p12be | yuv420p12le) echo 'yuv' ;;
    yuv422p12be | yuv422p12le) echo 'yuv' ;;
    yuv440p12be | yuv440p12le) echo 'yuv' ;;
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
    bayer_bggr16be | bayer_bggr16le | bayer_rggb16be | bayer_rggb16le | bayer_gbrg16be | bayer_gbrg16le | bayer_grbg16be | bayer_grbg16le) echo 'bayer' ;;
    yuv420p16be | yuv420p16le) echo 'yuv' ;;
    yuv422p16be | yuv422p16le) echo 'yuv' ;;
    yuv440p16be | yuv440p16le) echo 'yuv' ;;
    yuv444p16be | yuv444p16le) echo 'yuv' ;;
    yuva420p16be | yuva420p16le) echo 'yuv' ;;
    yuva422p16be | yuva422p16le) echo 'yuv' ;;
    ayuv64be | ayuv64le | yuva444p16be | yuva444p16le) echo 'yuv' ;;
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
    nv20be | nv20le) echo '8' ;;
    nv24 | nv42) echo '8' ;;
    p010be | p010le) echo '8' ;;
    p016be | p016le) echo '8' ;;
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
    yuva422p9be | yuva422p9le) echo '9' ;;
    yuva440p9be | yuva440p9le) echo '9' ;;
    yuva444p9be | yuva444p9le) echo '9' ;;
    gray10be | gray10le) echo '10' ;;
    gbrp10be | gbrp10le) echo '10' ;;
    gbrap10be | gbrap10le) echo '10' ;;
    yuv420p10be | yuv420p10le) echo '10' ;;
    yuv422p10be | yuv422p10le) echo '10' ;;
    yuv440p10be | yuv440p10le) echo '10' ;;
    yuv444p10be | yuv444p10le) echo '10' ;;
    yuva420p10be | yuva420p10le) echo '10' ;;
    yuva422p10be | yuva422p10le) echo '10' ;;
    yuva440p10be | yuva440p10le) echo '10' ;;
    yuva444p10be | yuva444p10le) echo '10' ;;
    gray12be | gray12le) echo '12' ;;
    xyz12be | xyz12le | gbrp12be | gbrp12le) echo '12' ;;
    gbrap12be | gbrap12le) echo '12' ;;
    yuv420p12be | yuv420p12le) echo '12' ;;
    yuv422p12be | yuv422p12le) echo '12' ;;
    yuv440p12be | yuv440p12le) echo '12' ;;
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
    bayer_bggr16be | bayer_bggr16le | bayer_rggb16be | bayer_rggb16le | bayer_gbrg16be | bayer_gbrg16le | bayer_grbg16be | bayer_grbg16le) echo '16' ;;
    yuv420p16be | yuv420p16le) echo '16' ;;
    yuv422p16be | yuv422p16le) echo '16' ;;
    yuv440p16be | yuv440p16le) echo '16' ;;
    yuv444p16be | yuv444p16le) echo '16' ;;
    yuva420p16be | yuva420p16le) echo '16' ;;
    yuva422p16be | yuva422p16le) echo '16' ;;
    ayuv64be | ayuv64le | yuva444p16be | yuva444p16le) echo '16' ;;
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
    nv20be | nv20le) echo '442' ;;
    nv24 | nv42) echo '444' ;;
    p010be | p010le) echo '420' ;;
    p016be | p016le) echo '444' ;;
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
    yuva422p9be | yuva422p9le) echo '422' ;;
    yuva440p9be | yuva440p9le) echo '440' ;;
    yuva444p9be | yuva444p9le) echo '444' ;;
    gray10be | gray10le) echo '444' ;;
    gbrp10be | gbrp10le) echo '444' ;;
    gbrap10be | gbrap10le) echo '444' ;;
    yuv420p10be | yuv420p10le) echo '420' ;;
    yuv422p10be | yuv422p10le) echo '422' ;;
    yuv440p10be | yuv440p10le) echo '440' ;;
    yuv444p10be | yuv444p10le) echo '444' ;;
    yuva420p10be | yuva420p10le) echo '420' ;;
    yuva422p10be | yuva422p10le) echo '422' ;;
    yuva440p10be | yuva440p10le) echo '440' ;;
    yuva444p10be | yuva444p10le) echo '444' ;;
    gray12be | gray12le) echo '444' ;;
    xyz12be | xyz12le | gbrp12be | gbrp12le) echo '444' ;;
    gbrap12be | gbrap12le) echo '444' ;;
    yuv420p12be | yuv420p12le) echo '420' ;;
    yuv422p12be | yuv422p12le) echo '422' ;;
    yuv440p12be | yuv440p12le) echo '440' ;;
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
    bayer_bggr16be | bayer_bggr16le | bayer_rggb16be | bayer_rggb16le | bayer_gbrg16be | bayer_gbrg16le | bayer_grbg16be | bayer_grbg16le) echo '444' ;;
    yuv420p16be | yuv420p16le) echo '420' ;;
    yuv422p16be | yuv422p16le) echo '422' ;;
    yuv440p16be | yuv440p16le) echo '440' ;;
    yuv444p16be | yuv444p16le) echo '444' ;;
    yuva420p16be | yuva420p16le) echo '420' ;;
    yuva422p16be | yuva422p16le) echo '422' ;;
    ayuv64be | ayuv64le | yuva444p16be | yuva444p16le) echo '444' ;;
    grayf32be | grayf32le) echo '444' ;;
    gbrpf32be | gbrpf32le) echo '444' ;;
    gbrapf32be | gbrapf32le) echo '444' ;;
    *) echo '-1' ;;
  esac
}

getColorChannelCount() {
  local pixelFormat="${1,,}"
  local channel=''
  channel="$(echo "${allPixelFormats}" | regexFind ".*\s${pixelFormat}\s.*" | awk '{print $3}')"
  if [[ -z "${channel}" ]]; then
    echo '-1'
  else
    echo "${channel}"
  fi
}

getColorBitCount() {
  local pixelFormat="${1,,}"
  local bits=''
  bits="$(echo "${allPixelFormats}" | regexFind ".*\s${pixelFormat}\s.*" | awk '{print $4}')"
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
  for newPixelFormat in $(regex 's/,/\n/g' "${newPixelFormatList}"); do
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
    regex 's/,/\n/g' "${newList},${hasCopy}"
  elif [[ -n "${newList}" ]]; then
    regex 's/,/\n/g' "${newList}"
  else
    echo "${hasCopy}"
  fi
}

findPixelFormatAdequateFromList() {
  local function="${1}"
  local oldPixelFormat="${2,,}"
  local comparison="${3}"
  local newPixelFormatList="${4,,}"
  local oldPixelValue=''
  local newPixelFormat=''
  local newPixelValue=''
  local newList=''
  oldPixelValue="$(${function} "${oldPixelFormat}")"

  IFS=$'\n'
  for newPixelFormat in $(regex 's/,/\n/g' "${newPixelFormatList}"); do
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

  if [[ "$(doesListContain "${oldPixelFormat}" "${videoPixelFormat,,}" ',')" == 'true' ]]; then
    newPixelFormat="$(regex 's/,/\n/g' "${videoPixelFormat}")"
    for newPixelFormatOrder in $(regex 's/,/\n/g' "${videoPixelFormatExclusionOrder}"); do
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

    for newPixelFormatOrder in $(regex 's/,/\n/g' "${videoPixelFormatPreferenceOrder}"); do
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
    getListFirstValue "${newPixelFormat}" ','
  else
    getListFirstValue "${videoPixelFormat}" ','
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
    *) echo '-1' ;;
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
  case "$(normalizeSubtitleCodec "${codecName}")" in
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
  local encoder="${1,,}"
  local profile="${2,,}"
  local pixelFormat="${3,,}"
  local colorDepth=''
  local colorCompression=''

  encoder="$(normalizeVideoCodec "${encoder}")"
  profile="$(normalizeVideoProfileComplexity "${profile}")"
  colorDepth="$(getColorDepth "${pixelFormat}")"
  colorCompression="$(getColorCompression "${pixelFormat}")"

  if [[ "${encoder}" == 'hevc' ]]; then
    if [[ "${profile}" == 'main' || "${profile}" == 'high' ]]; then
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
    else
      echo "${2,,}"
    fi
  elif [[ "${encoder}" == 'h264' ]]; then
    if [[ "${profile}" == 'high' ]]; then
      if [[ "${colorCompression}" -ge 444 ]]; then
        echo 'high444'
      elif [[ "${colorCompression}" -ge 422 ]]; then
        echo 'high422'
      elif [[ "${colorDepth}" -le 8 ]]; then
        echo 'high'
      elif [[ "${colorDepth}" -le 10 ]]; then
        echo 'high10'
      else
        echo 'high'
      fi
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

  echo "${stream}" | regexFind "^${id}=.*$" | regexFind '[^=]*$'
}

getMetadata() {
  local id="${1}"
  local stream="${2}"

  getValue "TAG:${id}" "${stream}"
}

getCodecFromStream() {
  local stream="${1}"
  local oldCodec=''

  oldCodec="$(getMetadata "${metadataCodecName}" "${stream}")"
  if [[ -z "${oldCodec}" ]]; then
    oldCodec="$(getValue 'codec_name' "${stream}")"
  fi

  echo "${oldCodec}"
}

getAudioBitRateFromStream() {
  local stream="${1}"
  local oldBitRate=''

  oldBitRate="$(getMetadata "${metadataAudioBitRate}" "${stream}")"
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
  local codec=''
  local oldLevel=''

  oldLevel="$(getMetadata "${metadataVideoLevel}" "${stream}")"
  if [[ -z "${oldLevel}" ]]; then
    codec="$(normalizeVideoCodec "$(getCodecFromStream "${stream}")")"
    oldLevel="$(getValue 'level' "${stream}")"
    if [[ -z "${oldLevel}" ]]; then
      if [[ "${codec}" == 'hevc' ]]; then
        if [[ "${oldLevel}" -ge 241 && "$((oldLevel % 6))" -eq 1 ]]; then
          oldLevel="$(((oldLevel - 1) / 6))"
        elif [[ "${oldLevel}" -ge 30 && "$((oldLevel % 3))" -eq 0 ]]; then
          oldLevel="$((oldLevel / 3))"
        fi
      fi
    fi
  fi

  normalizeVideoLevel "${oldLevel}"
}

getVideoPixelFormatFromStream() {
  local stream="${1}"
  local oldFormat=''

  oldFormat="$(getMetadata "${metadataVideoPixelFormat}" "${stream}")"
  if [[ -z "${oldFormat}" ]]; then
    oldFormat="$(getValue 'pix_fmt' "${stream}")"
  fi

  echo "${oldFormat}"
}

getVideoFrameRateFromStream() {
  local stream="${1}"
  local oldRate=''

  oldRate="$(getMetadata "${metadataVideoFrameRate}" "${stream}")"
  if [[ -z "${oldRate}" ]]; then
    oldRate="$(getValue 'r_frame_rate' "${stream}")"
  fi

  echo "${oldRate}"
}

getVideoProfileFromStream() {
  local stream="${1}"
  local codec=''
  local oldProfile=''

  oldProfile="$(getMetadata "${metadataVideoProfile}" "${stream}")"
  if [[ -z "${oldProfile}" ]]; then
    codec="$(normalizeVideoCodec "$(getCodecFromStream "${stream}")")"
    if [[ "${codec}" == 'hevc' ]]; then
      oldProfile="$(getValue 'level' "${stream}")"
      if [[ "${oldProfile}" -ge 241 && "$((oldProfile % 6))" -eq 1 ]]; then
        oldProfile='high'
      elif [[ "${oldProfile}" -ge 30 && "$((oldProfile % 3))" -eq 0 ]]; then
        oldProfile='main'
      else
        oldProfile=''
      fi
    fi
  fi

  if [[ -z "${oldProfile}" ]]; then
    oldProfile="$(getValue 'profile' "${stream}")"
  fi

  echo "${oldProfile}"
}

getTitle() {
  local extras="${1}"
  local stream="${2}"
  local title=''

  title="$(getMetadata "${metadataTitle}" "${stream}")"
  if [[ -z "${title}" ]]; then
    IFS=$'\n'
    for title in $(regex 's/\./\n/g' "${extras}"); do
      if [[ "$(normalizeLanguage "${title}")" == 'und' && -n "$(trim "${title}")" ]]; then
        break
      fi
    done
  fi

  if [[ -n "${title}" ]]; then
    trim "${title}"
  else
    echo "Undetermined"
  fi
}

getLanguage() {
  local extras="${1}"
  local stream="${2}"
  local language=''

  language="$(getMetadata "${metadataLanguage}" "${stream}")"
  if [[ -z "${language}" ]]; then
    IFS=$'\n'
    for language in $(regex 's/\./\n/g' "${extras}"); do
      language="$(normalizeLanguage "${language}")"
      if [[ "${language}" != 'und' ]]; then
        break
      fi
    done
  fi

  if [[ -n "${language}" ]]; then
    trim "${language}"
  else
    echo "und"
  fi
}

determineTitle() {
  local extras="${1}"
  local stream="${2}"
  local audioChannelCount="${3}"
  local title=''
  local language=''

  title="$(getTitle "${extras}" "${stream}")"
  language="$(normalizeLanguageFullName "$(getLanguage "${extras}" "${stream}")")"

  if [[ -n "${audioChannelCount}" ]]; then
    audioChannelCount="$(getChannelNaming "${audioChannelCount}")"
  fi

  if [[ -n "${title}" && "${title}" != 'und' && "${title}" != 'Undetermined' && "$(normalizeLanguage "${title}")" == "und" ]]; then
    echo "${title}"
  elif [[ "${language}" != 'und' && "${language}" != 'Undetermined' ]]; then
    if [[ -n "${audioChannelCount}" ]]; then
      echo "${language} (${audioChannelCount})"
    else
      echo "${language}"
    fi
  fi
}

determineLanguage() {
  local extras="${1}"
  local stream="${2}"
  local title=''
  local language=''

  title="$(normalizeLanguage "$(getTitle "${extras}" "${stream}")")"
  language="$(normalizeLanguage "$(getLanguage "${extras}" "${stream}")")"

  if [[ -n "${language}" && "${language}" != 'und' ]]; then
    echo "${language}"
  elif [[ "${title}" != 'und' ]]; then
    echo "${title}"
  fi
}

isSupported() {
  local mode="${1}"
  local method="${2}"
  local codec="${3}"
  local normalizer="${4}"
  local supportedList="${5}"

  if [[ "${mode}" == 'convert' && "${method}" == 'convert' ]]; then
    echo 'true'
  elif [[ "${mode}" == 'convert' && "${method}" == 'export' ]]; then
    if [[ "$(doesListContain "${codec}" "${supportedList}" ',' "${normalizer}")" == 'true' ]]; then
      echo 'true'
    fi
  elif [[ "${mode}" == 'export' && "${method}" == 'export' ]]; then
    if [[ "$(doesListContain "${codec}" "${supportedList}" ',' "${normalizer}")" != 'true' ]]; then
      echo 'true'
    fi
  elif [[ "${mode}" == 'convert' && "${method}" == 'delete' ]]; then
    if [[ "$(doesListContain "${codec}" "${supportedList}" ',' "${normalizer}")" == 'true' ]]; then
      echo 'true'
    fi
  fi
}

getInputFiles() {
  local inputFile="${1}"
  local inputDirectory=''
  local inputFileName=''
  local fileExt=''

  inputDirectory="$(getDirectory "${inputFile}")"
  inputFileName="$(getFileName "${inputFile}")"

  echo "${inputFile}"
  IFS=$'\n'
  for fileExt in $(regex 's/,/\n/g' "${audioImportExtension}"); do
    find "${inputDirectory}" -type f -name "${inputFileName}*${fileExt}"
  done
  for fileExt in $(regex 's/,/\n/g' "${subtitleImportExtension}"); do
    find "${inputDirectory}" -type f -name "${inputFileName}*${fileExt}"
  done
}

#-----------------
# FFMpeg Argument Processing
#-----------------

getChapterSettings() {
  if [[ "${mode}" == 'convert' ]]; then
    local fileCount=0
    local index=0
    local inputFile="${1}"
    local mode="${2}"
    local chapterEncoding=''
    local chapterList=''
    local chapterCount=''
    local probeResult=''
    local chapter=0
    local oldTitle=''

    chapterList="$(ffprobe "${inputFile}" -loglevel error -show_chapters)"
    chapterCount="$(regexCount '\[CHAPTER\]' "${chapterList}")"

    if [[ "${chapterCount}" -gt 0 ]]; then
      chapterEncoding="${chapterEncoding} -map_chapters 0"
      for chapter in $(seq 0 1 $((chapterCount - 1))); do
        probeResult="$(echo "${chapterList}" | awk "/\[CHAPTER\]/{f=f+1} f==$((chapter + 1)){print;}")"
        oldTitle="$(getMetadata "${metadataTitle}" "${probeResult}")"

        trace "Stream ${fileCount}:chapter:${index} title:${oldTitle}"
        if [[ -n "${oldTitle}" ]]; then
          chapterEncoding="${chapterEncoding} -metadata:c:${index} '${metadataTitle}=${oldTitle}'"
        fi
        index="$((index + 1))"
      done
    fi
    echo "${chapterEncoding}"
  fi
}

getAudioEncodingSettings() {
  local baseFile="${1}"
  local outputFile="${2}"
  local mode="${3}"
  local audioEncoding=''
  local baseName=''
  local allFiles=''
  local fileCount=0
  local index=0
  local inputFile=''
  local outputDirectory=''

  baseName="$(getFileName "${baseFile}")"
  allFiles="$(getInputFiles "${baseFile}")"
  outputDirectory="$(getDirectory "${outputFile}")"

  IFS=$'\n'
  for inputFile in ${allFiles}; do
    local inputFileName=''
    local inputExtras=''
    local streamList=''
    local streamCount=''
    local probeResult=''
    local stream=0
    local duration=''
    local title=''
    local language=''
    local oldCodec=''
    local oldChannelCount=''
    local oldBitRate=''
    local newCodec=''
    local newChannelCount=''
    local newBitRate=''
    local normalizedOldCodecName=''
    local normalizedNewCodecName=''

    inputFileName="$(getFileName "${inputFile}")"
    inputExtras="${inputFileName#"${baseName}"}"
    streamList="$(ffprobe "${inputFile}" -loglevel error -show_streams -select_streams a)"
    streamCount="$(regexCount '\[STREAM\]' "${streamList}")"

    for stream in $(seq 0 1 $((streamCount - 1))); do
      probeResult="$(echo "${streamList}" | awk "/\[STREAM\]/{f=f+1} f==$((stream + 1)){print;}")"
      newCodec=''
      newChannelCount='2'
      oldCodec="$(getCodecFromStream "${probeResult}")"
      duration="$(getMetadata 'DURATION' "${probeResult}")"
      oldChannelCount="$(getValue 'channels' "${probeResult}")"
      if [[ -z "${oldChannelCount}" ]]; then
        oldChannelCount='2'
      fi
      title="$(determineTitle "${inputExtras}" "${probeResult}" "${oldChannelCount}")"
      language="$(determineLanguage "${inputExtras}" "${probeResult}")"
      oldBitRate="$(getAudioBitRateFromStream "${probeResult}")"
      outputFile="${outputDirectory}/${baseName}$(getAudioExportExtension)$(getCodecAudioExtension "${oldCodec}")"

      trace "Stream ${fileCount}:audio:${stream} codec:${oldCodec} duration:${duration} channels:${oldChannelCount} rate:${oldBitRate} title:${title} language:${language}"
      if [[ -n "${oldCodec}" && "${duration}" != '00:00:00.000000000' &&
       "$(isSupported "${mode}" "${audioUpdateMethod}" "${oldCodec}" 'normalizeAudioCodec' "${audioCodec}")" == 'true' ]]; then
        normalizedOldCodecName="$(normalizeAudioCodec "${oldCodec}")"
        if [[ "${mode}" == 'convert' ]]; then
          newCodec="$(getListFirstValue "${audioCodec}" ',')"
          newCodec="$(getListFirstMatch "${oldCodec}" "${audioCodec}" ',' 'normalizeAudioCodec' "${newCodec}")"
        else
          newCodec='copy'
        fi
        normalizedNewCodecName="$(normalizeAudioCodec "${newCodec}")"

        if [[ "${newChannelCount}" != "${oldChannelCount}" ]]; then
          newChannelCount="${oldChannelCount}"
        fi
        newBitRate="$((newChannelCount * bitratePerAudioChannel))"

        if [[ -n "${oldBitRate}" && "${newBitRate}" -gt "${oldBitRate}" ]]; then
          newBitRate="${oldBitRate}"
        elif [[ -z "${oldBitRate}" ]]; then
          oldBitRate='-1'
        fi

        trace "Stream ${fileCount}:audio:${stream} codec:${newCodec} channels:${newChannelCount} rate:${newBitRate}"
        if [[ -z "${newCodec}" || "${newCodec,,}" == "copy" ]] ||
          [[ "${forceRun}" == 'false' && "${normalizedOldCodecName}" == "${normalizedNewCodecName}" && "${oldBitRate}" -le "${newBitRate}" ]]; then
          audioEncoding="${audioEncoding} -map ${fileCount}:a:${stream}"
          audioEncoding="${audioEncoding} -codec:a:${index} copy -metadata:s:a:${index} '${metadataCodecName}=${oldCodec}'"
          if [[ -n "${oldBitRate}" && ${oldBitRate} -gt 0 ]]; then
            audioEncoding="${audioEncoding} -metadata:s:a:${index} '${metadataAudioBitRate}=${oldBitRate}'"
          fi
        else
          audioEncoding="${audioEncoding} -map ${fileCount}:a:${stream}"
          audioEncoding="${audioEncoding} -codec:a:${index} ${newCodec} -metadata:s:a:${index} '${metadataCodecName}=${newCodec}'"
          if [[ -n "${newBitRate}" ]]; then
            audioEncoding="${audioEncoding} -b:a:${index} ${newBitRate} -metadata:s:a:${index} '${metadataAudioBitRate}=${newBitRate}'"
          fi
        fi

        if [[ -n "${title}" ]]; then
          audioEncoding="${audioEncoding} -metadata:s:a:${index} '${metadataTitle}=${title}'"
        fi
        if [[ -n "${language}" ]]; then
          audioEncoding="${audioEncoding} -metadata:s:a:${index} '${metadataLanguage}=${language}'"
        fi
        if [[ "${mode}" == 'convert' ]]; then
          index="$((index + 1))"
        elif [[ "${mode}" == 'export' ]]; then
          trace "Stream ${fileCount}:audio:${stream} '${outputFile}'"
          audioEncoding="${audioEncoding} '$(regex "s/'/'\"'\"'/g" "${outputFile}")'"
        fi
      fi
    done
    fileCount="$((fileCount + 1))"
  done
  echo "${audioEncoding}"
}

getVideoEncodingSettings() {
  local baseFile="${1}"
  local outputFile="${2}"
  local mode="${3}"
  local videoEncoding=''
  local baseName=''
  local fileCount='0'
  local index='0'
  local inputFile=''
  local outputDirectory=''

  baseName="$(getFileName "${baseFile}")"
  outputDirectory="$(getDirectory "${outputFile}")"
  inputFile="${baseFile}"

  local inputFileName=''
  local inputExtras=''
  local streamList=''
  local streamCount=''
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
  local duration=''
  local title=''
  local language=''
  local oldCodec=''
  local oldLevel=''
  local oldPixelFormat=''
  local oldFrameRate=''
  local oldPreset=''
  local oldProfile=''
  local oldQuality=''
  local oldTune=''
  local oldPresetComplexity=''
  local normalizedOldCodecName=''
  local normalizedNewCodecName=''
  local normalizedOldVideoProfile=''
  local normalizedNewVideoProfile=''
  local normalizedOldFrameRate=''
  local normalizedNewFrameRate=''
  local additionalParameters=''
  local index='0'

  inputFileName="${baseName}"
  inputExtras="${inputFileName#"${baseName}"}"
  streamList="$(ffprobe "${inputFile}" -loglevel error -show_streams -select_streams v)"
  streamCount="$(regexCount '\[STREAM\]' "${streamList}")"

  for stream in $(seq 0 1 $((streamCount - 1))); do
    probeResult="$(echo "${streamList}" | awk "/\[STREAM\]/{f=f+1} f==$((stream + 1)){print;}")"
    newCodec=''
    newLevel="$(normalizeVideoLevel "${videoLevel}")"
    newPixelFormat="${videoPixelFormat}"
    newFrameRate="${videoFrameRate}"
    newPreset="${videoPreset}"
    newProfile="${videoProfile}"
    newQuality="${videoQuality}"
    newTune="${videoTune}"
    oldCodec="$(getCodecFromStream "${probeResult}")"
    duration="$(getMetadata 'DURATION' "${probeResult}")"
    title="$(determineTitle "${inputExtras}" "${probeResult}")"
    language="$(determineLanguage "${inputExtras}" "${probeResult}")"
    oldLevel="$(getVideoLevelFromStream "${probeResult}")"
    oldPixelFormat="$(getVideoPixelFormatFromStream "${probeResult}")"
    oldFrameRate="$(getVideoFrameRateFromStream "${probeResult}")"
    oldPreset="$(getMetadata "${metadataVideoPreset}" "${probeResult}")"
    oldProfile="$(getVideoProfileFromStream "${probeResult}")"
    oldQuality="$(getMetadata "${metadataVideoQuality}" "${probeResult}")"
    oldTune="$(getMetadata "${metadataVideoTune}" "${probeResult}")"
    outputFile="${outputDirectory}/${baseName}$(getVideoExportExtension)$(getCodecVideoExtension "${oldCodec}")"

    # Calculated Values
    normalizedOldFrameRate="$(normalizeFrameRate "${oldFrameRate}")"
    normalizedNewFrameRate="$(normalizeFrameRate "${newFrameRate}")"
    oldPresetComplexity="$(getPresetComplexityOrder "${oldPreset}")"
    newPresetComplexity="$(getPresetComplexityOrder "${newPreset}")"

    trace "Stream ${fileCount}:video:${stream} codec:${oldCodec} duration:${duration} level:${oldLevel} format:${oldPixelFormat} rate:${oldFrameRate} preset:${oldPreset} profile:${oldProfile} quality:${oldQuality} tune:${oldTune} title:${title} language:${language}"
    if [[ -n "${oldCodec}" && "${duration}" != '00:00:00.000000000' &&
     "$(isSupported "${mode}" "${videoUpdateMethod}" "${oldCodec}" 'normalizeVideoCodec' "${videoCodec}")" == 'true' ]]; then
      normalizedOldCodecName="$(normalizeVideoCodec "${oldCodec}")"
      if [[ "${mode}" == 'convert' ]]; then
        newCodec="$(getListFirstValue "${videoCodec}" ',')"
        newCodec="$(getListFirstMatch "${oldCodec}" "${videoCodec}" ',' 'normalizeVideoCodec' "${newCodec}")"
      else
        newCodec='copy'
      fi
      normalizedNewCodecName="$(normalizeVideoCodec "${newCodec}")"

      if [[ -z "${newProfile}" || "${newProfile,,}" == "copy" ]]; then
        newProfile="${oldProfile}"
      fi
      normalizedOldVideoProfile="$(normalizeVideoProfileComplexity "${oldProfile}")"
      normalizedNewVideoProfile="$(normalizeVideoProfileComplexity "${newProfile}")"

      if [[ -z "${newLevel}" || "${newLevel}" == 'copy' ]]; then
        newLevel="${oldLevel}"
      elif [[ -n "${oldLevel}" && "${oldLevel}" -ge '10' && "${newLevel}" -gt "${oldLevel}" ]]; then
        newLevel="${oldLevel}"
      fi
      if [[ -z "${newPixelFormat}" || "${newPixelFormat}" == 'copy' ]]; then
        newPixelFormat="${oldPixelFormat}"
      elif [[ "$(regexCount ',' "${newPixelFormat}")" -gt 0 ]]; then
        newPixelFormat="$(findPixelFormat "${oldPixelFormat}" "${newPixelFormat}")"
      fi
      if [[ -z "${oldQuality}" ]]; then
        oldQuality='0'
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

      trace "Stream ${fileCount}:video:${stream} codec:${newCodec} level:${newLevel} format:${newPixelFormat} rate:${newFrameRate} preset:${newPreset} profile:${newProfile} quality:${newQuality} tune:${newTune}"
      if [[ -z "${newCodec}" || "${newCodec,,}" == "copy" ]] ||
        [[ "${forceRun}" == 'false' && "${normalizedOldCodecName}" == "${normalizedNewCodecName}" && "${oldPresetComplexity}" -ge "${newPresetComplexity}" && "${oldQuality}" -ge "${newQuality}" && "${newPixelFormat}" == "${oldPixelFormat}" ]] ||
        [[ "${forceRun}" == 'false' && "${newPreset}" == 'ultrafast' && "${normalizedOldCodecName}" == "${normalizedNewCodecName}" ]]; then
        videoEncoding="${videoEncoding} -map ${fileCount}:v:${stream}"
        videoEncoding="${videoEncoding} -codec:v:${index} copy -metadata:s:v:${index} '${metadataCodecName}=${oldCodec}'"
        if [[ -n "${oldLevel}" ]]; then
          videoEncoding="${videoEncoding} -metadata:s:v:${index} '${metadataVideoLevel}=${oldLevel::-1}.${oldLevel: -1}'"
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
        additionalParameters=''
        videoEncoding="${videoEncoding} -map ${fileCount}:v:${stream}"
        videoEncoding="${videoEncoding} -codec:v:${index} ${newCodec} -metadata:s:v:${index} '${metadataCodecName}=${newCodec}'"
        if [[ -n "${newLevel}" ]]; then
          if [[ "${normalizedNewCodecName}" == 'hevc' ]]; then
            additionalParameters="${additionalParameters}:level-idc=${newLevel}"
            videoEncoding="${videoEncoding} -metadata:s:v:${index} '${metadataVideoLevel}=${newLevel::-1}.${newLevel: -1}'"
          else
            videoEncoding="${videoEncoding} -level:v:${index} ${newLevel} -metadata:s:v:${index} '${metadataVideoLevel}=${newLevel::-1}.${newLevel: -1}'"
          fi
        fi
        if [[ -n "${newPixelFormat}" ]]; then
          videoEncoding="${videoEncoding} -pix_fmt:v:${index} ${newPixelFormat} -metadata:s:v:${index} '${metadataVideoPixelFormat}=${newPixelFormat}'"
        fi
        if [[ "${normalizedNewFrameRate}" == 'source_fps' || "${normalizedNewFrameRate}" == "${normalizedOldFrameRate}" ]]; then
          if [[ -n "${normalizedOldFrameRate}" && "${normalizedOldFrameRate}" != 'source_fps' ]]; then
            videoEncoding="${videoEncoding} -metadata:s:v:${index} '${metadataVideoFrameRate}=${normalizedOldFrameRate}'"
          fi
        elif [[ -n "${normalizedNewFrameRate}" ]]; then
          videoEncoding="${videoEncoding} -filter:v:${index} 'fps=fps=${normalizedNewFrameRate}:round=near' -metadata:s:v:${index} '${metadataVideoFrameRate}=${normalizedNewFrameRate}'"
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
        if [[ -n "${additionalParameters}" ]]; then
          if [[ "${normalizedNewCodecName}" == 'hevc' ]]; then
            videoEncoding="${videoEncoding} -x265-params:v:${index} '${additionalParameters:1}'"
          elif [[ "${normalizedNewCodecName}" == 'h264' ]]; then
            videoEncoding="${videoEncoding} -x264-params:v:${index} '${additionalParameters:1}'"
          fi
        fi
      fi
      if [[ "${streamCount}" -gt 1 ]]; then
        if [[ -n "${title}" ]]; then
          videoEncoding="${videoEncoding} -metadata:s:v:${index} '${metadataTitle}=${title}'"
        fi
        if [[ -n "${language}" ]]; then
          videoEncoding="${videoEncoding} -metadata:s:v:${index} '${metadataLanguage}=${language}'"
        fi
      fi
      if [[ "${mode}" == 'convert' ]]; then
        index="$((index + 1))"
      elif [[ "${mode}" == 'export' ]]; then
        trace "Stream ${fileCount}:video:${stream} '${outputFile}'"
        videoEncoding="${videoEncoding} '$(regex "s/'/'\"'\"'/g" "${outputFile}")'"
      fi
    fi
  done
  echo "${videoEncoding}"
}

getSubtitleEncodingSettings() {
  local baseFile="${1}"
  local outputFile="${2}"
  local mode="${3}"
  local subtitleEncoding=''
  local baseName=''
  local allFiles=''
  local fileCount='0'
  local index='0'
  local inputFile=''
  local outputDirectory''

  baseName="$(getFileName "${baseFile}")"
  outputDirectory="$(getDirectory "${outputFile}")"
  allFiles="$(getInputFiles "${baseFile}")"

  IFS=$'\n'
  for inputFile in ${allFiles}; do
    local inputFileName=''
    local inputExtras=''
    local streamList=''
    local streamCount=''
    local probeResult=''
    local stream=0
    local duration=''
    local title=''
    local language=''
    local oldCodec=''
    local newCodec=''
    local normalizedOldCodecName=''
    local normalizedNewCodecName=''

    inputFileName="$(getFileName "${inputFile}")"
    inputExtras="${inputFileName#"${baseName}"}"
    streamList="$(ffprobe "${inputFile}" -loglevel error -show_streams -select_streams s)"
    streamCount="$(regexCount '\[STREAM\]' "${streamList}")"

    for stream in $(seq 0 1 $((streamCount - 1))); do
      probeResult="$(echo "${streamList}" | awk "/\[STREAM\]/{f=f+1} f==$((stream + 1)){print;}")"
      oldCodec="$(getCodecFromStream "${probeResult}")"
      duration="$(getMetadata 'DURATION' "${probeResult}")"
      title="$(determineTitle "${inputExtras}" "${probeResult}")"
      language="$(determineLanguage "${inputExtras}" "${probeResult}")"
      outputFile="${outputDirectory}/${baseName}$(getSubtitleExportExtension)$(getCodecSubtitleExtension "${oldCodec}")"

      trace "Stream ${fileCount}:subtitles:${stream} codec:${oldCodec} duration:${duration} title:${title} language:${language}"
      if [[ -n "${oldCodec}" && "${duration}" != '00:00:00.000000000' &&
       "$(isSupported "${mode}" "${subtitlesUpdateMethod}" "${oldCodec}" 'normalizeSubtitleCodec' "${subtitleCodec}")" == 'true' ]]; then
        normalizedOldCodecName="$(normalizeSubtitleCodec "${oldCodec}")"
        if [[ "${mode}" == 'convert' ]]; then
          newCodec="$(getListFirstMatch "${oldCodec}" "${subtitleCodec}" ',' 'getSubtitleEncodingType' 'copy')"
          newCodec="$(getListFirstMatch "${oldCodec}" "${subtitleCodec}" ',' 'normalizeSubtitleCodec' "${newCodec}")"
        else
          newCodec='copy'
        fi
        normalizedNewCodecName="$(normalizeSubtitleCodec "${newCodec}")"

        trace "Stream ${fileCount}:subtitles:${stream} codec:${newCodec}"
        if [[ -z "${newCodec}" || "${newCodec,,}" == "copy" ]] || [[ "${forceRun}" == 'false' && "${normalizedOldCodecName}" == "${normalizedNewCodecName}" ]]; then
          subtitleEncoding="${subtitleEncoding} -map ${fileCount}:s:${stream}"
          subtitleEncoding="${subtitleEncoding} -codec:s:${index} copy -metadata:s:s:${index} '${metadataCodecName}=${oldCodec}'"
        else
          subtitleEncoding="${subtitleEncoding} -map ${fileCount}:s:${stream}"
          subtitleEncoding="${subtitleEncoding} -codec:s:${index} ${newCodec} -metadata:s:s:${index} '${metadataCodecName}=${newCodec}'"
        fi
        if [[ -n "${title}" ]]; then
          subtitleEncoding="${subtitleEncoding} -metadata:s:s:${index} '${metadataTitle}=${title}'"
        fi
        if [[ -n "${language}" ]]; then
          subtitleEncoding="${subtitleEncoding} -metadata:s:s:${index} '${metadataLanguage}=${language}'"
        fi
        if [[ "${mode}" == 'convert' ]]; then
          index="$((index + 1))"
        elif [[ "${mode}" == 'export' ]]; then
          trace "Stream ${fileCount}:subtitles:${stream} '${outputFile}'"
          subtitleEncoding="${subtitleEncoding} '$(regex "s/'/'\"'\"'/g" "${outputFile}")'"
        fi
      fi
    done

    fileCount="$((fileCount + 1))"
  done

  echo "${subtitleEncoding}"
}

assembleArguments() {
  local inputFile="${1}"
  local outputFile="${2}"
  local arguments=''
  local chapterConvertArguments=''
  local videoConvertArguments=''
  local audioConvertArguments=''
  local subtitleConvertArguments=''
  local chapterExportArguments=''
  local videoExportArguments=''
  local audioExportArguments=''
  local subtitleExportArguments=''
  local fileFromList=''

  chapterConvertArguments="$(getChapterSettings "${inputFile}" "${outputFile}" 'convert')"
  videoConvertArguments="$(getVideoEncodingSettings "${inputFile}" "${outputFile}" 'convert')"
  audioConvertArguments="$(getAudioEncodingSettings "${inputFile}" "${outputFile}" 'convert')"
  subtitleConvertArguments="$(getSubtitleEncodingSettings "${inputFile}" "${outputFile}" 'convert')"

  chapterExportArguments="$(getChapterSettings "${inputFile}" "${outputFile}" 'export')"
  if [[ "${videoUpdateMethod}" == 'export' ]]; then
    videoExportArguments="$(getVideoEncodingSettings "${inputFile}" "${outputFile}" 'export')"
  fi
  if [[ "${audioUpdateMethod}" == 'export' ]]; then
    audioExportArguments="$(getAudioEncodingSettings "${inputFile}" "${outputFile}" 'export')"
  fi
  if [[ "${subtitlesUpdateMethod}" == 'export' ]]; then
    subtitleExportArguments="$(getSubtitleEncodingSettings "${inputFile}" "${outputFile}" 'export')"
  fi

  if [[ "$(( "$(regexCount '\s-codec:v:[0-9]+\s' "${videoConvertArguments}")" + "$(regexCount '\s-codec:v:[0-9]+\s' "${videoExportArguments}")" ))" -gt 1 ]]; then
    warn "${inputFile} has multiple supported Video files"
  elif [[ "$(( "$(regexCount '\s-codec:v:[0-9]+\s' "${videoConvertArguments}")" + "$(regexCount '\s-codec:v:[0-9]+\s' "${videoExportArguments}")" ))" -eq 0 ]]; then
    error "${inputFile} has no supported Video files"
  fi
  if [[ "$(( "$(regexCount '\s-codec:a:[0-9]+\s' "${audioConvertArguments}")" + "$(regexCount '\s-codec:a:[0-9]+\s' "${audioExportArguments}")" ))" -eq 0 ]]; then
    warn "${inputFile} has no supported Audio files"
  fi

  IFS=$'\n'
  for fileFromList in $(getInputFiles "${inputFile}"); do
    arguments="${arguments} -i '$(regex "s/'/'\"'\"'/g" "${fileFromList}")'"
  done

  arguments="${arguments}$(if [ "${deleteMetadata}" = true ]; then echo ' -map_metadata -1'; fi) ${chapterConvertArguments} ${videoConvertArguments} ${audioConvertArguments} ${subtitleConvertArguments} -threads ${threadCount} '$(regex "s/'/'\"'\"'/g" "${outputFile}")' ${chapterExportArguments} ${videoExportArguments} ${audioExportArguments} ${subtitleExportArguments}"

  echo "${arguments}"
}

hasChanges() {
  local runnable="${1}"
  local inputFile="${2}"
  local streamList=''
  local streamCount=''


  if [[ "$(regexCount '\s-codec:[vas]:[0-9]+\s+([^c]|c[^o]|co[^p]|cop[^y])' "${runnable}")" -gt 0 ]]; then
    echo 'true'
  elif [[ "$(regexCount "\\s*-i\\s*'[^']*'" "${runnable}")" -gt 1 ]]; then
    echo 'true'
  else
    streamList="$(ffprobe "${inputFile}" -loglevel error -show_streams)"
    streamCount="$(regexCount '\[STREAM\]' "${streamList}")"
    if [[ "$(regexCount '\s-codec:[vas]:[0-9]+\s+' "${runnable}")" -ne "${streamCount}" ]]; then
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
  local runnable=''

  runnable="ffmpeg -loglevel warning $(assembleArguments "${inputFile}" "${outputFile}")"

  debug "${runnable}"
  if [[ "${runnable}" =~ .*-codec:v:0.* ]]; then
    if [[ "${metadataRun}" == 'true' || "$(hasChanges "${runnable}" "${inputFile}")" == 'true' ]]; then
      if [ "$(lockFile "${inputFile}" "${pid}")" = 'false' ]; then
        hasCodecChanges='conflict'
        convertErrorCode=0
      else
        hasCodecChanges='true'
        if [[ "${logLevelValue}" -ge 6 ]]; then
          eval "${runnable}"
          convertErrorCode=$?
        else
          eval "${runnable}" > /dev/null 2>&1
          convertErrorCode=$?
        fi
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

  local inputBaseName=''
  local inputDirectory=''
  local tmpDirectory=''
  local outputBaseName=''
  local outputDirectory=''
  local outputExtension=''
  local mod=''
  local owner=''
  local group=''
  local originalSize=''
  local finalSize=''
  local arguments=''

  mod="$(stat --format '%a' "${inputFile}")"
  owner="$(ls -al "${inputFile}" | awk '{print $3}')"
  group="$(ls -al "${inputFile}" | awk '{print $4}')"
  originalSize="$(ls -al "${inputFile}" | awk '{print $5}')"
  inputBaseName="$(getFileName "${inputFile}")"
  inputDirectory="$(getDirectory "${inputFile}")"
  tmpDirectory="$(getDirectory "${tmpFile}")"
  outputBaseName="$(getFileName "${outputFile}")"
  outputDirectory="$(getDirectory "${outputFile}")"
  outputExtension="$(getExtension "${outputFile}")"

  if [[ "$dryRun" == "true" ]]; then
    finalSize="$(ls -al "${inputFile}" | awk '{print $5}')"
    debug "convert \"${inputFile}\" \"${tmpFile}\" \"${pid}\""
    arguments="ffmpeg $(assembleArguments "${inputFile}" "${tmpDirectory}/${outputBaseName}${outputExtension}")"
    debug "${arguments}"
    if [[ "$(hasChanges "${arguments}" "${inputFile}")" == 'true' ]]; then
      debug "Has Changes; Will Convert"
    else
      debug "No Changes detected; Will not convert"
    fi
    if [[ "${deleteInputFiles}" == 'true' ]]; then
      local fileFromList=''
      IFS=$'\n'
      for fileFromList in $(getInputFiles "${inputFile}"); do
        debug "rm \"${fileFromList}\""
      done
    elif [[ "${inputDirectory}" == "${outputDirectory}" && "${inputBaseName}" == "${outputBaseName}" ]]; then
      debug "rm \"${inputFile}\""
    fi
    debug "mv \"${tmpFile}\" \"${outputFile}\""
    debug "find \"${tmpDirectory}\" -type f -name \"${outputBaseName}.*\" -exec mv '{}' \"${outputDirectory}/.\" \;"
    debug "chown \"${owner}:${group}\" -v \"${outputFile}\""
    debug "chmod \"${mod}\" -v \"${outputFile}\""
    debug "File '${inputFile}' reduced to $((finalSize / (1024 * 1024) ))MiB from original size $((originalSize / (1024 * 1024) ))MiB"
  else
    convert "${inputFile}" "${tmpFile}" "${pid}"
    finalSize="$(ls -al "${tmpFile}" | awk '{print $5}')"
    if [[ "${hasCodecChanges}" == 'false' ]]; then
      trace "Not processing file '${inputFile}', as no changes would be made."
    elif [[ "${hasCodecChanges}" == 'conflict' ]]; then
      info "Cannot achieve lock on file '${inputFile}', Skipping."
    elif [[ -f "${tmpFile}" && "${convertErrorCode}" == "0" && -n "${finalSize}" && "${finalSize}" -gt 0 && -n "${originalSize}" && "$((originalSize / finalSize))" -lt 1000 ]]; then
      if [[ "${deleteInputFiles}" == 'true' ]]; then
        local fileFromList=''
        IFS=$'\n'
        for fileFromList in $(getInputFiles "${inputFile}"); do
          rm "${fileFromList}"
        done
      elif [[ "${inputDirectory}" == "${outputDirectory}" && "${inputBaseName}" == "${outputBaseName}" ]]; then
        rm "${inputFile}"
      fi
      mv "${tmpFile}" "${outputFile}"
      find "${tmpDirectory}" -type f -name "${outputBaseName}.*" -exec mv '{}' "/${outputDirectory}/" \;
      chown "${owner}:${group}" "${outputFile}"
      chmod "${mod}" "${outputFile}"
      trace "File '${inputFile}' reduced to $((finalSize / 1024 / 1204))MiB from original size $((originalSize / 1024 / 1204))MiB"
      info "Completed '${inputFile}'"
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
  local inputDirectoryLength=''
  local currentDirectory=''
  local currentFileName=''
  local currentExt=''
  local tmpFile=''
  local outputFile=''
  local outputExtension=''
  local inputFile=''
  local sortingType=''
  local sortingOrder=''
  local allInputFiles=''
  local fileCount=''

  inputDirectory="$(normalizeDirectory "${inputDirectory}")"
  tmpDirectory="$(normalizeDirectory "${tmpDirectory}")"
  outputDirectory="$(normalizeDirectory "${outputDirectory}")"
  inputDirectoryLength="$(("${#inputDirectory}" + 1))"
  if [[ "${sortBy^^}" =~ ^.*'DATE'$ ]]; then
    sortingType='%T@ %p\n'
  elif [[ "${sortBy^^}" =~ ^.*'NAME'$ ]]; then
    sortingType='%p\n'
  else
    sortingType='%s %p\n'
  fi
  if [[ "${sortBy^^}" =~ ^'REVERSE'.*$ ]]; then
    if [[ "${sortBy^^}" =~ ^.*'NAME'$ ]]; then
      sortingOrder='-rn'
    else
      sortingOrder='-n'
    fi
  else
    if [[ "${sortBy^^}" =~ ^.*'NAME'$ ]]; then
      sortingOrder='-n'
    else
      sortingOrder='-rn'
    fi
  fi
  if [[ "${sortBy^^}" =~ ^.*'NAME'$ ]]; then
    allInputFiles="$(find "${inputDirectory}" -type f -printf "${sortingType}" | sort "${sortingOrder}" | sed 's/^ *//g' | xargs -d "\n" file -N -i | sed -n 's!: video/[^:]*$!!p')"
  else
    allInputFiles="$(find "${inputDirectory}" -type f -printf "${sortingType}" | sort "${sortingOrder}" | awk '!($1="")' | sed 's/^ *//g' | xargs -d "\n" file -N -i | sed -n 's!: video/[^:]*$!!p')"
  fi
  fileCount="$(echo "${allInputFiles}" | wc -l)"

  info "Processing ${fileCount} file"
  IFS=$'\n'
  # shellcheck disable=SC2068
  for inputFile in ${allInputFiles[@]}; do
    if [[ -n "${pidLocation}" && "${pid}" != "$(cat "${pidLocation}")" ]]; then
      info "PID mismatch; Stopping"
      break
    fi

    if [[ -z "${fileIgnoreRegex}" || "$(regexCount "${fileIgnoreRegex}" "${inputFile}")" -eq 0 ]]; then
      currentDirectory="$(getDirectory "${inputFile}")"
      currentFileName="$(getFileName "${inputFile}")"
      currentExt="$(getExtension "${inputFile}")"

      if [[ -z "${videoOutputExtension}" || "${videoOutputExtension}" == copy ]]; then
        outputExtension="${currentExt}"
      else
        outputExtension="${videoOutputExtension}"
      fi

      if [[ "${currentExt}" != "part" ]]; then
        tmpFile="${tmpDirectory}/${currentFileName}/${currentFileName}${outputExtension}"
        if [[ -f "${tmpFile}" ]]; then
          rm -f "${tmpFile}"
        fi
        if [[ -z "${outputDirectory}" ]]; then
          outputFile="${currentDirectory}/${currentFileName}${outputExtension}"
        else
          outputFile="${outputDirectory}/${currentDirectory:${inputDirectoryLength}}/${currentFileName}${outputExtension}"
        fi
        if [[ -f "${outputFile}" && "${inputFile}" != "${outputFile}" ]]; then
          warn "Cannot convert '${inputFile}' as it would overwrite '${outputFile}'"
        else
          trace "Converting '${inputFile}' to '${outputFile}'"
          convertFile "${inputFile}" "${tmpFile}" "${outputFile}" "${pid}"
        fi
      fi
    else
      trace "Skipping '${inputFile}' due to --ignore parameter"
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
      echo "${pid}" >"${pidLocation}"
    fi
    info "$(getCommand "${command}")"
    mkdir -p "${tmpDirectory}/${pid}"

    if [[ -n "${logFile}" ]]; then
      convertAll "${inputDirectory}" "${tmpDirectory}/${pid}" "${outputDirectory}" "${pid}" 2>>"${logFile}"
    else
      convertAll "${inputDirectory}" "${tmpDirectory}/${pid}" "${outputDirectory}" "${pid}"
    fi
  fi
}

startDaemon() {
  local vars=''
  if [[ "$(isRunning)" == "true" ]]; then
    echo "Daemon is already running"
  else
    echo "Starting Daemon"
    vars="$(getCommand "start-local")"
    eval "nohup ${vars} >/dev/null 2>&1 &"
  fi
}

isPidRunning() {
  local pid="${1}"
  if [[ -n "${pid}" ]]; then
    isRunning="$(ps ax | awk '{print $1}' | regexFind "${pid}")"
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
    pid="$(getListFirstValue "$(cat "${pidLocation}")" '')"
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
    echo "-1" >>"${pidLocation}"
    echo "Stop signal has been sent to the process"
  else
    echo "Daemon is not running"
  fi
}

runCommand() {
  local command="${1,,}"

  if [[ "$(getPresetComplexityOrder "${videoPreset}")" -lt 1 ]]; then
    error "--video-preset is an invalid value"
    command="badVariable"
  fi

  if [[ "${command}" == "active" ]]; then
    isRunning
  elif [[ "${command}" == "start-local" ]]; then
    getCommand "${command}"
    startLocal
  elif [[ "${command}" == "start" ]]; then
    getCommand "${command}"
    startDaemon
  elif [[ "${command::6}" == "output" ]]; then
    local level="${command:6}"
    case "${level}" in
      -error) cat "${logFile}" | regexFind '.*\[(ERROR)\].*' | tail -n 1000 ;;
      -warn) cat "${logFile}" | regexFind '.*\[(ERROR|WARN)\].*'| tail -n 1000 ;;
      -info) cat "${logFile}" | regexFind '.*\[(ERROR|WARN|INFO)\].*' | tail -n 1000 ;;
      -debug) cat "${logFile}" | regexFind '.*\[(ERROR|WARN|INFO|DEBUG)\].*' | tail -n 1000 ;;
      -trace) cat "${logFile}" | regexFind '.*\[(ERROR|WARN|INFO|DEBUG|TRACE)\].*' | tail -n 1000 ;;
      -all) tail -n 1000 "${logFile}" ;;
    esac
  elif [[ "${command}" == "stop" ]]; then
    getCommand "${command}"
    stopProcess
  else
    getCommand "${1}"
    getUsage
    exit 1
  fi

  if [[ -n "${additionalParameters}" || -n "${passedParameters}" ]]; then
    echo "Unused Values: ${additionalParameters} -- ${passedParameters}"
  fi
}

runCommand "${command}"
