#!/bin/sh
# /root/pdx-004.sh

iloApiAddress='https://<REDACTED>/rest/v1/Systems/1'
iloAddress='https://<REDACTED>'
serverInternalAddresss='http://<REDACTED>'
serverExternalAddress='http://<REDACTED>'
user='<REDACTED>'
password='<REDACTED>'
command="$1"; shift

/root/GenericServer.sh "$0" "$iloApiAddress" "$iloAddress" "$serverInternalAddresss" "$serverExternalAddress" "$user" "$password" "$command"
