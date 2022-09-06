#!/bin/sh
# /server/discord.sh
source /server/properties.sh

sendMessage() {
	local message="${1}"; shift
	local address="$(getProperty 'discord.address')"

	curl --silent --request POST --header 'Content-Type: application/json' --data "{\"content\":\"${message}\"}" "${address}"
}

sendMessageAndUpdateIfDiffer() {
  local value="${1}"; shift
  local location="${1}"; shift
	local message="${1}"; shift
  local oldValue="$(cat "${location}")"

  if [ "${value}" != "${oldValue}" ]; then
    echo "${value}" > "${location}"
    sendMessage "${message}"
  fi
}