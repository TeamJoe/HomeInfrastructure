#!/bin/bash
# /root/radarr.sh

service='radarr.service'
externalAddress='http://DaveyJonesLocker.lan:7878'

/root/ServiceStatus.sh "$0" "$service" "$externalAddress" "$1"
