#!/bin/bash
# /home/satisfactory/GenericSatisfactoryServer.sh

path="$1"; shift
tag="$1"; shift
service="$1"; shift
user="$1"; shift
description="$1"; shift
address="$1"; shift
serverport="$1"; shift
beaconport="$1"; shift
queryport="$1"; shift
installDirectory="$1"; shift
command="$1"; shift
externalAddress="${address}:${queryport}"
startParameters=$(echo \
                "--publish ${serverport}:${serverport}/udp" \
                "--publish ${beaconport}:${beaconport}/udp" \
                "--publish ${queryport}:${queryport}/udp" \
                "--env PORT_SERVER_QUERY=${queryport}" \
                "--env PORT_BEACON=${beaconport}" \
                "--env PORT_SERVER=${serverport}" \
                "--env AUTO_UPDATE=true" \
                "--env PUID=$(id -u ${user})" \
                "--env PGID=$(id -g ${user})" \
                "--env TZ=${timezone}" \
                "--mount type=bind,source=${installDirectory}/logs,target=/home/satisfactory/FactoryGame/Saved/Logs" \
                "--mount type=bind,source=${installDirectory}/config,target=/home/satisfactory/FactoryGame/Saved/Config/LinuxServer" \
                "--mount type=bind,source=${installDirectory}/saves,target=/home/satisfactory/.config/Epic/FactoryGame/Saved/SaveGames" \
                "--mount type=bind,source=${installDirectory}/GUID.ini,target=/home/satisfactory/.config/Epic/FactoryGame/GUID.ini" \
                "--restart unless-stopped ${tag}" \
                )

minimum_server_boot_time=3600
minimum_disconnect_live_time=1200

server_start_regex='\[([^\]]+)\].*Created[[:blank:]]socket[[:blank:]]for[[:blank:]]bind[[:blank:]]address'
player_join_regex='Join[[:blank:]]succeeded:[[:blank:]](.+)'
player_leave_regex='UNetConnection::Close.*Driver:[[:blank:]]GameNetDriver.*UniqueId:[[:blank:]]([^,]+),'


#++++++++++++++++++++
#--------------------
# Helper Functions
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

getSimpleLogFile() {
	echo "${installDirectory}/logs/$(ls -Art "${installDirectory}/logs/"simple* | tail --lines=1)"
}


getLogFile() {
	echo "${installDirectory}/logs/FactoryGame.log"
}

extractLogValue() {
	local regex_pattern="$1"; shift
	local extract_group="$1"; shift
	local default_value="$1"; shift
	local get_last="$1"; shift

	local match=""
	local output="$default_value"
	local line=""
	IFS=$'\n'
	
	for line in $(cat "$(getLogFile)"); do
		match="$(regExMatch "$line" "$regex_pattern" $extract_group)"
		if [ -n "$match" ]; then
			output="$match"
			if [[ "$get_last" != "true" ]]; then
				break;
			fi
		fi
	done
	
	echo "$output"
}

regexCount() {
  local regex="${1}"
  local value="${2}"

  if [[ -p /dev/stdin ]]; then
    cat - | grep --count --extended-regexp "${regex}"
  else
    echo "${value}" | grep --count --extended-regexp "${regex}"
  fi
}


callParent() {
	local command="$1"; shift
	/server/DockerService.sh "$path" "$service" "$description" "$externalAddress" "$startParameters" "$command"
}

