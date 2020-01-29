#!/bin/bash

# SCRIPT=$(readlink -f "$0")
# SCRIPTPATH=$(dirname $SCRIPT)
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
. $SCRIPTPATH/env.properties

COMMAND="az ad sp create-for-rbac --name ${SERVICE_PRINCIPAL_NAME}"

echo Executing command : $COMMAND
SP_RESULT=`$COMMAND`

echo $SP_RESULT | jq

# creating sp.properties
SP_ID=`echo $SP_RESULT | jq -r '.appId'`
CLIENT_SECRET=`echo $SP_RESULT | jq -r '.password'`

echo "SERVICE_PRINCIPAL_ID=$SP_ID" > $SCRIPTPATH/sp.properties
echo "CLIENT_SECRET=$CLIENT_SECRET" >> $SCRIPTPATH/sp.properties
