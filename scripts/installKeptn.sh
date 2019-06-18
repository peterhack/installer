#!/bin/bash

LOG_LOCATION=./logs
exec > >(tee -i $LOG_LOCATION/installKeptn.log)
exec 2>&1

case $PLATFORM in
  aks)
    echo "Install on AKS"
    ./aks/installOnAKS.sh
    ;;
  eks)
    echo "$PLATFORM NOT SUPPORTED"
    exit 1
    ;;
  openshift)
    echo "$PLATFORM NOT SUPPORTED"
    exit 1
    ;;
  gke)    
    ./gke/installOnGKE.sh
    ;;
  pks) # Pivotal Container Service (PKS) on GCP has the same install process like GKE (for now)
    ./gke/installOnGKE.sh
    ;;
  *)
    ./gke/installOnGKE.sh     
    ;;
esac
