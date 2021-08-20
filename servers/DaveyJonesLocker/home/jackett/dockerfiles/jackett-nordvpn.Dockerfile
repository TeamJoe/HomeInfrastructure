# /home/jackett/dockerfiles/jackett-nordvpn.Dockerfile
# (cd /home/jackett/dockerfiles; docker build -f jackett-nordvpn.Dockerfile -t jackett .)

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
    useradd --system --shell /usr/sbin/nologin vpn && \
	echo '#!/bin/bash'"\n" \
		'GATEWAY="$(ip -4 route ls | grep default | grep -Po '"'"'(?<=via )(\S+)'"'"')"'"\n" \
        'IP="$(hostname -I | awk '"'"'{print $1}'"'"')"'"\n" \
        'if [ -n "${VUID}" ]; then usermod -u "${VUID}" vpn; fi '"\n" \
        'if [ -n "${VGID}" ]; then groupmod -g "${VGID}" vpn; fi '"\n" \
        'openpyn --update'"\n" \
        'systemctl start openpyn'"\n" \
        'while ! ip link show dev $(ip link | grep -o tun[0-9]*) >/dev/null 2>&1 ; do sleep .5 ; done'"\n" \
        'TUNNEL="$(ip link | grep -o tun[0-9]*)"'"\n" \
        'ip rule add from ${IP} table 128'"\n" \
        'ip route add table 128 to ${GATEWAY}/8 dev eth0'"\n" \
        'ip route add table 128 default via ${GATEWAY}'"\n" \
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
        "while [[ -n \"\$(ip link show dev \${TUNNEL} 2> /dev/null)\" && -n \"\$(ps -u abc | awk 'NR!=1{print \$1}')\" ]]; do sleep .5 ; done\n" \
        "kill -9 \$(ps -u abc | awk 'NR!=1{print \$1}') \$(ps ax | grep jackett | awk '{print \$1}')\n" > /build/start.sh && \
	chmod 555 /build/start.sh

ENTRYPOINT ["/bin/bash", "/build/start.sh"]
