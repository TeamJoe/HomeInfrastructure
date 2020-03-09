#!/bin/bash

path="$1"; shift
name="$1"; shift
data_directory="$1"; shift
input_file="$1"; shift
output_file="$1"; shift
simple_output_file="$1"; shift
start_script="$1"; shift

minimum_server_boot_time=3600
minimum_disconnect_live_time=1200
list_player_command="c_listallplayers()"
online_count_pattern='\[[0-9]+:[0-9]+:[0-9]+\]:[[:blank:]]RemoteCommandInput:[[:blank:]]"c_listallplayers\(\)"'
player_list_pattern='\[[0-9]+:[0-9]+:[0-9]+\]:[[:blank:]]\[([0-9]+)\][[:blank:]]\(([a-zA-Z0-9_-]+)\)[[:blank:]](.*)[[:blank:]]<([a-zA-Z0-9_-]+)>'

start() {
	local service="$1"
	
	if [ "$(isRunning)" == "true" ]; then
		echo "Cannot start: Server is already running"
	else
		mkdir -p "$(dirname ""$input_file"")"
		mkdir -p "$(dirname ""$output_file"")"
		rm -f "$input_file"
		rm -f "$output_file"
		touch "$input_file"
		touch "$output_file"
		chmod 777 "$input_file"
		if [ ! "$service" == 'true' ]; then
			nohup "$path" direct-start >> "$output_file" &
			sleepUntil "true" 10
		else
			runServer |& tee "$output_file"
		fi
	fi
}

sleepUntil() {
	local started="$1"
	local value="$2"
	
	for (( c=0; c<=$value; c++ )); do
		if [ "$(isRunning)" == "$started" ]; then
			break
		fi
		sleep 1
	done
}

regex() {
	gawk 'match($0,/'$1'/, ary) {print ary['${2:-'0'}']}'
}

regExMatch() {
	local match="$(echo "$1" | regex "$2" 0)"
	if [ -n "$match" ]; then
		echo "$(echo "$1" | regex "$2" ${@:3})"
	fi
}

log() {
	echo "[$(date +"%D %T")] $1" >> "$simple_output_file"
}

logger() {
	local server_started_pattern=':[[:blank:]]\[Steam\][[:blank:]]SteamGameServer_Init[[:blank:]]success'
	local player_join_pattern=':[[:blank:]]\[Join[[:blank:]]Announcement\][[:blank:]](.*)'
	local player_leave_pattern=':[[:blank:]]\[Leave[[:blank:]]Announcement\][[:blank:]](.*)'
	local player_death_pattern=':[[:blank:]]\[Death[[:blank:]]Announcement\][[:blank:]](.*)'
	local server_stopped_pattern=':[[:blank:]]Shutting[[:blank:]]down'

	log "Server Starting"

	local line=""
	local match=""
	IFS=$'\n'

	tail --retry -f -n 10 "$output_file" | while read line; do
		match="$(regExMatch "$line" "$server_started_pattern" 0)"
		if [ -n "$match" ]; then
			log "Server Started"
		fi
		match="$(regExMatch "$line" "$server_stopped_pattern" 0)"
		if [ -n "$match" ]; then
			log "Server Stopped"
		fi
		match="$(regExMatch "$line" "$player_join_pattern" 1)"
		if [ -n "$match" ]; then
			match="$(echo -e "${match}" | tr -d '[:blank:]')"
			log "Player Joined ($match)"
			log "Player Count $(getPlayerCount)"
		fi
		match="$(regExMatch "$line" "$player_leave_pattern" 1)"
		if [ -n "$match" ]; then
			match="$(echo "$match" | awk '{$1=$1};1')"
			log "Player Left ($match)"
			log "Player Count $(getPlayerCount)"
		fi
		match="$(regExMatch "$line" "$player_death_pattern" 1)"
		if [ -n "$match" ]; then
			match="$(echo "$match" | awk '{$1=$1};1')"
			log "Player Died ($match)"
			log "Player Count $(getPlayerCount)"
		fi
	done
}

getTruePlayerCount() {
	local match=""
	local player_count="-1"
	local isMatched="false"
	local list=""
	local line=""
	IFS=$'\n'
	
	echo "$list_player_command" >> "$input_file"
	sleep 2
	
	for line in $(tail -n 50 "$output_file"); do
		match="$(regExMatch "$line" "$online_count_pattern" 0)"
		if [ -n "$match" ]; then
			isMatched="true"
			player_count="0"
			list=""
		fi
		
		match="$(regExMatch "$line" "$player_list_pattern" 0)"
		if [ -n "$match" ]; then
			match="$(regExMatch "$line" "$player_list_pattern" 1)"
			if [ -n "$match" ] && [ "$match" -gt "$player_count" ]; then
				player_count="$match"
			fi
			
			match="$(regExMatch "$line" "$player_list_pattern" 3)"
			if [ -n "$match" ]; then
				list="${list}'${match}' "
			fi
		fi
	done
	
	list="$(echo -e "${list}" | tr -d '[:space:]')"
	if [ "$player_count" == "-1" ]; then
		echo "Failed to get count"
	elif [ -z "$list" ]; then
		echo "$player_count"
	else
		echo "$player_count ($list)"
	fi
}

