#!/bin/bash

path="$0"
external_address="lobythepirate.mooo.com"
#minecraft_dir='/home/minecraft/data/Vanilla/1.16.3'
#minecraft_jar='paper-229.jar'
minecraft_dir='/home/minecraft/data/Vanilla/1.16.4'
minecraft_jar='paper-1.16.4-319.jar'
start_script="java -Xms32G -Xmx32G -d64 -server -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=40 -XX:G1MaxNewSizePercent=50 -XX:G1HeapRegionSize=16M -XX:G1ReservePercent=15 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=20 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true  -Dfml.readTimeout=90 -Dfml.queryResult=confirm -Dlog4j.configurationFile=log4j2.xml -jar \"${minecraft_jar}\" nogui"

/home/minecraft/GenericPaperServer-1-16.sh "$path" "$external_address" "$minecraft_dir" "$minecraft_jar" "$start_script" "$@"
