#!/bin/bash
# /root/status.sh

tmpStatusFile=/tmp/status.out
statusFile=/root/status.out
sleepTimeInSeconds=60

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
	echo "$((100 - ($(vmstat 1 2 | awk '{for(i=NF;i>0;i--)if($i=="id"){x=i;break}}END{print $x}'))))%"
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
	local radioNumber="$1"
	local radioName="$(uci get wireless.@wifi-iface[$radioNumber].device)"
	local ifname="$(ubus call network.wireless status | jsonfilter -e "@.${radioName}.interfaces[0].ifname")"
	local ssid="$(uci get wireless.@wifi-iface[$radioNumber].ssid)"
	local configuredChannel="$(uci get wireless.@wifi-device[$radioNumber].channel)"
	if [ "$configuredChannel" = "auto" ]; then
		local actualChannel="$(iwinfo $ifname info | grep -o 'Channel.*' | grep -o '\d*' | awk 'NR==1{print $1}')"
		local channel="${configuredChannel}:${actualChannel:=Unknown}"
	else
		local channel="$configuredChannel"
	fi
	local frequency="$(iwinfo $ifname info | grep -o 'Channel.*' | grep -o '\d*\.\d*')"
	local deviceCount="$(iwinfo $ifname assoclist | grep -c '^[0-9a-fA-F][0-9a-fA-F]:.*$')"
	local signalPower="$(iwinfo $ifname info | grep -o 'Tx-Power: [0-9]*' | grep -o '[0-9]*')"
	local isOnline="$( if [ -n "$signalPower" ] && [ "$signalPower" -gt 0 ]; then echo 'Online'; else echo 'Offline'; fi )"
	echo "${isOnline:=Offline} (${deviceCount:=0}) '${ssid}' ${frequency:=0}Ghz (${channel:=0})"
}

stats=('echo "<b>Server Stats</b>"'
'echo "&nbsp;&nbsp;Host: $(getHostname)"'
'echo "&nbsp;&nbsp;Date: $(getDate)"'
'echo "&nbsp;&nbsp;Uptime: $(getUptime)"'
'echo "&nbsp;&nbsp;SSID 1: $(getSsid 0)"'
'echo "&nbsp;&nbsp;SSID 2: $(getSsid 1)"'
'echo "&nbsp;&nbsp;SSID 3: $(getSsid 2)"'
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


while true; do
	runAllCommands
	getResults > "$tmpStatusFile"
	mv "$tmpStatusFile" "$statusFile"
	sleep "$sleepTimeInSeconds"
done

