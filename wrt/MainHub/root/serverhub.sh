#!/bin/sh
# /root/serverhub.sh

serverInternalAddresss='http://ServerHub.lan:20000'
serverExternalAddress='http://%24address:40080/status'
command="$1"; shift

/root/GenericServer.sh "$0" "$serverInternalAddresss" "$serverExternalAddress" "$command"

