#!/bin/bash
# /root/plex.sh

service='plexmediaserver.service'
description='Plex Streaming Service'
externalAddress='http://lobythepirate.mooo.com:50400/web'

/root/ServiceStatus.sh "$0" "$service" "$description" "$externalAddress" "$1"
