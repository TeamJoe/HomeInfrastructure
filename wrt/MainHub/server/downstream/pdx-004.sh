#!/bin/sh
# /server/downstream/pdx-004.sh
prefix='pdx.004'
path="${0}";
command="${1}"; shift
source /server/generic/iLO4Server.sh

runCommand "${path}" "${name}" "${description}" "${iloApiAddress}" "${iloAddress}" "${serverInternalAddress}" "${serverExternalAddress}" "${user}" "${password}" "${command}"
