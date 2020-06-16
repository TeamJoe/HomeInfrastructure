#!/bin/bash

path="$1"; shift
external_address="$1"; shift
minecraft_dir="$1"; shift
minecraft_jar="$1"; shift

log_std_out='true'
start_script="$1"; shift
list_player_command='list'
online_count_pattern='There[[:blank:]]are[[:blank:]]([0-9]+)[[:blank:]]of[[:blank:]]a[[:blank:]]max[[:blank:]]([0-9]+)[[:blank:]]players[[:blank:]]online'
player_join_pattern='([a-zA-Z0-9_-]*)[[:blank:]]joined[[:blank:]]the[[:blank:]]game'
player_leave_pattern='([a-zA-Z0-9_-]*)[[:blank:]]left[[:blank:]]the[[:blank:]]game'
player_list_pattern='There[[:blank:]]are[[:blank:]]([0-9]+)[[:blank:]]of[[:blank:]]a[[:blank:]]max[[:blank:]]([0-9]+)[[:blank:]]players[[:blank:]]online:[[:blank:]]*(([a-zA-Z0-9_-]+[[:blank:]]*)*)'
player_list_pattern_next_line='false'

/home/minecraft/GenericMinecraftServer.sh "$path" "$external_address" "$minecraft_dir" "$minecraft_jar" "$log_std_out" "$start_script" "$list_player_command" "$online_count_pattern" "$player_join_pattern" "$player_leave_pattern" "$player_list_pattern" "$player_list_pattern_next_line" "$@"
