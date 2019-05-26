#!/bin/bash

minecraft_dir='/home/joe/minecraft/Vanilla/1.14.1'
minecraft_jar='minecraft-server-1.14.1.jar'
input_file="${minecraft_dir}/logs/input.txt"
output_file="${minecraft_dir}/logs/output.log"

start_script="java -server -Xmx16384M -XX:+UseParNewGC -XX:+CMSIncrementalPacing -XX:+CMSClassUnloadingEnabled -XX:ParallelGCThreads=5 -XX:MinHeapFreeRatio=5 -XX:MaxHeapFreeRatio=10 -jar '$minecraft_jar' nogui"

clean() {
	rm -f "$input_file"
	rm -f "$output_file"
	rm -rf "${minecraft_dir}/logs"
}

start() {
	mkdir -p "$(dirname ""$input_file"")"
	mkdir -p "$(dirname ""$output_file"")"
	rm -f "$input_file"
	rm -f "$output_file"
	touch "$input_file"
	touch "$output_file"
	nohup sh -c "cd $minecraft_dir; tail -f -n 0 $input_file | $start_script" >> "$output_file" &
}

connect() {
	output &
	input
}

output() {
	tail -f -n 100 "$output_file"
}

input() {
	while IFS= read -r line; do
  		echo "$line" >> "$input_file"
	done
}

stop() {
	local process="$(getProcess)"
	if [ ! -z "$process" ]; then
		echo "Sending 'stop' to $input_file"
		echo 'stop' >> "$input_file"
		sleep 10
	fi
	
	local process="$(getProcess)"
	if [ ! -z "$process" ]; then
		echo "Stopping $process"
		kill $process
		sleep 10
	fi
	
	local process="$(getProcess)"
	if [ ! -z "$process" ]; then
		echo "Force stopping $process"
		kill -9 $process
		sleep 10
	fi
	
	local process="$(getProcess)"
	if [ ! -z "$process" ]; then
		echo "Unable to stop server"
	else
		local process="$(ps aux | grep "[t]ail -f -n 0 $input_file" | awk '{print $2}')"
		if [ ! -z "$process" ]; then
			kill -9 $process
		fi
	fi
}

getProcess() {
	echo "$(ps aux | grep "[j]ava.*-jar $minecraft_jar" | awk '{print $2}')"
}

if [ "$1" == 'start' ]; then
	stop
	start
	connect
elif [ "$1" == 'connect' ]; then
	connect
elif [ "$1" == 'input' ]; then
	input
elif [ "$1" == 'output' ]; then
	output
elif [ "$1" == 'clean' ]; then
	stop
	clean
elif [ "$1" == 'stop' ]; then
	stop
else
	echo "Usage: $0 [start|connect|input|output|clean|stop]"
fi
