#!/bin/bash
# /home/plexmeta/plexmeta.sh

description='Plex Meta Manager [Single Shot]'
timezone="$(/server/Properties.sh 'timezone')"
architecture="$(/server/Properties.sh 'architecture')"
imageName='lscr.io/linuxserver/plex-meta-manager'
imageVersion="${architecture}-latest"
if [[ "$2" == 'once' ]]; then
  service='oncemeta'
  startParameters=$(echo \
                  "--env PUID=$(id -u plexmeta)" \
                  "--env PGID=$(id -g plexmeta)" \
                  "--env TZ=${timezone}" \
                  "--env VERSION=latest" \
                  "--env PMM_CONFIG=/config/config.yml" \
                  "--env PMM_RUN=True" \
                  "--env PMM_TEST=False" \
                  "--env PMM_NO_MISSING=False" \
                  "--mount type=bind,source=/home/plexmeta,target=/config" \
                  "--mount type=bind,source=/home/plexmeta,target=/home/plexmeta" \
                  "--rm" \
                  "--run-once" \
                  )
else
  service='metadata'
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
                  "--rm" \
                  "--restart unless-stopped" \
                  )
fi


/server/DockerService.sh "$0" "$service" "$description" "" "$startParameters" "${imageName}:${imageVersion}" '' "$1"
