#!/bin/bash
RG=
CLUSTER=
LOCATION= #koreacentral
CLUSTER_RG=MC_$RG_$CLUSTER_$LOCATION
STORAGE_ACCOUNT= #stersdev
az storage account create --name $STORAGE_ACCOUNT --resource-group $CLUSTER_RG --location $LOCATION --sku Standard_LRS --kind StorageV2
