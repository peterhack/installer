#!/bin/bash
source ./common/utils.sh

# Deploy uniform
kubectl apply -f ../manifests/keptn/uniform-services.yaml --wait
verify_kubectl $? "Deploying keptn's uniform-services failed."
sleep 20
kubectl apply -f ../manifests/keptn/uniform-subscriptions.yaml --wait
verify_kubectl $? "Deploying keptn's uniform-subscriptions failed."

##############################################
## Start validation of keptn's uniform      ##
##############################################
wait_for_all_pods_in_namespace "keptn"

wait_for_deployment_in_namespace "gatekeeper-service" "keptn"
wait_for_deployment_in_namespace "jmeter-service" "keptn"
wait_for_deployment_in_namespace "helm-service" "keptn"
wait_for_deployment_in_namespace "github-service" "keptn"
wait_for_deployment_in_namespace "servicenow-service" "keptn"
wait_for_deployment_in_namespace "pitometer-service" "keptn"