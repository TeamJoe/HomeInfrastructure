#!/bin/bash
# /home/radarr/radarr.sh

service='radarr'
description='Radarr Movie Manager'
protocol="$(/server/Properties.sh 'radarr.protocol')"
address="$(/server/Properties.sh 'radarr.address')"
port="$(/server/Properties.sh 'radarr.port')"
timezone="$(/server/Properties.sh 'timezone')"
architecture="$(/server/Properties.sh 'architecture')"
externalAddress="${protocol}://${address}:${port}"
startParameters=$(echo \
                "--publish ${port}:7878" \
                "--env PUID=$(id -u radarr)" \
                "--env PGID=$(id -g radarr)" \
                "--env TZ=${timezone}" \
                "--env VERSION=latest" \
                "--mount type=bind,source=/home/radarr,target=/config" \
                "--mount type=bind,source=/home/radarr,target=/home/radarr" \
                "--mount type=bind,source=/home/public,target=/home/public" \
                "--mount type=bind,source=/home2/public,target=/home2/public" \
                "--restart unless-stopped ghcr.io/linuxserver/radarr:${architecture}-latest" \
                )

/server/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "$1"