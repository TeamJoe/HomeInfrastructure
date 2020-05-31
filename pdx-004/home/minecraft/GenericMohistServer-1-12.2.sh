#!/bin/bash

path="$1"; shift
external_address="$1"; shift
minecraft_dir="$1"; shift
minecraft_jar="$1"; shift

start_script="$1"; shift
list_player_command="list players"
online_count_pattern='There[[:blank:]]are[[:blank:]]§r([0-9]+)§r\/§r([0-9]+)§r[[:blank:]]players[[:blank:]]online:§r'
player_join_pattern='UUID[[:blank:]]of[[:blank:]]player[[:blank:]]([a-zA-Z0-9_-]*)[[:blank:]]is[[:blank:]]([a-zA-Z0-9_-]*)'
player_leave_pattern='§e([a-zA-Z0-9_-]*)[[:blank:]]left[[:blank:]]the[[:blank:]]game§r'
player_list_pattern='(\[[^]]*\][[:blank:]]*)+:([[:blank:]])*(([a-zA-Z0-9_-]+[[:blank:]]*)*)§r'
player_list_pattern_next_line='true'


/home/minecraft/GenericMinecraftServer.sh "$path" "$external_address" "$minecraft_dir" "$minecraft_jar" "$start_script" "$list_player_command" "$online_count_pattern" "$player_join_pattern" "$player_leave_pattern" "$player_list_pattern" "$player_list_pattern_next_line" "$@"
