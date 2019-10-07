#!/bin/bash

minecraft_dir='/home/joe/minecraft/ATM3'
minecraft_jar='forge-1.12.2-14.23.5.2844-universal.jar'
input_file="${minecraft_dir}/logs/input.txt"
output_file="${minecraft_dir}/logs/output.log"

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

updateDomain() {
	#curl <REDACTED:http://freedns.afraid.org/dynamic/>
}

start() {
	local service="$1"
	
	updateDomain
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
			nohup sh -c "cd $minecraft_dir; tail -f -n 0 $input_file | $start_script &" >> "$output_file" &
			sleep 10
		elif
			(cd $minecraft_dir; $start_script |& tee "$output_file")
		fi
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
	elif [ "$command" == 'updatedomain' ]; then
		updateDomain
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
	elif [ ! "$command" == 'connect' ]; then
		echo "Usage: $runPath [start|connect|updatedomain|input|output|clean|restart|stop] [-connect true|false] [-output on|off] [-service true|false]"
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
