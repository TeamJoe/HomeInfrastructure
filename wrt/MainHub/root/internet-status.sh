#!/bin/bash
# /root/internet-status.sh
source /server/discord.sh

CHECK_PING="${1:-8.8.8.8}"
ALWAYS_LOG="${2:-false}"
STATUS_FILE="${3:-/root/internet-status.csv}"

getResult() {
  echo "$(ping -q -w 5 -W 5 $CHECK_PING)"
}

getDate() {
  echo "$(date '+%F %T')"
}

getStatus() {
  local loss="$(getPacketLoss "$1")"
  if [[ -z "${loss}" ]]; then
    echo 'down'
  elif [[ 100 -eq "${loss}" ]]; then
    echo 'down'
  else
    echo 'up'
  fi
}

getLastStatus() {
  tail -n 1 "$STATUS_FILE" | awk -F "\"*,\"*" '{print $2}'
}

getHost() {
  echo "$1" | grep -oE 'PING [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} ' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
}

getHostIP() {
  echo "$1" | grep -oE '\([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
}

getPacketsTransmitted() {
  echo "$1" | grep -oE '[0-9]* packets transmitted' | grep -o '\d*'
}

getPacketsRecieved() {
  echo "$1" | grep -oE '[0-9]* packets received' | grep -o '\d*'
}

getPacketLoss() {
  echo "$1" | grep -oE '[0-9]{1,3}%' | grep -o '\d*'
}

getLatencyMinimum() {
  echo "$1" | grep -oE ' [0-9]\.[0-9]{1,4}\/' | grep -oE '[0-9]\.[0-9]{1,4}'
}

getLatencyAverage() {
  echo "$1" | grep -oE '\/[0-9]\.[0-9]{1,4}\/' | grep -oE '[0-9]\.[0-9]{1,4}'
}

getLatencyMaximum() {
  echo "$1" | grep -oE '\/[0-9]\.[0-9]{1,4} ' | grep -oE '[0-9]\.[0-9]{1,4}'
}

logHeader() {
  if [ ! -f "$STATUS_FILE" ]; then
  	echo '"date","status","host","host ip","packets transmitted","packets received","packet loss","packet loss","latency minimum","latency average","latency maximum"' > "$STATUS_FILE"
  fi
}

logResult() {
	echo "\"$(getDate "$1")\",\"$(getStatus "$1")\",\"$(getHost "$1")\",\"$(getHostIP "$1")\",\"$(getPacketsTransmitted "$1")\",\"$(getPacketsRecieved "$1")\",\"$(getPacketLoss "$1")%\",\"$(getLatencyMinimum "$1")\",\"$(getLatencyAverage "$1")\",\"$(getLatencyMaximum "$1")\"" >> "$STATUS_FILE"
}

logHeader
result="$(getResult)"
if [[ "$(getStatus "${result}")" != "$(getLastStatus)" ]]; then
  logResult "${result}"
  sendMessage "Main Hub: ${result}"
elif [[ "${ALWAYS_LOG}" == 'true' ]]; then
  logResult "${result}"
elif [[ "$(getStatus "${result}")" == 'up' && "$(getPacketLoss "${result}")" != '0' ]]; then
  logResult "${result}"
fi
