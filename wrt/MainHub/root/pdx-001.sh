#!/bin/sh
# /root/pdx-001.sh

description="Nothing Installed"
iloApiAddress='https://192.168.1.61/ribcl'
iloAddress='https://%24address:41000'
serverInternalAddresss='http://192.168.1.51/'
serverExternalAddress='http://%24address:41080/status'
user='<REDACTED>'
password='<REDACTED>'
command="$1"; shift

/root/iLO3Server.sh "$0" "$description" "$iloApiAddress" "$iloAddress" "$serverInternalAddresss" "$serverExternalAddress" "$user" "$password" "$command"
