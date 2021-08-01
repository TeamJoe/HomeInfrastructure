#!/bin/bash
# /home/plex/plex.sh

service='plex'
description='Plex Streaming Service'
protocol="$(/server/Properties.sh 'plex.protocol')"
address="$(/server/Properties.sh 'plex.address')"
port="$(/server/Properties.sh 'plex.port')"
externalAddress="${protocol}://${address}:${port}/web"
startParameters="--publish ${port}:32400 --publish 1900:1900/udp --publish 3005:3005 --publish 5353:5353/udp --publish 8324:8324 --publish 32410:32410/udp --publish 32412:32412/udp --publish 32413:32413/udp --publish 32414:32414/udp --publish 32469:32469 --env PUID=$(id -u plex) --env PGID=$(id -g plex) --env TZ=America/Vancouver --env VERSION=latest --mount type=bind,source=/home/plex,target=/config --mount type=bind,source=/home/public,target=/home/public --restart unless-stopped ghcr.io/linuxserver/plex:arm64v8-latest"

/server/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "$1"

