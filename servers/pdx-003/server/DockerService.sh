#!/bin/bash
# /server/DockerService.sh

# Usage: getId [Service]
getId() {
	echo "$(docker ps --filter name=${1} --filter status=running -q --all)"
}

# Usage: isActive [Service]
isActive() {
	if [[ -n "$(getId "${1}")" ]]; then
		echo 'true'
	else
		echo 'false'
	fi
}

# Usage: startUp [Service] [Start Parameters]
powerOn() {
  local service="${1}"; shift
	docker rm "$(docker ps --filter name=${service} -q --all)"
	docker run -d --name ${service} ${@}
	echo "Service Started"
}

# Usage: sendCommand [Service] [Command]
sendCommand() {
  local service="${1}"; shift
	if [[ "$(isActive "${service}")" == "true" ]]; then
		echo "$(docker exec "$(getId "${service}")" ${@})"
	else
		echo "Cannot send command from terminated instance"
	fi
}

# Usage: getIP [Service]
getIP() {
  sendCommand "${1}" curl --location --silent ipconfig.me
}

# Usage: openBash [Service]
openBash() {
	if [[ "$(isActive "${1}")" == "true" ]]; then
		docker exec --interactive --tty "$(getId "${1}")" /bin/bash
	else
		echo "Cannot start bash session in terminated instance"
	fi
}

# Usage: startUp [Service] [Start Parameters]
startUp() {
  local service="${1}"; shift
	if [[ "$(isActive "${service}")" == "true" ]]; then
		echo "Already On"
	else
		echo "$(powerOn ${service} ${@})"
	fi
}

# Usage: monitor [Service]
monitor() {
	trap "{ echo 'Quit Signal Received, Please call \"${path} stop\" to stop the service' ; exit 1 ; }" SIGQUIT
	trap "{ echo 'Abort Signal Received, Please call \"${path} stop\" to stop the service' ; exit 1 ; }" SIGABRT
	trap "{ echo 'Interrupt Signal Received, Please call \"${path} stop\" to stop the service' ; exit 1 ; }" SIGINT
	trap "{ echo 'Terminate Signal Received, Please call \"${path} stop\" to stop the service' ; exit 1 ; }" SIGTERM
	if [[ "$(isActive "${1}")" != "true" ]]; then
		sleep 10
	fi
	while [[ "$(isActive "${1}")" == "true" ]]; do
		sleep 5
	done
}

# Usage: currentStatus [Service]
currentStatus() {
	if [[ "$(isActive "${1}")" == "true" ]]; then
		echo "Powered On"
	else
		echo "Powered Off"
	fi
}

# Usage: stopService [Service]
stopService() {
	if [[ "$(isActive "${1}")" == "true" ]]; then
		docker stop "$(getId "${1}")"
	else
		echo "Already Off"
	fi
}