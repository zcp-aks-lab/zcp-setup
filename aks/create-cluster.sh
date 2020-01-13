#!/bin/bash

CLUSTER_NAME=cloudzcp-skn-ers-dev
# 노드에 생성되는 username. node ssh 접속시 필요. default 는 azureuser
ADMIN_USERNAME=cloudzcp-admin
RESOURCE_GROUP=ERS-DEV-RG
KUBERNETES_VERSION=1.15.7
# 워커 노드 사이즈는 그때그때 결정
WORKER_NODE_SIZE=Standard_F8s
# 워커 노드 수도 그때그때 결정
WORKER_NODE_COUNT=1
# 기본 생성되는 노드 풀
# 네이밍 룰은 역할_cpu_mem_k8sMinorVersion 어떨지??
# 클러스터 업그레이드할때 노드풀을 새로 생성할거라 구분이 필요할거 같아서..
NODEPOOL_NAME=w8x16
# id 방법 확인 필요 (cli 에서 --id 로밖에 조회가 안됨)
SERVICE_PRINCIPAL=
# CLI 로 신규 생성 가능한지 확인 필요
CLIENT_SECRET=
# Subnet id 추출
VNET_NAME=ERS-DEV-VNet
SUBNET_NAME=ERS-DEV-AKS-SubNet
VNET_SUBNET_ID=$(az network vnet subnet show -g $RESOURCE_GROUP --vnet-name $VNET_NAME --name $SUBNET_NAME --query id -o tsv)
POD_CIDR=172.40.0.0/16
SERVICE_CIDR=172.21.0.0/16
DNS_SERVICE=172.21.0.10

az aks create --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --admin-username $ADMIN_USERNAME \
    --kubernetes-version $KUBERNETES_VERSION \
    --network-plugin kubenet \
    --network-policy calico \
    --node-vm-size $WORKER_NODE_SIZE \
    --node-count $WORKER_NODE_COUNT \
    --nodepool-name $NODEPOOL_NAME \
    --service-principal $SERVICE_PRINCIPAL \
    --client-secret $CLIENT_SECRET \
    --vm-set-type VirtualMachineScaleSets \
    --vnet-subnet-id $VNET_SUBNET_ID \
    --pod-cidr $POD_CIDR \
    --service-cidr $SERVICE_CIDR \
    --dns-service-ip $DNS_SERVICE \
    --ssh-key-value ./id_rsa.pub
