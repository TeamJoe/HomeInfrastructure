#!/bin/bash

path="$1"; shift
init_directory="$1"; shift
game_directory="$1"; shift
external_address="$1"; shift
output_file="${game_directory}/factorio-current.log"
simple_output_file="${game_directory}/factorio-simple.log"
executable_file="${init_directory}/factorio"
config_file="${init_directory}/config"
server_pid_file="${game_directory}/server.pid"

minimum_server_boot_time=3600
minimum_disconnect_live_time=1200

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
	echo "$($simple_log_server "$path" "$simple_output_file" active "$minimum_server_boot_time" "$minimum_disconnect_live_time")"
}

extractLogValue() {
	echo "$($simple_log_server "$path" "$simple_output_file" extract "$1" "$2" "$3")"
}

#++++++++++++++++++++
#--------------------
# Local Commands 
#--------------------
#++++++++++++++++++++

regex() {
	gawk 'match($0,/'$1'/, ary) {print ary['${2:-'0'}']}'
}

regExMatch() {
	local match="$(echo "$1" | regex "$2" 0)"
	if [ -n "$match" ]; then
		echo "$(echo "$1" | regex "$2" ${@:3})"
	fi
}

getPort() {
	local line="$(cat "${config_file}" | awk '/PORT=.*/{print $1}')"
	echo "${line:5}"
}

changePort() {
	local port="${1}"
	
	if ((port >= 1)); then
		sed -i "s/PORT=[0-9]*/PORT=${port}/g" "${config_file}"
	fi
}

getPid() {
	if [ -f "${server_pid_file}" ]; then
		local pid="$(cat "${server_pid_file}")"
		local isUp="$(ps -p ${pid} | grep ${pid})"
		if [ -n "$isUp" ]; then
			echo "${pid}"
		fi
	fi
}

getPlayerList() {
	if [ "$(isRunning)" != "true" ]; then
		echo ""
	else
		echo "$(${executable_file} players-online)" | tr -s '[:blank:]' | tr -s '[:space:]' | xargs
	fi
}

getPlayerCount() {
	local list="$(getPlayerList)"
	if [ -z "$list" ]; then
		echo "0"
	else
		echo "$(echo "$list" | wc -w)"
	fi
}

getLastPlayerCount() {
	local simple_player_count_pattern='\[([^\]]+)\][[:blank:]]Player[[:blank:]]Count[[:blank:]]([0-9]+)'
	echo "$(extractLogValue "$simple_player_count_pattern" 2 "0")"
}

updateLog() {
	if [ "$(isRunning)" == "true" ]; then
		if [ "$(isStarted)" != "true" ]; then
			log "Server Started"
			log "Player Count $(getPlayerCount)"
			log "Player List: $(getPlayerList)"
		elif [ "$(getPlayerCount)" != "$(getLastPlayerCount)" ]; then
			log "Player Count $(getPlayerCount)"
			log "Player List: $(getPlayerList)"
		fi
	fi
}

isRunning() {
	local process="$(getPid)"
	if [ -n "$process" ]; then
		echo "true"
	else
		echo "false"
	fi
}

start() {
	log "Server Starting"
	${executable_file} start
}

stop() {
	log "Server Stopped"
	${executable_file} stop
}

restart() {
	log "Server Stopped"
	log "Server Starting"
	${executable_file} restart
}

update() {
	log "Server Updating"
	${executable_file} update
}

getVersion() {
	echo "$(${executable_file} version)"
}

info() {
	local port="$(getPort)"
	if [ -n "$port" ]; then
		echo "Version: $(getVersion) Address: ${external_address}:${port}"
	else
		echo "Version: $(getVersion) Address: ${external_address}"
	fi
}

runCommand() {
	local runPath="$1"; shift
	local command="$1"; shift
	local update="$1"; shift
	local port="$1"; shift
	
	changePort "$port"	
	if [ "$update" == 'true' ]; then
		update
	fi

	if [ "$command" != 'running' ] && [ "$command" != 'count' ]; then
		updateLog
	fi
	
	if [ "$command" == 'start' ]; then
		start
	elif [ "$command" == 'restart' ]; then
		restart
	elif [ "$command" == 'stop' ]; then
		stop
	elif [ "$command" == 'count' ]; then
		echo "$(getPlayerCount)"
	elif [ "$command" == 'list' ]; then
		echo "$(getPlayerCount) $(getPlayerList)"
	elif [ "$command" == 'started' ]; then
		echo "$(isStarted)"
	elif [ "$command" == 'running' ]; then
		echo "$(isRunning)"
	elif [ "$command" == 'status' ]; then
		echo "$(getStatus)"
	elif [ "$command" == 'uptime' ]; then
		echo "$(getUptime)"
	elif [ "$command" == 'simple' ]; then
		tail -n 1000 "$simple_output_file"
	elif [ "$command" == 'logs' ]; then
		tail -n 1000 "$output_file"
	elif [ "$command" == 'active' ]; then
		echo "$(isActive)"
	elif [ "$command" == 'info' ]; then
		echo "$(info)"
	else
		echo "Usage: $runPath [start|restart|stop|count|list|started|running|status|uptime|simple|logs|active|info] [-update true|false] [-port ####]"
		exit 1
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

execute() {
	local runPath="$1"; shift
	local command="$1"; shift
	local update="$(getInputVariable 'false' 'update' ""$@"")"
	local port="$(getInputVariable '0' 'port' ""$@"")"
	
	runCommand "$runPath" "$command" "$update" "$port"
}

execute "$path" "$@"

