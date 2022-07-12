#!/bin/sh
# /root/pdx-002.sh

description="Nothing Installed"
iloApiAddress='https://192.168.1.62/ribcl'
iloPort='42000'
serverInternalAddresss='http://192.168.1.52/'
serverExternalPort='42080'
user='<REDACTED>'
password='<REDACTED>'
command="$1"; shift

/root/iLO3Server.sh "$0" "$description" "$iloApiAddress" "$iloPort" "$serverInternalAddresss" "$serverExternalPort" "$user" "$password" "$command"
