#!/bin/bash
# /home/plexmeta/plexmeta.sh

service='metadata'
description='Plex Meta Manager'
timezone="$(/server/Properties.sh 'timezone')"
architecture="$(/server/Properties.sh 'architecture')"
startParameters=$(echo \
                "--env PUID=$(id -u plexmeta)" \
                "--env PGID=$(id -g plexmeta)" \
                "--env TZ=${timezone}" \
                "--env VERSION=latest" \
                "--env PMM_CONFIG=/config/config.yml" \
                "--env PMM_TIME=03:00" \
                "--env PMM_RUN=False" \
                "--env PMM_TEST=False" \
                "--env PMM_NO_MISSING=False" \
                "--mount type=bind,source=/home/plexmeta,target=/config" \
                "--mount type=bind,source=/home/plexmeta,target=/home/plexmeta" \
                "--restart unless-stopped lscr.io/linuxserver/plex-meta-manager:${architecture}-latest" \
                )

/server/DockerService.sh "$0" "$service" "$description" "" "$startParameters" "$1"

