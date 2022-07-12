#!/bin/sh
# /root/pdx-004.sh

description="Don't Starve | Factorio | Minecraft | ATM3R | ATM5 | RLCraft | SevTech | SkyFactory"
iloApiAddress='https://192.168.1.64/rest/v1/Systems/1'
iloAddress='https://%24address:44000'
serverInternalAddresss='http://192.168.1.54/'
serverExternalAddress='http://%24address:44080/status'
user='<REDACTED>'
password='<REDACTED>'
command="$1"; shift

/root/iLO4Server.sh "$0" "$description" "$iloApiAddress" "$iloAddress" "$serverInternalAddresss" "$serverExternalAddress" "$user" "$password" "$command"
