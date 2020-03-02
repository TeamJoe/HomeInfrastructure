#!/bin/bash

start() {
        cd /home/steam/steamapps/DST/bin
        nohup bash -c 'LD_LIBRARY_PATH=~/dst_lib ./dontstarve_dedicated_server_nullrenderer -console -cluster Cluster_1 -shard Master' &
        nohup bash -c 'LD_LIBRARY_PATH=~/dst_lib ./dontstarve_dedicated_server_nullrenderer -console -cluster Cluster_1 -shard Caves' &
}

getProcess() {
        local type="$1"; shift
        local regex="$1"; shift

        local processesOfType="$(pidof "$type")"
        local processesOfRegex="$(ps aux | grep "$regex" | awk '{print $2}')"

        local C="$(echo ${processesOfType[@]} ${processesOfRegex[@]} | sed 's/ /\n/g' | sort | uniq -d)"
        echo "$(echo $C | sed -E "s/[[:space:]]\+/ /g")"
}

stop() {
        local pids="$(getProcess 'dontstarve_dedicated_server_nullrenderer' 'Cluster_1')"
        echo "kill $pids"
        kill -1 $pids
}

update() {
        /home/steam/steamcmd/steamcmd.sh +@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +login anonymous +force_install_dir /home/steam/steamapps/DST +app_update 343050 validate +quit
        /home/steam/steamapps/DST/bin/dontstarve_dedicated_server_nullrenderer -only_update_server_mods
}


if [ "$1" == 'stop' ]; then
        stop
elif [ "$1" == 'start' ]; then
        start
elif [ "$1" == 'update' ]; then
        update
fi