processDate()
{
	local rawDate=''
	local count=0
	local date=''
	local output=''
	
	rawDate="$1"; shift
	rawDate="$( echo "${rawDate//[-:\. ]/ }" | tr ' ' '\n' )"
	
	IFS=$'\n'
	for date in $rawDate
	do
		if [[ "$count" -lt 2 ]]; then
			output="${output}${date}-"
		elif [[ "$count" -eq 2 ]]; then
			output="${output}${date} "
		elif [[ "$count" -lt 5 ]]; then
			output="${output}${date}:"
		elif [[ "$count" -eq 5 ]]; then
			output="${output}${date}"
		fi
		count="$(($count + 1))"
	done
	
	echo "$(date --date="${output}" +"%s")"
}

#++++++++++++++++++++
#--------------------
# Last Event Time
#--------------------
#++++++++++++++++++++

getBootTime() {
	local fileNameMatcher='log-([^\.]+).log'
	local rawDate=''
	
	rawDate="$(regExMatch "$(getSimpleLogFile)" "$fileNameMatcher" 1)"
	echo "$(processDate "$rawDate")"
}

getStartTime() {
	local rawDate=''
	
	rawDate="$(extractLogValue "$server_start_regex" 1 "" "false")"
	echo "$(processDate "$rawDate")"
}

getTimeSinceServerBoot() {
	date -d@$(printf '%.0f\n' "$(awk '{print $1}' /proc/uptime)") +"%s"
}

getLastActivityTime() {
	local simple_server_date_pattern='\[([^\]]+)\].*'

	local rawDate=''
	local count=0
	local date=''
	local output=''

	local match=""
	local output=""
	local line=""
	IFS=$'\n'
	
	for line in $(tail --lines=25 "$(getLogFile)"); do
		match="$(regExMatch "$line" "$simple_server_date_pattern" 1)"
		if [ -n "$match" ]; then
			output="$match"
		fi
	done
	
	if [ -n "$output" ]; then
		echo "$(processDate "$output")"
	fi
}

getUptime() {
	if [ "$(isStarted)" != "true" ]; then
		echo "0"
	else
		local currentTimeStamp="$(date +"%s")"
		local startTimeStamp="$(getStartTime)"
		echo "$((currentTimeStamp-startTimeStamp))"
	fi
}


#++++++++++++++++++++
#--------------------
# Server State
#--------------------
#++++++++++++++++++++

isBooted() {
	if [ "$(callParent "status")" != "Powered On" ]; then
		echo "false"
	else
		echo "true"
	fi
}

isStarted() {
	if [ "$(isBooted)" != "true" ]; then
		echo "false"
	else
		local bootTimeStamp="$(getBootTime)"
		local startTimeStamp="$(getStartTime)"
		
		if [ $startTimeStamp -ge $bootTimeStamp ]; then
			echo "true"
		else
			echo "false"
		fi
	fi
}

getPlayerCount() {
	if [ "$(isStarted)" != "true" ]; then
		echo "0"
	else
		local joined="$(cat "$(getLogFile)" | regexCount "$player_join_regex")"
		local left="$(cat "$(getLogFile)" | regexCount "$player_leave_regex")"
		echo "$(($joined - $left))"
	fi
}

isActive() {
	local currentTimeStamp=''
	local startTimeStamp=''
	local lastActivityTimeStamp=''
	local timeSinceStart=''
	local timeSinceActive=''
	local minimumBootRemaining=''
	local minimumActiveRemaining=''

	currentTimeStamp="$(date +"%s")"
	if [ "$(isStarted)" != "true" ]; then
		if [ "$(isBooted)" == "true" ]; then
			startTimeStamp="$(getBootTime)"
			timeSinceStart="$((currentTimeStamp-startTimeStamp))"
			minimumBootRemaining="$((minimum_server_boot_time-timeSinceStart))"
			if [ "$minimumBootRemaining" -ge "0" ]; then
				echo "$minimumBootRemaining"
			else
				echo "0"
			fi
		else
			echo "0"
		fi
	else
		startTimeStamp="$(getStartTime)"
		timeSinceStart="$((currentTimeStamp-startTimeStamp))"
		minimumBootRemaining="$((minimum_server_boot_time-timeSinceStart))"
		
		if [ ! "$(getPlayerCount)" == 0 ]; then
			if [ "$minimumBootRemaining" -ge "$minimum_disconnect_live_time" ]; then
				echo "$minimumBootRemaining"
			else
				echo "$minimum_disconnect_live_time"
			fi
		else
			lastActivityTimeStamp="$(getLastActivityTime)"
			timeSinceActive="$((currentTimeStamp-lastActivityTimeStamp))"
			minimumActiveRemaining="$((minimum_disconnect_live_time-timeSinceActive))"
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

getStatus() {
	local currentTimeStamp=''
	local bootTimeStamp=''
	local startTimeStamp=''
	local serverBootTime=''
	local bootTime=''
	local startTime=''
	
	if [ "$(isBooted)" == "true" ]; then
		if [ "$(isStarted)" == "true" ]; then
			echo "Running"
		else
			echo "Starting"
		fi
	else
		currentTimeStamp="$(date +"%s")"
		bootTimeStamp="$(getBootTime)"
		serverBootTime="$(getTimeSinceServerBoot)"
		bootTime="$((currentTimeStamp-bootTimeStamp))"
		if [ "$bootTime" -lt "$serverBootTime" ]; then
			startTimeStamp="$(getStartTime)"
			startTime="$((currentTimeStamp-startTimeStamp))"
			if [ "$startTime" -lt "$bootTime" ]; then
				echo "Down"
			else
				echo "Failed to Boot"
			fi
		else
			echo "Not Booted"
		fi
	fi
}


startServer() {
	local command="$1"; shift
	
	mkdir -p "${installDirectory}/logs"
	mkdir -p "${installDirectory}/config"
	mkdir -p "${installDirectory}/saves"
	touch "${installDirectory}/GUID.ini"
	chown $(id -u ${username}):$(id -g ${username}) -R "${installDirectory}"
	chmod 755 -R "${installDirectory}"
	
	callParent "$command"
}

runCommand() {
	local runPath="$1"; shift
	local command="$1"; shift
	
	if [[ "$command" == "info" ]]; then
		echo "Address: ${externalAddress}"
	elif [[ "$command" == "logs" ]]; then
		tail --lines=1000 "$(getLogFile)"
	elif [[ "$command" == "status" ]]; then
		echo "$(getStatus)"
	elif [ "$command" == 'uptime' ]; then
		echo "$(getUptime)"
	elif [ "$command" == 'booted' ]; then
		echo "$(isBooted)"
	elif [ "$command" == 'started' ]; then
		echo "$(isStarted)"
	elif [ "$command" == 'active' ]; then
		echo "$(isActive)"
	elif [ "$command" == 'list' ]; then
		echo "$(getPlayerCount)"
	elif [[ "$command" == "start" || "$command" == "start-monitor" ]]; then
		startServer "$command"
	elif [[ "$command" == "monitor" || "$command" == "ip" || "$command" == "bash" || "$command" == "description" || "$command" == "address" || "$command" == "stop" ]]; then
		callParent "$command"
	else
		echo "Usage: $runPath [start|start-monitor|monitor|uptime|booted|started|active|list|status|ip|bash|info|logs|description|address|stop]"
		exit 1
	fi
}

runCommand "${path}" "${command}"