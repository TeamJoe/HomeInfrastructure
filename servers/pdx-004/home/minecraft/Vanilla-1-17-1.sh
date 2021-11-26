#!/bin/bash

path="$0"
external_address="lobythepirate.mooo.com"
minecraft_dir='/home/minecraft/data/Vanilla/1.17.1'
minecraft_jar='paper-1.17.1-349.jar'
start_script="java -Xms32G -Xmx32G -server -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true  -Dfml.readTimeout=90 -Dfml.queryResult=confirm -Dlog4j.configurationFile=log4j2.xml -jar "${minecraft_jar}" --nogui"

/home/minecraft/GenericPaperServer-1-17-1.sh "$path" "$external_address" "$minecraft_dir" "$minecraft_jar" "$start_script" "$@"
