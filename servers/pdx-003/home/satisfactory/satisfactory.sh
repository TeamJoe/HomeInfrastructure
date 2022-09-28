#!/bin/bash
# /home/satisfactory/satisfactory.sh
path="${0}"
command="${1}"
prefix='satisfactory.1'
source /home/satisfactory/GenericSatisfactoryServer.sh
runCommand "${path}" "${@}"