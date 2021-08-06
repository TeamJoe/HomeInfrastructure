#!/bin/bash
# /home/jackett/jackett.sh

service='jackett'
description='Jackett Indexing Service'
protocol="$(/server/Properties.sh 'jackett.protocol')"
address="$(/server/Properties.sh 'jackett.address')"
port="$(/server/Properties.sh 'jackett.port')"
timezone="$(/server/Properties.sh 'timezone')"
externalAddress="${protocol}://${address}:${port}"
startParameters=$(echo \
                "--cap-add=NET_ADMIN" \
                "--device /dev/net/tun" \
                "--publish ${port}:9117" \
                "--env PUID=$(id -u jackett)" \
                "--env PGID=$(id -g jackett)" \
                "--env VUID=$(id -u vpn)" \
                "--env VGID=$(id -g vpn)" \
                "--env TZ=${timezone}" \
                "--env AUTO_UPDATE=true" \
                "--mount type=bind,source=/home/vpn,target=/home/vpn" \
                "--mount type=bind,source=/home/jackett,target=/home/jackett" \
                "--mount type=bind,source=/home/jackett/config,target=/config" \
                "--mount type=bind,source=/home/jackett/downloads,target=/downloads" \
                "--restart unless-stopped jackett:latest" \
                )

/server/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "$1"

