#!/bin/bash

minecraft_dir='/home/joe/minecraft/FTB/Stoneblock/1.14.0'
minecraft_jar='FTBserver-1.12.2-14.23.5.2838-universal.jar'
input_file="${minecraft_dir}/logs/input.txt"
output_file="${minecraft_dir}/logs/output.log"

#start_script="java -server -Xmx16G -Xms16G -XX:+UseParNewGC -XX:+CMSIncrementalPacing -XX:+CMSClassUnloadingEnabled -XX:ParallelGCThreads=5 -XX:MinHeapFreeRatio=5 -XX:MaxHeapFreeRatio=10 -jar '$minecraft_jar' nogui"
start_script="java -server -Xms16G -Xmx16G -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=100 -XX:+DisableExplicitGC -XX:TargetSurvivorRatio=90 -XX:G1NewSizePercent=35 -XX:G1MaxNewSizePercent=60 -XX:G1MixedGCLiveThresholdPercent=50 -XX:+AlwaysPreTouch -jar '$minecraft_jar' nogui"

clean() {
	killProcess "$(ps aux | grep '[t]ail' | awk '{print $2}')"
	killProcess "$(ps aux | grep '[j]ava' | awk '{print $2}')"
	rm -f "$input_file"
	rm -f "$output_file"
	rm -rf "${minecraft_dir}/logs"
	rm -rf "${minecraft_dir}/crash-reports"
}

start() {
	if [ "$(isRunning)" == "true" ]; then
		echo "Cannot start: Server is already running"
	else
		mkdir -p "$(dirname ""$input_file"")"
		mkdir -p "$(dirname ""$output_file"")"
		rm -f "$input_file"
		rm -f "$output_file"
		touch "$input_file"
		touch "$output_file"
		nohup sh -c "cd $minecraft_dir; tail -f -n 0 $input_file | $start_script &" >> "$output_file" &
		sleep 10
	fi
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
		sleep 10
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
	
	if [ "$command" == 'start' ]; then
		start
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
		start
	elif [ "$command" == 'stop' ]; then
		stop
		connect='false'
	elif [ ! "$command" == 'connect' ]; then
		echo "Usage: $runPath [start|connect|input|output|clean|restart|stop] [-connect true|false] [-output on|off]"
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
	
	if [ ! "$output" == 'off' ]; then
		runCommand "$runPath" "$command" "$connect"
	else
		runCommand "$runPath" "$command" "$connect" > /dev/null 2>&1
	fi
}

execute "$0" "$@"
