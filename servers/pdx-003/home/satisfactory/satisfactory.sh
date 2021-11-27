#!/bin/bash
# /home/satisfactory/satisfactory.sh

tag='pacificengine/satisfactory:early-access'
service='satisfactory'
user='satisfactory'
description='Satisfactory Game Server'
address="$(/server/Properties.sh 'satisfactory.address')"
serverport="$(/server/Properties.sh 'satisfactory.port.server')"
beaconport="$(/server/Properties.sh 'satisfactory.port.beacon')"
queryport="$(/server/Properties.sh 'satisfactory.port.query')"
installDirectory="$(/server/Properties.sh 'satisfactory.dir.install')"

/home/satisfactory/GenericSatisfactoryServer.sh "$0" "$tag" "$service" "$user" "$description" "$address" "$serverport" "$beaconport" "$queryport" "$installDirectory" "$1"

