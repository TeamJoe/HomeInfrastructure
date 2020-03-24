#!/bin/bash

tmpStatusFile='/tmp/status.out'
statusFile='/home/joe/status.out'
stats=('echo "Server Stats"'
'echo "  Date: $(date +"%D %T")"'
'echo "  Uptime: $(getUptime "$(awk '"'"'{print $1}'"'"' /proc/uptime)")"'
'echo "  CPU: $(echo "$((100 - ($(awk '"'"'{for(i=NF;i>0;i--)if($i=="id"){x=i;break}}END{print $x}'"'"' <(vmstat)))))")%"'
'echo "  Memory: $(awk '"'"'/^Total/ {print $3}'"'"' <(free -t -m))Mb/$(awk '"'"'/^Total/ {print $2}'"'"' <(free -t -m))Mb"'
'echo "  Disk: $(awk '"'"'/^total/ {print $3}'"'"' <(df -m --total))Mb/$(awk '"'"'/^total/ {print $2}'"'"' <(df -m --total))Mb"'
'echo "Mincraft ATM3 1.5.4"'
'echo "  Status: $(/home/minecraft/ATM3Server.sh status)"'
'echo "  Uptime: $(getUptime "$(/home/minecraft/ATM3Server.sh uptime)")"'
'echo "  Active: $(/home/minecraft/ATM3Server.sh active)"'
'echo "  Count: $(/home/minecraft/ATM3Server.sh count)"'
'echo "Mincraft ATM5 1.10.0"'
'echo "  Status: $(/home/minecraft/ATM5Server.sh status)"'
'echo "  Uptime: $(getUptime "$(/home/minecraft/ATM5Server.sh uptime)")"'
'echo "  Active: $(/home/minecraft/ATM5Server.sh active)"'
'echo "  Count: $(/home/minecraft/ATM5Server.sh count)"'
'echo "Mincraft Vanilla 1.15.2"'
'echo "  Status: $(/home/minecraft/VanillaServer.sh status)"'
'echo "  Uptime: $(getUptime "$(/home/minecraft/VanillaServer.sh uptime)")"'
'echo "  Active: $(/home/minecraft/VanillaServer.sh active)"'
'echo "  Count: $(/home/minecraft/VanillaServer.sh count)"'
'echo "DST Master"'
'echo "  Status: $(/home/steam/dst-master.sh status)"'
'echo "  Uptime: $(getUptime "$(/home/steam/dst-master.sh uptime)")"'
'echo "  Active: $(/home/steam/dst-master.sh active)"'
'echo "  Count: $(/home/steam/dst-master.sh count)"'
'echo "DST Caves"'
'echo "  Status: $(/home/steam/dst-caves.sh status)"'
'echo "  Uptime: $(getUptime "$(/home/steam/dst-caves.sh uptime)")"'
'echo "  Active: $(/home/steam/dst-caves.sh active)"'
'echo "  Count: $(/home/steam/dst-caves.sh count)"')

getUptime() {
	local uptime="$1"
	echo "$(($(date -d@$(printf '%.0f\n' "${uptime}") -u +%-j) - 1)) Days $(date -d@$(printf '%.0f\n' "${uptime}") -u +'%-H Hours %-M Minutes %-S Seconds')"
}

runAllCommands() {
	for i in $(echo ${!stats[@]}); do
		eval "${stats[$i]}"
	done
}

while true; do
	runAllCommands > "$tmpStatusFile"
	mv "$tmpStatusFile" "$statusFile"
done
