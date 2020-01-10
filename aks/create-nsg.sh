#!/bin/bash
set -e

# variables
RESOURCE_GROUP=ERS-DEV-RG
VNET=ERS-DEV-VNet
SUBNET=ERS-DEV-AKS-SubNet
NSG=nsg-skn-ers-dev


# Create NSG
az network nsg create --name $NSG --resource-group $RESOURCE_GROUP
az network vnet subnet update --resource-group $RESOURCE_GROUP -n $SUBNET --vnet-name $VNET --network-security-group $NSG


# Inbound
az network nsg rule create -g $RESOURCE_GROUP --nsg-name $NSG -n AllowVnetInBound \
--priority 400 --source-address-prefixes VirtualNetwork --destination-address-prefixes VirtualNetwork \
--destination-port-ranges "*" --direction Inbound --access Allow --protocol "*"
 
az network nsg rule create -g $RESOURCE_GROUP --nsg-name $NSG -n AllowAzureLoadBalancerInBound \
--priority 401 --source-address-prefixes AzureLoadBalancer --destination-address-prefixes "*" \
--destination-port-ranges "*" --direction Inbound --access Allow --protocol "*"
 
az network nsg rule create -g $RESOURCE_GROUP --nsg-name $NSG -n DenyAllInBound \
--priority 500 --source-address-prefixes "*" --destination-address-prefixes "*" \
--destination-port-ranges "*" --direction Inbound --access Deny --protocol "*"

# Outbound
az network nsg rule create -g $RESOURCE_GROUP --nsg-name $NSG -n DenyAllInternet \
    --priority 500 --source-address-prefixes VirtualNetwork --destination-address-prefixes Internet \
    --destination-port-ranges "*" --direction Outbound --access Deny --protocol "*"

az network nsg rule create -g $RESOURCE_GROUP --nsg-name $NSG -n AzureCloudOutBound \
    --priority 301 --source-address-prefixes VirtualNetwork --destination-address-prefixes AzureCloud \
    --destination-port-ranges "443,22,9000" --direction Outbound --access Allow --protocol "*"
     
az network nsg rule create -g $RESOURCE_GROUP --nsg-name $NSG -n AzureContainerRegistryOutBound \
    --priority 302 --source-address-prefixes VirtualNetwork --destination-address-prefixes AzureContainerRegistry \
    --destination-port-ranges 443 --direction Outbound --access Allow --protocol "*"
 
az network nsg rule create -g $RESOURCE_GROUP --nsg-name $NSG -n MicrosoftContainerRegistryOutBound \
    --priority 303 --source-address-prefixes VirtualNetwork --destination-address-prefixes MicrosoftContainerRegistry \
    --destination-port-ranges 443 --direction Outbound --access Allow --protocol "*"
 
az network nsg rule create -g $RESOURCE_GROUP --nsg-name $NSG -n ApiManagementOutBound \
    --priority 304 --source-address-prefixes VirtualNetwork --destination-address-prefixes ApiManagement \
    --destination-port-ranges 443 --direction Outbound --access Allow --protocol "*"
 
az network nsg rule create -g $RESOURCE_GROUP --nsg-name $NSG -n AzureActiveDirectoryOutBound \
    --priority 305 --source-address-prefixes VirtualNetwork --destination-address-prefixes AzureActiveDirectory \
    --destination-port-ranges 443 --direction Outbound --access Allow --protocol "*"
