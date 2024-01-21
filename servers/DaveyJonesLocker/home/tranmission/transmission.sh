#!/bin/bash
# /home/transmission/transmission.sh

service='transmission'
description='Transmission Torrent Client'
protocol="$(/server/Properties.sh 'transmission.protocol')"
address="$(/server/Properties.sh 'transmission.address')"
port="$(/server/Properties.sh 'transmission.port')"
timezone="$(/server/Properties.sh 'timezone')"
externalAddress="${protocol}://${address}:${port}"
imageName='transmission'
imageVersion='latest'
installCommand='(cd /home/transmission/dockerfiles; docker build -f transmission-pia.Dockerfile -t transmission .)'
startParameters=$(echo \
                "--cap-add=NET_ADMIN" \
                "--device /dev/net/tun" \
                "--publish ${port}:9091" \
                "--env PUID=$(id -u transmission)" \
                "--env PGID=$(id -g transmission)" \
                "--env VUID=$(id -u vpn)" \
                "--env VGID=$(id -g vpn)" \
                "--env TZ=${timezone}" \
                "--mount type=bind,source=/home/vpn,target=/home/vpn" \
                "--mount type=bind,source=/home/transmission,target=/home/transmission" \
                "--mount type=bind,source=/home/public,target=/home/public" \
                "--mount type=bind,source=/home2/public,target=/home2/public" \
                "--rm" \
                "--restart unless-stopped" \
                )

/server/DockerService.sh "$0" "$service" "$description" "$externalAddress" "$startParameters" "${imageName}:${imageVersion}" "${installCommand}" "$1"
