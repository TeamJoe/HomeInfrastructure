#!/bin/bash
# /root/status.sh

tmpStatusFile='/tmp/status.out'
statusFile='/home/joe/status.out'
sleepTimeInSeconds=60

getHostname() {
	echo "$(cat /proc/sys/kernel/hostname)"
}

getUptime() {
	local uptime="$1"
	echo "$(($(date -d@$(printf '%.0f\n' "${uptime}") -u +%-j) - 1)) Days $(date -d@$(printf '%.0f\n' "${uptime}") -u +'%-H Hours %-M Minutes %-S Seconds')"
}

getCPU() {
	echo "$((100 - ($(vmstat 1 2 | awk '{for(i=NF;i>0;i--)if($i=="id"){x=i;break}}END{print $x}'))))%"
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

getTemperature() {
	echo "$( sensors | grep '.*temp1.*' | awk '{print $2}' | cut -c 2-)"
}

stats=('echo "<b>Server Stats</b>"'
'echo "&nbsp;&nbsp;Host: $(getHostname)"'
'echo "&nbsp;&nbsp;Date: $(date +"%D %T")"'
'echo "&nbsp;&nbsp;Uptime: $(getUptime "$(awk '"'"'{print $1}'"'"' /proc/uptime)")"'
'echo "&nbsp;&nbsp;CPU: $(getCPU)"'
'echo "&nbsp;&nbsp;Temperature: $(getTemperature)"'
'echo "&nbsp;&nbsp;Memory: $(getMemory)"'
'echo "&nbsp;&nbsp;Disk: $(getDisk)"'
'echo "&nbsp;&nbsp;Media Drive: $(getMediaDisk)"'
''
'echo "<b>VPN</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/openpyn.sh status)"'
'echo "&nbsp;&nbsp;Description: $(/root/openpyn.sh description)"'
'echo "&nbsp;&nbsp;IP: $(curl ifconfig.co/)"'
''
'echo "<b>Plex</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/plex.sh status)"'
'echo "&nbsp;&nbsp;Description: $(/root/plex.sh description)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/root/plex.sh address)'"'"'>Link</a>"'
''
'echo "<b>Sonarr</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/sonarr.sh status)"'
'echo "&nbsp;&nbsp;Description: $(/root/sonarr.sh description)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/root/sonarr.sh address)'"'"'>Link</a>"'
''
'echo "<b>Radarr</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/radarr.sh status)"'
'echo "&nbsp;&nbsp;Description: $(/root/radarr.sh description)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/root/radarr.sh address)'"'"'>Link</a>"'
''
'echo "<b>Lidarr</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/lidarr.sh status)"'
'echo "&nbsp;&nbsp;Description: $(/root/lidarr.sh description)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/root/lidarr.sh address)'"'"'>Link</a>"'
''
'echo "<b>Bazarr</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/bazarr.sh status)"'
'echo "&nbsp;&nbsp;Description: $(/root/bazarr.sh description)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/root/bazarr.sh address)'"'"'>Link</a>"'
''
'echo "<b>Transmission</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/transmission.sh status)"'
'echo "&nbsp;&nbsp;IP: $(/root/transmission.sh ip)"'
'echo "&nbsp;&nbsp;Description: $(/root/transmission.sh description)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/root/transmission.sh address)'"'"'>Link</a>"'
''
'echo "<b>OMBI</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/ombi.sh status)"'
'echo "&nbsp;&nbsp;Description: $(/root/ombi.sh description)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/root/ombi.sh address)'"'"'>Link</a>"'
''
'echo "<b>Compression - Ultra Fast</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/compression.sh status ultrafast 3)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/compression/ultrafast/start'"'"'>Start</a> | <a href='"'"'/compression/ultrafast/output'"'"'>Output</a>"'
''
'echo "<b>Compression - Fast</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/compression.sh status fast 2)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/compression/fast/start'"'"'>Start</a> | <a href='"'"'/compression/fast/output'"'"'>Output</a>"'
''
'echo "<b>Compression - Very Slow</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/compression.sh status veryslow 1)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/compression/veryslow/start'"'"'>Start</a> | <a href='"'"'/compression/veryslow/output'"'"'>Output</a>"')


runAllCommands() {
	local pids
	for i in $(echo ${!stats[@]}); do
		eval "${stats[$i]}" > "/tmp/status-${i}.result" &
		pids[${i}]=$!
	done
	for pid in ${pids[*]}; do
		wait $pid
	done
}

getResults() {
	echo '<html><head><meta http-equiv="refresh" content="5"></head><body><p>'
	for i in $(echo ${!stats[@]}); do
		echo "$(cat "/tmp/status-${i}.result")"
		rm "/tmp/status-${i}.result"
		echo '</br>'
	done
	echo '</p></body></html>'
}

while true; do
	runAllCommands
	getResults > "$tmpStatusFile"
	mv "$tmpStatusFile" "$statusFile"
	sleep "$sleepTimeInSeconds"
done
