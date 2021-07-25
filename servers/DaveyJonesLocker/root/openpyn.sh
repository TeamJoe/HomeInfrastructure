#!/bin/bash
# /root/openpyn.sh

service='openpyn.service'
description='VPN Service'
externalAddress=''

/root/ServiceStatus.sh "$0" "$service" "$description" "$externalAddress" "$1"
