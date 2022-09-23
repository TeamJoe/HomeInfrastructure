#!/bin/bash
# /home/satisfactory/GenericSatisfactoryServer.sh
source /server/regex.sh
source /server/discord.sh
source /server/process.sh
source /server/properties.sh
source /server/DockerService.sh

minimum_server_boot_time=3600
minimum_disconnect_live_time=1200

if [ -n "${prefix}" ]; then
  tag="$(getProperty "${prefix}.tag")"
  service="$(getProperty "${prefix}.service")"
  user="$(getProperty "${prefix}.user")"
  description="$(getProperty "${prefix}.description")"
  address="$(getProperty "${prefix}.address")"
  serverport="$(getProperty "${prefix}.port.server")"
  beaconport="$(getProperty "${prefix}.port.beacon")"
  queryport="$(getProperty "${prefix}.port.query")"
  installDirectory="$(getProperty "${prefix}.dir.install")"
fi

simple_output_file="${installDirectory}/logs/output.log"
simple_server_start_regex='.*Booting Server'
#server_start_regex='Took ([0-9]+\.[0-9]+) seconds to LoadMap'
server_start_regex='\[([^\]]+)\].*Created socket for bind address'
player_join_regex='Join\ssucceeded:\s(.+)'
player_leave_regex='UNetConnection::Close.*Driver:\s+GameNetDriver.*UniqueId:\s+([^,]+),'

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
                "${tag}" \
                )

#++++++++++++++++++++
#--------------------
# Helper Functions
#--------------------
#++++++++++++++++++++

getSimpleLogFile() {
	echo "$(ls -Art "${installDirectory}/logs/"simple* | tail --lines=1)"
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
	
	for match in $(cat "$(getLogFile)" | regexExtract "$regex_pattern" $extract_group); do
		if [[ -n "$match" ]]; then
			output="$match"
			if [[ "$get_last" != "true" ]]; then
				break;
			fi
		fi
	done
	
	echo "$output"
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
	
	rawDate="$(regexExtract "$(getSimpleLogFile)" "$fileNameMatcher" 1)"
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
		match="$(regexExtract "$line" "$simple_server_date_pattern" 1)"
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
	if [ "$(statusService "${service}")" != "Powered On" ]; then
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

isServerActive() {
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

debugServer() {
	mkdir -p "${installDirectory}/logs"
	mkdir -p "${installDirectory}/config"
	mkdir -p "${installDirectory}/saves"
	touch "${installDirectory}/GUID.ini"
	chown $(id -u ${username}):$(id -g ${username}) -R "${installDirectory}"
	chmod 755 -R "${installDirectory}"

	debugService "${service}" ${startParameters[@]}
}

startServer() {
	mkdir -p "${installDirectory}/logs"
	mkdir -p "${installDirectory}/config"
	mkdir -p "${installDirectory}/saves"
	touch "${installDirectory}/GUID.ini"
	chown $(id -u ${username}):$(id -g ${username}) -R "${installDirectory}"
	chmod 755 -R "${installDirectory}"
	
	startService "${service}" ${startParameters[@]}
}

log() {
	echo "[$(date +"%D %T")] ${1}" >> "${simple_output_file}"
	sendMessage "${description}: ${1}"
}

monitorLogs() {
  sleep 10

  while [[ "$(statusService "${service}")" == "Powered On" ]];  do
    tail --follow --lines=1000 "$(getLogFile)" | while read line; do
      processLog "${line}"
    done
    sleep 5
  done

  log "Server Stopped"
}

processLog() {
  local match=""

  match="$(regexExtract "${line}" "${server_start_regex}" 1)"
  if [[ -n "${match}" ]]; then
    log "Server Started (${match})"
  fi

  match="$(regexExtract "${line}" "${player_join_regex}" 1)"
  if [[ -n "${match}" ]]; then
    log "Player Joined (${match})"
    log "Player Count $(getPlayerCount)"
  fi

  match="$(regexExtract "${line}" "${player_leave_regex}" 1)"
  if [[ -n "${match}" ]]; then
    log "Player Left (${match})"
    log "Player Count $(getPlayerCount)"
  fi
}

runCommand() {
	local runPath="${1}"; shift
	local command="${1}"; shift
	
	if [[ "${command}" == "info" ]]; then
		echo "Address: ${address} Port: ${queryport}"
	elif [[ "${command}" == "logs" ]]; then
		tail --lines=1000 "$(getLogFile)"
	elif [[ "${command}" == "simple" ]]; then
		tail --lines=1000 "$(getSimpleLogFile)"
	elif [[ "${command}" == "status" ]]; then
		getStatus
	elif [ "${command}" == 'uptime' ]; then
		getUptime
	elif [ "${command}" == 'booted' ]; then
		isBooted
	elif [ "${command}" == 'started' ]; then
		isStarted
	elif [ "${command}" == 'active' ]; then
		isServerActive
	elif [ "${command}" == 'list' ]; then
		getPlayerCount
	elif [[ "$command" == "start" ]]; then
		startServer
	elif [[ "$command" == "debug" ]]; then
		debugServer
	elif [[ "${command}" == "command" ]]; then
		sendCommand "${service}" ${@}
	elif [[ "${command}" == "start-monitor" ]]; then
		startServer
		monitorLogs &
		monitorService "${service}"
	elif [[ "${command}" == "monitor" ]]; then
		monitorService "${service}"
	elif [[ "${command}" == "ip" ]]; then
		getIP "${service}"
	elif [[ "${command}" == "bash" ]]; then
		openBash "${service}"
	elif [[ "${command}" == "description" ]]; then
		echo "${description}"
	elif [[ "${command}" == "address" ]]; then
		echo "${externalAddress}"
	elif [[ "${command}" == "stop" ]]; then
		stopService "${service}"
		killProcess $(getProcess 'tail' "$(getLogFile)")
		log "Server Stopped"
	else
		echo "Usage: $runPath [start|start-monitor|debug|monitor|command|uptime|booted|started|active|list|status|ip|bash|info|logs|simple|description|address|stop]"
		exit 1
	fi
}