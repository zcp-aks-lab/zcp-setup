#!/bin/bash
if [ -f "$1" ]; then
  ENV_FILE="$1"
else
  SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
  # . $SCRIPTPATH/env.properties
  ENV_FILE=$SCRIPTPATH/env.properties
fi
echo "Load $ENV_FILE" >&2 && . $ENV_FILE

function execute() {
  COMMAND=$1
  echo Executing command : $COMMAND
#  eval $COMMAND
}

#export AZURE_STORAGE_ACCOUNT=$STORAGE_ACCOUNT_NAME
export AZURE_STORAGE_KEY=$STORAGE_ACCOUNT_KEY

execute "az storage container create --resource-group $CLUSTER_RESOURCE_GROUP \
    --name $BLOB_CONTAINER_NAME \
    --account-name $STORAGE_ACCOUNT_NAME \
    "
#    --account-key $STORAGE_ACCOUNT_KEY"
