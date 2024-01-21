#!/bin/bash

# Setting Start-up Variables
VPN_CREDENTIALS="${VPN_CREDENTIALS:-/home/vpn/credentials}"
SERVICE_DIRECTORY="${TRANSMISSION_DIR:-/home/transmission}"
LOG_DIRECTORY="${LOG_DIRECTORY:-/home/transmission/logs}"
SERVICE_USERNAME="${TRANSMISSION_USER:-debian-transmission}"
SERVICE_USERGROUP="${TRANSMISSION_GROUP:-debian-transmission}"
VPN_USERNAME="${VPN_USER:-vpn}"
VPN_USERGROUP="${VPN_GROUP:-vpn}"
LOG_LEVEL="${LOG_LEVEL:-info}"
PIA_PF="${PIA_PF:-true}"
GATEWAY="$(ip -4 route ls | grep default | grep -Po '(?<=via )(\S+)')"
IP="$(hostname -I | awk '{print $1}')"
if [ -n "${PUID}" ]; then
  usermod -u "${PUID}" ${SERVICE_USERNAME}
fi
if [ -n "${PGID}" ]; then
  groupmod -g "${PGID}" ${SERVICE_USERGROUP}
fi
if [ -n "${VUID}" ]; then
  usermod -u "${VUID}" ${VPN_USERNAME}
fi
if [ -n "${VGID}" ]; then
  groupmod -g "${VGID}" ${VPN_USERGROUP}
fi

# Establish Directory Ownership
mkdir -p "${LOG_DIRECTORY}"
chown ${SERVICE_USERNAME}:${SERVICE_USERGROUP} -R "${LOG_DIRECTORY}"
chown ${SERVICE_USERNAME}:${SERVICE_USERGROUP} -R "${DIRECTORY}"

# Establishing VPN Connection
cd /etc/pia
PIA_USER="${PIA_USER:-$(cat "${VPN_CREDENTIALS}" | awk 'NR==1')}" \
  PIA_PASS="${PIA_PASS:-$(cat "${VPN_CREDENTIALS}" | awk 'NR==2')}" \
  PIA_PF="${PIA_PF:-true}" \
  DISABLE_IPV6="${DISABLE_IPV6:-true}" \
  AUTOCONNECT="${AUTOCONNECT:-true}" \
  VPN_PROTOCOL="${VPN_PROTOCOL:-openvpn_udp_standard}" \
  MAX_LATENCY="${MAX_LATENCY:-0.05}" \
  PREFERRED_REGION="${PREFERRED_REGION:-none}" \
  PIA_DNS="${PIA_DNS:-true}" \
  /etc/pia/run_setup.sh > "${LOG_DIRECTORY}/pia-output.log" &
while ! ip link show dev $(ip link | grep -o tun[0-9]*) >/dev/null 2>&1 ; do
  sleep .5
done

# Verifying VPN Connection
TUNNEL="$(ip link | grep -o tun[0-9]*)"
ip rule add from ${IP} table 128
ip route add table 128 to ${GATEWAY}/8 dev eth0
ip route add table 128 default via ${GATEWAY}
if [ "${PIA_PF}" = "true" ]; then
  while [ -z "$(cat "${LOG_DIRECTORY}/pia-output.log" | grep "Forwarded port" | grep -o "[0-9]*")" ]; do
    sleep .5
  done
  PORT="$(cat "${LOG_DIRECTORY}/pia-output.log" | grep "Forwarded port" | grep -o "[0-9]*")"
else
  PORT=0
fi

# Editing Transmission Settings
if [ -f "${SERVICE_DIRECTORY}/info/settings.json.template" ]; then
  cp "${SERVICE_DIRECTORY}/info/settings.json" "${SERVICE_DIRECTORY}/info/settings.json.template"
fi
jq -M ".\"peer-port\"=${PORT}" "${SERVICE_DIRECTORY}/info/settings.json.template" > "${SERVICE_DIRECTORY}/info/settings.json"

# Starting Transmission
sudo su ${SERVICE_USERNAME} -s /etc/init.d/transmission-daemon -- start
for i in {1..1000}; do
  if [[ -n "$(ip link show dev ${TUNNEL} 2> /dev/null)" && -n "$(ps -u ${SERVICE_USERNAME} | awk 'NR!=1{print $1}')" ]]; then
    break
  fi
  sleep 1
done

# Killing Service on VPN Failure
trap '{ echo "Quit Signal Received" ; kill -9 $(ps -u '"${SERVICE_USERNAME}"' | awk '"'"'NR!=1{print $1}'"'"') ; }' SIGQUIT
trap '{ echo "Abort Signal Received" ; kill -9 $(ps -u '"${SERVICE_USERNAME}"' | awk '"'"'NR!=1{print $1}'"'"') ; }' SIGABRT
trap '{ echo "Interrupt Signal Received" ; kill -9 $(ps -u '"${SERVICE_USERNAME}"' | awk '"'"'NR!=1{print $1}'"'"') ; }' SIGINT
trap '{ echo "Terminate Signal Received" ; kill -9 $(ps -u '"${SERVICE_USERNAME}"' | awk '"'"'NR!=1{print $1}'"'"') ; }' SIGTERM

# Keep process running as long as the VPN is up and Service is running
while true; do
  if [[ -z "$(ip link show dev ${TUNNEL} 2> /dev/null)" || -z "$(ps -u ${SERVICE_USERNAME} | awk 'NR!=1{print $1}')" ]]; then
    break
  fi
  sleep 1
done

# Cleanup any unterminated Service processes
kill -9 $(ps -u ${SERVICE_USERNAME} | awk 'NR!=1{print $1}') $(ps ax | grep ${SERVICE_USERNAME} | awk '{print $1}')