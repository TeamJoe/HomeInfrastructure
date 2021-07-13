#!/bin/bash
# /root/status.sh

getHostname() {
	echo "$(cat /proc/sys/kernel/hostname)"
}

getDate() {
	echo "$(date +"%D %T")"
}

getUptime() {
	local uptime="$(awk '{print $1}' /proc/uptime)"
	echo "$(($(date -d@$(printf '%.0f\n' "${uptime}") -u +%-j) - 1)) Days $(date -d@$(printf '%.0f\n' "${uptime}") -u +'%-H Hours %-M Minutes %-S Seconds')"
}

getCPU() {
	echo "$((100 - ($(vmstat | awk '{for(i=NF;i>0;i--)if($i=="id"){x=i;break}}END{print $x}'))))%"
}

getMemory() {
	echo "$((($(free | awk '/^Mem/ {print $3}')) / 1024))Mb/$((($(free | awk '/^Mem/ {print $2}')) / 1024))Mb"
}

getDisk() {
	local totalUsed="$(df | awk 'NR>2 && /^\/dev\//{sum+=$3}END{print sum}')"
	local mediaUsed="$(df | awk 'NR>2 && /^\/dev\/sda1/{sum+=$3}END{print sum}')"
	local totalAvailable="$(df | awk 'NR>2 && /^\/dev\//{sum+=$2}END{print sum}')"
	local mediaAvailable="$(df | awk 'NR>2 && /^\/dev\/sda1/{sum+=$2}END{print sum}')"
	
	echo "$((totalUsed - mediaUsed))kB/$((totalAvailable - mediaAvailable))kB"
}

getMediaDisk() {
	local mediaUsed="$(df -m | awk 'NR>2 && /^\/dev\/sda1/{sum+=$3}END{print sum}')"
	local mediaAvailable="$(df -m | awk 'NR>2 && /^\/dev\/sda1/{sum+=$2}END{print sum}')"
	
	echo "${mediaUsed}MB/${mediaAvailable}MB"
}

tmpStatusFile='/tmp/status.out'
statusFile='/root/status.out'
stats=('echo "<b>Server Stats</b>"'
'echo "&nbsp;&nbsp;Host: $(getHostname)"'
'echo "&nbsp;&nbsp;Date: $(getDate)"'
'echo "&nbsp;&nbsp;Uptime: $(getUptime)"'
'echo "&nbsp;&nbsp;CPU: $(getCPU)"'
'echo "&nbsp;&nbsp;Memory: $(getMemory)"'
'echo "&nbsp;&nbsp;Disk: $(getDisk)"'
'echo "&nbsp;&nbsp;Media Disk: $(getMediaDisk)"'
'echo ""'
'echo "<b>ServerHub</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/serverhub.sh status)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/root/serverhub.sh address)/status'"'"'>Status</a>"'
'echo ""'
'echo "<b>MediaHub</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/mediahub.sh status)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/root/mediahub.sh address)/status'"'"'>Status</a>"')

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

createResultFile() {
	runAllCommands
	getResults > "$tmpStatusFile"
	mv "$tmpStatusFile" "$statusFile"
}

createResultFile
cat "$statusFile"
