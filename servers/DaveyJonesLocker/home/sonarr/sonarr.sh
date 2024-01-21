#!/bin/bash
# /home/sonarr/sonarr.sh

service='sonarr'
description='Sonarr TV Series Manager'
protocol="$(/server/Properties.sh 'sonarr.protocol')"
address="$(/server/Properties.sh 'sonarr.address')"
port="$(/server/Properties.sh 'sonarr.port')"
timezone="$(/server/Properties.sh 'timezone')"
architecture="$(/server/Properties.sh 'architecture')"
externalAddress="${protocol}://${address}:${port}"
imageName='ghcr.io/linuxserver/sonarr'
imageVersion="${architecture}-latest"
startParameters=$(echo \
                "--publish ${port}:8989" \
                "--env PUID=$(id -u sonarr)" \
                "--env PGID=$(id -g sonarr)" \
                "--env TZ=${timezone}" \
                "--env VERSION=latest" \
                "--mount type=bind,source=/home/sonarr,target=/config" \
                "--mount type=bind,source=/home/sonarr,target=/home/sonarr" \
                "--mount type=bind,source=/home/public,target=/home/public" \
                "--mount type=bind,source=/home2/public,target=/home2/public" \
                "--restart unless-stopped" \
                )

/server/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "${imageName}:${imageVersion}" '' "$1"
