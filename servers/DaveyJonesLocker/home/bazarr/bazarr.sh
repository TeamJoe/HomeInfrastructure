#!/bin/bash
# /home/bazarr/bazarr.sh

service='bazarr'
description='Bazarr Subtitle Manager'
protocol="$(/server/Properties.sh 'bazarr.protocol')"
address="$(/server/Properties.sh 'bazarr.address')"
port="$(/server/Properties.sh 'bazarr.port')"
architecture="$(/server/Properties.sh 'architecture')"
externalAddress="${protocol}://${address}:${port}/web"
startParameters="--publish ${port}:6767 --env PUID=$(id -u bazarr) --env PGID=$(id -g bazarr) --env TZ=America/Vancouver --env VERSION=latest --mount type=bind,source=/home/bazarr,target=/config --mount type=bind,source=/home/bazarr,target=/home/bazarr --mount type=bind,source=/home/public,target=/home/public --restart unless-stopped ghcr.io/linuxserver/bazarr:${architecture}-latest"

/server/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "$1"

