#!/bin/bash
# /home/bazarr/bazarr.sh

service='bazarr'
description='Bazarr Subtitle Manager'
protocol="$(/server/Properties.sh 'bazarr.protocol')"
address="$(/server/Properties.sh 'bazarr.address')"
port="$(/server/Properties.sh 'bazarr.port')"
timezone="$(/server/Properties.sh 'timezone')"
architecture="$(/server/Properties.sh 'architecture')"
externalAddress="${protocol}://${address}:${port}"
imageName='ghcr.io/linuxserver/bazarr'
imageVersion="${architecture}-latest"
startParameters=$(echo \
                "--publish ${port}:6767" \
                "--env PUID=$(id -u bazarr)" \
                "--env PGID=$(id -g bazarr)" \
                "--env TZ=${timezone}" \
                "--env VERSION=latest" \
                "--mount type=bind,source=/home/bazarr,target=/config" \
                "--mount type=bind,source=/home/bazarr,target=/home/bazarr" \
                "--mount type=bind,source=/home/public,target=/home/public" \
                "--mount type=bind,source=/home2/public,target=/home2/public" \
                "--rm" \
                "--restart unless-stopped" \
                )

/server/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "${imageName}:${imageVersion}" '' "$1"
