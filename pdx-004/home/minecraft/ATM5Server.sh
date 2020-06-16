#!/bin/bash

path="$0"
external_address="<REDACTED>"
minecraft_dir='/home/minecraft/data/ATM5/1.10'
minecraft_jar='forge-ATM5-1.10.jar'
start_script="java -Xms32G -Xmx32G -d64 -server -XX:+AggressiveOpts -XX:ParallelGCThreads=3 -XX:+UseConcMarkSweepGC -XX:+UnlockExperimentalVMOptions -XX:+UseParNewGC -XX:+ExplicitGCInvokesConcurrent -XX:MaxGCPauseMillis=10 -XX:GCPauseIntervalMillis=50 -XX:+UseFastAccessorMethods -XX:+OptimizeStringConcat -XX:NewSize=84m -XX:+UseAdaptiveGCBoundary -XX:NewRatio=3 -Dfml.readTimeout=90 -Dfml.queryResult=confirm -jar \"${minecraft_jar}\" nogui"

/home/minecraft/GenericMinecraftServer-1-15-2.sh "$path" "$external_address" "$minecraft_dir" "$minecraft_jar" "$start_script" "$@"