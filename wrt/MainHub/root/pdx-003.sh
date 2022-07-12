#!/bin/sh
# /root/pdx-003.sh

description="Satisfactory"
iloApiAddress='https://192.168.1.63/rest/v1/Systems/1'
iloAddress='https://%24address:43000'
serverInternalAddresss='http://192.168.1.53/'
serverExternalAddress='http://%24address:43080/status'
user='<REDACTED>'
password='<REDACTED>'
command="$1"; shift

/root/iLO4Server.sh "$0" "$description" "$iloApiAddress" "$iloAddress" "$serverInternalAddresss" "$serverExternalAddress" "$user" "$password" "$command"
