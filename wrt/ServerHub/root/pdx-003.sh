#!/bin/sh
# /root/pdx-003.sh

description="Nothing Installed"
iloApiAddress='https://<REDACTED>/rest/v1/Systems/1'
iloAddress='<REDACTED>'
serverInternalAddresss='<REDACTED>'
serverExternalAddress='<REDACTED>'
user='<REDACTED>'
password='<REDACTED>'
command="$1"; shift

/root/iLO4Server.sh "$0" "$description" "$iloApiAddress" "$iloAddress" "$serverInternalAddresss" "$serverExternalAddress" "$user" "$password" "$command"
