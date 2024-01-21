#!/bin/bash
# /root/status.sh

tmpStatusFile='/tmp/status.out'
statusFile='/root/status.out'
sleepTimeInSeconds=60

getHostname() {
	echo "$(cat /proc/sys/kernel/hostname)"
}

getUptime() {
	local uptime="$1"
	echo "$(($(date -d@$(printf '%.0f\n' "${uptime}") -u +%-j) - 1)) Days $(date -d@$(printf '%.0f\n' "${uptime}") -u +'%-H Hours %-M Minutes %-S Seconds')"
}

getCPU() {
	echo "$((100 - $(vmstat 1 3 | awk '{for(i=NF;i>0;i--)if($i=="id"){x=i;break}}END{print $x}')))%"
}

getMemory() {
	echo "$(free -m | awk '/^Mem/ {print $3}')Mb/$(free -m | awk '/^Mem/ {print $2}')Mb"
}

getDisk() {
	local totalUsed="$(df -m | awk 'NR>2 && /^\/dev\/[^s]/{sum+=$3}END{print sum}')"
	local totalAvailable="$(df -m | awk 'NR>2 && /^\/dev\/[^s]/{sum+=$2}END{print sum}')"
	
	echo "$((totalUsed))MiB/$((totalAvailable))MiB"
}

getMediaDisk() {
	local mediaUsed="$(( "$(df -m | awk 'NR>2 && /^\/dev\/sda1/{sum+=$3}END{print sum}')" / 1024 ))"
	local mediaAvailable="$(( "$(df -m | awk 'NR>2 && /^\/dev\/sda1/{sum+=$2}END{print sum}')" / 1024 ))"
	
	echo "${mediaUsed}GiB/${mediaAvailable}GiB"
}

getMediaDisk2() {
	local mediaUsed="$(( "$(df -m | awk 'NR>2 && /^\/dev\/sdb1/{sum+=$3}END{print sum}')" / 1024 ))"
	local mediaAvailable="$(( "$(df -m | awk 'NR>2 && /^\/dev\/sdb1/{sum+=$2}END{print sum}')" / 1024 ))"

	echo "${mediaUsed}GiB/${mediaAvailable}GiB"
}

getTemperature() {
	echo "$( sensors | grep '.*temp1.*' | awk '{print $2}' | cut -c 2-)"
}

getIP() {
	echo "$( curl --location --silent ifconfig.co )"
}

getDockerStats() {
  local runner="${1}"
  local linePrefix="${2}"
  local newLine="${3:-<br/>}"
  local status="$(eval "${runner} status")"
  echo "${linePrefix}Status: ${status}"
  if [[ "${status}" == "Powered On" ]]; then
    echo "${newLine}${linePrefix}CPU: $(eval "${runner} stat-cpu")"
    echo "${newLine}${linePrefix}Memory: $(eval "${runner} stat-mem")"
    echo "${newLine}${linePrefix}Network In: $(eval "${runner} stat-neti")"
    echo "${newLine}${linePrefix}Network Out: $(eval "${runner} stat-neto")"
    echo "${newLine}${linePrefix}Disk In: $(eval "${runner} stat-blki")"
    echo "${newLine}${linePrefix}Disk Out: $(eval "${runner} stat-blko")"
  fi
}

