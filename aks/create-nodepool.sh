#!/bin/bash

RESOURCE_GROUP=ERS-DEV-RG
CLUSTER_NAME=cloudzcp-skn-ers-dev

MANAGE=management
MANAGE_SIZE=Standard_F8
 
LOGGING=logging
LOGGING_SIZE=Standard_D4_v3
 
# EDGE=
# EDGE_SIZE=

WORKER=w8x16v115
WORKER_SIZE=Standard_F8s


# Management Node
# if [[ -v MANAGE ]]
  az aks nodepool add --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --name $MANAGE --node-count 2 --node-vm-size $MANAGE_SIZE
 
# Worker Node
# if [[ -v WORKER ]]
  az aks nodepool add --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --name $WORKER --node-count 2 --node-vm-size $WORKER_SIZE
 
# Logging Node
# if [[ -v LOGGING ]]
  az aks nodepool add --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --name $LOGGING --node-count 1 --node-vm-size $LOGGING_SIZE
 
# Edge Node
# if [[ -v EDGE ]]
#   az aks nodepool add --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --name $EDGE --node-count 2 --node-vm-size $EDGE_SIZE