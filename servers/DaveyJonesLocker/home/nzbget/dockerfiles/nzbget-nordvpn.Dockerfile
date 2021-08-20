# /home/nzbget/dockerfiles/nzbget-nordvpn.Dockerfile
# (cd /home/nzbget/dockerfiles; docker build -f nzbget-nordvpn.Dockerfile -t nzbget .)

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
    useradd --system --shell /usr/sbin/nologin vpn && \
	echo '#!/bin/bash'"\n" \
		'GATEWAY="$(ip -4 route ls | grep default | grep -Po '"'"'(?<=via )(\S+)'"'"')"'"\n" \
        'IP="$(hostname -I | awk '"'"'{print $1}'"'"')"'"\n" \
        'if [ -n "${PUID}" ]; then usermod -u "${PUID}" nzbget; fi '"\n" \
        'if [ -n "${PGID}" ]; then groupmod -g "${PGID}" nzbget; fi '"\n" \
        'if [ -n "${VUID}" ]; then usermod -u "${VUID}" vpn; fi '"\n" \
        'if [ -n "${VGID}" ]; then groupmod -g "${VGID}" vpn; fi '"\n" \
        'openpyn --update'"\n" \
        'systemctl start openpyn'"\n" \
        'while ! ip link show dev $(ip link | grep -o tun[0-9]*) >/dev/null 2>&1 ; do sleep .5 ; done'"\n" \
        'TUNNEL="$(ip link | grep -o tun[0-9]*)"'"\n" \
        'ip rule add from ${IP} table 128'"\n" \
        'ip route add table 128 to ${GATEWAY}/8 dev eth0'"\n" \
        'ip route add table 128 default via ${GATEWAY}'"\n" \
		'cd /lib/nzbget'"\n" \
		"sudo su nzbget -s /lib/nzbget/nzbget -- --daemon --configfile '${NZBGET_DIR}/nzbget.conf &'\n" \
        'for i in {1..1000}; do'"\n" \
            "if [[ -n \"\$(ip link show dev \${TUNNEL} 2> /dev/null)\" && -n \"\$(ps -u nzbget | awk 'NR!=1{print \$1}')\" ]]; then break; fi\n" \
            'sleep 1'"\n" \
        'done'"\n" \
        "trap '{ echo \"Quit Signal Received\" ; kill -9 \$(ps -u nzbget | awk 'NR!=1{print \$1}') ; }' SIGQUIT\n" \
        "trap '{ echo \"Abort Signal Received\" ; kill -9 \$(ps -u nzbget | awk 'NR!=1{print \$1}') ; }' SIGABRT\n" \
        "trap '{ echo \"Interrupt Signal Received\" ; kill -9 \$(ps -u nzbget | awk 'NR!=1{print \$1}') ; }' SIGINT\n" \
        "trap '{ echo \"Terminate Signal Received\" ; kill -9 \$(ps -u nzbget | awk 'NR!=1{print \$1}') ; }' SIGTERM\n" \
        "while [[ -n \"\$(ip link show dev \${TUNNEL} 2> /dev/null)\" && -n \"\$(ps -u nzbget | awk 'NR!=1{print \$1}')\" ]]; do sleep .5 ; done\n" \
        "kill -9 \$(ps -u nzbget | awk 'NR!=1{print \$1}') \$(ps ax | grep nzbget| awk '{print \$1}')\n" > /build/start.sh && \
	chmod 555 /build/start.sh

CMD ["/bin/bash", "/build/start.sh"]
