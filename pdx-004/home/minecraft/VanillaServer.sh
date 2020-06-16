#!/bin/bash

path="$0"
external_address="<REDACTED>"
minecraft_dir='/home/minecraft/data/Vanilla/1.15.2'
minecraft_jar='minecraft_server.1.15.2.jar'
start_script="java -server -Xms16G -Xmx16G -d64 -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:MaxGCPauseMillis=100 -XX:+DisableExplicitGC -XX:TargetSurvivorRatio=90 -XX:G1NewSizePercent=35 -XX:G1MaxNewSizePercent=60 -XX:G1MixedGCLiveThresholdPercent=50 -XX:+AlwaysPreTouch -jar '$minecraft_jar' nogui"

/home/minecraft/GenericMinecraftServer-1-15-2.sh "$path" "$external_address" "$minecraft_dir" "$minecraft_jar" "$start_script" "$@"