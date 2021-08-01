#!/bin/bash
# /home/transmission/transmission.sh

service='transmission'
description='Transmission Torrent Client'
protocol="$(/server/Properties.sh 'transmission.protocol')"
address="$(/server/Properties.sh 'transmission.address')"
port="$(/server/Properties.sh 'transmission.port')"
externalAddress="${protocol}://${address}:${port}"
startParameters="--cap-add=NET_ADMIN --device /dev/net/tun --publish ${port}:9091 --env PUID=$(id -u transmission) --env PGID=$(id -g transmission) --env TZ=America/Vancouver --mount type=bind,source=/home/public,target=/home/public --mount type=bind,source=/home/transmission,target=/home/transmission --mount type=bind,source=/home/vpn,target=/home/vpn --restart unless-stopped transmission:latest"

/server/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "$1"

