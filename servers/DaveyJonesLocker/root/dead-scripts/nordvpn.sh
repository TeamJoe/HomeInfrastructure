#!/bin/bash
# Script to start NordVPN
# $1 should be the VPN server to connect to. Default: vn1
# $2 should be the protocol "tcp" or "udp". Default: tcp

username="<REDACTED>"
password="<REDACTED>"
openvpn_dir="/etc/openvpn"
server=${1:-"vn1"}
proto=${2:-"tcp"}
port=

if [ "$proto" == "tcp" ]; then
	port="443";
elif [ $proto == "udp" ]; then
	port="1194";
fi

echo "" > "${openvpn_dir}/nordvpn-auth.txt"
chmod 200 "${openvpn_dir}/nordvpn-auth.txt"
printf "${username}\n${password}" > "${openvpn_dir}/nordvpn-auth.txt"

openvpn --config "${openvpn_dir}/ovpn_${proto}/${server}.nordvpn.com.${proto}.ovpn" --auth-user-pass "${openvpn_dir}/nordvpn-auth.txt"