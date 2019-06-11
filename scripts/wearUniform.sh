#!/bin/bash
source ./utils.sh

# Deploy uniform
kubectl apply -f ../manifests/keptn/uniform.yaml
verify_kubectl $? "Deploying keptn's uniform failed."

##############################################
## Start validation of keptn's uniform      ##
##############################################
wait_for_all_pods_in_namespace "keptn"

wait_for_deployment_in_namespace "github-service" "keptn"
wait_for_deployment_in_namespace "servicenow-service" "keptn"
wait_for_deployment_in_namespace "pitometer-service" "keptn"
