#!/bin/bash
# /home/jackett/jackett.sh

service='jackett'
description='Jackett Indexing Service'
protocol="$(/server/Properties.sh 'jackett.protocol')"
address="$(/server/Properties.sh 'jackett.address')"
port="$(/server/Properties.sh 'jackett.port')"
externalAddress="${protocol}://${address}:${port}"
startParameters="--cap-add=NET_ADMIN --device /dev/net/tun --publish ${port}:9117 --env PUID=$(id -u jackett) --env PGID=$(id -g jackett) --env TZ=America/Vancouver --env AUTO_UPDATE=true --mount type=bind,source=/home/jackett/downloads,target=/downloads --mount type=bind,source=/home/jackett/config,target=/config  --mount type=bind,source=/home/vpn,target=/home/vpn --restart unless-stopped jackett:latest"

/server/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "$1"

