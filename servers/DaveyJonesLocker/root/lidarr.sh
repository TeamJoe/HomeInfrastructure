#!/bin/bash
# /root/lidarr.sh

service='lidarr.service'
description='Lidarr Music Manager'
externalAddress='http://DaveyJonesLocker.lan:8686'

/root/ServiceStatus.sh "$0" "$service" "$description" "$externalAddress" "$1"
