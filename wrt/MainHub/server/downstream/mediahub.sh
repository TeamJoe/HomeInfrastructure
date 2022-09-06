#!/bin/sh
# /server/downstream/mediahub.sh
prefix='wrt.002'
path="${0}";
command="${1}"; shift
source /server/generic/GenericServer.sh

runCommand "${path}" "${name}" "${description}" "${serverInternalAddress}" "${serverExternalAddress}" "${command}"

