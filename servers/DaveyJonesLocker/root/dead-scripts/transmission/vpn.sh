#!/bin/bash

command="${1}"; shift
options="$@"

# Default Values
networkInterface='eth0'
namespaceName='vpn'
namespaceUser='vpn'

# Processing Values
namespaceRun="ip netns exec ${namespaceName}"
vpnDir="/usr/local/lib/python3.8/dist-packages/openpyn/"
vethHost="veth.${namespaceName}.host"
vethPeer="veth.${namespaceName}.peer"
vethHostAddress="10.200.1.1"
vethPeerAddress="10.200.1.2"
#vpnStart="${namespaceRun} /usr/local/bin/openpyn us --max-load 70 --top-servers 10 --pings 3 --p2p -o ' --ifconfig-noexec --route-noexec --script-security 2 --setenv NETNS "${namespaceName}" --up openvpn-scripts/netns --route-up openvpn-scripts/netns --down openvpn-scripts/netns '"
vpnStart="${namespaceRun} /usr/local/bin/openpyn us --max-load 70 --top-servers 10 --pings 3 --p2p -o ' --ifconfig-noexec --route-noexec --script-security 2 --dev ${vethPeer} '"

available_interfaces() {
	local ret=()

	local ifaces=$(ip li sh | cut -d " " -f 2 | tr "\n" " ")
	read -a arr <<< "${ifaces}" 

	for each in "${arr[@]}"; do
		each=${each::-1}
		if [[ ${each} != "lo" && ${each} != veth* ]]; then
			ret+=( "${each}" )
		fi
	done
	echo ${ret[@]}
}

getNetworkInterface() {
	local ifaces=($(available_interfaces))
	if [[ ${#ifaces[@]} -gt 0 ]]; then
		echo "${ifaces[0]}"
	else
		echo ""
	fi
}

start_vpn() {
	echo "Add network interface"

	# Make the netns.
	ip netns add ${namespaceName}

	# Create veth link.
	ip link add ${vethHost} type veth peer name ${vethPeer}
	ip link set ${vethPeer} netns ${namespaceName}

	# Setup IP address of ${vethHost}
	ip addr add ${vethHostAddress}/24 dev ${vethHost}
	ip link set ${vethHost} up

	# Setup IP ${vethPeer}
	${namespaceRun} ip addr add ${vethPeerAddress}/24 dev ${vethPeer}
	${namespaceRun} ip link set ${vethPeer} up
	${namespaceRun} ip link set lo up
	${namespaceRun} ip route add default via ${vethHostAddress}

	# Enable IP-forwarding.
	echo 1 > /proc/sys/net/ipv4/ip_forward

	# Add IP Resolution
	mkdir -p "/etc/netns/${namespaceName}"
	ln -s /run/systemd/resolve/resolv.conf /etc/netns/"${namespaceName}"/resolv.conf

	# Enable masquerading of 10.200.1.0.
	iptables -t nat -A POSTROUTING -s ${vethHostAddress}/24 -o ${networkInterface} -j MASQUERADE
	
	# Add forwarding information
	iptables -A FORWARD -i ${networkInterface} -o ${vethHost} -j ACCEPT
	iptables -A FORWARD -o ${networkInterface} -i ${vethHost} -j ACCEPT

	# we should have full network access in the namespace
	${namespaceRun} ping -c 3 www.google.com

	# start OpenVPN in the namespace
	echo "Starting VPN"
	cd "${vpnDir}"
	${vpnStart}
}

flush() {
	# Flush forward rules.
	iptables -P FORWARD DROP
	iptables -F FORWARD
	 
	# Flush nat rules.
	iptables -t nat -F
}

stop_vpn() {
	echo "Stopping VPN"
	ip netns pids ${namespaceName} | xargs -rd'\n' kill
	# TODO wait for terminate

	# clear NAT
	iptables -t nat -D POSTROUTING -s ${vethHostAddress}/24 -o ${networkInterface} -j MASQUERADE
	
	# clear forwarding information
	iptables -D FORWARD -i ${networkInterface} -o ${vethHost} -j ACCEPT
	iptables -D FORWARD -o ${networkInterface} -i ${vethHost} -j ACCEPT

	# Delete veth link
	ip link delete ${vethHost}

	echo "Delete network interface ${namespaceName}"
	rm -rf /etc/netns/${namespaceName}
	ip netns delete ${namespaceName}
}

run_command() {
	# wait for the tunnel interface to come up
	while ! $NS_EXEC ip link show dev tun0 >/dev/null 2>&1 ; do sleep .5 ; done
	
	${namespaceRun} sudo -u ${namespaceUser} $@
}

get_vpn_ip() {
	echo "$(run_command curl https://ifconfig.me/)"
}

process_commands() {
	while true; do
		case "${1}" in
			--iface ) networkInterface="${2}"; shift 2;;
			--name ) namespaceName="${2}"; shift 2;;
			--user ) namespaceUser="${2}"; shift 2;;
			-- ) shift; break;;
			* ) break;;
		esac
	done
	
	namespaceRun="ip netns exec $namespaceName"
	vpnDir="/usr/local/lib/python3.8/dist-packages/openpyn/"
	vpnStart="${namespaceRun} /usr/local/bin/openpyn us --max-load 70 --top-servers 10 --pings 3 --p2p"
	vethHost="veth.${namespaceName}.host"
	vethPeer="veth.${namespaceName}.peer"
	
	if [ -z "${networkInterface}" ]; then
		networkInterface="$(getNetworkInterface)"
	fi
	
	if [ -z "${networkInterface}" ]; then
		echo 'Unable to find available network interface'
		exit 1
	elif [ -z "${namespaceName}" ]; then
		echo 'Network Namespace name is required'
		exit 1
	elif [ -z "${namespaceUser}" ]; then
		echo 'Network Namespace user is required'
		exit 1
	fi
	
	echo "$@"
}

if [ $USER != 'root' ]; then
	echo 'This must be run as root.'
	exit 1
fi

set -e # exit on error
set -o pipefail
#set -x # trace option
leftoverOptions="$(process_commands $options)"
if [ "${command}" = 'start' ]; then
	trap stop_vpn EXIT # stop VPN on exit (even when error occured)
	start_vpn
elif [ "${command}" = 'stop' ]; then
	stop_vpn
elif [ "${command}" = 'add' ]; then
	run_command $leftoverOptions
elif [ "${command}" = 'ip' ]; then
	echo "$(get_vpn_ip)"
else
	echo "Usage $path [start|add|ip|stop] [--iface netwrokInterface eth0] [--name namespaceName vpn] [--user namespaceUser vpn] [add command]"
	exit 1
fi

