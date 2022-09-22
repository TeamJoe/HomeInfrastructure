#!/bin/bash
# /server/DockerService.sh

getId() {
  local service="${1}"; shift

	echo "$(docker ps --filter name=${service} --filter status=running -q --all)"
}

isActive() {
  local service="${1}"; shift

	if [[ -n "$(getId "${service}")" ]]; then
		echo 'true'
	else
		echo 'false'
	fi
}

powerOn() {
  local service="${1}"; shift
  local startParameters="${1}"; shift

	docker rm "$(docker ps --filter name=${service} -q --all)"
	docker run -d --name ${service} ${startParameters[@]}
	echo "Service Started"
}

getIP() {
  local service="${1}"

	if [[ "$(isActive "${service}")" == "true" ]]; then
		echo "$(docker exec "$(getId "${service}")" curl --location --silent ipconfig.me)"
	else
		echo "Cannot get ip from terminated instance"
	fi
}

openBash() {
  local service="${1}"; shift

	if [[ "$(isActive "${service}")" == "true" ]]; then
		docker exec -it "$(getId "${service}")" /bin/bash
	else
		echo "Cannot start bash session in terminated instance"
	fi
}

startUp() {
  local service="${1}"; shift
  local startParameters="${1}"; shift

	if [[ "$(isActive "${service}")" == "true" ]]; then
		echo "Already On"
	else
		echo "$(powerOn "${service}" "${startParameters}")"
	fi
}

monitor() {
  local service="${1}"; shift

	trap "{ echo 'Quit Signal Received, Please call \"${path} stop\" to stop the service' ; exit 1 ; }" SIGQUIT
	trap "{ echo 'Abort Signal Received, Please call \"${path} stop\" to stop the service' ; exit 1 ; }" SIGABRT
	trap "{ echo 'Interrupt Signal Received, Please call \"${path} stop\" to stop the service' ; exit 1 ; }" SIGINT
	trap "{ echo 'Terminate Signal Received, Please call \"${path} stop\" to stop the service' ; exit 1 ; }" SIGTERM
	if [[ "$(isActive "${service}")" != "true" ]]; then
		sleep 10
	fi
	while [[ "$(isActive "${service}")" == "true" ]]; do
		sleep 5
	done
}

currentStatus() {
  local service="${1}"; shift

	if [[ "$(isActive "${service}")" == "true" ]]; then
		echo "Powered On"
	else
		echo "Powered Off"
	fi
}

stopService() {
  local service="${1}"; shift

	if [[ "$(isActive "${service}")" == "true" ]]; then
		docker stop "$(getId "${service}")"
	else
		echo "Already Off"
	fi
}