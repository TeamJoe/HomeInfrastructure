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
	local temp1="$(sensors | grep '.*temp1:.*' | awk 'NR==2{print $2}' | cut -c 2-)"
	local temp2="$(sensors | grep '.*temp1:.*' | awk 'NR==1{print $2}' | cut -c 2-)"
	echo "$temp1 $temp2"
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
'echo "<b>Factorio</b>"'
'echo "&nbsp;&nbsp;$(/home/factorio/FactorioServer.sh info)"'
'echo "&nbsp;&nbsp;Status: $(/home/factorio/FactorioServer.sh status)"'
'echo "&nbsp;&nbsp;Uptime: $(getUptime "$(/home/factorio/FactorioServer.sh uptime)")"'
'echo "&nbsp;&nbsp;Remaining: $(getUptime "$(/home/factorio/FactorioServer.sh active)")"'
'echo "&nbsp;&nbsp;Count: $(/home/factorio/FactorioServer.sh list)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/factorio/start'"'"'>Start</a> | <a href='"'"'/factorio/simple'"'"'>Overview</a> | <a href='"'"'/factorio/logs'"'"'>Logs</a>"'
'echo ""'
'echo "<b>Minecraft ATM3 1.6.0</b>"'
'echo "&nbsp;&nbsp;$(/home/minecraft/ATM3Server.sh info)"'
'echo "&nbsp;&nbsp;Status: $(/home/minecraft/ATM3Server.sh status)"'
'echo "&nbsp;&nbsp;Uptime: $(getUptime "$(/home/minecraft/ATM3Server.sh uptime)")"'
'echo "&nbsp;&nbsp;Remaining: $(getUptime "$(/home/minecraft/ATM3Server.sh active)")"'
'echo "&nbsp;&nbsp;Count: $(/home/minecraft/ATM3Server.sh count)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/atm3/start'"'"'>Start</a> | <a href='"'"'/atm3/simple'"'"'>Overview</a> | <a href='"'"'/atm3/logs'"'"'>Logs</a> | <a href='"'"'/atm3/download/All+The+Mods+3+-+Remix+2.0.0.zip'"'"'>Download</a>"'
'echo ""'
'echo "<b>Minecraft ATM5 1.10.0</b>"'
'echo "&nbsp;&nbsp;$(/home/minecraft/ATM5Server.sh info)"'
'echo "&nbsp;&nbsp;Status: $(/home/minecraft/ATM5Server.sh status)"'
'echo "&nbsp;&nbsp;Uptime: $(getUptime "$(/home/minecraft/ATM5Server.sh uptime)")"'
'echo "&nbsp;&nbsp;Remaining: $(getUptime "$(/home/minecraft/ATM5Server.sh active)")"'
'echo "&nbsp;&nbsp;Count: $(/home/minecraft/ATM5Server.sh count)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/atm5/start'"'"'>Start</a> | <a href='"'"'/atm5/simple'"'"'>Overview</a> | <a href='"'"'/atm5/logs'"'"'>Logs</a>"'
'echo ""'
'echo "<b>Minecraft Vanilla 1.15.2</b>"'
'echo "&nbsp;&nbsp;$(/home/minecraft/VanillaServer.sh info)"'
'echo "&nbsp;&nbsp;Status: $(/home/minecraft/VanillaServer.sh status)"'
'echo "&nbsp;&nbsp;Uptime: $(getUptime "$(/home/minecraft/VanillaServer.sh uptime)")"'
'echo "&nbsp;&nbsp;Remaining: $(getUptime "$(/home/minecraft/VanillaServer.sh active)")"'
'echo "&nbsp;&nbsp;Count: $(/home/minecraft/VanillaServer.sh count)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/vanilla/start'"'"'>Start</a> | <a href='"'"'/vanilla/simple'"'"'>Overview</a> | <a href='"'"'/vanilla/logs'"'"'>Logs</a>"'
'echo ""'
'echo "<b>Minecraft Vanilla 1.16.4</b>"'
'echo "&nbsp;&nbsp;$(/home/minecraft/Vanilla-1-16.sh info)"'
'echo "&nbsp;&nbsp;Status: $(/home/minecraft/Vanilla-1-16.sh status)"'
'echo "&nbsp;&nbsp;Uptime: $(getUptime "$(/home/minecraft/Vanilla-1-16.sh uptime)")"'
'echo "&nbsp;&nbsp;Remaining: $(getUptime "$(/home/minecraft/Vanilla-1-16.sh active)")"'
'echo "&nbsp;&nbsp;Count: $(/home/minecraft/Vanilla-1-16.sh count)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/vanilla-1-16/start'"'"'>Start</a> | <a href='"'"'/vanilla-1-16/simple'"'"'>Overview</a> | <a href='"'"'/vanilla-1-16/logs'"'"'>Logs</a>"'
'echo ""'
'echo "<b>Minecraft Vanilla 1.17.1</b>"'
'echo "&nbsp;&nbsp;$(/home/minecraft/Vanilla-1-17-1.sh info)"'
'echo "&nbsp;&nbsp;Status: $(/home/minecraft/Vanilla-1-17-1.sh status)"'
'echo "&nbsp;&nbsp;Uptime: $(getUptime "$(/home/minecraft/Vanilla-1-17-1.sh uptime)")"'
'echo "&nbsp;&nbsp;Remaining: $(getUptime "$(/home/minecraft/Vanilla-1-17-1.sh active)")"'
'echo "&nbsp;&nbsp;Count: $(/home/minecraft/Vanilla-1-17-1.sh count)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/vanilla-1-17-1/start'"'"'>Start</a> | <a href='"'"'/vanilla-1-17-1/simple'"'"'>Overview</a> | <a href='"'"'/vanilla-1-17-1/logs'"'"'>Logs</a>"'
'echo ""'
'echo "<b>Minecraft Vanilla 1.19.2</b>"'
'echo "&nbsp;&nbsp;$(/home/minecraft/Vanilla-1-19-2.sh info)"'
'echo "&nbsp;&nbsp;Status: $(/home/minecraft/Vanilla-1-19-2.sh status)"'
'echo "&nbsp;&nbsp;Uptime: $(getUptime "$(/home/minecraft/Vanilla-1-19-2.sh uptime)")"'
'echo "&nbsp;&nbsp;Remaining: $(getUptime "$(/home/minecraft/Vanilla-1-19-2.sh active)")"'
'echo "&nbsp;&nbsp;Count: $(/home/minecraft/Vanilla-1-19-2.sh count)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/vanilla-1-19-2/start'"'"'>Start</a> | <a href='"'"'/vanilla-1-19-2/simple'"'"'>Overview</a> | <a href='"'"'/vanilla-1-19-2/logs'"'"'>Logs</a>"'
'echo ""'
'echo "<b>Minecraft Modern RLCraft 1.5.0 with NuclearCraft 2.18y-1.12.2</b>"'
'echo "&nbsp;&nbsp;$(/home/minecraft/RLCraftServer.sh info)"'
'echo "&nbsp;&nbsp;Status: $(/home/minecraft/RLCraftServer.sh status)"'
'echo "&nbsp;&nbsp;Uptime: $(getUptime "$(/home/minecraft/RLCraftServer.sh uptime)")"'
'echo "&nbsp;&nbsp;Remaining: $(getUptime "$(/home/minecraft/RLCraftServer.sh active)")"'
'echo "&nbsp;&nbsp;Count: $(/home/minecraft/RLCraftServer.sh count)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/rlcraft/start'"'"'>Start</a> | <a href='"'"'/rlcraft/simple'"'"'>Overview</a> | <a href='"'"'/rlcraft/logs'"'"'>Logs</a>"'
'echo ""'
'echo "<b>Minecraft SkyFactory 4.2.2</b>"'
'echo "&nbsp;&nbsp;$(/home/minecraft/SkyFactory4Server.sh info)"'
'echo "&nbsp;&nbsp;Status: $(/home/minecraft/SkyFactory4Server.sh status)"'
'echo "&nbsp;&nbsp;Uptime: $(getUptime "$(/home/minecraft/SkyFactory4Server.sh uptime)")"'
'echo "&nbsp;&nbsp;Remaining: $(getUptime "$(/home/minecraft/SkyFactory4Server.sh active)")"'
'echo "&nbsp;&nbsp;Count: $(/home/minecraft/SkyFactory4Server.sh count)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/skyfactory4/start'"'"'>Start</a> | <a href='"'"'/skyfactory4/simple'"'"'>Overview</a> | <a href='"'"'/skyfactory4/logs'"'"'>Logs</a>"'
'echo ""'
'echo "<b>Minecraft SevTech: Ages 3.1.7</b>"'
'echo "&nbsp;&nbsp;$(/home/minecraft/SevTechServer.sh info)"'
'echo "&nbsp;&nbsp;Status: $(/home/minecraft/SevTechServer.sh status)"'
'echo "&nbsp;&nbsp;Uptime: $(getUptime "$(/home/minecraft/SevTechServer.sh uptime)")"'
'echo "&nbsp;&nbsp;Remaining: $(getUptime "$(/home/minecraft/SevTechServer.sh active)")"'
'echo "&nbsp;&nbsp;Count: $(/home/minecraft/SevTechServer.sh count)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/sevtech/start'"'"'>Start</a> | <a href='"'"'/sevtech/simple'"'"'>Overview</a> | <a href='"'"'/sevtech/logs'"'"'>Logs</a>"'
'echo ""'
'echo "<b>Don'"'"'t Starve Together - Overworld</b>"'
'echo "&nbsp;&nbsp;$(/home/steam/dst-master.sh info)"'
'echo "&nbsp;&nbsp;Status: $(/home/steam/dst-master.sh status)"'
'echo "&nbsp;&nbsp;Uptime: $(getUptime "$(/home/steam/dst-master.sh uptime)")"'
'echo "&nbsp;&nbsp;Remaining: $(getUptime "$(/home/steam/dst-master.sh active)")"'
'echo "&nbsp;&nbsp;Count: $(/home/steam/dst-master.sh count)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/dst/start'"'"'>Start</a> | <a href='"'"'/dst/simple'"'"'>Overview</a> | <a href='"'"'/dst/logs'"'"'>Logs</a>"'
'echo ""'
'echo "<b>Don'"'"'t Starve Together - Caves</b>"'
'echo "&nbsp;&nbsp;$(/home/steam/dst-caves.sh info)"'
'echo "&nbsp;&nbsp;Status: $(/home/steam/dst-caves.sh status)"'
'echo "&nbsp;&nbsp;Uptime: $(getUptime "$(/home/steam/dst-caves.sh uptime)")"'
'echo "&nbsp;&nbsp;Remaining: $(getUptime "$(/home/steam/dst-caves.sh active)")"'
'echo "&nbsp;&nbsp;Count: $(/home/steam/dst-caves.sh count)"'
'echo "&nbsp;&nbsp;Links: <a href='"'"'/caves/start'"'"'>Start</a> | <a href='"'"'/caves/simple'"'"'>Overview</a> | <a href='"'"'/caves/logs'"'"'>Logs</a>"')


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
