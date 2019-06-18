#!/bin/bash
CLUSTER_NAME=$1
AZURE_RESOURCEGROUP=$2

az aks get-credentials --resource-group $AZURE_RESOURCEGROUP --name $CLUSTER_NAME --overwrite-existing

if [[ $? != '0' ]]
then
  exit 1
fi
