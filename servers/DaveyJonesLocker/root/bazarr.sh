#!/bin/bash
# /root/bazarr.sh

service='bazarr.service'
description='Bazarr Subtitles Manager'
externalAddress='http://DaveyJonesLocker.lan:6767'

/root/ServiceStatus.sh "$0" "$service" "$description" "$externalAddress" "$1"
