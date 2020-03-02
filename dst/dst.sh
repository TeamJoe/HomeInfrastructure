#!/bin/bash

start() {
	cd /home/steam/steamapps/DST/bin
	bash -c "LD_LIBRARY_PATH=~/dst_lib ./dontstarve_dedicated_server_nullrenderer -console -cluster Cluster_1 -shard $1"
}

getServerProcess() {
	echo "$(getProcess 'dontstarve_dedicated_server_nullrenderer' "Cluster_1.*${1}")"
}

getProcess() {
	local type="$1"; shift
	local regex="$1"; shift

	local processesOfType="$(pidof "$type")"
	local processesOfRegex="$(ps aux | grep "$regex" | awk '{print $2}')"

	local C="$(echo ${processesOfType[@]} ${processesOfRegex[@]} | sed 's/ /\n/g' | sort | uniq -d)"
	echo "$(echo $C | sed -E "s/[[:space:]]\+/ /g")"
}

stopProcess() {
	local process="$1"
	if [ -n "$process" ]; then
		echo "Stopping $process"
		kill $process
	fi
}

killProcess() {
	local process="$1"
	if [ -n "$process" ]; then
		echo "Force stopping $process"
		kill -9 $process
	fi
}

isRunning() {
	local process="$(getServerProcess "$1")"
	if [ -n "$process" ]; then
		echo "true"
	else
		echo "false"
	fi
}

stop() {
	if [ "$(isRunning)" == "true" ]; then
		stopProcess "$(getServerProcess "$1")"
		sleep 10
	fi

	if [ "$(isRunning)" == "true" ]; then
		killProcess "$(getServerProcess "$1")"
		sleep 10
	fi

	if [ "$(isRunning)" == "true" ]; then
		echo "Cannot stop: Server is still running after multiple attempts to stop"
	fi
}

update() {
	/home/steam/steamcmd/steamcmd.sh +@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +login anonymous +force_install_dir /home/steam/steamapps/DST +app_update 343050 validate +quit
	/home/steam/steamapps/DST/bin/dontstarve_dedicated_server_nullrenderer -only_update_server_mods
}


if [ "$1" == 'stop' ]; then
	stop $2
elif [ "$1" == 'start' ]; then
	start $2
elif [ "$1" == 'update' ]; then
	update
fi
