#!/bin/bash

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname $SCRIPT)
. $SCRIPTPATH/env.properties

COMMAND="az network vnet create \
    --name ${VIRTUAL_NETWORK_NAME} \
    --resource-group ${RESOURCE_GROUP} \
    --address-prefixes ${VNET_ADDRESS} \
    --subnet-name ${SUBNET_NAME} \
    --subnet-prefixes ${SUBNET_ADDRESS}"
echo Executing $COMMAND
eval $COMMAND
