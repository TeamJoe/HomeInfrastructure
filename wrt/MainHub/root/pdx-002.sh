#!/bin/sh
# /root/pdx-002.sh

description="Nothing Installed"
iloApiAddress='http://<REDACTED>/ribcl'
iloAddress='<REDACTED>'
serverInternalAddresss='<REDACTED>'
serverExternalAddress='<REDACTED>'
user='<REDACTED>'
password='<REDACTED>'
command="$1"; shift

/root/iLO3Server.sh "$0" "$description" "$iloApiAddress" "$iloAddress" "$serverInternalAddresss" "$serverExternalAddress" "$user" "$password" "$command"
