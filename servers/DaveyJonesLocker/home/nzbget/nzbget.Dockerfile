# docker build -f nzbget.Dockerfile -t nzbget --build-arg NZBGET_DIR=/home/nzbget .

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
	mkdir -p /home/vpn/log/nbzget && \
	echo "${NORD_USER}\n${NORD_PASSWORD}" > /home/vpn/credentials && \
	ln -s /home/vpn/log/nbzget /var/log/openpyn && \
	ln -s /home/vpn/credentials "$(python3 -m pip show openpyn | grep 'Location' | awk '{print $2}')"/openpyn/credentials && \
	openpyn --daemon us --p2p

ARG NZBGET_DIR=/home/nzbget
RUN mkdir -p /lib/nzbget && \
	mkdir -p "${NZBGET_DIR}" && \
	curl -L https://nzbget.net/download/nzbget-latest-bin-linux.run -o /lib/nzbget/nzbget-latest-bin-linux.run && \
	sh /lib/nzbget/nzbget-latest-bin-linux.run --destdir /lib/nzbget --arch armhf && \
	rm -f /lib/nzbget/nzbget-latest-bin-linux.run && \
	mv /lib/nzbget/nzbget.conf "${NZBGET_DIR}/nzbget.conf" && \
	ln "${NZBGET_DIR}/nzbget.conf" /lib/nzbget/nzbget.conf 

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
		'cd /lib/nzbget'"\n" \
		"./nzbget --daemon --configfile '${NZBGET_DIR}/nzbget.conf'\n" \
		'sleep infinity'"\n" > /build/start.sh && \
	chmod 555 /build/start.sh

CMD ["/bin/bash", "/build/start.sh"]
