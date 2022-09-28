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

simple_log_file="${installDirectory}/logs/simple.log"
extended_log_file="${installDirectory}/logs/FactoryGame.log"
player_list_file="${installDirectory}/logs/user.csv"
simple_server_date_pattern='\[([^]]+)\].*'
server_start_regex='\[([^]]+)\].*Session Started.*'
player_join_regex='\[([^]]+)\].*Player Joined.*\((.*)\)'
player_leave_regex='\[([^]]+)\].*Player Left.*\((.*)\)'
server_stop_regex='\[([^]]+)\].*Server Shutdown.*'

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
  if [[ -f "${simple_log_file}" ]]; then
    echo "${simple_log_file}"
  else
	  echo "$(ls -Art "${installDirectory}/logs/"simple* | tail --lines=1)"
  fi
}

#++++++++++++++++++++
#--------------------
# Last Event Time
#--------------------
#++++++++++++++++++++

getBootTime() {
	local date=''
	local fileNameMatcher='simple\.([^\.]+)\.log'
	local rawDate="$(head --lines=1 "$(getSimpleLogFile)" | regex --find "$fileNameMatcher" --group 1 --trim)"
  if [[ -z "${rawDate}" ]]; then
    echo "0"
  else
    readarray -td, date <<< "${rawDate//[T:-]/,}"
    echo "$(date --date="${date[0]}-${date[1]}-${date[2]}T${date[3]}:${date[4]}:${date[5]}" +"%s")"
  fi
}

getStartTime() {
	local date=''
	local rawDate="$(cat "$(getSimpleLogFile)" | regex --find "${server_start_regex}" --group 1 --trim | tail --lines=1)"
	if [[ -z "${rawDate}" ]]; then
	  echo "0"
	else
    readarray -td, date <<< "${rawDate//[T:-]/,}"
    echo "$(date --date="${date[0]}-${date[1]}-${date[2]}T${date[3]}:${date[4]}:${date[5]}" +"%s")"
	fi
}

getShutDownTime() {
	local date=''
	local rawDate="$(cat "$(getSimpleLogFile)" | regex --find "${server_stop_regex}" --group 1 --trim | tail --lines=1)"
	if [[ -z "${rawDate}" ]]; then
	  echo "0"
	else
    readarray -td, date <<< "${rawDate//[T:-]/,}"
    echo "$(date --date="${date[0]}-${date[1]}-${date[2]}T${date[3]}:${date[4]}:${date[5]}" +"%s")"
	fi
}

getTimeSinceServerBoot() {
	date -d@$(printf '%.0f\n' "$(awk '{print $1}' /proc/uptime)") +"%s"
}

getLastActivityTime() {
  local date=''
  local rawDate=''
  local log_file="$(getSimpleLogFile)"
	local rawDate="$(cat "${log_file}" | regex --find "${simple_server_date_pattern}" --group 1 --trim | tail --lines=1)"
	if [[ -n "${rawDate}" ]]; then
    	readarray -td, date <<< "${rawDate//[T:-]/,}"
    	echo "$(date --date="${date[0]}-${date[1]}-${date[2]}T${date[3]}:${date[4]}:${date[5]}" +"%s")"
	fi
}

getUptime() {
	if [[ "$(isStarted)" != "true" ]]; then
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
	if [[ "$(statusService "${service}")" != "Powered On" ]]; then
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
		
		if [[ $startTimeStamp -ge $bootTimeStamp ]]; then
			echo "true"
		else
			echo "false"
		fi
	fi
}

