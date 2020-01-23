#!/bin/bash

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname $SCRIPT)
. $SCRIPTPATH/env.properties

function execute() {
  COMMAND=$1
  echo Executing command : $COMMAND
  eval $COMMAND
}

# Create NSG
execute "az network nsg create --name $NETWORK_SECURITY_GROUP_NAME --resource-group $RESOURCE_GROUP"
execute "az network vnet subnet update --resource-group $RESOURCE_GROUP -n $SUBNET_NAME --vnet-name $VIRTUAL_NETWORK_NAME --network-security-group $NETWORK_SECURITY_GROUP_NAME"


# Inbound
# Useless.. public loadbalancer inbound rules are defined in AKS Native nsg.
#execute "az network nsg rule create -g $RESOURCE_GROUP --nsg-name $NETWORK_SECURITY_GROUP_NAME -n AllowVnetInBound \
#    --priority 400 --source-address-prefixes VirtualNetwork --destination-address-prefixes VirtualNetwork \
#    --destination-port-ranges '*' --direction Inbound --access Allow --protocol '*'"
 
#execute "az network nsg rule create -g $RESOURCE_GROUP --nsg-name $NETWORK_SECURITY_GROUP_NAME -n AllowAzureLoadBalancerInBound \
#    --priority 401 --source-address-prefixes AzureLoadBalancer --destination-address-prefixes '*' \
#    --destination-port-ranges '*' --direction Inbound --access Allow --protocol '*'"
 
#execute "az network nsg rule create -g $RESOURCE_GROUP --nsg-name $NETWORK_SECURITY_GROUP_NAME -n DenyAllInBound \
#    --priority 500 --source-address-prefixes '*' --destination-address-prefixes '*' \
#    --destination-port-ranges '*' --direction Inbound --access Deny --protocol '*'"

# Outbound
execute "az network nsg rule create -g $RESOURCE_GROUP --nsg-name $NETWORK_SECURITY_GROUP_NAME -n DenyAllInternet \
    --priority 500 --source-address-prefixes VirtualNetwork --destination-address-prefixes Internet \
    --destination-port-ranges '*' --direction Outbound --access Deny --protocol '*'"

execute "az network nsg rule create -g $RESOURCE_GROUP --nsg-name $NETWORK_SECURITY_GROUP_NAME -n AzureCloudOutBound \
    --priority 301 --source-address-prefixes VirtualNetwork --destination-address-prefixes AzureCloud \
    --destination-port-ranges 443 22 9000 --direction Outbound --access Allow --protocol '*'"
     
execute "az network nsg rule create -g $RESOURCE_GROUP --nsg-name $NETWORK_SECURITY_GROUP_NAME -n AzureContainerRegistryOutBound \
    --priority 302 --source-address-prefixes VirtualNetwork --destination-address-prefixes AzureContainerRegistry \
    --destination-port-ranges 443 --direction Outbound --access Allow --protocol '*'"
 
execute "az network nsg rule create -g $RESOURCE_GROUP --nsg-name $NETWORK_SECURITY_GROUP_NAME -n MicrosoftContainerRegistryOutBound \
    --priority 303 --source-address-prefixes VirtualNetwork --destination-address-prefixes MicrosoftContainerRegistry \
    --destination-port-ranges 443 --direction Outbound --access Allow --protocol '*'"
 
execute "az network nsg rule create -g $RESOURCE_GROUP --nsg-name $NETWORK_SECURITY_GROUP_NAME -n ApiManagementOutBound \
    --priority 304 --source-address-prefixes VirtualNetwork --destination-address-prefixes ApiManagement \
    --destination-port-ranges 443 --direction Outbound --access Allow --protocol '*'"
 
execute "az network nsg rule create -g $RESOURCE_GROUP --nsg-name $NETWORK_SECURITY_GROUP_NAME -n AzureActiveDirectoryOutBound \
    --priority 305 --source-address-prefixes VirtualNetwork --destination-address-prefixes AzureActiveDirectory \
    --destination-port-ranges 443 --direction Outbound --access Allow --protocol '*'"

execute "az network nsg rule create -g $RESOURCE_GROUP --nsg-name $NETWORK_SECURITY_GROUP_NAME -n AzureStorageOutBound \
    --priority 306 --source-address-prefixes VirtualNetwork --destination-address-prefixes Storage \
    --destination-port-ranges '*' --direction Outbound --access Allow --protocol '*'"

execute "az network nsg rule create -g $RESOURCE_GROUP --nsg-name $NETWORK_SECURITY_GROUP_NAME -n IbmRegistryOutBound \
    --priority 307 --source-address-prefixes VirtualNetwork --destination-address-prefixes \
    169.60.72.144/28 169.61.76.176/28 169.62.37.240/29 169.60.98.80/29 169.63.104.232/29 \
    168.1.45.160/27 168.1.139.32/27 168.1.1.240/29 130.198.88.128/29 135.90.66.48/29 \
    --destination-port-ranges '*' --direction Outbound --access Allow --protocol '*'"

execute "az network nsg rule create -g $RESOURCE_GROUP --nsg-name $NETWORK_SECURITY_GROUP_NAME -n IbmObjectStorageOutBound \
    --priority 308 --source-address-prefixes VirtualNetwork --destination-address-prefixes 169.56.118.97 \
    --destination-port-ranges '*' --direction Outbound --access Allow --protocol '*'"

# Show rule list
execute "az network nsg rule list -o table -g $RESOURCE_GROUP --nsg-name $NETWORK_SECURITY_GROUP_NAME"
