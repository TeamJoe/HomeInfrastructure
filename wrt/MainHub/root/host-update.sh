#!/bin/sh
# /root/host-update.sh
# /etc/crontabs/root: "*/5 * * * * /root/host-update.sh"

HOST_FILE='/tmp/generated_hosts'

#echo "$(ifstatus wan |  jsonfilter -e '@["ipv4-address"][0].address') <REDACTED:http://freedns.afraid.org/dynamic/>" > "$HOST_FILE"
