#!/bin/sh
# /root/pdx-004.sh

description="Don't Starve | Factorio | Minecraft | ATM3R | ATM5 | RLCraft | SevTech | SkyFactory"
iloApiAddress='https://192.168.1.64/rest/v1/Systems/1'
iloPort='44000'
serverInternalAddresss='http://192.168.1.54/'
serverExternalPort='44080'
user='<REDACTED>'
password='<REDACTED>'
command="$1"; shift

/root/iLO4Server.sh "$0" "$description" "$iloApiAddress" "$iloPort" "$serverInternalAddresss" "$serverExternalPort" "$user" "$password" "$command"
