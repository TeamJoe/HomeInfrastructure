#!/bin/sh
# /root/mediahub.sh

serverInternalAddresss='http://MediaHub.lan:20000'
serverExternalPort='20080'
command="$1"; shift

/root/GenericServer.sh "$0" "$serverInternalAddresss" "$serverExternalPort" "$command"
