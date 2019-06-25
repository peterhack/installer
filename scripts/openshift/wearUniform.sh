#!/bin/bash
source ./common/utils.sh

# Deploy uniform
kubectl apply -f ../manifests/keptn/uniform-services-openshift.yaml --wait
verify_kubectl $? "Deploying keptn's uniform-services failed."
sleep 20
kubectl apply -f ../manifests/keptn/uniform-subscriptions-openshift.yaml --wait
verify_kubectl $? "Deploying keptn's uniform-subscriptions failed."

##############################################
## Start validation of keptn's uniform      ##
##############################################
wait_for_all_pods_in_namespace "keptn"

wait_for_deployment_in_namespace "openshift-route-service" "keptn"
