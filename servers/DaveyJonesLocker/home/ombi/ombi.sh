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
startParameters=$(echo \
                "--publish ${port}:3579" \
                "--env PUID=$(id -u ombi)" \
                "--env PGID=$(id -g ombi)" \
                "--env TZ=${timezone}" \
                "--env VERSION=latest" \
                "--mount type=bind,source=/home/ombi,target=/config" \
                "--mount type=bind,source=/home/ombi,target=/home/ombi" \
                "--mount type=bind,source=/home/public,target=/home/public" \
                "--restart unless-stopped ghcr.io/linuxserver/ombi:${architecture}-latest" \
                )

/server/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "$1"

