#!/bin/sh
# /server/downstream/daveyjoneslocker.sh
prefix='pi.001'
path="${0}";
command="${1}"; shift
source /server/generic/GenericServer.sh

runCommand "${path}" "${name}" "${description}" "${serverInternalAddress}" "${serverExternalAddress}" "${command}"
