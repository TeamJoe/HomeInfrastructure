#!/bin/bash
# /root/ombi.sh

service='ombi.service'
description='OMBI Requester Service'
externalAddress='http://DaveyJonesLocker.lan:5000'

/root/ServiceStatus.sh "$0" "$service" "$description" "$externalAddress" "$1"
