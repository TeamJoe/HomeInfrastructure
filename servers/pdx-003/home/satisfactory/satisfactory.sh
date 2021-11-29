#!/bin/bash
# /home/satisfactory/satisfactory.sh

tag='pacificengine/satisfactory:early-access'
service='satisfactory'
user='satisfactory'
description='Satisfactory (Kevin y Jose)'
address="$(/server/Properties.sh 'satisfactory.1.address')"
serverport="$(/server/Properties.sh 'satisfactory.1.port.server')"
beaconport="$(/server/Properties.sh 'satisfactory.1.port.beacon')"
queryport="$(/server/Properties.sh 'satisfactory.1.port.query')"
installDirectory="$(/server/Properties.sh 'satisfactory.1.dir.install')"

/home/satisfactory/GenericSatisfactoryServer.sh "$0" "$tag" "$service" "$user" "$description" "$address" "$serverport" "$beaconport" "$queryport" "$installDirectory" "$1"

