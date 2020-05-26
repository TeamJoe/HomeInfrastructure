#!/bin/sh
# /root/status.sh

getUptime() {
	local uptime="$1"
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


echo '<html><body><p>'
echo "<b>Server Stats</b><br/>"
echo "&nbsp;&nbsp;Date: $(date +"%D %T")<br/>"
echo "&nbsp;&nbsp;Uptime: $(getUptime "$(awk '{print $1}' /proc/uptime)")<br/>"
echo "&nbsp;&nbsp;CPU: $(getCPU)<br/>"
echo "&nbsp;&nbsp;Memory: $(getMemory)<br/>"
echo "&nbsp;&nbsp;Disk: $(getDisk)<br/>"
echo "<br/>"
echo "<b>Portland 004</b><br/>"
echo "&nbsp;&nbsp;Status: $(/root/pdx-004.sh status)<br/>"
echo "&nbsp;&nbsp;Links: <a href='/pdx-004/start'>Start</a> | <a href='$(/root/pdx-004.sh ilo)'>iLO</a> | <a href='$(/root/pdx-004.sh address)/status'>Status</a><br/>"
echo '</p></body></html>'
