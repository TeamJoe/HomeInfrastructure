# docker build -f transmission.Dockerfile -t transmission --build-arg TRANSMISSION_DIR=/home/transmission .

FROM ubuntu
ARG TRANSMISSION_DIR=/home/transmission

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
		iputils-ping \
		python3-setuptools \
		python3-pip \
		transmission-cli \
		transmission-common \
		transmission-daemon && \
	service transmission-daemon stop && \
	python3 -m pip install --upgrade openpyn

RUN cd /etc/openvpn && \
	curl -L https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip -o ovpn.zip && \
	unzip ovpn.zip -d /etc/openvpn && \
	unzip ovpn.zip -d "$(pip show openpyn | grep 'Location' | awk '{print $2}')"/openpyn/files && \
	rm ovpn.zip
	

RUN mkdir -p /var/log && \
	mkdir -p /home/vpn/log/transmission && \
	echo "Fake\nCreds" > /home/vpn/credentials && \
	ln -s /home/vpn/log/transmission /var/log/openpyn && \
	ln -s /home/vpn/credentials "$(pip show openpyn | grep 'Location' | awk '{print $2}')"/openpyn/credentials && \
	openpyn --daemon us --p2p

# +-----------------------------
# Uncomment if you want the credentials file to be stored on the docker image rather than mounted
# +-----------------------------
# ARG NORD_USER
# ARG NORD_PASSWORD
# RUN echo "$NORD_USER\n$NORD_PASSWORD" > "$(pip show openpyn | grep 'Location' | awk '{print $2}')"/openpyn/credentials

# +-----------------------------
# Uncomment if you want transmission to stay within the docker image
# +-----------------------------
# ARG TRANSMISSION_USER=transmission
# ARG TRANSMISSION_PASSWORD=transmission
# ARG TRANSMISSION_PORT=9091
# ARG TRANSMISSION_WHITELIST=127.0.0.1,0.0.0.0
# ARG TRANSMISSION_WHITELIST_ENABLED=false
# RUN mv /var/lib/transmission-daemon/info/settings.json /var/lib/transmission-daemon/info/settings.json.bak && \
#	jq -M ".\"rpc-username\"=\"$TRANSMISSION_USER\" | .\"rpc-password\"=\"$TRANSMISSION_PASSWORD\" | .\"rpc-port\"=$TRANSMISSION_PORT | .\"rpc-whitelist\"=\"$TRANSMISSION_WHITELIST\" | .\"rpc-whitelist-enabled\"=$TRANSMISSION_WHITELIST_ENABLED | .\"download-dir\"=\"$TRANSMISSION_DIR/downloads\" | .\"incomplete-dir\"=\"$TRANSMISSION_DIR/incomplete\" | .\"incomplete-dir-enabled\"=true" /var/lib/transmission-daemon/info/settings.json.bak > /var/lib/transmission-daemon/info/settings.json

# +-----------------------------
# Uncomment if you want transmission to use docker mount instead
# +-----------------------------
RUN echo 'ENABLE_DAEMON=1'"\n" \
		"CONFIG_DIR=\"$TRANSMISSION_DIR/info\"\n" \
		'OPTIONS="--config-dir $CONFIG_DIR"'"\n"  > /etc/default/transmission-daemon && \
	mkdir -p /home/transmission && \
	mv /var/lib/transmission-daemon/info /home/transmission/info && \
	mv /var/lib/transmission-daemon/.config /home/transmission/.config && \
	mv /etc/transmission-daemon/settings.json /home/transmission/info/settings.json && \
	ln -s /home/transmission/info /var/lib/transmission-daemon/info && \
	ln -s /home/transmission/info/settings.json /etc/transmission-daemon/settings.json && \
	mkdir -p /etc/systemd/system/transmission-daemon.service.d && \
	echo "[Service]\nExecStart=/usr/bin/transmission-daemon -f --log-error --config-dir \"$TRANSMISSION_DIR/info\"\n" > /etc/systemd/system/transmission-daemon.service.d/override.conf

RUN mkdir build && \
	echo '#!/bin/bash'"\n" \
		'openpyn --update'"\n" \
		'systemctl start openpyn'"\n" \
		'while ! $NS_EXEC ip link show dev tun0 >/dev/null 2>&1 ; do sleep .5 ; done'"\n" \
		'IP="$(hostname -I | awk '"'"'{print $2}'"'"')"'"\n" \
		'GATEWAY="$(ip -4 route ls | grep default | grep -Po '"'"'(?<=via )(\S+)'"'"')"'"\n" \
		'ip rule add from ${IP} table 128'"\n" \
		'ip route add table 128 to ${GATEWAY}/8 dev eth0'"\n" \
		'ip route add table 128 default via ${GATEWAY}'"\n" \
		"/usr/bin/transmission-daemon -f --log-error --config-dir \"$TRANSMISSION_DIR/info\"\n" \
		'sleep infinity'"\n" > /build/start.sh && \
	chmod 555 /build/start.sh

CMD ["/bin/bash", "/build/start.sh"]
