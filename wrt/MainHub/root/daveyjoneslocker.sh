#!/bin/sh
# /root/daveyjoneslocker.sh

serverInternalAddresss='<REDACTED>'
serverExternalAddress='<REDACTED>'
command="$1"; shift

/root/GenericServer.sh "$0" "$serverInternalAddresss" "$serverExternalAddress" "$command"
