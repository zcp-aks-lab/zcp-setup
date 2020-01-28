#!/bin/bash
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
. $SCRIPTPATH/env.properties

function execute() {
  COMMAND=$1
  echo Executing command : $COMMAND
  eval $COMMAND
}

execute "az storage account create --resource-group $CLUSTER_RESOURCE_GROUP \
    --name $STORAGE_ACCOUNT_NAME \
    --location $LOCATION \
    --sku Standard_LRS \
    --kind StorageV2"
