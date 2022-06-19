#!/bin/sh
# /root/checkspeed.sh
# 0 0 * * 0 sleep "$(awk 'BEGIN{srand();print int(rand()*7*24*60)}')m" ; /root/checkspeed.sh

SPEED_FILE='/root/speed-results.csv'

if [ ! -f "$SPEED_FILE" ]; then
	echo '"date","server name","server id","latency","jitter","packet loss","download","upload","download bytes","upload bytes","share url"' > "$SPEED_FILE"
fi

RESULT="$(speedtest -f csv)"
if [ -n "$RESULT" ]; then
	echo "\"$(date '+%F %T')\",$(speedtest -f csv)" >> "$SPEED_FILE"
fi
