#!/bin/sh
# /server/discord.sh
source /server/properties.sh

sendMessage() {
	local message="${1}"; shift
	local address="$(getProperty 'discord.address')"

	curl --silent --request POST --header 'Content-Type: application/json' --data "{\"content\":\"${message}\"}" "${address}"
}