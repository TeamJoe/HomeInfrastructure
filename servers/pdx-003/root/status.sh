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
	local temp1="$(sensors | grep '.*temp1:.*' | awk 'NR==3{print $2}' | cut -c 2-)"
	local temp2="$(sensors | grep '.*temp1:.*' | awk 'NR==1{print $2}' | cut -c 2-)"
	local temp3="$(sensors | grep '.*temp1:.*' | awk 'NR==2{print $2}' | cut -c 2-)"
	local temp4="$(sensors | grep '.*temp1:.*' | awk 'NR==4{print $2}' | cut -c 2-)"
	local temp5="$(sensors | grep '.*temp1:.*' | awk 'NR==5{print $2}' | cut -c 2-)"
	echo "$temp1 $temp2 $temp3 $temp4 $temp5"
}

getCPUTemperature() {
	local core000="$(sensors | grep '.*Core 0:.*' | awk 'NR==1{print $3}' | cut -c 2-)"
	local core001="$(sensors | grep '.*Core 1:.*' | awk 'NR==1{print $3}' | cut -c 2-)"
	local core002="$(sensors | grep '.*Core 2:.*' | awk 'NR==1{print $3}' | cut -c 2-)"
	local core003="$(sensors | grep '.*Core 3:.*' | awk 'NR==1{print $3}' | cut -c 2-)"
	local core004="$(sensors | grep '.*Core 4:.*' | awk 'NR==1{print $3}' | cut -c 2-)"
	local core005="$(sensors | grep '.*Core 5:.*' | awk 'NR==1{print $3}' | cut -c 2-)"
	local core006="$(sensors | grep '.*Core 6:.*' | awk 'NR==1{print $3}' | cut -c 2-)"
	local core007="$(sensors | grep '.*Core 7:.*' | awk 'NR==1{print $3}' | cut -c 2-)"
	local core100="$(sensors | grep '.*Core 0:.*' | awk 'NR==2{print $3}' | cut -c 2-)"
	local core101="$(sensors | grep '.*Core 1:.*' | awk 'NR==2{print $3}' | cut -c 2-)"
	local core102="$(sensors | grep '.*Core 2:.*' | awk 'NR==2{print $3}' | cut -c 2-)"
	local core103="$(sensors | grep '.*Core 3:.*' | awk 'NR==2{print $3}' | cut -c 2-)"
	local core104="$(sensors | grep '.*Core 4:.*' | awk 'NR==2{print $3}' | cut -c 2-)"
	local core105="$(sensors | grep '.*Core 5:.*' | awk 'NR==2{print $3}' | cut -c 2-)"
	local core106="$(sensors | grep '.*Core 6:.*' | awk 'NR==2{print $3}' | cut -c 2-)"
	local core107="$(sensors | grep '.*Core 7:.*' | awk 'NR==2{print $3}' | cut -c 2-)"
	echo "$core000 $core001 $core002 $core003 $core004 $core005 $core006 $core007 $core100 $core101 $core102 $core103 $core104 $core105 $core106 $core107"
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
'echo "&nbsp;&nbsp;CPU Temperature: $(getCPUTemperature)"'
'echo ""'
'echo "<b>$(/home/satisfactory/satisfactory.sh description)</b>"'
'echo "&nbsp;&nbsp;$(/home/satisfactory/satisfactory.sh info)"'
'echo "&nbsp;&nbsp;Status: $(/home/satisfactory/satisfactory.sh status)"'
'echo "&nbsp;&nbsp;Uptime: $(getUptime "$(/home/satisfactory/satisfactory.sh uptime)")"'
'echo "&nbsp;&nbsp;Remaining: $(getUptime "$(/home/satisfactory/satisfactory.sh active)")"'
'echo "&nbsp;&nbsp;Count: $(/home/satisfactory/satisfactory.sh list)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/satisfactory/1/start'"'"'>Start</a> | <a href='"'"'/satisfactory/1/logs'"'"'>Logs</a>"'
'echo ""'
'echo "<b>$(/home/satisfactory/satisfactory2.sh description)</b>"'
'echo "&nbsp;&nbsp;$(/home/satisfactory/satisfactory2.sh info)"'
'echo "&nbsp;&nbsp;Status: $(/home/satisfactory/satisfactory2.sh status)"'
'echo "&nbsp;&nbsp;Uptime: $(getUptime "$(/home/satisfactory/satisfactory2.sh uptime)")"'
'echo "&nbsp;&nbsp;Remaining: $(getUptime "$(/home/satisfactory/satisfactory2.sh active)")"'
'echo "&nbsp;&nbsp;Count: $(/home/satisfactory/satisfactory2.sh list)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/satisfactory/2/start'"'"'>Start</a> | <a href='"'"'/satisfactory/2/logs'"'"'>Logs</a>"'
'echo ""'
'echo "<b>$(/home/satisfactory/satisfactory3.sh description)</b>"'
'echo "&nbsp;&nbsp;$(/home/satisfactory/satisfactory3.sh info)"'
'echo "&nbsp;&nbsp;Status: $(/home/satisfactory/satisfactory3.sh status)"'
'echo "&nbsp;&nbsp;Uptime: $(getUptime "$(/home/satisfactory/satisfactory3.sh uptime)")"'
'echo "&nbsp;&nbsp;Remaining: $(getUptime "$(/home/satisfactory/satisfactory3.sh active)")"'
'echo "&nbsp;&nbsp;Count: $(/home/satisfactory/satisfactory3.sh list)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/satisfactory/3/start'"'"'>Start</a> | <a href='"'"'/satisfactory/3/logs'"'"'>Logs</a>"'
'echo ""')


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
