#!/bin/bash
# /home/satisfactory/satisfactory.sh

tag='pacificengine/satisfactory:early-access'
service='satisfactory.2'
user='satisfactory'
description='Satisfactory (The Manks Monkeying About)'
address="$(/server/Properties.sh 'satisfactory.2.address')"
serverport="$(/server/Properties.sh 'satisfactory.2.port.server')"
beaconport="$(/server/Properties.sh 'satisfactory.2.port.beacon')"
queryport="$(/server/Properties.sh 'satisfactory.2.port.query')"
installDirectory="$(/server/Properties.sh 'satisfactory.2.dir.install')"

/home/satisfactory/GenericSatisfactoryServer.sh "$0" "$tag" "$service" "$user" "$description" "$address" "$serverport" "$beaconport" "$queryport" "$installDirectory" "$1"

