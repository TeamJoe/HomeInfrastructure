#!/bin/bash
# /root/nzbget.sh

service='nzbget'
description='NZBGet Usenet Client'
externalAddress='http://DaveyJonesLocker.lan:6789'
startParameters="--cap-add=NET_ADMIN --device /dev/net/tun --publish 6789:6789 --mount type=bind,source=/home/public,target=/home/public --mount type=bind,source=/home/nzbget,target=/home/nzbget --mount type=bind,source=/home/vpn,target=/home/vpn nzbget:latest"

/root/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "$1"

