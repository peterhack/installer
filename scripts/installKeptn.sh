#!/bin/bash

LOG_LOCATION=./logs
exec > >(tee -i $LOG_LOCATION/installKeptn.log)
exec 2>&1

source ./common/utils.sh

case $PLATFORM in
  aks)
    kubectl apply --filename https://github.com/knative/serving/releases/download/v0.4.0/istio-crds.yaml
    verify_kubectl $? "Error applying Istio Credentials"
    kubectl apply --filename https://github.com/knative/serving/releases/download/v0.4.0/istio.yaml
    verify_kubectl $? "Error applying Istio"
    kubectl label namespace default istio-injection=enabled --overwrite=true
    verify_kubectl $? "Error setting istio-injection flag "
    wait_for_all_pods_in_namespace "istio-system"
    ;;
  eks)
    echo "$PLATFORM NOT SUPPORTED"
    exit 1
    ;;
  ocp)
    ./openshift/installOnOpenshift.sh
    ;;
  gke)
    ./installOnGKE.sh
  *)
    ./installOnGKE.sh     
    ;;
esac
