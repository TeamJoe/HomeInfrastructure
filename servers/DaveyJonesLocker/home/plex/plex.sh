#!/bin/bash
# /home/plex/plex.sh

service='plex'
description='Plex Streaming Service'
protocol="$(/server/Properties.sh 'plex.protocol')"
address="$(/server/Properties.sh 'plex.address')"
port="$(/server/Properties.sh 'plex.port')"
timezone="$(/server/Properties.sh 'timezone')"
architecture="$(/server/Properties.sh 'architecture')"
externalAddress="${protocol}://${address}:${port}/web"
imageName='ghcr.io/linuxserver/plex'
imageVersion="${architecture}-latest"
startParameters=$(echo \
                "--publish ${port}:32400" \
                "--publish 3005:3005/udp" \
                "--publish 5353:5353/udp" \
                "--publish 8324:8324" \
                "--publish 32410:32410/udp" \
                "--publish 32412:32412/udp" \
                "--publish 32413:32413/udp" \
                "--publish 32414:32414/udp" \
                "--publish 32469:32469" \
                "--env PUID=$(id -u plex)" \
                "--env PGID=$(id -g plex)" \
                "--env TZ=${timezone}" \
                "--env VERSION=latest" \
                "--mount type=bind,source=/home/plex,target=/config" \
                "--mount type=bind,source=/home/plex,target=/home/plex" \
                "--mount type=bind,source=/home/public,target=/home/public" \
                "--mount type=bind,source=/home2/public,target=/home2/public" \
                "--rm" \
                "--restart unless-stopped" \
                )

/server/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "${imageName}:${imageVersion}" '' "$1"