getEstimatedPlayerCount() {
	local match=""
	local player_count="0"
	local list=""
	
	local simple_server_started_pattern='\[([^\]]+)\][[:blank:]]Server[[:blank:]]Started'
	local simple_server_stopped_pattern='\[([^\]]+)\][[:blank:]]Server[[:blank:]]Stopped'
	local simple_server_join_pattern='\[([^\]]+)\][[:blank:]]Player[[:blank:]]Joined[[:blank:]]\((.*)\)'
	local simple_server_leave_pattern='\[([^\]]+)\][[:blank:]]Player[[:blank:]]Left[[:blank:]]\((.*)\)'
	
	IFS=$'\n'
	for line in $(cat "$simple_output_file"); do
		match="$(regExMatch "$line" "$simple_server_started_pattern" 0)"
		if [ -n "$match" ]; then
			player_count="0"
			list=""
		fi
		
		match="$(regExMatch "$line" "$simple_server_stopped_pattern" 0)"
		if [ -n "$match" ]; then
			player_count="0"
			list=""
		fi
		
		match="$(regExMatch "$line" "$simple_server_join_pattern" 0)"
		if [ -n "$match" ]; then
			player_count="$((player_count + 1))"
			match="$(regExMatch "$line" "$simple_server_join_pattern" 2)"
			match="$(echo "$match" | awk '{$1=$1};1')"
			if [ -n "$match" ]; then
				list="${list}${match}$IFS"
			fi
		fi
		
		match="$(regExMatch "$line" "$simple_server_leave_pattern" 0)"
		if [ -n "$match" ]; then
			player_count="$((player_count - 1))"
			match="$(regExMatch "$line" "$simple_server_leave_pattern" 2)"
			match="$(echo "$match" | awk '{$1=$1};1')"
			if [ -n "$match" ]; then
				local newList=""
				for item in $list; do
					if [ -n "$item" ] && [ "$item" != "$match" ]; then
						newList="${newList}${item}$IFS"
					fi
				done
				list="${newList}"
			fi
		fi
	done
	
	list="$(echo "$list" | awk '{$1=$1};1')"
	if [ "$player_count" -lt "0" ]; then
		echo "Failed to get count"
	elif [ -z "$list" ]; then
		echo "$player_count"
	else
		echo "$player_count ($list)"
	fi
}

getPlayerCount() {
	local trueCount="$(getTruePlayerCount)"
	
	if [ "$trueCount" == "Failed to get count" ]; then
		local estimatedCount="$(getEstimatedPlayerCount)"
		if [ "$estimatedCount" == "Failed to get count" ]; then
			echo "0"
		else
			echo "$estimatedCount"
		fi
	else
		echo "$trueCount"
	fi
}

getStartTime() {
	local simple_server_started_pattern='\[([^\]]+)\][[:blank:]]Server[[:blank:]]Started'

	local match=""
	local output=""
	local line=""
	
	IFS=$'\n'
	for line in $(cat "$simple_output_file"); do
		match="$(regExMatch "$line" "$simple_server_started_pattern" 1)"
		if [ -n "$match" ]; then
			output="$match"
		fi
	done
	
	echo "$output"
}

getLastActivityTime() {
	local simple_server_date_pattern='\[([0-9]+\/[0-9]+\/[0-9]+[[:blank:]]+[0-9]+:[0-9]+:[0-9]+)\]'

	local match=""
	local output=""
	local line=""
	
	IFS=$'\n'
	for line in $(tail -n 25 "$simple_output_file"); do
		match="$(regExMatch "$line" "$simple_server_date_pattern" 1)"
		if [ -n "$match" ]; then
			output="$match"
		fi
	done
	
	echo "$output"
}

isActive() {
	local currentTimeStamp="$(date +"%s")"
	local startTimeStamp="$(date -d"$(getStartTime)" +"%s")"
	local lastActivityTimeStamp="$(date -d"$(getLastActivityTime)" +"%s")"
	local timeSinceStart="$((currentTimeStamp-startTimeStamp))"
	local timeSinceActive="$((currentTimeStamp-lastActivityTimeStamp))"
	
	if [ "$(isRunning)" == "true" ] && [ ! "$(getPlayerCount)" == 0 ]; then
		echo "true"
	elif [ $minimum_server_boot_time -ge $timeSinceStart ]; then
		echo "true"
	elif [ $minimum_disconnect_live_time -ge $timeSinceActive ]; then
		echo "true"
	else
		echo "false"
	fi
}

runServer() {
	logger > /dev/null 2>&1 &
	sh -c "cd  /home/steam/steamapps/DST/bin; tail -f -n 0 $input_file | $start_script"
}

