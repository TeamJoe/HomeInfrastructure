#!/bin/bash
# /home/satisfactory/satisfactory.sh

service='satisfactory'
description='Satisfactory Indexing Service'
address="$(/server/Properties.sh 'satisfactory.address')"
serverport="$(/server/Properties.sh 'satisfactory.port.server')"
beaconport="$(/server/Properties.sh 'satisfactory.port.beacon')"
queryport="$(/server/Properties.sh 'satisfactory.port.query')"
externalAddress="${address}:${serverport}"
startParameters=$(echo \
                "--publish ${serverport}:${serverport}/udp" \
                "--publish ${beaconport}:${beaconport}/udp" \
                "--publish ${queryport}:${queryport}/udp" \
                "--env PORT_SERVER_QUERY=${queryport}" \
                "--env PORT_BEACON=${beaconport}" \
                "--env PORT_SERVER=${serverport}" \
                "--env LOGGING=true" \
                "--env AUTO_UPDATE=true" \
                "--env PUID=$(id -u satisfactory)" \
                "--env PGID=$(id -g satisfactory)" \
                "--env TZ=${timezone}" \
                "--mount type=bind,source=/home/satisfactory/logs,target=/logs" \
                "--mount type=bind,source=/home/satisfactory/config,target=/home/satisfactory/.config/Epic/FactoryGame/Config/LinuxServer" \
                "--mount type=bind,source=/home/satisfactory/saves,target=/home/satisfactory/.config/Epic/FactoryGame/Saved/SaveGames" \
                "--restart unless-stopped satisfactory:latest" \
                )

/server/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "$1"

