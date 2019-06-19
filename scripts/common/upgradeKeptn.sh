#!/bin/bash

LOG_LOCATION=./logs
exec > >(tee -i $LOG_LOCATION/upgradeKeptn.log)
exec 2>&1

source ./utils.sh

echo "Starting upgrade to keptn 0.2.2"

GITHUB_USER_NAME=$1
GITHUB_PERSONAL_ACCESS_TOKEN=$2

if [ -z $1 ]
then
  echo "Please provide the github username as first parameter"
  echo ""
  echo "Usage: ./upgradeKeptn.sh GitHub_username GitHub_personal_access_token"
  exit 1
fi

if [ -z $2 ]
then
  echo "Please provide the GitHub personal access token as second parameter"
  echo ""
  echo "Usage: ./upgradeKeptn.sh GitHub_username GitHub_personal_access_token"
  exit 1
fi

if [[ $GITHUB_USER_NAME = '' ]]
then
  echo "GitHub username not set."
  exit 1
fi

if [[ $GITHUB_PERSONAL_ACCESS_TOKEN = '' ]]
then
  echo "GitHub personal access token not set."
  exit 1
fi

SERVICENAME=control
print_debug "Update $SERVICENAME service"
SERVICE_REVISION=$(kubectl get revisions --namespace=keptn | grep $SERVICENAME | cut -d' ' -f1)
kubectl get ksvc $SERVICENAME -n keptn -o=yaml > $SERVICENAME-deployment.yaml
verify_kubectl $? "$SERVICENAME could not be retrieved."
yq w -i $SERVICENAME-deployment.yaml spec.runLatest.configuration.revisionTemplate.spec.container.image keptn/$SERVICENAME:0.2.2.latest
kubectl apply -f $SERVICENAME-deployment.yaml
verify_kubectl $? "Updating of $SERVICENAME failed."
print_debug "Removing old revision of $SERVICENAME service"
kubectl delete revision $SERVICE_REVISION -n keptn
rm $SERVICENAME-deployment.yaml


SERVICENAME=authenticator
print_debug "Update $SERVICENAME service"
SERVICE_REVISION=$(kubectl get revisions --namespace=keptn | grep $SERVICENAME | cut -d' ' -f1)
kubectl get ksvc $SERVICENAME -n keptn -o=yaml > $SERVICENAME-deployment.yaml
verify_kubectl $? "$SERVICENAME could not be retrieved."
yq w -i $SERVICENAME-deployment.yaml spec.runLatest.configuration.revisionTemplate.spec.container.image keptn/$SERVICENAME:0.2.2.latest
kubectl apply -f $SERVICENAME-deployment.yaml
verify_kubectl $? "Updating of $SERVICENAME failed."
print_debug "Removing old revision of $SERVICENAME service"
kubectl delete revision $SERVICE_REVISION -n keptn
rm $SERVICENAME-deployment.yaml


SERVICENAME=event-broker
IMAGENAME=eventbroker
print_debug "Update $SERVICENAME service"
SERVICE_REVISION=$(kubectl get revisions --namespace=keptn | grep $SERVICENAME | cut -d' ' -f1)
kubectl get ksvc $SERVICENAME -n keptn -o=yaml > $SERVICENAME-deployment.yaml
verify_kubectl $? "$SERVICENAME could not be retrieved."
yq w -i $SERVICENAME-deployment.yaml spec.runLatest.configuration.revisionTemplate.spec.container.image keptn/$IMAGENAME:0.2.2.latest
kubectl apply -f $SERVICENAME-deployment.yaml
verify_kubectl $? "Updating of $SERVICENAME failed."
print_debug "Removing old revision of $SERVICENAME service"
kubectl delete revision $SERVICE_REVISION -n keptn
rm $SERVICENAME-deployment.yaml


