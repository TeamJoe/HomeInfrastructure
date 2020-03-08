#!/bin/bash

path="$0"
minecraft_dir='/home/joe/minecraft/Vanilla/1.15.2'
minecraft_jar='minecraft_server.1.15.2.jar'
input_file="${minecraft_dir}/logs/input.txt"
output_file="${minecraft_dir}/logs/output.log"
simple_output_file="${minecraft_dir}/logs/simple.log"

start_script="java -server -Xms16G -Xmx16G -d64 -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=100 -XX:+DisableExplicitGC -XX:TargetSurvivorRatio=90 -XX:G1NewSizePercent=35 -XX:G1MaxNewSizePercent=60 -XX:G1MixedGCLiveThresholdPercent=50 -XX:+AlwaysPreTouch -jar '$minecraft_jar' nogui"
minimum_server_boot_time=3600
minimum_disconnect_live_time=1200
list_player_command="list"
online_count_pattern='There[[:blank:]]are[[:blank:]]([0-9]+)[[:blank:]]of[[:blank:]]a[[:blank:]]max[[:blank:]]([0-9]+)[[:blank:]]players[[:blank:]]online'
player_list_pattern='There[[:blank:]]are[[:blank:]]([0-9]+)[[:blank:]]of[[:blank:]]a[[:blank:]]max[[:blank:]]([0-9]+)[[:blank:]]players[[:blank:]]online:[[:blank:]]*(([a-zA-Z0-9_-]+[[:blank:]]*)*)'
player_list_pattern_next_line='false'

/home/joe/GenericServer.sh "$0" "$minecraft_dir" "$minecraft_jar" "$input_file" "$output_file" "$simple_output_file" "$start_script" "$minimum_server_boot_time" "$minimum_disconnect_live_time" "$list_player_command" "$online_count_pattern" "$player_list_pattern" "$player_list_pattern_next_line" "$@"
