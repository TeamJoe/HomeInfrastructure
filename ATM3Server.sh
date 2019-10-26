#!/bin/bash

minecraft_dir='/home/joe/minecraft/ATM3'
minecraft_jar='forge-1.12.2-14.23.5.2844-universal.jar'
input_file="${minecraft_dir}/logs/input.txt"
output_file="${minecraft_dir}/logs/output.log"
simple_output_file="${minecraft_dir}/logs/simple.log"

#start_script='sh ServerStart.sh'
start_script="java -Xms64G -Xmx64G -d64 -server -XX:+AggressiveOpts -XX:ParallelGCThreads=3 -XX:+UseConcMarkSweepGC -XX:+UnlockExperimentalVMOptions -XX:+UseParNewGC -XX:+ExplicitGCInvokesConcurrent -XX:MaxGCPauseMillis=10 -XX:GCPauseIntervalMillis=50 -XX:+UseFastAccessorMethods -XX:+OptimizeStringConcat -XX:NewSize=84m -XX:+UseAdaptiveGCBoundary -XX:NewRatio=3 -Dfml.readTimeout=90 -Dfml.queryResult=confirm -jar \"${minecraft_jar}\" nogui"


clean() {
	killProcess "$(ps aux | grep '[t]ail' | awk '{print $2}')"
	killProcess "$(ps aux | grep '[j]ava' | awk '{print $2}')"
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
		if [ ! "$service" == 'true' ]; then
			nohup runServer >> "$output_file" &
			sleep 10
		else
			runServer |& tee "$output_file"
		fi
	fi
}

regex() {
	gawk 'match($0,/'$1'/, ary) {print ary['${2:-'0'}']}';
}

log() {
	echo "[$(date +"%D %T")] $1" >> "$simple_output_file"
}

server_started_pattern='Done[[:blank:]]\((.*)\)![[:blank:]]For[[:blank:]]help,[[:blank:]]type[[:blank:]]"help"'
player_join_pattern='([a-zA-Z0-9_-]*)[[:blank:]]joined[[:blank:]]the[[:blank:]]game'
player_leave_pattern='([a-zA-Z0-9_-]*)[[:blank:]]left[[:blank:]]the[[:blank:]]game'
server_stopped_pattern='Stopping[[:blank:]]the[[:blank:]]server'

logger() {
	log "Server Starting"

	local match=""
	local output=""
	IFS=$'\n'

	for line in $(tail -f -n 0 "$output_file" | grep --line-buffered '.*')
	do
		match=$(echo "$line" | regex "$server_started_pattern" 0)
		output=$(echo "$line" | regex "$server_started_pattern" 1)
		if [ ! -z "$match" ]; then
			log "Server Started ($output)"
		fi
		match=$(echo "$line" | regex "$server_stopped_pattern" 0)
		output=$(echo "$line" | regex "$server_stopped_pattern" 1)
		if [ ! -z "$match" ]; then
			log "Server Stopped"
		fi
		match=$(echo "$line" | regex "$player_join_pattern" 0)
		output=$(echo "$line" | regex "$player_join_pattern" 1)
		if [ ! -z "$match" ]; then
			log "Player Joined ($output)"
			log "$(getPlayerCount)"
		fi
		match=$(echo "$line" | regex "$player_leave_pattern" 0)
		output=$(echo "$line" | regex "$player_leave_pattern" 1)
		if [ ! -z "$match" ]; then
			log "Player Left ($output)"
			log "$(getPlayerCount)"
		fi
	done
}


online_count_pattern='There[[:blank:]]are[[:blank:]]([[:digit:]]+)\/([[:digit:]]+)[[:blank:]]players[[:blank:]]online'
player_list_pattern='(\[[^]]*\][[:blank:]]*)+:[[:blank:]]*(([a-zA-Z0-9_-]+[[:blank:]]*)*)'

getPlayerCount() {
	local match=""
	local output=""
	local count="-1"
	local list=""
	IFS=$'\n'
	
	echo "list players" >> "$input_file"
	sleep 1
	
	for line in $(tail -n 10 "$output_file" | grep --line-buffered '.*')
	do
		match=$(echo "$line" | regex "$online_count_pattern" 0)
		output=$(echo "$line" | regex "$online_count_pattern" 1)
		if [ ! -z "$match" ]; then
			count="$output"
			list="next-line-is-player-list"
		elif [ "$list" == 'next-line-is-player-list' ]; then
			list=$(echo "$line" | regex "$player_list_pattern" 2)
		fi
	done
	
	if [ "$list" == 'next-line-is-player-list' ]; then
		list=""
	fi
	
	if [ "$count" == "-1" ]; then
		echo "Failed to get count"
	elif [ -z "$list" ]; then
		echo "$count"
	else
		echo "$count ($list)"
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
			killProcess "$(ps aux | grep '[t]ail -f -n 1000' | awk '{print $2}')"
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
			if [ ! -z "$line" ]; then
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
		stopProcess "$(getProcess)"
		sleep 10
	fi
	
	if [ "$(isRunning)" == "true" ]; then
		killProcess "$(getProcess)"
		sleep 10
	fi
	
	if [ "$(isRunning)" == "true" ]; then
		echo "Cannot stop: Server is still running after multiple attempts to stop"
	else
		killProcess "$(ps aux | grep '[t]ail -f -n 0' | awk '{print $2}')"
	fi
}

stopProcess() {
	local process="$1"
	if [ ! -z "$process" ]; then
		echo "Stopping $process"
		kill $process
	fi
}

killProcess() {
	local process="$1"
	if [ ! -z "$process" ]; then
		echo "Force stopping $process"
		kill -9 $process
	fi
}

isRunning() {
	local process="$(getProcess)"
	if [ ! -z "$process" ]; then
		echo "true"
	else
		echo "false"
	fi
}

getProcess() {
	echo "$(ps aux | grep '[j]ava.*' | awk '{print $2}')"
}

getInputVariable() {
	local expected="-${2}"
	local defaultValue="$1"
	local returnNext='false'
	local returnValue="$defaultValue"
	
	for var in "${@:3}"; do
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
	local runPath="$1"
	local command="$2"
	local connect="$3"
	local service="$4"
	
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
	elif [ ! "$command" == 'connect' ]; then
		echo "Usage: $runPath [start|connect|input|output|clean|restart|stop|count] [-connect true|false] [-output on|off] [-service true|false]"
		exit 1
	fi
	
	if [ "$command" == 'connect' ]; then
		connect
	elif [ ! "$connect" == 'false' ]; then
		connect
	fi

}

execute() {
	local runPath="$1"
	local command="$2"
	local connect="$(getInputVariable 'true' 'connect' ""${@:3}"")"
	local output="$(getInputVariable 'on' 'output' ""${@:3}"")"
	local service="$(getInputVariable 'false' 'service' ""${@:3}"")"
	
	if [ ! "$output" == 'off' ]; then
		runCommand "$runPath" "$command" "$connect" "$service"
	else
		runCommand "$runPath" "$command" "$connect" "$service" > /dev/null 2>&1
	fi
}

execute "$0" "$@"
