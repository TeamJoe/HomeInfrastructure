#!/bin/sh

address='https://<REDACTED>/rest/v1/Systems/1'
user='<REDACTED>'
password='<REDACTED>'

isPoweredOn() {
	local state="$(curl "$address" --insecure -u "${user}:${password}" -L | awk '{print tolower($0)}')"
	local power="$(echo "$state" | grep -o '"power":"[^"]*",' | grep -o ':"[^"]*"' | grep -o '"[^"]*"' | grep -o '[^"]*' | awk '{print tolower($0)}')"
	if [ "${power}" == "off" ]; then
		echo "false"
	else
		echo "true"
	fi
}

powerOn() {
	curl -d '{ "Action": "PowerButton", "PushType": "Press", "Target": "/Oem/Hp"}' -H 'Content-Type: application/json' "$address" --insecure -u "${user}:${password}" -L
}

if [ "$(isPoweredOn)" != "true" ]; then
	powerOn
	echo "Powering On"
else
	echo "Already On"
fi


