#!/bin/bash
# /server/DockerService.sh

path="$1"; shift
service="$1"; shift
description="$1"; shift
externalAddress="$1"; shift
startParameters="$1"; shift
image="$1"; shift
installCommand="${1:-"docker image pull ${image}"}"; shift
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

powerOn() {
	docker rm "$(docker ps --filter name=${service} -q --all)"
	docker run -d --name ${service} ${startParameters[@]} ${image}
	echo "Service Started"
}

getIP() {
	if [[ "$(isActive)" == 'true' ]]; then
		echo "$(docker exec "$(getId)" curl --location --silent ipconfig.me)"
	else
		echo "Cannot get ip from terminated instance"
	fi
}

openBash() {
	if [[ "$(isActive)" == 'true' ]]; then
		docker exec -it "$(getId)" /bin/bash
	else
		echo "Cannot start bash session in terminated instance"
	fi
}

startUp() {
	if [[ "$(isActive)" == 'true' ]]; then
		echo "Already On"
	else
	  if [[ "$(isInstalled)" != 'true' ]]; then
	    install
	  fi
		echo "$(powerOn)"
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

restartService() {
  stopService
  startUp
}

installService() {
  if [[ -z "${installCommand}" ]]; then
    exit "Service does not support install"
  elif [[ "$(isActive)" == 'true' ]]; then
    echo "Already On"
  elif [[ "$(isInstalled)" == 'true' ]]; then
    echo "Already Installed"
  else
    install
  fi
}

upgradeService() {
  local imageId="$(getImageId)"
  if [[ -z "${installCommand}" ]]; then
    exit "Service does not support upgrade"
  else
    install
    if [[ "$(isActive)" == 'true' ]]; then
        restartService
    fi
    if [[ -n "${imageId}" ]]; then
      docker rmi -f ${imageId}
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
		startUp
	elif [[ "$command" == "start-monitor" ]]; then
	  startUp
	  monitor
	elif [[ "$command" == "monitor" ]]; then
		monitor
	elif [[ "$command" == "status" ]]; then
		echo "$(currentStatus)"
	elif [[ "$command" == "ip" ]]; then
		echo "$(getIP)"
	elif [[ "$command" == "bash" ]]; then
		openBash
	elif [[ "$command" == "description" ]]; then
		echo "$description"
	elif [[ "$command" == "address" ]]; then
		echo "$externalAddress"
	elif [[ "$command" == "install" ]]; then
    echo "$(installService)"
	elif [[ "$command" == "upgrade" ]]; then
  	echo "$(upgradeService)"
  elif [[ "$command" == "restart" ]]; then
  	echo "$(restartService)"
	elif [[ "$command" == "stop" ]]; then
		echo "$(stopService)"
	else
		echo "Usage: $runPath [start|start-monitor|monitor|status|ip|bash|description|address|install|upgrade|restart|stop]"
		exit 1
	fi
}

runCommand "$path" "$command"
