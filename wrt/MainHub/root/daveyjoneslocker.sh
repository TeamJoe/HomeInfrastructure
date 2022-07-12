#!/bin/sh
# /root/daveyjoneslocker.sh

serverInternalAddresss='http://DaveyJonesLocker.lan'
serverExternalAddress='http://%24address:50080/status'
command="$1"; shift

/root/GenericServer.sh "$0" "$serverInternalAddresss" "$serverExternalAddress" "$command"
