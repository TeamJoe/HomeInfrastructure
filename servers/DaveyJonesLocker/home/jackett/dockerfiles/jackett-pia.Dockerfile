# /home/jackett/dockerfiles/jackett-pia.Dockerfile
# (cd /home/jackett/dockerfiles; docker build -f jackett-pia.Dockerfile -t jackett .)

FROM ghcr.io/linuxserver/jackett

RUN echo "deb http://ports.ubuntu.com/ubuntu-ports focal main restricted" >> /etc/apt/sources.list && \
	echo "deb http://ports.ubuntu.com/ubuntu-ports focal universe" >> /etc/apt/sources.list && \
	echo "deb http://ports.ubuntu.com/ubuntu-ports focal-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
	echo "deb http://ports.ubuntu.com/ubuntu-ports focal-security main restricted" >> /etc/apt/sources.list && \
	echo "deb http://ports.ubuntu.com/ubuntu-ports focal-security universe" >> /etc/apt/sources.list && \
	echo "deb http://ports.ubuntu.com/ubuntu-ports focal-security multiverse" >> /etc/apt/sources.list && \
	apt-get update && \
	apt-get install -y \
		sudo \
		systemctl \
		curl \
		wget \
		jq \
		ca-certificates \
		openvpn \
		unzip \
		iputils-ping

ARG VPN_CONFIG=https://www.privateinternetaccess.com/openvpn/openvpn.zip 
RUN mkdir -p /etc/openvpn && \
	curl -L "${VPN_CONFIG}" -o /etc/openvpn/ovpn.zip && \
	unzip /etc/openvpn/ovpn.zip -d /etc/openvpn && \
	rm /etc/openvpn/ovpn.zip

ARG PIA_DOWNLOAD=https://github.com/pia-foss/manual-connections/archive/refs/tags/v2.0.0.zip
RUN mkdir -p /etc/pia && \
	curl -L "${PIA_DOWNLOAD}" -o /etc/pia/pia.zip && \
	unzip /etc/pia/pia.zip -d /etc/pia && \
	rm -f /etc/pia/pia.zip && \
	mv /etc/pia/*/* /etc/pia/.

ARG PIA_USER=
ARG PIA_PASS=
ARG PIA_PF=false
ARG DISABLE_IPV6=true
ARG AUTOCONNECT=true
ARG VPN_PROTOCOL=openvpn_udp_standard
ARG MAX_LATENCY=0.05
ARG PREFERRED_REGION=none
ARG PIA_DNS=true
RUN mkdir build && \
	useradd --system --shell /usr/sbin/nologin vpn && \
	echo '#!/bin/bash'"\n" \
        'GATEWAY="$(ip -4 route ls | grep default | grep -Po '"'"'(?<=via )(\S+)'"'"')"'"\n" \
        'IP="$(hostname -I | awk '"'"'{print $1}'"'"')"'"\n" \
        'if [ -n "${VUID}" ]; then usermod -u "${VUID}" vpn; fi '"\n" \
        'if [ -n "${VGID}" ]; then groupmod -g "${VGID}" vpn; fi '"\n" \
        'PIA_PF="${PIA_PF:-'"${PIA_PF:-true}"'}" '"\n" \
        'cd /etc/pia'"\n" \
            'PIA_USER="${PIA_USER:-'$( if [ -n "${PIA_USER}" ]; then echo "${PIA_USER}"; else echo '$(cat /home/vpn/credentials | awk '"'NR==1'"')'; fi )'}" ' \
            'PIA_PASS="${PIA_PASS:-'$( if [ -n "${PIA_PASS}" ]; then echo "${PIA_PASS}"; else echo '$(cat /home/vpn/credentials | awk '"'NR==2'"')'; fi )'}" ' \
            'PIA_PF="${PIA_PF}" ' \
            'DISABLE_IPV6="${DISABLE_IPV6:-'"${DISABLE_IPV6:-true}"'}" ' \
            'AUTOCONNECT="${AUTOCONNECT:-'"${AUTOCONNECT:-true}"'}" ' \
            'VPN_PROTOCOL="${VPN_PROTOCOL:-'"${VPN_PROTOCOL:-openvpn_udp_standard}"'}" ' \
            'MAX_LATENCY="${MAX_LATENCY:-'"${MAX_LATENCY:-0.05}"'}" ' \
            'PREFERRED_REGION="${PREFERRED_REGION:-'"${PREFERRED_REGION:-none}"'}" ' \
            'PIA_DNS="${PIA_DNS:-'"${PIA_DNS:-true}"'}" ' \
            '/etc/pia/run_setup.sh > /build/setup.out &'"\n" \
        'while ! ip link show dev $(ip link | grep -o tun[0-9]*) >/dev/null 2>&1 ; do sleep .5 ; done'"\n" \
        'TUNNEL="$(ip link | grep -o tun[0-9]*)"'"\n" \
        'ip rule add from ${IP} table 128'"\n" \
        'ip route add table 128 to ${GATEWAY}/8 dev eth0'"\n" \
        'ip route add table 128 default via ${GATEWAY}'"\n" \
        'if [ "${PIA_PF}" = "true" ]; then'"\n" \
            'while [ -z "$(cat /build/setup.out | grep "Forwarded port" | grep -o "[0-9]*")" ]; do sleep .5 ; done'"\n" \
            'PORT="$(cat /build/setup.out | grep "Forwarded port" | grep -o "[0-9]*")"'"\n" \
        'else'"\n" \
            'PORT=0'"\n" \
        'fi'"\n" \
		'mkdir -p /home/jackett/logs'"\n" \
		'/init > /home/jackett/logs/init.out &'"\n" \
        'for i in {1..1000}; do'"\n" \
            "if [[ -n \"\$(ip link show dev \${TUNNEL} 2> /dev/null)\" && -n \"\$(ps -u abc | awk 'NR!=1{print \$1}')\" ]]; then break; fi\n" \
            'sleep 1'"\n" \
        'done'"\n" \
        "trap '{ echo \"Quit Signal Received\" ; kill -9 \$(ps -u abc | awk 'NR!=1{print \$1}') ; }' SIGQUIT\n" \
        "trap '{ echo \"Abort Signal Received\" ; kill -9 \$(ps -u abc | awk 'NR!=1{print \$1}') ; }' SIGABRT\n" \
        "trap '{ echo \"Interrupt Signal Received\" ; kill -9 \$(ps -u abc | awk 'NR!=1{print \$1}') ; }' SIGINT\n" \
        "trap '{ echo \"Terminate Signal Received\" ; kill -9 \$(ps -u abc | awk 'NR!=1{print \$1}') ; }' SIGTERM\n" \
        'while true; do'"\n" \
            "if [[ -z \"\$(ip link show dev \${TUNNEL} 2> /dev/null)\" || -z \"\$(ps -u abc | awk 'NR!=1{print \$1}')\" ]]; then break; fi\n" \
            'sleep 1'"\n" \
        'done'"\n" \
        "kill -9 \$(ps -u abc | awk 'NR!=1{print \$1}') \$(ps ax | grep jackett | awk '{print \$1}')\n" > /build/start.sh && \
	chmod 555 /build/start.sh

ENTRYPOINT ["/bin/bash", "/build/start.sh"]
