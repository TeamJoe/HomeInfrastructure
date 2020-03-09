#!/bin/bash

path="$0"
name="Master"
data_directory="/home/steam/.klei/DoNotStarveTogether/Cluster_1/Master"
input_file="/home/steam/logs/input-master.txt"
output_file="/home/steam/logs/output-master.log"
simple_output_file="/home/steam/logs/simple-master.log"
start_script="bash -c \"LD_LIBRARY_PATH=~/dst_lib ./dontstarve_dedicated_server_nullrenderer -console -cluster Cluster_1 -shard $name\""

/home/steam/GenericDSTServer.sh "$path" "$name" "$data_directory" "$input_file" "$output_file" "$simple_output_file" "$start_script" "$@"