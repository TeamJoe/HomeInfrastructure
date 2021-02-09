#!/bin/bash

path="$0"
init_directory="/home/factorio/init"
game_directory="/home/factorio/game"
external_address="<REDACTED>"

/home/factorio/GenericFactorioServer.sh "$path" "$init_directory" "$game_directory" "$external_address" "$@"
