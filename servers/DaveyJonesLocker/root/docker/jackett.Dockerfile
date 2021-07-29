# docker build -f jackett.Dockerfile -t jackett .

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
		iputils-ping \
		python3-setuptools \
		python3-pip && \
	python3 -m pip install --upgrade openpyn

RUN cd /etc/openvpn && \
	curl -L https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip -o ovpn.zip && \
	unzip ovpn.zip -d /etc/openvpn && \
	unzip ovpn.zip -d "$(python3 -m pip show openpyn | grep 'Location' | awk '{print $2}')"/openpyn/files && \
	rm ovpn.zip
	

# Only required if you want to store credentials right in the docker instance
# Not Required if you mount the dockerfile instead
ARG NORD_USER=Nord
ARG NORD_PASSWORD=Password
RUN mkdir -p /var/log && \
	mkdir -p /home/vpn/log/jackett && \
	echo "${NORD_USER}\n${NORD_PASSWORD}" > /home/vpn/credentials && \
	ln -s /home/vpn/log/jackett /var/log/openpyn && \
	ln -s /home/vpn/credentials "$(python3 -m pip show openpyn | grep 'Location' | awk '{print $2}')"/openpyn/credentials && \
	openpyn --daemon us --p2p

RUN mkdir build && \
	echo '#!/bin/bash'"\n" \
		'openpyn --update'"\n" \
		'service openpyn start'"\n" \
		'while ! $NS_EXEC ip link show dev tun0 >/dev/null 2>&1 ; do sleep .5 ; done'"\n" \
		'IP="$(hostname -I | awk '"'"'{print $2}'"'"')"'"\n" \
		'GATEWAY="$(ip -4 route ls | grep default | grep -Po '"'"'(?<=via )(\S+)'"'"')"'"\n" \
		'ip rule add from ${IP} table 128'"\n" \
		'ip route add table 128 to ${GATEWAY}/8 dev eth0'"\n" \
		'ip route add table 128 default via ${GATEWAY}'"\n" \
		'/init'"\n" > /build/start.sh && \
	chmod 555 /build/start.sh

CMD ["/bin/bash", "/build/start.sh"]
