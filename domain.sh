#!/bin/sh
# /etc/crontabs/root/ "*/5 * * * * /root/domain.sh"

IP_FILE_LOCATION='/root/ip.txt'
LOG_LOCATION='/root/ip-logs.txt'

updateDomains() {
	#curl <REDACTED:http://freedns.afraid.org/dynamic/> >> "${LOG_LOCATION}"
}

getCurrentIP() {
	echo "$(curl ifconfig.co)"
}

getLastIP() {
	echo "$(cat ""${IP_FILE_LOCATION}"")"
}

check() {
	local currentIP="$(getCurrentIP)"
	local lastIP="$(getLastIP)"
	
	if [ "${currentIP}" != "${lastIP}" ]; then
		local now="$(date +"%T")"
		echo "${now}: ${currentIP} != ${lastIP}" >> "${LOG_LOCATION}"
		updateDomains
		echo "${currentIP}" > "${IP_FILE_LOCATION}"
	fi
}

check
