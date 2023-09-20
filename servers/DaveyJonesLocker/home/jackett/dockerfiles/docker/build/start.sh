#!/bin/bash


GATEWAY="$(ip -4 route ls | grep default | grep -Po '(?<=via )(\S+)')"
IP="$(hostname -I | awk '{print $1}')"
if [ -n "${VUID}" ]; then usermod -u "${VUID}" vpn; fi
if [ -n "${VGID}" ]; then groupmod -g "${VGID}" vpn; fi
PIA_PF="${PIA_PF:=true}"

cd /etc/pia
    PIA_USER="${PIA_USER:-'$( if [ -n "${PIA_USER}" ]; then echo "${PIA_USER}"; else echo '$(cat /home/vpn/credentials | awk '"'NR==1'"')'; fi )'}"
    PIA_PASS="${PIA_PASS:-'$( if [ -n "${PIA_PASS}" ]; then echo "${PIA_PASS}"; else echo '$(cat /home/vpn/credentials | awk '"'NR==2'"')'; fi )'}"
    PIA_PF="${PIA_PF}"
    DISABLE_IPV6="${DISABLE_IPV6:-'"${DISABLE_IPV6:-true}"'}"
    AUTOCONNECT="${AUTOCONNECT:-'"${AUTOCONNECT:-true}"'}"
    VPN_PROTOCOL="${VPN_PROTOCOL:-'"${VPN_PROTOCOL:-openvpn_udp_standard}"'}"
    MAX_LATENCY="${MAX_LATENCY:-'"${MAX_LATENCY:-0.05}"'}"
    PREFERRED_REGION="${PREFERRED_REGION:-'"${PREFERRED_REGION:-none}"'}"
    PIA_DNS="${PIA_DNS:-'"${PIA_DNS:-true}"'}"
    /etc/pia/run_setup.sh > /build/setup.out &
while ! ip link show dev $(ip link | grep -o tun[0-9]*) >/dev/null 2>&1 ; do sleep .5 ; done
TUNNEL="$(ip link | grep -o tun[0-9]*)"
ip rule add from ${IP} table 128
ip route add table 128 to ${GATEWAY}/8 dev eth0
ip route add table 128 default via ${GATEWAY}
if [ "${PIA_PF}" = "true" ]; then
    while [ -z "$(cat /build/setup.out | grep "Forwarded port" | grep -o "[0-9]*")" ]; do sleep .5 ; done
    PORT="$(cat /build/setup.out | grep "Forwarded port" | grep -o "[0-9]*")"
else
    PORT=0
fi
mkdir -p /home/jackett/logs
/init > /home/jackett/logs/init.out &
for i in {1..1000}; do
            "if [[ -n \"\$(ip link show dev \${TUNNEL} 2> /dev/null)\" && -n \"\$(ps -u abc | awk 'NR!=1{print \$1}')\" ]]; then break; fi\n" \
    sleep 1
done
        "trap '{ echo \"Quit Signal Received\" ; kill -9 \$(ps -u abc | awk 'NR!=1{print \$1}') ; }' SIGQUIT\n" \
        "trap '{ echo \"Abort Signal Received\" ; kill -9 \$(ps -u abc | awk 'NR!=1{print \$1}') ; }' SIGABRT\n" \
        "trap '{ echo \"Interrupt Signal Received\" ; kill -9 \$(ps -u abc | awk 'NR!=1{print \$1}') ; }' SIGINT\n" \
        "trap '{ echo \"Terminate Signal Received\" ; kill -9 \$(ps -u abc | awk 'NR!=1{print \$1}') ; }' SIGTERM\n" \
while true; do
            "if [[ -z \"\$(ip link show dev \${TUNNEL} 2> /dev/null)\" || -z \"\$(ps -u abc | awk 'NR!=1{print \$1}')\" ]]; then break; fi\n" \
    sleep 1
done
        "kill -9 \$(ps -u abc | awk 'NR!=1{print \$1}') \$(ps ax | grep jackett | awk '{print \$1}')\n" > /build/start.sh && \