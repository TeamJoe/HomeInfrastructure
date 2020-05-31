#!/bin/bash

path="$0"
external_address="lobythepirate.mooo.com"
#minecraft_dir='/home/minecraft/data/ATM3/1.5.1'
#minecraft_jar='forge-1.12.2-14.23.5.2844-universal.jar'
minecraft_dir='/home/minecraft/data/ATM3/1.5.4'
#minecraft_jar='forge-1.12.2-14.23.5.2847-universal.jar'
#start_script="java -Xms32G -Xmx32G -d64 -server -XX:+AggressiveOpts -XX:ParallelGCThreads=3 -XX:+UseConcMarkSweepGC -XX:+UnlockExperimentalVMOptions -XX:+UseParNewGC -XX:+ExplicitGCInvokesConcurrent -XX:MaxGCPauseMillis=10 -XX:GCPauseIntervalMillis=50 -XX:+UseFastAccessorMethods -XX:+OptimizeStringConcat -XX:NewSize=84m -XX:+UseAdaptiveGCBoundary -XX:NewRatio=3 -Dfml.readTimeout=90 -Dfml.queryResult=confirm -jar \"${minecraft_jar}\" nogui"
#minecraft_jar='Magma-3d116a0-server.jar'
minecraft_jar='Mohist-1.12.2-1010498-server.jar'
#start_script="java -Xms32G -Xmx32G -d64 -server -Dlog4j.configurationFile=log4j2.xml -jar \"${minecraft_jar}\" nogui"
start_script="java -Xms32G -Xmx32G -d64 -server -d64 -server -XX:+AggressiveOpts -XX:ParallelGCThreads=3 -XX:+UseConcMarkSweepGC -XX:+UnlockExperimentalVMOptions -XX:+UseParNewGC -XX:+ExplicitGCInvokesConcurrent -XX:MaxGCPauseMillis=10 -XX:GCPauseIntervalMillis=50 -XX:+UseFastAccessorMethods -XX:+OptimizeStringConcat -XX:NewSize=84m -XX:+UseAdaptiveGCBoundary -XX:NewRatio=3 -Dfml.readTimeout=90 -Dfml.queryResult=confirm -Dlog4j.configurationFile=log4j2.xml -jar \"${minecraft_jar}\" nogui"

/home/minecraft/GenericMohistServer-1-12.2.sh "$path" "$external_address" "$minecraft_dir" "$minecraft_jar" "$start_script" "$@"
