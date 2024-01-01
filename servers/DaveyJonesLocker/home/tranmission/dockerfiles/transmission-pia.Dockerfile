# /home/transmission/dockerfiles/transmission-pia.Dockerfile
# (cd /home/transmission/dockerfiles; docker build -f transmission-pia.Dockerfile -t transmission .)

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

ENV TRANSMISSION_DIR=/home/transmission
COPY ./files/etc/default/transmission-daemon /etc/default/transmission-daemon
RUN chmod 555 /etc/default/transmission-daemon && \
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

ENV LOG_LEVEL=info
RUN mkdir build && \
	useradd --system --shell /usr/sbin/nologin vpn

COPY ./files/build/start-pia.sh /build/start-pia.sh
RUN chmod 555 /build/start-pia.sh

CMD ["/bin/bash", "/build/start-pia.sh"]