connect() {
	if [ "$(isRunning)" == "true" ]; then
		output &
		input
		
		if [ ! "$(isRunning)" == "true" ]; then
			killProcess "$(getProcess 'tail' "${input_file}")"
			killProcess "$(getProcess 'tail' "${output_file}")"
		fi
	else
		echo "Cannot connect: Server is not running"
	fi
}

output() {
	clear
	tail -f -n 1000 "$output_file"
}

input() {
	while IFS= read -r line; do
  		if [ "$(isRunning)" == "true" ]; then
			if [ "$line" == "disconnect" ]; then
				echo "Disconnecting from server"
				break;
			elif [ -n "$line" ]; then
				echo "$line" >> "$input_file"
			fi
		else
			echo "Server has disconnected"
			break
		fi
	done
}

stop() {
	if [ "$(isRunning)" == "true" ]; then
		echo "Sending 'c_shutdown(true)' to $input_file"
		echo 'c_shutdown(true)' >> "$input_file"
		sleepUntil "false" 60
	else
		echo "Cannot stop: Server is not running"
	fi

	if [ "$(isRunning)" == "true" ]; then
		stopProcess "$(getServerProcess)"
		sleepUntil "false" 30
	fi

	if [ "$(isRunning)" == "true" ]; then
		killProcess "$(getServerProcess)"
		sleepUntil "false" 10
	fi

	if [ "$(isRunning)" == "true" ]; then
		echo "Cannot stop: Server is still running after multiple attempts to stop"
	fi
}

stopProcess() {
	local process="$1"
	if [ -n "$process" ]; then
		echo "Stopping $process"
		kill $process
	fi
}

killProcess() {
	local process="$1"
	if [ -n "$process" ]; then
		echo "Force stopping $process"
		kill -9 $process
	fi
}

isRunning() {
	local process="$(getServerProcess)"
	if [ -n "$process" ]; then
		echo "true"
	else
		echo "false"
	fi
}

getServerProcess() {
	echo "$(getProcess 'dontstarve_dedicated_server_nullrenderer' "Cluster_1.*${name}")"
}

getProcess() {
	local type="$1"; shift
	local regex="$1"; shift

	local processesOfType="$(pidof "$type")"
	local processesOfRegex="$(ps aux | grep "$regex" | awk '{print $2}')"

	local C="$(echo ${processesOfType[@]} ${processesOfRegex[@]} | sed 's/ /\n/g' | sort | uniq -d)"
	echo "$(echo $C | sed -E "s/[[:space:]]\+/ /g")"
}

update() {
	/home/steam/steamcmd/steamcmd.sh +@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +login anonymous +force_install_dir /home/steam/steamapps/DST +app_update 343050 validate +quit
	/home/steam/steamapps/DST/bin/dontstarve_dedicated_server_nullrenderer -only_update_server_mods
}

getInputVariable() {
	local defaultValue="$1"; shift
	local expected="-${1}"; shift
	local returnNext='false'
	local returnValue="$defaultValue"
	
	for var in "$@"; do
		if [ "$returnNext" == 'true' ]; then
			local returnValue="$var"
			break
		elif [ "$var" == "$expected" ]; then
			local returnNext='true'
		fi
	done
	
	echo "$returnValue"
}

runCommand() {
	local runPath="$1"; shift
	local command="$1"; shift
	local connect="$1"; shift
	local service="$1"; shift
	
	if [ "$command" == 'update' ]; then
		stop
		update
	elif [ "$command" == 'start' ]; then
		start "$service"
	elif [ "$command" == 'input' ]; then
		input
		connect='false'
	elif [ "$command" == 'output' ]; then
		output
		connect='false'
	elif [ "$command" == 'clean' ]; then
		stop
		clean
		connect='false'
	elif [ "$command" == 'restart' ]; then
		stop
		start "$service"
	elif [ "$command" == 'stop' ]; then
		stop
		connect='false'
	elif [ "$command" == 'count' ]; then
		echo "$(getPlayerCount)"
		connect='false'
	elif [ "$command" == 'active' ]; then
		echo "$(isActive)"
		connect='false'
	elif [ ! "$command" == 'connect' ]; then
		echo "Usage: $runPath [start|connect|input|output|clean|restart|stop|count|active] [-connect true|false] [-output on|off] [-service true|false]"
		exit 1
	fi
	
	if [ "$command" == 'connect' ]; then
		connect
	elif [ ! "$connect" == 'false' ]; then
		connect
	fi
}

execute() {
	local runPath="$1"; shift
	local command="$1"; shift
	local connect="$(getInputVariable 'true' 'connect' ""$@"")"
	local output="$(getInputVariable 'on' 'output' ""$@"")"
	local service="$(getInputVariable 'false' 'service' ""$@"")"
	
	if [ "$command" == "direct-start" ]; then
		runServer
	elif [ ! "$output" == 'off' ]; then
		runCommand "$runPath" "$command" "$connect" "$service"
	else
		runCommand "$runPath" "$command" "$connect" "$service" > /dev/null 2>&1
	fi
}

execute "$path" "$@"