SERVICENAME=event-broker-ext
IMAGENAME=eventbroker-ext
print_debug "Update $SERVICENAME service"
SERVICE_REVISION=$(kubectl get revisions --namespace=keptn | grep $SERVICENAME | cut -d' ' -f1)
kubectl get ksvc $SERVICENAME -n keptn -o=yaml > $SERVICENAME-deployment.yaml
verify_kubectl $? "$SERVICENAME could not be retrieved."
yq w -i $SERVICENAME-deployment.yaml spec.runLatest.configuration.revisionTemplate.spec.container.image keptn/$IMAGENAME:0.2.2.latest
kubectl apply -f $SERVICENAME-deployment.yaml
verify_kubectl $? "Updating of $SERVICENAME failed."
print_debug "Removing old revision of $SERVICENAME service"
kubectl delete revision $SERVICE_REVISION -n keptn
rm $SERVICENAME-deployment.yaml

SERVICENAME=github-service
print_debug "Update $SERVICENAME service"
SERVICE_REVISION=$(kubectl get revisions --namespace=keptn | grep $SERVICENAME | cut -d' ' -f1)
kubectl get ksvc $SERVICENAME -n keptn -o=yaml > $SERVICENAME-deployment.yaml
verify_kubectl $? "$SERVICENAME could not be retrieved."
yq w -i $SERVICENAME-deployment.yaml spec.runLatest.configuration.revisionTemplate.spec.container.image keptn/$SERVICENAME:0.2.0.latest
kubectl apply -f $SERVICENAME-deployment.yaml
verify_kubectl $? "Updating of $SERVICENAME failed."
print_debug "Removing old revision of $SERVICENAME service"
kubectl delete revision $SERVICE_REVISION -n keptn
rm $SERVICENAME-deployment.yaml

SERVICENAME=pitometer-service
print_debug "Update $SERVICENAME service"
SERVICE_REVISION=$(kubectl get revisions --namespace=keptn | grep $SERVICENAME | cut -d' ' -f1)
kubectl get ksvc $SERVICENAME -n keptn -o=yaml > $SERVICENAME-deployment.yaml
verify_kubectl $? "$SERVICENAME could not be retrieved."
yq w -i $SERVICENAME-deployment.yaml spec.runLatest.configuration.revisionTemplate.spec.container.image keptn/$SERVICENAME:0.1.2.latest
kubectl apply -f $SERVICENAME-deployment.yaml
print_debug "Removing old revision of $SERVICENAME service"
kubectl delete revision $SERVICE_REVISION -n keptn
rm $SERVICENAME-deployment.yaml

SERVICENAME=servicenow-service
print_debug "Update $SERVICENAME service"
SERVICE_REVISION=$(kubectl get revisions --namespace=keptn | grep $SERVICENAME | cut -d' ' -f1)
kubectl get ksvc $SERVICENAME -n keptn -o=yaml > $SERVICENAME-deployment.yaml
verify_kubectl $? "$SERVICENAME could not be retrieved."
yq w -i $SERVICENAME-deployment.yaml spec.runLatest.configuration.revisionTemplate.spec.container.image keptn/$SERVICENAME:0.1.1.latest
kubectl apply -f $SERVICENAME-deployment.yaml
print_debug "Removing old revision of $SERVICENAME service"
kubectl delete revision $SERVICE_REVISION -n keptn
rm $SERVICENAME-deployment.yaml

SERVICENAME=bridge
print_debug "Install $SERVICENAME"
BRIDGE_RELEASE="release-0.1.0"
kubectl delete -f https://raw.githubusercontent.com/keptn/bridge/$BRIDGE_RELEASE/config/bridge.yaml --ignore-not-found
kubectl apply -f https://raw.githubusercontent.com/keptn/bridge/$BRIDGE_RELEASE/config/bridge.yaml
verify_kubectl $? "Deploying keptn's bridge failed."

# Remove subscriptions of Jenkins service
kubectl delete subscription jenkins-configuration-changed-subscription -n keptn
kubectl delete subscription jenkins-deployment-finished-subscription -n keptn
kubectl delete subscription jenkins-evaluation-done-subscription -n keptn


echo "Upgrade to keptn 0.2.2 done."
