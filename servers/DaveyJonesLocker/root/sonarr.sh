#!/bin/bash
# /root/sonarr.sh

service='sonarr.service'
externalAddress='http://DaveyJonesLocker.lan:8989'

/root/ServiceStatus.sh "$0" "$service" "$externalAddress" "$1"
