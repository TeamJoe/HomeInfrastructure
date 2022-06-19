#!/bin/sh
# /root/checkspeed.sh

if [ -z "$1" ]; then
  SPEED_FILE='/root/speed-results.csv'
else
  SPEED_FILE="$1"
fi

if [ ! -f "$SPEED_FILE" ]; then
	echo '"date","server name","server id","latency","jitter","packet loss","download","upload","download bytes","upload bytes","share url"' > "$SPEED_FILE"
fi

RESULT="$(speedtest -f csv)"
if [ -n "$RESULT" ]; then
	echo "\"$(date '+%F %T')\",$(speedtest -f csv)" >> "$SPEED_FILE"
fi
