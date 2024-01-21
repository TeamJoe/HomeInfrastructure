#!/bin/bash
# /home/ombi/ombi.sh

service='ombi'
description='OMBI Requesting Manager'
protocol="$(/server/Properties.sh 'ombi.protocol')"
address="$(/server/Properties.sh 'ombi.address')"
port="$(/server/Properties.sh 'ombi.port')"
timezone="$(/server/Properties.sh 'timezone')"
architecture="$(/server/Properties.sh 'architecture')"
externalAddress="${protocol}://${address}:${port}"
imageName='ghcr.io/linuxserver/ombi'
imageVersion="${architecture}-latest"
startParameters=$(echo \
                "--publish ${port}:3579" \
                "--env PUID=$(id -u ombi)" \
                "--env PGID=$(id -g ombi)" \
                "--env TZ=${timezone}" \
                "--env VERSION=latest" \
                "--mount type=bind,source=/home/ombi,target=/config" \
                "--mount type=bind,source=/home/ombi,target=/home/ombi" \
                "--mount type=bind,source=/home/public,target=/home/public" \
                "--mount type=bind,source=/home2/public,target=/home2/public" \
                "--rm" \
                "--restart unless-stopped" \
                )

/server/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "${imageName}:${imageVersion}" '' "$1"
