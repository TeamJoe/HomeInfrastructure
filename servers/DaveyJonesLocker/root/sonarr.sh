#!/bin/bash
# /root/sonarr.sh

service='sonarr.service'
description='Sonarr TV Series Manager'
externalAddress='http://DaveyJonesLocker.lan:8989'

/root/ServiceStatus.sh "$0" "$service" "$description" "$externalAddress" "$1"
