#!/bin/bash
# /home/sonarr/sonarr.sh

service='sonarr'
description='Sonarr TV Series Manager'
protocol="$(/server/Properties.sh 'sonarr.protocol')"
address="$(/server/Properties.sh 'sonarr.address')"
port="$(/server/Properties.sh 'sonarr.port')"
architecture="$(/server/Properties.sh 'architecture')"
externalAddress="${protocol}://${address}:${port}/web"
startParameters="--publish ${port}:8989 --env PUID=$(id -u sonarr) --env PGID=$(id -g sonarr) --env TZ=America/Vancouver --env VERSION=latest --mount type=bind,source=/home/sonarr,target=/config --mount type=bind,source=/home/sonarr,target=/home/sonarr --mount type=bind,source=/home/public,target=/home/public --restart unless-stopped ghcr.io/linuxserver/sonarr:${architecture}-latest"

/server/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "$1"

