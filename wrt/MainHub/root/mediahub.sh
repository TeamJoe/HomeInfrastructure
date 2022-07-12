#!/bin/sh
# /root/mediahub.sh

serverInternalAddresss='http://MediaHub.lan:20000'
serverExternalAddress='http://%24address:20080/status'
command="$1"; shift

/root/GenericServer.sh "$0" "$serverInternalAddresss" "$serverExternalAddress" "$command"

