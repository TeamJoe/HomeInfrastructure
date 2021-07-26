#!/bin/bash
# start openvpn tunnel and torrent client inside Linux network namespace
#
# this is a fork of schnouki's script, see original blog post
# https://schnouki.net/posts/2014/12/12/openvpn-for-a-single-application-on-linux/
#
# original script can be found here
# https://gist.github.com/Schnouki/fd171bcb2d8c556e8fdf

# ------------ adjust values below ------------
# network namespace
networkInterface=eth0
namespaceName=vpn
namespaceUser=vpn
# ---------------------------------------------

command="${1}"; shift
options="$@"

while true; do
	case "${1}" in
		--iface ) networkInterface="${2}"; shift 2;;
		--name ) namespaceName="${2}"; shift 2;;
		--user ) namespaceUser="${2}"; shift 2;;
		-- ) shift; break;;
		* ) break;;
	esac
done

bridgeIdentifier="br_${namespaceName}"
namespaceRun="ip netns exec $namespaceName"
vpnDir="/usr/local/lib/python3.8/dist-packages/openpyn/"
vpnStart="${namespaceRun} /usr/local/bin/openpyn us --max-load 70 --top-servers 10 --pings 3 --p2p"
vethHost="veth.${namespaceName}.host"
vethPeer="veth.${namespaceName}.peer"

set -e # exit on error
set -o pipefail
#set -x # trace option

if [ $USER != "root" ]; then
	echo "This must be run as root."
	exit 1
fi

start_vpn() {
	echo "Add network interface"

	# Make the netns.
	ip netns add ${namespaceName}

	# Start the loopback interface in the namespace
	#${namespaceRun} ip addr add 127.0.0.1/8 dev lo
	#${namespaceRun} ip link set lo up

	ip link add ${bridgeIdentifier} type bridge
	ip link set ${bridgeIdentifier} up

	# Make the inter-namespace pipe and bridge the host end.
	ip link add ${vethHost} type veth peer name ${vethPeer}
	ip link set ${vethHost} master ${bridgeIdentifier} up
	ip link set ${vethPeer} netns ${namespaceName} up

	# Bridge the wired ethernet.
	ip link set ${networkInterface} master ${bridgeIdentifier} up

	# Start dhcpcd on the bridge for the host to use and on ${vethPeer}
	# for the ${namespaceName} netns to use. The router will grant separate IP
	# addresses to both! (They have different MAC addresses.)
	dhcpcd ${bridgeIdentifier}
	${namespaceRun} dhcpcd ${vethPeer}

	# we should have full network access in the namespace
	${namespaceRun} ping -c 3 www.google.com

	# start OpenVPN in the namespace
	echo "Starting VPN"
	cd "${vpnDir}"
	${vpnStart}
}

stop_vpn() {
	echo "Stopping VPN"
	ip netns pids ${namespaceName} | xargs -rd'\n' kill
	# TODO wait for terminate

	echo "Delete network interface"
	ip link delete ${vethHost}
	ip link delete ${bridgeIdentifier}
	
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

if [ "${command}" = 'start' ]; then
	# stop VPN on exit (even when error occured)
	trap stop_vpn EXIT
	start_vpn
elif [ "${command}" = 'stop' ]; then
	stop_vpn
elif [ "${command}" = 'add' ]; then
	run_command $@
elif [ "${command}" = 'ip' ]; then
	echo "$(get_vpn_ip)"
else
	echo "Usage $path [start|add|ip|stop] [--iface netwrokInterface eth0] [--name namespaceName vpn] [--user namespaceUser vpn] [add command]"
	exit 1
fi

