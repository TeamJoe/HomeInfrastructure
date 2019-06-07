#!/bin/bash

minecraft_dir='/home/ec2-user/minecraft/Vanilla/1.14.2'
minecraft_jar='minecraft-server-1.14.2.jar'
input_file="${minecraft_dir}/logs/input.txt"
output_file="${minecraft_dir}/logs/output.log"

#start_script="java -server -Xmx16G -Xms16G -XX:+UseParNewGC -XX:+CMSIncrementalPacing -XX:+CMSClassUnloadingEnabled -XX:ParallelGCThreads=5 -XX:MinHeapFreeRatio=5 -XX:MaxHeapFreeRatio=10 -jar '$minecraft_jar' nogui"
#start_script="java -server -Xms16G -Xmx16G -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=100 -XX:+DisableExplicitGC -XX:TargetSurvivorRatio=90 -XX:G1NewSizePercent=35 -XX:G1MaxNewSizePercent=60 -XX:G1MixedGCLiveThresholdPercent=50 -XX:+AlwaysPreTouch -jar '$minecraft_jar' nogui"
start_script="java -server -Xmx868M -Xms868M -jar '$minecraft_jar' nogui"

clean() {
	rm -f "$input_file"
	rm -f "$output_file"
	rm -rf "${minecraft_dir}/logs"
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

if [ "$1" == 'start' ]; then
	start
	if [ ! "$2" == 'noConnect' ]; then
		connect
	fi
elif [ "$1" == 'connect' ]; then
	connect
elif [ "$1" == 'input' ]; then
	input
elif [ "$1" == 'output' ]; then
	output
elif [ "$1" == 'clean' ]; then
	stop
	clean
elif [ "$1" == 'restart' ]; then
	stop
	start
	if [ ! "$2" == 'noConnect' ]; then
		connect
	fi
elif [ "$1" == 'stop' ]; then
	stop
else
	echo "Usage: $0 [start|connect|input|output|clean|restart|stop] [noConnect]"
fi
