#!/bin/sh
# /root/heavenhub.sh

serverInternalAddresss='http://HeavenHub.lan:20000'
serverExternalPort='30080'
command="$1"; shift

/root/GenericServer.sh "$0" "$serverInternalAddresss" "$serverExternalPort" "$command"
