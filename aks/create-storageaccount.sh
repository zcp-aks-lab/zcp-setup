#!/bin/bash
RG=ERS-DEV-RG
CLUSTER=cloudzcp-skn-ers-dev
LOCATION=koreacentral
CLUSTER_RG=MC_${RG}_${CLUSTER}_${LOCATION}
STORAGE_ACCOUNT=stersdev
az storage account create --name $STORAGE_ACCOUNT --resource-group $CLUSTER_RG --location $LOCATION --sku Standard_LRS --kind StorageV2
