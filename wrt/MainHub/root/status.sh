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
	local totalAvailable="$(df | awk 'NR>2 && /^\/dev\//{sum+=$2}END{print sum}')"
	
	echo "$((totalUsed))kB/$((totalAvailable))kB"
}

getTemperature() {
	local temp1="$(sensors | grep '.*temp1.*' | awk 'NR==1{print $2}' | cut -c 2-)"
	local temp2="$(sensors | grep '.*temp1.*' | awk 'NR==2{print $2}' | cut -c 2-)"
	local temp3="$(sensors | grep '.*temp2.*' | awk 'NR==1{print $2}' | cut -c 2-)"
	echo "$temp1 $temp2 $temp3"
}

getSsid() {
	local ssid1="$(cat /etc/config/wireless | grep '.*ssid.*' | awk 'NR==1{print $3}')"
	local ssid2="$(cat /etc/config/wireless | grep '.*ssid.*' | awk 'NR==2{print $3}')"
	local ssid3="$(cat /etc/config/wireless | grep '.*ssid.*' | awk 'NR==3{print $3}')"
	echo "${ssid1:1:-1} ${ssid2:1:-1} ${ssid3:1:-1}"
}

tmpStatusFile='/tmp/status.out'
statusFile='/root/status.out'
stats=('echo "<b>Server Stats</b>"'
'echo "&nbsp;&nbsp;Host: $(getHostname)"'
'echo "&nbsp;&nbsp;Date: $(getDate)"'
'echo "&nbsp;&nbsp;Uptime: $(getUptime)"'
'echo "&nbsp;&nbsp;SSID: $(getSsid)"'
'echo "&nbsp;&nbsp;CPU: $(getCPU)"'
'echo "&nbsp;&nbsp;Temperature: $(getTemperature)"'
'echo "&nbsp;&nbsp;Memory: $(getMemory)"'
'echo "&nbsp;&nbsp;Disk: $(getDisk)"'
'echo ""'
'echo "<b>MediaHub</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/mediahub.sh status)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/root/mediahub.sh address)/status'"'"'>Status</a>"'
'echo ""'
'echo "<b>HeavenHub</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/heavenhub.sh status)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/root/heavenhub.sh address)/status'"'"'>Status</a>"'
'echo ""'
'echo "<b>ServerHub</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/serverhub.sh status)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/root/serverhub.sh address)/status'"'"'>Status</a>"'
'echo ""'
'echo "<b>Portland 001</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/pdx-001.sh status)"'
'echo "&nbsp;&nbsp;Description: $(/root/pdx-001.sh description)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/pdx-001/start'"'"'>Start</a> | <a href='"'"'$(/root/pdx-001.sh ilo)'"'"'>iLO</a> | <a href='"'"'$(/root/pdx-001.sh address)/status'"'"'>Status</a>"'
'echo ""'
'echo "<b>Portland 002</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/pdx-002.sh status)"'
'echo "&nbsp;&nbsp;Description: $(/root/pdx-002.sh description)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/pdx-002/start'"'"'>Start</a> | <a href='"'"'$(/root/pdx-002.sh ilo)'"'"'>iLO</a> | <a href='"'"'$(/root/pdx-002.sh address)/status'"'"'>Status</a>"'
'echo ""'
'echo "<b>Portland 003</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/pdx-003.sh status)"'
'echo "&nbsp;&nbsp;Description: $(/root/pdx-003.sh description)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/pdx-003/start'"'"'>Start</a> | <a href='"'"'$(/root/pdx-003.sh ilo)'"'"'>iLO</a> | <a href='"'"'$(/root/pdx-003.sh address)/status'"'"'>Status</a>"'
'echo ""'
'echo "<b>Portland 004</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/pdx-004.sh status)"'
'echo "&nbsp;&nbsp;Description: $(/root/pdx-004.sh description)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/pdx-004/start'"'"'>Start</a> | <a href='"'"'$(/root/pdx-004.sh ilo)'"'"'>iLO</a> | <a href='"'"'$(/root/pdx-004.sh address)/status'"'"'>Status</a>"'
'echo ""'
'echo "<b>Davey Jones Locker</b>"'
'echo "&nbsp;&nbsp;Status: $(/root/daveyjoneslocker.sh status)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'$(/root/daveyjoneslocker.sh address)/status'"'"'>Status</a>"')

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
