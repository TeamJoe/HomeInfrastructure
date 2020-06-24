#!/bin/sh
# /root/domain.sh
# /etc/crontabs/root: "*/5 * * * * /root/domain.sh"

IPV4_FILE_LOCATION='/root/ipv4.txt'
IPV6_FILE_LOCATION='/root/ipv6.txt'
LOG_LOCATION='/root/ip-logs.txt'

updateDomainsIP() {
	#curl -s -f $@ <REDACTED:http://freedns.afraid.org/dynamic/> >> "${LOG_LOCATION}" 2>&1
}

getCurrenIPFromDomain() {
	local IP="$(curl -s -f $@)"
	if [ -n "$(echo "$IP" | grep -i 'error')" ]; then
		echo ""
	else
		echo "$IP"
	fi
}

getCurrentIP() {
	local IP="$(getCurrenIPFromDomain $@ ifconfig.me)"
	if [ -z "$IP" ]; then
		local IP="$(getCurrenIPFromDomain $@ ifconfig.co)"
	fi

	if [ -n "$IP" ]; then
		echo "$IP"
	else
		echo "NO IP FOUND"
	fi
}

getIPSaveLocation() {
	if [ "$1" == "-4" ]; then
		echo "${IPV4_FILE_LOCATION}"
	elif [ "$1" == "-6" ]; then
		echo "${IPV6_FILE_LOCATION}"
	fi
}

getLastIP() {
	echo "$(cat "$(getIPSaveLocation $@)" | echo "NO PREVIOUS IP")"
}

checkIP() {
	touch -a "$(getIPSaveLocation $@)"

	local currentIP="$(getCurrentIP $@)"
	local lastIP="$(getLastIP $@)"

	if [ "${currentIP}" != "${lastIP}" ]; then
		local now="$(date +"%T")"
		echo "${now}: ${currentIP} != ${lastIP}" >> "${LOG_LOCATION}"
		updateDomainsIP $@
		if [ "${currentIP}" != "NO IP FOUND" ]; then
			echo "${currentIP}" > "$(getIPSaveLocation $@)"
		fi
	fi
}

checkIP -4
checkIP -6

