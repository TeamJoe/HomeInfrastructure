#!/bin/bash
# /server/process.sh
source /server/regex.sh

getProcess() {
	local type="$1"; shift
	local regex="$1"; shift

	local processesOfType="$(pidof "$type")"
	local processesOfRegex="$(ps aux | regexFind ".*${regex}.*" | awk '{print $2}')"

	local C="$(echo ${processesOfType[@]} ${processesOfRegex[@]} | regexReplace ' ' '\n' | sort | uniq -d)"
	echo "$(echo $C | regexReplace '\s+' ' ')"
}

stopProcess() {
	local process="$1"
	if [ -n "$process" ]; then
		kill $process
	fi
}

killProcess() {
	local process="$1"
	if [ -n "$process" ]; then
		kill -9 $process
	fi
}