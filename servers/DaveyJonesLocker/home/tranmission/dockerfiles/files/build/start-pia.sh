#!/bin/bash

# Setting Start-up Variables
VPN_CREDENTIALS="${VPN_CREDENTIALS:-/home/vpn/credentials}"
TRANSMISSION_DIR="${TRANSMISSION_DIR:-/home/transmission}"
LOG_LEVEL="${LOG_LEVEL:-info}"
PIA_PF="${PIA_PF:-true}"
GATEWAY="$(ip -4 route ls | grep default | grep -Po '(?<=via )(\S+)')"
IP="$(hostname -I | awk '{print $1}')"
if [ -n "${PUID}" ]; then
  usermod -u "${PUID}" debian-transmission
fi
if [ -n "${PGID}" ]; then
  groupmod -g "${PGID}" debian-transmission
fi
if [ -n "${VUID}" ]; then
  usermod -u "${VUID}" vpn
fi
if [ -n "${VGID}" ]; then
  groupmod -g "${VGID}" vpn
fi

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
  /etc/pia/run_setup.sh > /build/setup.out &
while ! ip link show dev $(ip link | grep -o tun[0-9]*) >/dev/null 2>&1 ; do
  sleep .5
done

# Verifying VPN Connection
TUNNEL="$(ip link | grep -o tun[0-9]*)"
ip rule add from ${IP} table 128
ip route add table 128 to ${GATEWAY}/8 dev eth0
ip route add table 128 default via ${GATEWAY}
if [ "${PIA_PF}" = "true" ]; then
  while [ -z "$(cat /build/setup.out | grep "Forwarded port" | grep -o "[0-9]*")" ]; do
    sleep .5
  done
  PORT="$(cat /build/setup.out | grep "Forwarded port" | grep -o "[0-9]*")"
else
  PORT=0
fi

# Editing Transmission Settings
if [ -f "${TRANSMISSION_DIR}/info/settings.json.template" ]; then
  cp "${TRANSMISSION_DIR}/info/settings.json" "${TRANSMISSION_DIR}/info/settings.json.template"
fi
jq -M ".\"peer-port\"=${PORT}" "${TRANSMISSION_DIR}/info/settings.json.template" > "${TRANSMISSION_DIR}/info/settings.json"

# Starting Transmission
chown debian-transmission:debian-transmission -R "${TRANSMISSION_DIR}"
sudo su debian-transmission -s /etc/init.d/transmission-daemon -- start
for i in {1..1000}; do
  if [[ -n "$(ip link show dev ${TUNNEL} 2> /dev/null)" && -n "$(ps -u debian-transmission | awk 'NR!=1{print $1}')" ]]; then
    break
  fi
  sleep 1
done

# Killing Transmission on VPN Failure
trap '{ echo "Quit Signal Received" ; kill -9 $(ps -u debian-transmission | awk 'NR!=1{print $1}') ; }' SIGQUIT
trap '{ echo "Abort Signal Received" ; kill -9 $(ps -u debian-transmission | awk 'NR!=1{print $1}') ; }' SIGABRT
trap '{ echo "Interrupt Signal Received" ; kill -9 $(ps -u debian-transmission | awk 'NR!=1{print $1}') ; }' SIGINT
trap '{ echo "Terminate Signal Received" ; kill -9 $(ps -u debian-transmission | awk 'NR!=1{print $1}') ; }' SIGTERM

# Keep process running as long as the VPN is up and Transmission is running
while true; do
  if [[ -z "$(ip link show dev ${TUNNEL} 2> /dev/null)" || -z "$(ps -u debian-transmission | awk 'NR!=1{print $1}')" ]]; then
    break
  fi
  sleep 1
done

# Cleanup any unterminated Transmission processes
kill -9 $(ps -u debian-transmission | awk 'NR!=1{print $1}') $(ps ax | grep debian-transmission | awk '{print $1}')