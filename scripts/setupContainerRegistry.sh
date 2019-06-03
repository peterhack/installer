#!/bin/bash

source ./utils.sh

kubectl apply -f ../manifests/container-registry/configmap.yml
verify_kubectl $? "Creating config map for container registry failed."

kubectl apply -f ../manifests/container-registry/pvc.yml
verify_kubectl $? "Creating persistent volume claim for container registry failed."

kubectl apply -f ../manifests/container-registry/deployment.yml
verify_kubectl $? "Creating deployment for container registry failed."

kubectl apply -f ../manifests/container-registry/service.yml
verify_kubectl $? "Creating service for container registry failed."
