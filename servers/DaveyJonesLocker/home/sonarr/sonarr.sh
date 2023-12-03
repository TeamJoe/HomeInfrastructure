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
                "--mount type=bind,source=/home2/public/Videos/Movies/Anime,target=/home/public/Videos/Movies/Anime" \
                "--mount type=bind,source=/home2/public/Videos/Movies/Hentai,target=/home/public/Videos/Movies/Hentai" \
                "--mount type=bind,source=/home2/public/Videos/TV/Anime,target=/home/public/Videos/TV/Anime" \
                "--mount type=bind,source=/home2/public/Videos/TV/Hentai,target=/home/public/Videos/TV/Hentai" \
                "--restart unless-stopped ghcr.io/linuxserver/sonarr:${architecture}-latest" \
                )

/server/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "$1"