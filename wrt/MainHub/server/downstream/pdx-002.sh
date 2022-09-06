#!/bin/sh
# /server/downstream/pdx-002.sh
prefix='pdx.002'
path="${0}";
command="${1}"; shift
source /server/generic/iLO3Server.sh

runCommand "${path}" "${name}" "${description}" "${iloApiAddress}" "${iloAddress}" "${serverInternalAddress}" "${serverExternalAddress}" "${user}" "${password}" "${command}"
