#!/bin/bash

minecraft_dir='/home/joe/minecraft/FTB/Revelation/3.0.1'
minecraft_jar='FTBserver-1.12.2-14.23.5.2836-universal.jar'
input_file="${minecraft_dir}/logs/input.txt"
output_file="${minecraft_dir}/logs/output.log"

start_script='sh ServerStart.sh'

start() {
	stop
	
	rm -rf $input_file
	rm -rf $output_file
	touch $input_file
	touch $output_file
	
	nohup sh -c "cd $minecraft_dir; tail -f $input_file | $start_script" >> $output_file &

	connect
}

connect() {
	output &
	input
}

output() {
	tail -f "$output_file"
}

input() {
	while IFS= read -r line; do
  		echo "$line" >> $input_file
	done
}

stop() {
	local process="$(getProcess)"
	if [ ! -z "$process" ]; then
		echo "Sending 'stop' to $input_file"
		echo 'stop' >> $input_file
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
	fi
}

getProcess() {
	echo "$(ps aux | grep "[j]ava.*-jar $minecraft_jar" | awk '{print $2}')"
}

if [ "$1" == 'start' ]; then
	start
elif [ "$1" == 'connect' ]; then
	connect
elif [ "$1" == 'input' ]; then
	input
elif [ "$1" == 'output' ]; then
	output
elif [ "$1" == 'stop' ]; then
	stop
else
	echo "Usage: $0 [start|connect|input|output|stop]"
fi
