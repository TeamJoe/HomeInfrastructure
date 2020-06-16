#!/bin/bash

path="$1"; shift
external_address="$1"; shift
minecraft_dir="$1"; shift
minecraft_jar="$1"; shift

log_std_out='false'
start_script="$1"; shift
list_player_command='list players'
online_count_pattern='There[[:blank:]]are[[:blank:]]([0-9]+)\/([0-9]+)[[:blank:]]players[[:blank:]]online:'
player_join_pattern='Sending[[:blank:]]Player[[:blank:]]Data[[:blank:]]to[[:blank:]]player[[:blank:]]([a-zA-Z0-9_-]*)[[:blank:]]with[[:blank:]]UUID[[:blank:]]([a-zA-Z0-9_-]*)\.'
player_leave_pattern='([a-zA-Z0-9_-]*)[[:blank:]]left[[:blank:]]the[[:blank:]]game'
player_list_pattern='(\[[^]]*\][[:blank:]]*)+:([[:blank:]])*(([a-zA-Z0-9_-]+[[:blank:]]*)*)'
player_list_pattern_next_line='true'


/home/minecraft/GenericMinecraftServer.sh "$path" "$external_address" "$minecraft_dir" "$minecraft_jar" "$log_std_out" "$start_script" "$list_player_command" "$online_count_pattern" "$player_join_pattern" "$player_leave_pattern" "$player_list_pattern" "$player_list_pattern_next_line" "$@"
