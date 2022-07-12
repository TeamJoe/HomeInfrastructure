#!/bin/sh
# /root/pdx-003.sh

description="Satisfactory"
iloApiAddress='https://192.168.1.63/rest/v1/Systems/1'
iloPort='43000'
serverInternalAddresss='http://192.168.1.53/'
serverExternalPort='43080'
user='<REDACTED>'
password='<REDACTED>'
command="$1"; shift

/root/iLO4Server.sh "$0" "$description" "$iloApiAddress" "$iloPort" "$serverInternalAddresss" "$serverExternalPort" "$user" "$password" "$command"
