#!/bin/bash

path="$1"; shift
simple_output_file="$1"; shift

#++++++++++++++++++++
#--------------------
# External Commands count|running
#--------------------
#++++++++++++++++++++
getPlayerCount() {
	echo "$($path 'count')"
}

isRunning() {
	echo "$($path 'running')"
}

#++++++++++++++++++++
#--------------------
# Local Commands log|status|uptime|booted|started|active
#--------------------
#++++++++++++++++++++
log() {
	echo "[$(date +"%D %T")] $1" >> "$simple_output_file"
}

getStatus() {
	local currentTimeStamp="$(date +"%s")"
	local bootTimeStamp="$(date -d"$(getBootTime)" +"%s")"
	local startTimeStamp="$(date -d"$(getStartTime)" +"%s")"
	
	local serverBootTime="$(getTimeSinceServerBoot)"
	local bootTime="$((currentTimeStamp-bootTimeStamp))"
	local startTime="$((currentTimeStamp-startTimeStamp))"
	local running="$(isRunning)"
	local started="$(isStarted)"
	
	if [ "${running}" == "true" ]; then
		if [ "${started}" == "true" ]; then
			echo "Running"
		else
			echo "Starting"
		fi
	elif [ "$bootTime" -lt "$serverBootTime" ]; then
		if [ "$startTime" -lt "$bootTime" ]; then
			echo "Down"
		else
			echo "Failed to Boot"
		fi
	else
		echo "Not Booted"
	fi
}

getUptime() {
	if [ "$(isStarted)" != "true" ]; then
		echo "0"
	else
		local currentTimeStamp="$(date +"%s")"
		local startTimeStamp="$(date -d"$(getStartTime)" +"%s")"
		echo "$((currentTimeStamp-startTimeStamp))"
	fi
}

isBooted() {
	if [ "$(isRunning)" != "true" ]; then
		echo "false"
	else
		echo "true"
	fi
}

isStarted() {
	if [ "$(isRunning)" != "true" ]; then
		echo "false"
	else
		local bootTimeStamp="$(date -d"$(getBootTime)" +"%s")"
		local startTimeStamp="$(date -d"$(getStartTime)" +"%s")"
		
		if [ $startTimeStamp -ge $bootTimeStamp ]; then
			echo "true"
		else
			echo "false"
		fi
	fi
}

isActive() {
	if [ "$(isRunning)" != "true" ]; then
		echo "0"
	else
		local minimum_server_boot_time="$1"; shift
		local minimum_disconnect_live_time="$1"; shift

		local currentTimeStamp="$(date +"%s")"
		local startTimeStamp="$(date -d"$(getStartTime)" +"%s")"
		local lastActivityTimeStamp="$(date -d"$(getLastActivityTime)" +"%s")"
		local timeSinceStart="$((currentTimeStamp-startTimeStamp))"
		local timeSinceActive="$((currentTimeStamp-lastActivityTimeStamp))"
		
		local minimumBootRemaining="$((minimum_server_boot_time-timeSinceStart))"
		local minimumActiveRemaining="$((minimum_disconnect_live_time-timeSinceActive))"
		
		if [ ! "$(getPlayerCount)" == 0 ]; then
			if [ "$minimumBootRemaining" -ge "$minimum_disconnect_live_time" ]; then
				echo "$minimumBootRemaining"
			else
				echo "$minimum_disconnect_live_time"
			fi
		else
			if [ "$minimumBootRemaining" -ge 0 ] && [ "$minimumBootRemaining" -ge "$minimumActiveRemaining" ]; then
				echo "$minimumBootRemaining"
			elif [ "$minimumActiveRemaining" -ge 0 ]; then
				echo "$minimumActiveRemaining"
			else
				echo "0"
			fi
		fi
	fi
}

#++++++++++++++++++++
#--------------------
# Internal Helper Functions
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

extractLogValue() {
	local regex_pattern="$1"; shift
	local extract_group="$1"; shift
	local default_value="$1"; shift

	local match=""
	local output="$default_value"
	local line=""
	IFS=$'\n'
	
	for line in $(cat "$simple_output_file"); do
		match="$(regExMatch "$line" "$regex_pattern" $extract_group)"
		if [ -n "$match" ]; then
			output="$match"
		fi
	done
	
	echo "$output"
}

getBootTime() {
	local simple_server_starting_pattern='\[([^\]]+)\][[:blank:]]Server[[:blank:]]Starting'
	echo "$(extractLogValue "$simple_server_starting_pattern" 1 "")"
}

getStartTime() {
	local simple_server_started_pattern='\[([^\]]+)\][[:blank:]]Server[[:blank:]]Started'
	echo "$(extractLogValue "$simple_server_started_pattern" 1 "")"
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

getTimeSinceServerBoot() {
	date -d@$(printf '%.0f\n' "$(awk '{print $1}' /proc/uptime)") +"%s"
}

#++++++++++++++++++++
#--------------------
# Entry Point Functions
#--------------------
#++++++++++++++++++++

execute() {
	local command="$1"; shift
	
	if [ "$command" == 'log' ]; then
		log "$1"
	elif [ "$command" == 'extract' ]; then
		extractLogValue "$1" "$2" "$3"
	elif [ "$command" == 'status' ]; then
		echo "$(getStatus)"
	elif [ "$command" == 'uptime' ]; then
		echo "$(getUptime)"
	elif [ "$command" == 'booted' ]; then
		echo "$(isBooted)"
	elif [ "$command" == 'started' ]; then
		echo "$(isStarted)"
	elif [ "$command" == 'active' ]; then
		echo "$(isActive "$1" "$2")"
	else
		echo "Usage: $path [log|extract|status|uptime|booted|started|active] [log message]"
		exit 1
	fi
}

execute "$@"