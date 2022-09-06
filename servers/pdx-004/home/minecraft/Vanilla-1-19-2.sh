#!/bin/bash

path="$0"
external_address="lobythepirate.mooo.com"
minecraft_dir='/home/minecraft/data/Vanilla/1.19.2'
minecraft_jar='paper-1.19.2-138.jar'
start_script="/usr/lib/jvm/java-17-openjdk-amd64/bin/java -Xms32G -Xmx32G -server -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true  -Dfml.readTimeout=90 -Dfml.queryResult=confirm -Dlog4j.configurationFile=log4j2.xml -jar "${minecraft_jar}" --nogui"

/home/minecraft/GenericPaperServer-1-19-2.sh "$path" "$external_address" "$minecraft_dir" "$minecraft_jar" "$start_script" "$@"

