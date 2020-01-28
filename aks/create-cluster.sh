#!/bin/bash

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname $SCRIPT)
. $SCRIPTPATH/env.properties
. $SCRIPTPATH/sp.properties
function execute() {
  COMMAND=$1
  echo Executing command : $COMMAND
  eval $COMMAND
}

# Subnet id 추출
VNET_SUBNET_ID=$(az network vnet subnet show -g $RESOURCE_GROUP --vnet-name $VIRTUAL_NETWORK_NAME --name $SUBNET_NAME --query id -o tsv)

execute "az aks create --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --admin-username $ADMIN_USERNAME \
    --kubernetes-version $KUBERNETES_VERSION \
    --network-plugin kubenet \
    --network-policy calico \
    --node-vm-size $WORKER_NODE_SIZE \
    --node-count 1 \
    --nodepool-name $DEFAULT_NODEPOOL_NAME \
    --service-principal $SERVICE_PRINCIPAL_ID \
    --client-secret $CLIENT_SECRET \
    --vm-set-type VirtualMachineScaleSets \
    --vnet-subnet-id $VNET_SUBNET_ID \
    --pod-cidr $POD_CIDR \
    --service-cidr $SERVICE_CIDR \
    --dns-service-ip $DNS_SERVICE_IP \
    --ssh-key-value $SCRIPTPATH/../../zcp-aks-cert/ssh/id_rsa.pub"
