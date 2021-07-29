#!/bin/bash
# /root/transmission.sh

service='transmission'
description='Transmission Torrent Client'
externalAddress='http://DaveyJonesLocker.lan:9091'
startParameters="--cap-add=NET_ADMIN --device /dev/net/tun --publish 9091:9091 --mount type=bind,source=/home/public,target=/home/public --mount type=bind,source=/home/transmission,target=/home/transmission --mount type=bind,source=/home/vpn,target=/home/vpn  transmission:latest"

/root/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "$1"

