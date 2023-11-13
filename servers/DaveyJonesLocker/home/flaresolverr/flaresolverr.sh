#!/bin/bash
# /home/flaresolverr/flaresolverr.sh

service='flaresolverr'
description='FlareSolverr Security ByPass'
protocol="$(/server/Properties.sh 'flaresolverr.protocol')"
address="$(/server/Properties.sh 'flaresolverr.address')"
port="$(/server/Properties.sh 'flaresolverr.port')"
timezone="$(/server/Properties.sh 'timezone')"
externalAddress="${protocol}://${address}:${port}"
startParameters=$(echo \
                "--publish ${port}:8191" \
                "--env PUID=$(id -u flaresolverr)" \
                "--env PGID=$(id -g flaresolverr)" \
                "--env TZ=${timezone}" \
                "--env LOG_LEVEL=info" \
                "--env VERSION=latest" \
                "--mount type=bind,source=/home/flaresolverr,target=/home/flaresolverr" \
                "--restart unless-stopped ghcr.io/flaresolverr/flaresolverr:latest" \
                )

/server/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "$1"
