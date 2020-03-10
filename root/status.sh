#!/bin/bash

tmpStatusFile='/tmp/status.out'
statusFile='/home/joe/status.out'
stats=('echo "Server Stats"'
'echo "  Date: $(date +"%D %T")"'
'echo "  Uptime: $(($(date -d@$(printf '"'"'%.0f\n'"'"' "$(awk '"'"'{print $1}'"'"' /proc/uptime)") -u +%-j) - 1)) Days $(date -d@$(printf '"'"'%.0f\n'"'"' "$(awk '"'"'{print $1}'"'"' /proc/uptime)") -u +'"'"'%-H Hours %-M Minutes %-S Seconds'"'"')"'
'echo "Mincraft ATM3 1.5.1"'
'echo "  Started: $(/home/minecraft/ATM3Server.sh started)"'
'echo "  Running: $(/home/minecraft/ATM3Server.sh running)"'
'echo "  Active: $(/home/minecraft/ATM3Server.sh active)"'
'echo "  Count: $(/home/minecraft/ATM3Server.sh count)"'
'echo "Mincraft ATM5 1.10.0"'
'echo "  Started: $(/home/minecraft/ATM5Server.sh started)"'
'echo "  Running: $(/home/minecraft/ATM5Server.sh running)"'
'echo "  Active: $(/home/minecraft/ATM5Server.sh active)"'
'echo "  Count: $(/home/minecraft/ATM5Server.sh count)"'
'echo "Mincraft Vanilla 1.15.2"'
'echo "  Started: $(/home/minecraft/VanillaServer.sh started)"'
'echo "  Running: $(/home/minecraft/VanillaServer.sh running)"'
'echo "  Active: $(/home/minecraft/VanillaServer.sh active)"'
'echo "  Count: $(/home/minecraft/VanillaServer.sh count)"'
'echo "DST Master"'
'echo "  Started: $(/home/steam/dst-master.sh started)"'
'echo "  Running: $(/home/steam/dst-master.sh running)"'
'echo "  Active: $(/home/steam/dst-master.sh active)"'
'echo "  Count: $(/home/steam/dst-master.sh count)"'
'echo "DST Caves"'
'echo "  Started: $(/home/steam/dst-caves.sh started)"'
'echo "  Running: $(/home/steam/dst-caves.sh running)"'
'echo "  Active: $(/home/steam/dst-caves.sh active)"'
'echo "  Count: $(/home/steam/dst-caves.sh count)"')

runAllCommands() {
	for i in $(echo ${!stats[@]}); do
		eval "${stats[$i]}"
	done
}

while true; do
	runAllCommands > "$tmpStatusFile"
	mv "$tmpStatusFile" "$statusFile"
done
