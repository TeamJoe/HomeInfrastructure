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
	echo "$(df -m | awk 'NR>2 && /^\/dev\//{sum+=$3}END{print sum}')Mb/$(df -m | awk 'NR>2 && /^\/dev\//{sum+=$2}END{print sum}')Mb"
}

getAdapterTemperature() {
	local temp1="$(sensors | grep '.*temp1:.*' | awk 'NR==1{print $2}' | cut -c 2-)"
	echo "$temp1"
}

getCPUTemperature() {
	local core000="$(sensors | grep '.*Core 0:.*' | awk 'NR==1{print $3}' | cut -c 2-)"
	local core001="$(sensors | grep '.*Core 1:.*' | awk 'NR==1{print $3}' | cut -c 2-)"
	local core002="$(sensors | grep '.*Core 2:.*' | awk 'NR==1{print $3}' | cut -c 2-)"
	local core008="$(sensors | grep '.*Core 8:.*' | awk 'NR==1{print $3}' | cut -c 2-)"
	local core009="$(sensors | grep '.*Core 9:.*' | awk 'NR==1{print $3}' | cut -c 2-)"
	local core010="$(sensors | grep '.*Core 10:.*' | awk 'NR==1{print $3}' | cut -c 2-)"
	local core100="$(sensors | grep '.*Core 0:.*' | awk 'NR==2{print $3}' | cut -c 2-)"
	local core101="$(sensors | grep '.*Core 1:.*' | awk 'NR==2{print $3}' | cut -c 2-)"
	local core102="$(sensors | grep '.*Core 2:.*' | awk 'NR==2{print $3}' | cut -c 2-)"
	local core108="$(sensors | grep '.*Core 8:.*' | awk 'NR==2{print $3}' | cut -c 2-)"
	local core109="$(sensors | grep '.*Core 9:.*' | awk 'NR==2{print $3}' | cut -c 2-)"
	local core110="$(sensors | grep '.*Core 10:.*' | awk 'NR==2{print $3}' | cut -c 2-)"
	echo "$core000 $core001 $core002 $core008 $core009 $core010 $core100 $core101 $core102 $core108 $core109 $core110"
}

tmpStatusFile='/tmp/status.out'
statusFile='/home/joe/status.out'
stats=('echo "<b>Server Stats</b>"'
'echo "&nbsp;&nbsp;Host: $(getHostname)"'
'echo "&nbsp;&nbsp;Date: $(date +"%D %T")"'
'echo "&nbsp;&nbsp;Uptime: $(getUptime "$(awk '"'"'{print $1}'"'"' /proc/uptime)")"'
'echo "&nbsp;&nbsp;CPU: $(getCPU)"'
'echo "&nbsp;&nbsp;Memory: $(getMemory)"'
'echo "&nbsp;&nbsp;Disk: $(getDisk)"'
'echo "&nbsp;&nbsp;Adapter Temperature: $(getAdapterTemperature)"'
'echo "&nbsp;&nbsp;CPU Temperature: $(getCPUTemperature)"')


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
	wait 15
done