stats=('echo "<b>Server Stats</b>"'
'echo "&nbsp;&nbsp;Host: $(getHostname)"'
'echo "&nbsp;&nbsp;Date: $(date +"%D %T")"'
'echo "&nbsp;&nbsp;Uptime: $(getUptime "$(awk '"'"'{print $1}'"'"' /proc/uptime)")"'
'echo "&nbsp;&nbsp;IP: $(getIP)"'
'echo "&nbsp;&nbsp;CPU: $(getCPU)"'
'echo "&nbsp;&nbsp;Temperature: $(getTemperature)"'
'echo "&nbsp;&nbsp;Memory: $(getMemory)"'
'echo "&nbsp;&nbsp;Disk: $(getDisk)"'
'echo "&nbsp;&nbsp;Media Drive #1: $(getMediaDisk)"'
'echo "&nbsp;&nbsp;Media Drive #2: $(getMediaDisk2)"'
''
'echo "<b>Plex</b>"'
'echo "&nbsp;&nbsp;Description: $(/home/plex/plex.sh description)"'
'getDockerStats "/home/plex/plex.sh" "&nbsp;&nbsp;"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/home/plex/plex.sh address)'"'"'>Link</a>"'
''
'echo "<b>Plex Meta Manager</b>"'
'echo "&nbsp;&nbsp;Description: $(/home/plexmeta/plexmeta.sh description)"'
'getDockerStats "/home/plexmeta/plexmeta.sh" "&nbsp;&nbsp;"'
''
'echo "<b>OMBI</b>"'
'echo "&nbsp;&nbsp;Description: $(/home/ombi/ombi.sh description)"'
'getDockerStats "/home/ombi/ombi.sh" "&nbsp;&nbsp;"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/home/ombi/ombi.sh address)'"'"'>Link</a>"'
''
'echo "<b>Sonarr</b>"'
'echo "&nbsp;&nbsp;Description: $(/home/sonarr/sonarr.sh description)"'
'getDockerStats "/home/sonarr/sonarr.sh" "&nbsp;&nbsp;"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/home/sonarr/sonarr.sh address)'"'"'>Link</a>"'
''
'echo "<b>Radarr</b>"'
'echo "&nbsp;&nbsp;Description: $(/home/radarr/radarr.sh description)"'
'getDockerStats "/home/radarr/radarr.sh" "&nbsp;&nbsp;"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/home/radarr/radarr.sh address)'"'"'>Link</a>"'
''
'echo "<b>Lidarr</b>"'
'echo "&nbsp;&nbsp;Description: $(/home/lidarr/lidarr.sh description)"'
'getDockerStats "/home/lidarr/lidarr.sh" "&nbsp;&nbsp;"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/home/lidarr/lidarr.sh address)'"'"'>Link</a>"'
''
'echo "<b>Bazarr</b>"'
'echo "&nbsp;&nbsp;Description: $(/home/bazarr/bazarr.sh description)"'
'getDockerStats "/home/bazarr/bazarr.sh" "&nbsp;&nbsp;"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/home/bazarr/bazarr.sh address)'"'"'>Link</a>"'
''
'echo "<b>Jackett</b>"'
'echo "&nbsp;&nbsp;Description: $(/home/jackett/jackett.sh description)"'
'getDockerStats "/home/jackett/jackett.sh" "&nbsp;&nbsp;"'
'echo "&nbsp;&nbsp;IP: $(/home/jackett/jackett.sh ip)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/home/jackett/jackett.sh address)'"'"'>Link</a>"'
''
'echo "<b>FlareSolverr</b>"'
'echo "&nbsp;&nbsp;Description: $(/home/flaresolverr/flaresolverr.sh description)"'
'getDockerStats "/home/flaresolverr/flaresolverr.sh" "&nbsp;&nbsp;"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/home/flaresolverr/flaresolverr.sh address)'"'"'>Link</a>"'
''
'echo "<b>Transmission</b>"'
'echo "&nbsp;&nbsp;Description: $(/home/transmission/transmission.sh description)"'
'getDockerStats "/home/transmission/transmission.sh" "&nbsp;&nbsp;"'
'echo "&nbsp;&nbsp;IP: $(/home/transmission/transmission.sh ip)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/home/transmission/transmission.sh address)'"'"'>Link</a>"'
''
'echo "<b>NZBGet</b>"'
'echo "&nbsp;&nbsp;Description: $(/home/nzbget/nzbget.sh description)"'
'getDockerStats "/home/nzbget/nzbget.sh" "&nbsp;&nbsp;"'
'echo "&nbsp;&nbsp;IP: $(/home/nzbget/nzbget.sh ip)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/home/nzbget/nzbget.sh address)'"'"'>Link</a>"'
''
'echo "<b>Compression - x264 - Ultra Fast</b>"'
'echo "&nbsp;&nbsp;Status: $(curl --location --silent localhost/compression/x264/ultrafast/status)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/compression/x264/ultrafast/start'"'"'>Start</a> | <a href='"'"'/compression/x264/ultrafast/output/info'"'"'>Output</a>"'
''
'echo "<b>Compression - x265 - Fast</b>"'
'echo "&nbsp;&nbsp;Status: $(curl --location --silent localhost/compression/x265/fast/status)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/compression/x265/fast/start'"'"'>Start</a> | <a href='"'"'/compression/x265/fast/output/info'"'"'>Output</a>"'
''
'echo "<b>Compression - x265 - Slow</b>"'
'echo "&nbsp;&nbsp;Status: $(curl --location --silent localhost/compression/x265/slow/status)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/compression/x265/slow/start'"'"'>Start</a> | <a href='"'"'/compression/x265/slow/output/info'"'"'>Output</a>"')


runAllCommandsInParralel() {
	local pids
	for i in $(echo ${!stats[@]}); do
		eval "${stats[$i]}" > "/tmp/status-${i}.result" &
		pids[${i}]=$!
	done
	for pid in ${pids[*]}; do
		wait $pid
	done
}

runAllCommands() {
	for i in $(echo ${!stats[@]}); do
		eval "${stats[$i]}" > "/tmp/status-${i}.result"
	done
}

getResults() {
	echo '<html><head><meta http-equiv="refresh" content="5"></head><body><p>'
	for i in $(echo ${!stats[@]}); do
		echo "$(cat "/tmp/status-${i}.result")"
		rm "/tmp/status-${i}.result"
		echo '<br/>'
	done
	echo '</p></body></html>'
}

while true; do
	runAllCommands 
	getResults > "$tmpStatusFile"
	mv "$tmpStatusFile" "$statusFile"
	sleep "$sleepTimeInSeconds"
done
