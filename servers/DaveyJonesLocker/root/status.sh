#!/bin/bash
# /root/status.sh

getHostname() {
	echo "$(cat /proc/sys/kernel/hostname)"
}

getUptime() {
	local uptime="$1"
	echo "$(($(date -d@$(printf '%.0f\n' "${uptime}") -u +%-j) - 1)) Days $(date -d@$(printf '%.0f\n' "${uptime}") -u +'%-H Hours %-M Minutes %-S Seconds')"
}

getCPU() {
	echo "$((100 - ($(vmstat | awk '{for(i=NF;i>0;i--)if($i=="id"){x=i;break}}END{print $x}'))))%"
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
	local mediaUsed="$(df -m | awk 'NR>2 && /^\/dev\/sda1/{sum+=$3}END{print sum}')"
	local mediaAvailable="$(df -m | awk 'NR>2 && /^\/dev\/sda1/{sum+=$2}END{print sum}')"
	
	echo "${mediaUsed}MiB/${mediaAvailable}MiB"
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
'echo "<b>Plex</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/plex.sh status)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/root/plex.sh address)'"'"'>Link</a>"'
''
'echo "<b>Sonarr</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/sonarr.sh status)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/root/sonarr.sh address)'"'"'>Link</a>"'
''
'echo "<b>Radarr</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/radarr.sh status)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/root/radarr.sh address)'"'"'>Link</a>"'
''
'echo "<b>Lidarr</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/lidarr.sh status)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/root/lidarr.sh address)'"'"'>Link</a>"')


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

runAllCommands
getResults
