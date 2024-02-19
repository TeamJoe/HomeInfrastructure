#!/bin/bash
# /server/DockerService.sh

path="$1"; shift
service="$1"; shift
description="$1"; shift
externalAddress="$1"; shift
startParameters="$1"; shift
image="$1"; shift
installCommand="${1:-"docker image pull ${image}"}"; shift
enableCommand="sudo systemctl enable /home/${service}/${service}.service"
disableCommand="sudo systemctl disable ${service}.service"
command="$1"; shift

getImageId() {
	echo "$(docker images --quiet ${image})"
}

getId() {
	echo "$(docker ps --filter name=${service} --filter status=running -q --all)"
}

isInstalled() {
  if [[ -n "$(getImageId)" ]]; then
    echo 'true'
  else
    echo 'false'
  fi
}

isActive() {
	if [[ -n "$(getId)" ]]; then
		echo 'true'
	else
		echo 'false'
	fi
}

install() {
  eval "${installCommand}"
}

startService() {
  local containerId="$(docker ps --filter name=${service} -q --all)"
  if [[ -n "${containerId}" ]]; then
	 docker rm --volumes ${containerId}
  fi
	docker run --detach --name ${service} ${startParameters[@]} ${image}
	echo "Service Started"
}

debugService() {
  local containerId="$(docker ps --filter name=${service} -q --all)"
  if [[ -n "${containerId}" ]]; then
	 docker rm --volumes ${containerId}
  fi
	docker run --detach --entrypoint /bin/sleep --name ${service} ${startParameters[@]} ${image} infinity
	echo "Service Debugging"
}

getIP() {
	if [[ "$(isActive)" == 'true' ]]; then
		echo "$(docker exec "$(getId)" curl --location --silent ipconfig.me)"
	fi
}

getStatCpu() {
	if [[ "$(isActive)" == 'true' ]]; then
    echo "$(docker stats ${service} --no-stream --no-trunc --format "{{.CPUPerc}}")" | tr -d ' '
  fi
}

getStatMemory() {
	if [[ "$(isActive)" == 'true' ]]; then
    echo "$(docker stats ${service} --no-stream --no-trunc --format "{{.MemUsage}}")" | cut -f1 -d"/" | tr -d ' '
  fi
}

getStatNetworkInput() {
	if [[ "$(isActive)" == 'true' ]]; then
    echo "$(docker stats ${service} --no-stream --no-trunc --format "{{.NetIO}}")" | cut -f1 -d"/" | tr -d ' '
  fi
}

getStatNetworkOutput() {
	if [[ "$(isActive)" == 'true' ]]; then
    echo "$(docker stats ${service} --no-stream --no-trunc --format "{{.NetIO}}")" | cut -f2 -d"/" | tr -d ' '
  fi
}

getStatBlockInput() {
	if [[ "$(isActive)" == 'true' ]]; then
    echo "$(docker stats ${service} --no-stream --no-trunc --format "{{.BlockIO}}")" | cut -f1 -d"/" | tr -d ' '
  fi
}

getStatBlockOutput() {
	if [[ "$(isActive)" == 'true' ]]; then
    echo "$(docker stats ${service} --no-stream --no-trunc --format "{{.BlockIO}}")" | cut -f2 -d"/" | tr -d ' '
  fi
}

openBash() {
	if [[ "$(isActive)" == 'true' ]]; then
		docker exec -it "$(getId)" /bin/bash
	else
		echo "Cannot start bash session in terminated instance"
	fi
}

startService() {
	if [[ "$(isActive)" == 'true' ]]; then
		echo "Already On"
	else
	  if [[ "$(isInstalled)" != 'true' ]]; then
	    install
	  fi
		echo "$(startService)"
	fi
}

startDebug() {
	if [[ "$(isActive)" == 'true' ]]; then
		echo "Already On"
	else
	  if [[ "$(isInstalled)" != 'true' ]]; then
	    install
	  fi
		echo "$(debugService)"
	fi
}

