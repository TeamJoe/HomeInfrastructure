#!/bin/sh
# /root/pdx-004.sh

description="Don't Starve | Factorio | Minecraft | ATM3R | ATM5 | RLCraft | SevTech | SkyFactory"
iloApiAddress='https://<REDACTED>/rest/v1/Systems/1'
iloAddress='<REDACTED>'
serverInternalAddresss='<REDACTED>'
serverExternalAddress='<REDACTED>'
user='<REDACTED>'
password='<REDACTED>'
command="$1"; shift

/root/iLO4Server.sh "$0" "$description" "$iloApiAddress" "$iloAddress" "$serverInternalAddresss" "$serverExternalAddress" "$user" "$password" "$command"
