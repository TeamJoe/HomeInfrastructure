#!/bin/sh
# /root/domain.sh
# /etc/crontabs/root: "*/5 * * * * /root/domain.sh"

IPV4_FILE_LOCATION='/root/ipv4.txt'
IPV6_FILE_LOCATION='/root/ipv6.txt'
LOG_LOCATION='/root/ip-logs.txt'

updateDomainsIP() {
	#curl -s -f $@ <REDACTED:http://freedns.afraid.org/dynamic/> >> "${LOG_LOCATION}" 2>&1
}

isIPv4() {
	echo "$1" | egrep -c -e '^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$'
}

isIPv6() {
	echo "$1" | egrep -c -e '^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$'
}

isIP() {
	if [ "$(isIPv4 "$1")" == 1 ]; then
		echo 1
	elif [ "$(isIPv6 "$1")" == 1 ]; then
		echo 1
	else
		echo 0
	fi
}

getCurrenIPFromDomain() {
	local IP="$(curl -s -f $@)"
	if [ "$(isIP "$IP")" == 1 ]; then
		echo "$IP"
	else
		echo "NO IP FOUND"
	fi
}

getCurrentIP() {
	local IP="$(getCurrenIPFromDomain $@ ifconfig.me)"
	if [ "$IP" == "NO IP FOUND" ]; then
		local IP="$(getCurrenIPFromDomain $@ ifconfig.co)"
	fi

	echo "$IP"
}

getIPSaveLocation() {
	if [ "$1" == "-4" ]; then
		echo "${IPV4_FILE_LOCATION}"
	elif [ "$1" == "-6" ]; then
		echo "${IPV6_FILE_LOCATION}"
	fi
}

getLastIP() {
	local IP="$(cat "$(getIPSaveLocation $@)")"
	if [ "$(isIP "$IP")" == 1 ]; then
		echo "$IP"
	else
		echo "NO PREVIOUS IP"
	fi
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

