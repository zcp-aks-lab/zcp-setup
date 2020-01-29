#!/bin/bash

# SCRIPT=$(readlink -f "$0")
# SCRIPTPATH=$(dirname $SCRIPT)
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
. $SCRIPTPATH/env.properties

COMMAND="az group create --location ${LOCATION} --name ${RESOURCE_GROUP}"
echo Executing $COMMAND
eval $COMMAND
