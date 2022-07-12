#!/bin/sh
# /root/heavenhub.sh

serverInternalAddresss='http://HeavenHub.lan:20000'
serverExternalAddress='http://%24address:30080/status'
command="$1"; shift

/root/GenericServer.sh "$0" "$serverInternalAddresss" "$serverExternalAddress" "$command"

