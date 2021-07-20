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
	echo "$(df -m | awk 'NR>2 && /^\/dev\//{sum+=$3}END{print sum}')Mb/$(df -m | awk 'NR>2 && /^\/dev\//{sum+=$2}END{print sum}')Mb"
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
'echo "&nbsp;&nbsp;Disk: $(getDisk)"')

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