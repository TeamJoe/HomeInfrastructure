#!/bin/sh
# /root/daveyjoneslocker.sh

serverInternalAddresss='http://DaveyJonesLocker.lan'
serverExternalPort='50080'
command="$1"; shift

/root/GenericServer.sh "$0" "$serverInternalAddresss" "$serverExternalPort" "$command"
