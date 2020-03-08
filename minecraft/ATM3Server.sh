#!/bin/bash

path="$0"
minecraft_dir='/home/joe/minecraft/ATM3'
minecraft_jar='forge-1.12.2-14.23.5.2844-universal.jar'
input_file="${minecraft_dir}/logs/input.txt"
output_file="${minecraft_dir}/logs/output.log"
simple_output_file="${minecraft_dir}/logs/simple.log"

start_script="java -Xms32G -Xmx32G -d64 -server -XX:+AggressiveOpts -XX:ParallelGCThreads=3 -XX:+UseConcMarkSweepGC -XX:+UnlockExperimentalVMOptions -XX:+UseParNewGC -XX:+ExplicitGCInvokesConcurrent -XX:MaxGCPauseMillis=10 -XX:GCPauseIntervalMillis=50 -XX:+UseFastAccessorMethods -XX:+OptimizeStringConcat -XX:NewSize=84m -XX:+UseAdaptiveGCBoundary -XX:NewRatio=3 -Dfml.readTimeout=90 -Dfml.queryResult=confirm -jar \"${minecraft_jar}\" nogui"
minimum_server_boot_time=3600
minimum_disconnect_live_time=1200
list_player_command="list players"
online_count_pattern='There[[:blank:]]are[[:blank:]]([0-9]+)\/([0-9]+)[[:blank:]]players[[:blank:]]online'
player_list_pattern='(\[[^]]*\][[:blank:]]*)+:([[:blank:]])*(([a-zA-Z0-9_-]+[[:blank:]]*)*)'
player_list_pattern_next_line='true'

/home/joe/GenericServer.sh "$0" "$minecraft_dir" "$minecraft_jar" "$input_file" "$output_file" "$simple_output_file" "$start_script" "$minimum_server_boot_time" "$minimum_disconnect_live_time" "$list_player_command" "$online_count_pattern" "$player_list_pattern" "$player_list_pattern_next_line" "$@"
