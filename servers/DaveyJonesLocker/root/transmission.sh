#!/bin/bash
# /root/transmission.sh

service='transmission-daemon.service'
description='Transmission Torrent Client'
externalAddress='http://DaveyJonesLocker.lan:9091'

/root/ServiceStatus.sh "$0" "$service" "$description" "$externalAddress" "$1"
