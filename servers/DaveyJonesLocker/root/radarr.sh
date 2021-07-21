#!/bin/bash
# /root/radarr.sh

service='radarr.service'
description='Radarr Movie Manager'
externalAddress='http://DaveyJonesLocker.lan:7878'

/root/ServiceStatus.sh "$0" "$service" "$description" "$externalAddress" "$1"
