#!/bin/sh
# /root/pdx-001.sh

description="Nothing Installed"
iloApiAddress='https://192.168.1.61/ribcl'
iloPort='41000'
serverInternalAddresss='http://192.168.1.51/'
serverExternalPort='41080'
user='<REDACTED>'
password='<REDACTED>'
command="$1"; shift

/root/iLO3Server.sh "$0" "$description" "$iloApiAddress" "$iloPort" "$serverInternalAddresss" "$serverExternalPort" "$user" "$password" "$command"
