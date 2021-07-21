#!/bin/bash
# /root/plex.sh

service='plexmediaserver.service'
externalAddress='http://lobythepirate.mooo.com:50400/web'

/root/ServiceStatus.sh "$0" "$service" "$externalAddress" "$1"
