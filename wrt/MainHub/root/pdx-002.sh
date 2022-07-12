#!/bin/sh
# /root/pdx-002.sh

description="Nothing Installed"
iloApiAddress='https://192.168.1.62/ribcl'
iloAddress='https://%24address:42000'
serverInternalAddresss='http://192.168.1.52/'
serverExternalAddress='http://%24address:42080/status'
user='<REDACTED>'
password='<REDACTED>'
command="$1"; shift

/root/iLO3Server.sh "$0" "$description" "$iloApiAddress" "$iloAddress" "$serverInternalAddresss" "$serverExternalAddress" "$user" "$password" "$command"
