#!/bin/bash

#SCRIPT=$(readlink -f "$0")
#SCRIPTPATH=$(dirname $SCRIPT)
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
. $SCRIPTPATH/env.properties
. $SCRIPTPATH/sp.properties

# Management Node
if [ ! -z ${MANAGEMENT_NODEPOOL_NAME} ]; then
  az aks nodepool add --resource-group ${RESOURCE_GROUP} --cluster-name ${CLUSTER_NAME} --name ${MANAGEMENT_NODEPOOL_NAME} --node-count ${MANAGEMENT_NODE_COUNT} --node-vm-size ${MANAGEMENT_NODE_SIZE}
fi
 
# Worker Node
if [ ! -z ${WORKER_NODEPOOL_NAME} ]; then
  az aks nodepool add --resource-group ${RESOURCE_GROUP} --cluster-name ${CLUSTER_NAME} --name ${WORKER_NODEPOOL_NAME} --node-count $((WORKER_NODE_COUNT-1)) --node-vm-size ${WORKER_NODE_SIZE}
fi
 
# Logging Node
if [ ! -z ${LOGGING_NODEPOOL_NAME} ]; then
  az aks nodepool add --resource-group ${RESOURCE_GROUP} --cluster-name ${CLUSTER_NAME} --name ${LOGGING_NODEPOOL_NAME} --node-count ${LOGGING_NODE_COUNT} --node-vm-size ${LOGGING_NODE_SIZE}
fi
 
# Edge Node
if [ ! -z ${EDGE_NODEPOOL_NAME} ]; then
  az aks nodepool add --resource-group ${RESOURCE_GROUP} --cluster-name ${CLUSTER_NAME} --name ${EDGE_NODEPOOL_NAME} --node-count ${EDGE_NODE_COUNT} --node-vm-size ${EDGE_NODE_SIZE}
fi