getPlayerCount() {
	if [[ "$(isStarted)" != "true" || "$(cat "${player_list_file}" | wc --lines)" == '0' ]]; then
		echo "0"
	else
		echo "$(cat "${player_list_file}" | wc --lines) ($(cat "${player_list_file}" | regex --global --find '\s+(.*)' --group 1 | regex --global --multiline --find '\s+' --replace ' ' --trim))"
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
	if [[ "$(isStarted)" != "true" ]]; then
		if [[ "$(isBooted)" == "true" ]]; then
			startTimeStamp="$(getBootTime)"
			timeSinceStart="$((currentTimeStamp-startTimeStamp))"
			minimumBootRemaining="$((minimum_server_boot_time-timeSinceStart))"
			if [[ "$minimumBootRemaining" -ge "0" ]]; then
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
		
		if [[ ! "$(getPlayerCount)" == '0' ]]; then
			if [[ "$minimumBootRemaining" -ge "$minimum_disconnect_live_time" ]]; then
				echo "$minimumBootRemaining"
			else
				echo "$minimum_disconnect_live_time"
			fi
		else
			lastActivityTimeStamp="$(getLastActivityTime)"
			timeSinceActive="$((currentTimeStamp-lastActivityTimeStamp))"
			minimumActiveRemaining="$((minimum_disconnect_live_time-timeSinceActive))"
			if [[ "$minimumBootRemaining" -ge 0 && "$minimumBootRemaining" -ge "$minimumActiveRemaining" ]]; then
				echo "$minimumBootRemaining"
			elif [[ "$minimumActiveRemaining" -ge 0 ]]; then
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
	local shutDownTimeStamp=''
	local serverBootTime=''
	local bootTime=''
	local startTime=''
	local shutDownTime=''
	
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
		if [[ "$bootTime" -lt "$serverBootTime" ]]; then
			startTimeStamp="$(getStartTime)"
			startTime="$((currentTimeStamp-startTimeStamp))"
			if [[ "$startTime" -lt "$bootTime" ]]; then
			  shutDownTimeStamp="$(getShutDownTime)"
			  shutDownTime="$((currentTimeStamp-shutDownTimeStamp))"
			  if [[ "$shutDownTime" -lt "$startTime" ]]; then
				  echo "Shut Down"
				else
				  echo "Down"
				fi
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

monitorLogs() {
  while [[ 1 ]];  do
    tail --retry --follow=name --lines 0 "${simple_log_file}" | while read line; do
      processLog "${line}"
    done
    if [[ "$(statusService "${service}")" != "Powered On" ]]; then
      break
    fi
    sleep 5
  done
}

processLog() {
  local match=""

  match="$(regex --find "${server_start_regex}" --group 1 --input "${1}")"
  if [[ -n "${match}" ]]; then
    sendMessage "[${description}] Session Started"
  fi

  match="$(regex --find "${player_join_regex}" --group 2 --input "${1}")"
  if [[ -n "${match}" ]]; then
    sendMessage "[${description}] Player Joined (${match})"
  fi

  match="$(regex --find "${player_leave_regex}" --group 2 --input "${1}")"
  if [[ -n "${match}" ]]; then
    sendMessage "[${description}] Player Left (${match})"
  fi

  match="$(regex --find "${server_stop_regex}" --group 1 --input "${1}")"
  if [[ -n "${match}" ]]; then
    sendMessage "[${description}] Session Stopped"
  fi
}

runCommand() {
	local runPath="${1}"; shift
	local command="${1}"; shift
	
	if [[ "${command}" == "info" ]]; then
		echo "Address: ${address} Port: ${queryport}"
	elif [[ "${command}" == "logs" ]]; then
		tail --lines=1000 "${extended_log_file}"
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
		sendCommand "${service}" "${@}"
	elif [[ "${command}" == "start-monitor" ]]; then
		monitorLogs &
		startServer
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
	  sendCommand "${service}" '/build/stop.sh'
		stopService "${service}"
		killProcess $(getProcess 'tail' "${simple_log_file}")
	else
		echo "Usage: $runPath [start|start-monitor|debug|monitor|command|uptime|booted|started|active|list|status|ip|bash|info|logs|simple|description|address|stop]"
		exit 1
	fi
}