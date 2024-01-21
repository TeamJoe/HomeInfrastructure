#!/bin/bash
# /home/lidarr/lidarr.sh

service='lidarr'
description='Lidarr Music Manager'
protocol="$(/server/Properties.sh 'lidarr.protocol')"
address="$(/server/Properties.sh 'lidarr.address')"
port="$(/server/Properties.sh 'lidarr.port')"
timezone="$(/server/Properties.sh 'timezone')"
architecture="$(/server/Properties.sh 'architecture')"
externalAddress="${protocol}://${address}:${port}"
imageName='ghcr.io/linuxserver/lidarr'
imageVersion="${architecture}-latest"
startParameters=$(echo \
                "--publish ${port}:8686" \
                "--env PUID=$(id -u lidarr)" \
                "--env PGID=$(id -g lidarr)" \
                "--env TZ=${timezone}" \
                "--env VERSION=latest" \
                "--mount type=bind,source=/home/lidarr,target=/config" \
                "--mount type=bind,source=/home/lidarr,target=/home/lidarr" \
                "--mount type=bind,source=/home/public,target=/home/public" \
                "--mount type=bind,source=/home2/public,target=/home2/public" \
                "--rm" \
                "--restart unless-stopped" \
                )

/server/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "${imageName}:${imageVersion}" '' "$1"
