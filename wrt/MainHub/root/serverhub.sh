#!/bin/sh
# /root/serverhub.sh

serverInternalAddresss='http://ServerHub.lan:20000'
serverExternalPort='40080'
command="$1"; shift

/root/GenericServer.sh "$0" "$serverInternalAddresss" "$serverExternalPort" "$command"
