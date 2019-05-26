#!/bin/bash

input_file='/home/joe/input.txt'
output_file='/home/joe/output.log'
start_script_file='/opt/minecraft/ServerStart.sh'
minecraft_jar='FTBserver-1.12.2-14.23.5.2836-universal.jar'

start() {
	stop
	
	rm -rf $input_file
	rm -rf $output_file
	touch $input_file
	touch $output_file
	
	nohup sh -c "tail -f $input_file | sh $start_script_file" >> $output_file &

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