monitor() {
  trap "{ echo 'Quit Signal Received, Please call \"${path} stop\" to stop the service' ; exit 1 ; }" SIGQUIT
  trap "{ echo 'Abort Signal Received, Please call \"${path} stop\" to stop the service' ; exit 1 ; }" SIGABRT
  trap "{ echo 'Interrupt Signal Received, Please call \"${path} stop\" to stop the service' ; exit 1 ; }" SIGINT
  trap "{ echo 'Terminate Signal Received, Please call \"${path} stop\" to stop the service' ; exit 1 ; }" SIGTERM
  if [[ "$(isActive)" != 'true' ]]; then
		sleep 10
	fi
  while [[ "$(isActive)" == 'true' ]]; do
    sleep 5
  done
}

currentStatus() {
	if [[ "$(isActive)" == 'true' ]]; then
		echo "Powered On"
	else
		echo "Powered Off"
	fi
}

enableService() {
  eval "${enableCommand}"
}

disableService() {
  eval "${disableCommand}"
}

restartService() {
  if [[ "$(isActive)" == 'true' ]]; then
    stopService
    startUp
  else
    echo "Already Off"
  fi
}

installService() {
  if [[ -z "${installCommand}" ]]; then
    exit "Service does not support install"
  elif [[ "$(isInstalled)" == 'true' ]]; then
    echo "Already Installed. Try using 'upgrade' command instead."
  elif [[ "$(isActive)" == 'true' ]]; then
    echo "Already On. Must be configured poorly in order to be 'On' byt not 'Installed'."
  else
    install
  fi
}

updateService() {
  if [[ -z "${installCommand}" ]]; then
    exit "Service does not support update"
  elif [[ "$(isInstalled)" != 'true' ]]; then
    echo "Not Installed. Try using 'install' command instead."
  else
    install
  fi
}

upgradeService() {
  local imageId="$(getImageId)"
  if [[ -z "${installCommand}" ]]; then
    exit "Service does not support upgrade"
  elif [[ "$(isInstalled)" != 'true' ]]; then
    echo "Not Installed. Try using 'install' command instead."
  elif [[ -n "${imageId}" ]]; then
    install
    if [[ "${imageId}" != "$(getImageId)" ]]; then
      if [[ "$(isActive)" == 'true' ]]; then
          restartService
      fi
      if [[ -n "${imageId}" ]]; then
        docker rmi -f ${imageId}
      fi
    fi
  fi
}

stopService() {
	if [[ "$(isActive)" == 'true' ]]; then
		docker stop "$(getId)"
	else
		echo "Already Off"
	fi
}

runCommand() {
	local runPath="$1"; shift
	local command="$1"; shift
	
	if [[ "$command" == "start" ]]; then
		startService
	elif [[ "$command" == "start-monitor" ]]; then
	  startService
	  monitor
	elif [[ "$command" == "debug" ]]; then
	  startDebug
	elif [[ "$command" == "monitor" ]]; then
		monitor
	elif [[ "$command" == "enable" ]]; then
		enableService
	elif [[ "$command" == "disable" ]]; then
		disableService
	elif [[ "$command" == "status" ]]; then
		currentStatus
	elif [[ "$command" == "ip" ]]; then
		getIP
  elif [[ "$command" == "stat-cpu" ]]; then
    getStatCpu
  elif [[ "$command" == "stat-mem" ]]; then
    getStatMemory
  elif [[ "$command" == "stat-neti" ]]; then
    getStatNetworkInput
  elif [[ "$command" == "stat-neto" ]]; then
    getStatNetworkOutput
  elif [[ "$command" == "stat-blki" ]]; then
    getStatBlockInput
  elif [[ "$command" == "stat-blko" ]]; then
    getStatBlockOutput
	elif [[ "$command" == "bash" ]]; then
		openBash
	elif [[ "$command" == "description" ]]; then
		echo "$description"
	elif [[ "$command" == "address" ]]; then
		echo "$externalAddress"
	elif [[ "$command" == "install" ]]; then
    installService
  elif [[ "$command" == "update" ]]; then
    updateService
	elif [[ "$command" == "upgrade" ]]; then
  	upgradeService
  elif [[ "$command" == "restart" ]]; then
  	restartService
	elif [[ "$command" == "stop" ]]; then
		stopService
	else
		echo "Usage: $runPath [start|start-monitor|debug|monitor|enable|disable|status|ip|stat-cpu|stat-mem|stat-neti|stat-neto|stat-blki|stat-blko|bash|description|address|install|update|upgrade|restart|stop]"
		exit 1
	fi
}

runCommand "$path" "$command"