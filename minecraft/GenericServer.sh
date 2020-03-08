#!/bin/bash

path="$1"; shift
minecraft_dir="$1"; shift
minecraft_jar="$1"; shift
input_file="$1"; shift
output_file="$1"; shift
simple_output_file="$1"; shift

start_script="$1"; shift
minimum_server_boot_time="$1"; shift
minimum_disconnect_live_time="$1"; shift


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
		
		echo "eula=true" >> "${minecraft_dir}/eula.txt"
		if [ ! "$service" == 'true' ]; then
			nohup "$path" direct-start >> "$output_file" &
			sleep 10
		else
			runServer |& tee "$output_file"
		fi
	fi
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

getPlayerCount() {
	local online_count_pattern='There[[:blank:]]are[[:blank:]]([0-9]+)\/([0-9]+)[[:blank:]]players[[:blank:]]online'
	local player_list_pattern='(\[[^]]*\][[:blank:]]*)+:[[:blank:]]*(([a-zA-Z0-9_-]+[[:blank:]]*)*)'

	local match=""
	local player_count="-1"
	local list=""
	local line=""
	IFS=$'\n'
	
	echo "list players" >> "$input_file"
	sleep 2
	
	for line in $(tail -n 25 "$output_file"); do
		match="$(regExMatch "$line" "$online_count_pattern" 1)"
		if [ -n "$match" ]; then
			player_count="$match"
			list="next-line-is-player-list"
		elif [ "$list" == 'next-line-is-player-list' ]; then
			list="$(regExMatch "$line" "$player_list_pattern" 2)"
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
			if [ -n "$line" ]; then
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
		sleep 60
	else
		echo "Cannot stop: Server is not running"
	fi
	
	if [ "$(isRunning)" == "true" ]; then
		stopProcess "$(getServerProcess)"
		sleep 10
	fi
	
	if [ "$(isRunning)" == "true" ]; then
		killProcess "$(getServerProcess)"
		sleep 10
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
	
	if ((port >= 1)); then
		sed -i "s/server-port=[0-9]*/server-port=${port}/g" "${minecraft_dir}/server.properties"
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
	elif [ "$command" == 'active' ]; then
		echo "$(isActive)"
		connect='false'
	elif [ ! "$command" == 'connect' ]; then
		echo "Usage: $runPath [start|connect|input|output|clean|restart|stop|count|active] [-connect true|false] [-output on|off] [-service true|false] [-port ####]"
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
