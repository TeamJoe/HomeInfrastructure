#!/bin/sh
# /server/downstream/heavenhub.sh
prefix='wrt.003'
path="${0}";
command="${1}"; shift
source /server/generic/GenericServer.sh

runCommand "${path}" "${name}" "${description}" "${serverInternalAddress}" "${serverExternalAddress}" "${command}"