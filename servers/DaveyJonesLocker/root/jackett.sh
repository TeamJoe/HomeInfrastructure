#!/bin/bash
# /root/jackett.sh

service='jackett'
description='Jackett Torrent Indexer'
externalAddress='http://DaveyJonesLocker.lan:9117'
startParameters="--publish 9117:9117 --env PUID=1000 --env PGID=1000 --env TZ=America/Vancouver --env AUTO_UPDATE=true --mount type=bind,source=/home/jackett/downloads,target=/downloads --mount type=bind,source=/home/jackett/config,target=/config jackett:latest"

/root/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "$1"

