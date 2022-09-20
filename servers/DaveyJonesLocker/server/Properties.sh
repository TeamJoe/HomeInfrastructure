#!/bin/bash
# /server/properties.sh

propertyFile=/server/properties

getProperty() {
	property="${1}"; shift
	echo "$(cat "${propertyFile}" | grep "${property}" | awk '{print $2}')"
}

getProperty "${1}"