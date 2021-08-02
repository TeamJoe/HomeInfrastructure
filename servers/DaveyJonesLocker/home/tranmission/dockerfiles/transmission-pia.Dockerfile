# docker build -f transmission-pia.Dockerfile -t transmission .

FROM ubuntu

RUN apt-get update && \
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

RUN apt-get update && \
	apt-get install -y \
		transmission-cli \
		transmission-common \
		transmission-daemon && \
	service transmission-daemon stop

ARG TRANSMISSION_DIR=/home/transmission
RUN echo 'ENABLE_DAEMON=1'"\n" \
		"CONFIG_DIR=\"${TRANSMISSION_DIR}/info\"\n" \
		'OPTIONS="--config-dir ${CONFIG_DIR}"'"\n"  > /etc/default/transmission-daemon && \
	mkdir -p "${TRANSMISSION_DIR}" && \
	mv /var/lib/transmission-daemon/info "${TRANSMISSION_DIR}/info" && \
	mv /var/lib/transmission-daemon/.config "${TRANSMISSION_DIR}/.config" && \
	mv /etc/transmission-daemon/settings.json "${TRANSMISSION_DIR}/info/settings.json" && \
	ln -s "${TRANSMISSION_DIR}/info" /var/lib/transmission-daemon/info && \
	ln -s "${TRANSMISSION_DIR}/info/settings.json" /etc/transmission-daemon/settings.json && \
	mkdir -p /etc/systemd/system/transmission-daemon.service.d && \
	echo "[Service]\nExecStart=/usr/bin/transmission-daemon -f --log-error --config-dir \"$TRANSMISSION_DIR/info\"\n" > /etc/systemd/system/transmission-daemon.service.d/override.conf

# Only required if you want to store the configuration right in the docker instance
# Not required if you mount it to the dockerfile instead
ARG TRANSMISSION_USER=transmission
ARG TRANSMISSION_PASSWORD=transmission
ARG TRANSMISSION_PORT=9091
ARG TRANSMISSION_WHITELIST=127.0.0.1,0.0.0.0
ARG TRANSMISSION_WHITELIST_ENABLED=false
RUN mv "${TRANSMISSION_DIR}/info/settings.json" "${TRANSMISSION_DIR}/info/settings.json.bak" && \
	jq -M ".\"rpc-username\"=\"${TRANSMISSION_USER}\" | .\"rpc-password\"=\"${TRANSMISSION_PASSWORD}\" | .\"rpc-port\"=${TRANSMISSION_PORT} | .\"rpc-whitelist\"=\"${TRANSMISSION_WHITELIST}\" | .\"rpc-whitelist-enabled\"=${TRANSMISSION_WHITELIST_ENABLED} | .\"download-dir\"=\"${TRANSMISSION_DIR}/downloads\" | .\"incomplete-dir\"=\"${TRANSMISSION_DIR}/incomplete\" | .\"incomplete-dir-enabled\"=true" "${TRANSMISSION_DIR}/info/settings.json.bak" > "${TRANSMISSION_DIR}/info/settings.json"

ARG PIA_USER=
ARG PIA_PASS=
ARG PIA_PF=true
ARG DISABLE_IPV6=true
ARG AUTOCONNECT=true
ARG VPN_PROTOCOL=openvpn_udp_standard
ARG MAX_LATENCY=0.05
ARG PREFERRED_REGION=none
ARG PIA_DNS=true
RUN mkdir build && \
	echo '#!/bin/bash'"\n" \
		'IP="$(hostname -I | awk '"'"'{print $1}'"'"')"'"\n" \
		'GATEWAY="$(ip -4 route ls | grep default | grep -Po '"'"'(?<=via )(\S+)'"'"')"'"\n" \
		'PIA_PF="${PIA_PF:-'"${PIA_PF:-true}"'}" '"\n" \
		'cd /etc/pia'"\n" \
		'PIA_USER="${PIA_USER:-'"$( if [ -n "${PIA_USER}" ]; then echo "${PIA_USER}"; else echo '$(cat /home/vpn/credentials | awk "NR==1")'; fi )"'}" ' \
		'PIA_PASS="${PIA_PASS:-'"$( if [ -n "${PIA_PASS}" ]; then echo "${PIA_PASS}"; else echo '$(cat /home/vpn/credentials | awk "NR==2")'; fi )"'}" ' \
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
		'if [ -f '"'${TRANSMISSION_DIR}/info/settings.json.template'"' ]; then'"\n" \
			"cp '${TRANSMISSION_DIR}/info/settings.json' '${TRANSMISSION_DIR}/info/settings.json.template'\n" \
		'fi'"\n" \
		'jq -M ".\"peer-port\"=${PORT}" '"'${TRANSMISSION_DIR}/info/settings.json.template'"' > '"'${TRANSMISSION_DIR}/info/settings.json'\n" \
		'/usr/bin/transmission-daemon -f --log-error --config-dir '"${TRANSMISSION_DIR}/info"' &'"\n" \
		'pid=$!'"\n" \
		'while ip link show dev ${TUNNEL} >/dev/null 2>&1 ; do sleep .5 ; done'"\n" \
		'kill -9 ${pid}'"\n" > /build/start.sh && \
	chmod 555 /build/start.sh

CMD ["/bin/bash", "/build/start.sh"]
