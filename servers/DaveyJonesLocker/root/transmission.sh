#!/bin/bash
# /root/transmission.sh

service='transmission'
hostname="$(hostname -I | awk '{print $1}')"
description='Transmission Torrent Client'
externalAddress='http://DaveyJonesLocker.lan:9091'
hostname="$(hostname -I | awk '{print $1}')"
startParameters="--cap-add=NET_ADMIN --device /dev/net/tun --publish 9091:9091 --mount type=bind,source=/home/public,target=/home/public --mount type=bind,source=/home/transmission,target=/home/transmission --mount type=bind,source=/home/vpn,target=/home/vpn  transmission:latest"

#sysctl net.ipv4.conf.all.forwarding=1
#sysctl net.ipv6.conf.all.forwarding=1
#sudo iptables -P FORWARD ACCEPT
#sudo ip6tables -P FORWARD ACCEPT

/root/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "$1"

