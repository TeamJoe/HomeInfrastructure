#!/bin/sh
# /server/downstream/serverhub.sh
prefix='wrt.004'
path="${0}";
command="${1}"; shift
source /server/generic/GenericServer.sh

runCommand "${path}" "${name}" "${description}" "${serverInternalAddress}" "${serverExternalAddress}" "${command}"

