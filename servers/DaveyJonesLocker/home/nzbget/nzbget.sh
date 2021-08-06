#!/bin/bash
# /home/nzbget/nzbget.sh

service='nzbget'
description='NZBGet Usenet Client'
protocol="$(/server/Properties.sh 'nzbget.protocol')"
address="$(/server/Properties.sh 'nzbget.address')"
port="$(/server/Properties.sh 'nzbget.port')"
timezone="$(/server/Properties.sh 'timezone')"
externalAddress="${protocol}://${address}:${port}"
startParameters=$(echo \
                "--cap-add=NET_ADMIN" \
                "--device /dev/net/tun" \
                "--publish ${port}:6789" \
                "--env PUID=$(id -u nzbget)" \
                "--env PGID=$(id -g nzbget)" \
                "--env VUID=$(id -u vpn)" \
                "--env VGID=$(id -g vpn)" \
                "--env TZ=${timezone}" \
                "--mount type=bind,source=/home/vpn,target=/home/vpn" \
                "--mount type=bind,source=/home/nzbget,target=/home/nzbget" \
                "--mount type=bind,source=/home/public,target=/home/public" \
                "--restart unless-stopped nzbget:latest" \
                )

/server/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "$1"

