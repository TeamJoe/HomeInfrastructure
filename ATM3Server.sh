#!/bin/bash

path="$0"
minecraft_dir='/home/joe/minecraft/ATM3'
minecraft_jar='forge-1.12.2-14.23.5.2844-universal.jar'
input_file="${minecraft_dir}/logs/input.txt"
output_file="${minecraft_dir}/logs/output.log"
simple_output_file="${minecraft_dir}/logs/simple.log"

#start_script='sh ServerStart.sh'
start_script="java -Xms64G -Xmx64G -d64 -server -XX:+AggressiveOpts -XX:ParallelGCThreads=3 -XX:+UseConcMarkSweepGC -XX:+UnlockExperimentalVMOptions -XX:+UseParNewGC -XX:+ExplicitGCInvokesConcurrent -XX:MaxGCPauseMillis=10 -XX:GCPauseIntervalMillis=50 -XX:+UseFastAccessorMethods -XX:+OptimizeStringConcat -XX:NewSize=84m -XX:+UseAdaptiveGCBoundary -XX:NewRatio=3 -Dfml.readTimeout=90 -Dfml.queryResult=confirm -jar \"${minecraft_jar}\" nogui"
minimum_server_boot_time=3600
minimum_disconnect_live_time=1200

/home/joe/GenericServer.sh "$0" "$minecraft_dir" "$minecraft_jar" "$input_file" "$output_file" "$simple_output_file" "$start_script" "$minimum_server_boot_time" "$minimum_disconnect_live_time" "$@"
