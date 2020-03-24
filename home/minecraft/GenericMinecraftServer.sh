#!/bin/bash

path="$1"; shift
minecraft_dir="$1"; shift
minecraft_jar="$1"; shift
input_file="${minecraft_dir}/logs/input.txt"
output_file="${minecraft_dir}/logs/output.log"
simple_output_file="${minecraft_dir}/logs/simple.log"

start_script="$1"; shift
minimum_server_boot_time=3600
minimum_disconnect_live_time=1200
list_player_command="$1"; shift
online_count_pattern="$1"; shift
player_list_pattern="$1"; shift
player_list_pattern_next_line="$1"; shift

#++++++++++++++++++++
#--------------------
# Simple Log Server Commands log|status|uptime|booted|started|active
#--------------------
#++++++++++++++++++++
simple_log_server="/server/SimpleLoggerServer.sh"

log() {
	$simple_log_server "$path" "$simple_output_file" log "$1"
}

getStatus() {
	echo "$($simple_log_server "$path" "$simple_output_file" status)"
}

getUptime() {
	echo "$($simple_log_server "$path" "$simple_output_file" uptime)"
}

isBooted() {
	echo "$($simple_log_server "$path" "$simple_output_file" booted)"
}

isStarted() {
	echo "$($simple_log_server "$path" "$simple_output_file" started)"
}

isActive() {
	echo "$($simple_log_server "$path" "$simple_output_file" active)"
}

#++++++++++++++++++++
#--------------------
# Local Commands 
#--------------------
#++++++++++++++++++++

clean() {
	killProcess "$(getProcess 'tail' 'tail')"
	killProcess "$(getProcess 'java' 'java')"
	rm -f "$input_file"
	rm -f "$output_file"
	rm -rf "${minecraft_dir}/logs"
	rm -rf "${minecraft_dir}/crash-reports"
}

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
		echo "eula=true" >> "${minecraft_dir}/eula.txt"
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

logger() {
	local server_started_pattern='Done[[:blank:]]\((.*)\)![[:blank:]]For[[:blank:]]help,[[:blank:]]type[[:blank:]]"help"'
	local player_join_pattern='([a-zA-Z0-9_-]*)[[:blank:]]joined[[:blank:]]the[[:blank:]]game'
	local player_leave_pattern='([a-zA-Z0-9_-]*)[[:blank:]]left[[:blank:]]the[[:blank:]]game'
	local server_stopped_pattern='Stopping[[:blank:]]the[[:blank:]]server'

	log "Server Starting"

	local line=""
	local match=""
	IFS=$'\n'

	tail --retry -f -n 10 "$output_file" | while read line; do
		match="$(regExMatch "$line" "$server_started_pattern" 1)"
		if [ -n "$match" ]; then
			log "Server Started ($match)"
		fi
		match="$(regExMatch "$line" "$server_stopped_pattern" 0)"
		if [ -n "$match" ]; then
			log "Server Stopped"
		fi
		match="$(regExMatch "$line" "$player_join_pattern" 1)"
		if [ -n "$match" ]; then
			log "Player Joined ($match)"
			log "Player Count $(getPlayerCount)"
		fi
		match="$(regExMatch "$line" "$player_leave_pattern" 1)"
		if [ -n "$match" ]; then
			log "Player Left ($match)"
			log "Player Count $(getPlayerCount)"
		fi
	done
}

getTruePlayerCount() {
	local match=""
	local player_count="-1"
	local list=""
	local line=""
	IFS=$'\n'
	
	echo "$list_player_command" >> "$input_file"
	sleep 2
	
	for line in $(tail -n 25 "$output_file"); do
		match="$(regExMatch "$line" "$online_count_pattern" 1)"
		if [ -n "$match" ]; then
			player_count="$match"
			list="$(regExMatch "$line" "$player_list_pattern" 3)"
			if [ "$player_list_pattern_next_line" == "true" ]; then
				list='next-line-is-player-list'
			fi
		elif [ "$list" == 'next-line-is-player-list' ]; then
			list="$(regExMatch "$line" "$player_list_pattern" 3)"
		fi
	done
	
	if [ "$list" == 'next-line-is-player-list' ]; then
		list=""
	fi
	
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

runServer() {
	logger > /dev/null 2>&1 &
	sh -c "cd $minecraft_dir; tail -f -n 0 $input_file | $start_script"
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
		echo "Sending 'stop' to $input_file"
		echo 'stop' >> "$input_file"
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
	else
		killProcess "$(getProcess 'tail' "${input_file}")"
		killProcess "$(getProcess 'tail' "${output_file}")"
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
	echo "$(getProcess 'java' "${minecraft_jar}")"
}

getProcess() {
	local type="$1"; shift
	local regex="$1"; shift
	
	local processesOfType="$(pidof "$type")"
	local processesOfRegex="$(ps aux | grep "$regex" | awk '{print $2}')"
	
	local C="$(echo ${processesOfType[@]} ${processesOfRegex[@]} | sed 's/ /\n/g' | sort | uniq -d)"
	echo "$(echo $C | sed -E "s/[[:space:]]\+/ /g")"
}

changePort() {
	local port="${1}"
	local rcon="$((${1} + 1000))"
	
	if ((port >= 1)); then
		sed -i "s/server-port=[0-9]*/server-port=${port}/g" "${minecraft_dir}/server.properties"
		sed -i "s/query.port=[0-9]*/query.port=${port}/g" "${minecraft_dir}/server.properties"
		sed -i "s/rcon.port=[0-9]*/rcon.port=${rcon}/g" "${minecraft_dir}/server.properties"
	fi
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
	local port="$1"; shift
	
	changePort "$port"
	if [ "$command" == 'start' ]; then
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
	elif [ "$command" == 'started' ]; then
		echo "$(isStarted)"
		connect='false'
	elif [ "$command" == 'running' ]; then
		echo "$(isRunning)"
		connect='false'
	elif [ "$command" == 'status' ]; then
		echo "$(getStatus)"
		connect='false'
	elif [ "$command" == 'uptime' ]; then
		echo "$(getUptime)"
		connect='false'
	elif [ "$command" == 'simple' ]; then
		tail -n 1000 "$simple_output_file"
		connect='false'
	elif [ "$command" == 'logs' ]; then
		tail -n 1000 "$output_file"
		connect='false'
	elif [ "$command" == 'active' ]; then
		echo "$(isActive)"
		connect='false'
	elif [ ! "$command" == 'connect' ]; then
		echo "Usage: $runPath [start|connect|input|output|clean|restart|stop|count|started|running|status|uptime|simple|logs|active] [-connect true|false] [-output on|off] [-service true|false] [-port ####]"
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
	local port="$(getInputVariable '0' 'port' ""$@"")"
	
	if [ "$command" == "direct-start" ]; then
		runServer
	elif [ ! "$output" == 'off' ]; then
		runCommand "$runPath" "$command" "$connect" "$service" "$port"
	else
		runCommand "$runPath" "$command" "$connect" "$service" "$port" > /dev/null 2>&1
	fi
}

execute "$path" "$@"
