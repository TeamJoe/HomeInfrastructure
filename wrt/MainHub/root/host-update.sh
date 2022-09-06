#!/bin/sh
# /root/host-update.sh
# /etc/crontabs/root: "*/5 * * * * /root/host-update.sh"
source /server/properties.sh

HOST_FILE='/tmp/generated_hosts'
ADDRESS="$(getProperty 'hostname.address')"

echo "" > "${HOST_FILE}"
for host in ${ADDRESS}; do
  echo "$(ifstatus wan | jsonfilter -e '@["ipv4-address"][0].address') ${host}" > "${HOST_FILE}"
done