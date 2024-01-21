# /home/jackett/dockerfiles/jackett-pia.Dockerfile
# (cd /home/jackett/dockerfiles; docker build -f jackett-pia.Dockerfile -t jackett .)

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

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
        apt-get install -y \
                apt-utils \
                mono-devel

ARG JACKETT_RELEASES=https://api.github.com/repos/Jackett/Jackett/releases
ARG JACKETT_BINARIES=Jackett.Binaries.LinuxARM64.tar.gz
ARG JACKETT_DIR=/etc/jackett
RUN mkdir -p "${JACKETT_DIR}" && \
        curl --location $(curl -s "${JACKETT_RELEASES}" | jq -r '.[].assets[] | select( .name == "'"${JACKETT_BINARIES}"'" ).browser_download_url' | head -n 1) --output "${JACKETT_DIR}/Jackett.tar.gz" && \
        tar -xvzf "${JACKETT_DIR}/Jackett.tar.gz" -C "${JACKETT_DIR}" && \
        rm "${JACKETT_DIR}/Jackett.tar.gz" && \
        mv "${JACKETT_DIR}"/Jackett/* "${JACKETT_DIR}"/. && \
        rm -R "${JACKETT_DIR}"/Jackett

ENV LOG_LEVEL=info
RUN mkdir build && \
	useradd --system --shell /usr/sbin/nologin jackett && \
	useradd --system --shell /usr/sbin/nologin vpn

COPY ./files/build/start-pia.sh /build/start-pia.sh
RUN chmod 555 /build/start-pia.sh

CMD ["/bin/bash", "/build/start-pia.sh"]
