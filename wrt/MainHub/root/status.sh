#!/bin/sh
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


echo '<html><head><meta http-equiv="refresh" content="30"></head><body><p>'
echo "<b>Server Stats</b><br/>"
echo "&nbsp;&nbsp;Host: $(getHostname)<br/>"
echo "&nbsp;&nbsp;Date: $(getDate)<br/>"
echo "&nbsp;&nbsp;Uptime: $(getUptime)<br/>"
echo "&nbsp;&nbsp;CPU: $(getCPU)<br/>"
echo "&nbsp;&nbsp;Memory: $(getMemory)<br/>"
echo "&nbsp;&nbsp;Disk: $(getDisk)<br/>"
echo "<br/>"
echo "<b>ServerHub</b><br/>"
echo "&nbsp;&nbsp;Status: $(/root/serverhub.sh status)<br/>"
echo "&nbsp;&nbsp;Links: <a href='$(/root/serverhub.sh address)/status'>Status</a><br/>"
echo '</p></body></html>'
