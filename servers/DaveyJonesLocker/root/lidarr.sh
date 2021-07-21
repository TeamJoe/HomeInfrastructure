#!/bin/bash
# /root/lidarr.sh

service='lidarr.service'
externalAddress='http://DaveyJonesLocker.lan:8686'

/root/ServiceStatus.sh "$0" "$service" "$externalAddress" "$1"
