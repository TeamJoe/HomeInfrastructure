#!/bin/bash
# /home/nzbget/nzbget.sh

service='nzbget'
description='NZBGet Usenet Client'
protocol="$(/server/Properties.sh 'nzbget.protocol')"
address="$(/server/Properties.sh 'nzbget.address')"
port="$(/server/Properties.sh 'nzbget.port')"
externalAddress="${protocol}://${address}:${port}"
startParameters="--cap-add=NET_ADMIN --device /dev/net/tun --publish ${port}:6789 --env PUID=$(id -u nzbget) --env PGID=$(id -g nzbget) --env TZ=America/Vancouver --mount type=bind,source=/home/public,target=/home/public --mount type=bind,source=/home/nzbget,target=/home/nzbget --mount type=bind,source=/home/vpn,target=/home/vpn --restart unless-stopped nzbget:latest"

/server/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "$1"

