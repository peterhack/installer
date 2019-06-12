#!/bin/bash
source ./common/utils.sh

# Environment variables for jenkins-service
if [[ -z "${JENKINS_USER}" ]]; then
  print_debug "JENKINS_USER not set, take it from creds.json"
  JENKINS_USER=$(cat creds.json | jq -r '.jenkinsUser')
  verify_variable "$JENKINS_USER" "JENKINS_USER is not defined in environment variable nor in creds.json file." 
fi

if [[ -z "${JENKINS_PASSWORD}" ]]; then
  print_debug "JENKINS_PASSWORD not set, take it from creds.json"
  JENKINS_PASSWORD=$(cat creds.json | jq -r '.jenkinsPassword')
  verify_variable "$JENKINS_PASSWORD" "JENKINS_PASSWORD is not defined in environment variable nor in creds.json file." 
fi

if [[ -z "${GITHUB_USER_NAME}" ]]; then
  print_debug "GITHUB_USER_NAME not set, take it from creds.json"
  GITHUB_USER_NAME=$(cat creds.json | jq -r '.githubUserName')
  verify_variable "$GITHUB_USER_NAME" "GITHUB_USER_NAME is not defined in environment variable nor in creds.json file." 
fi

if [[ -z "${GITHUB_PERSONAL_ACCESS_TOKEN}" ]]; then
  print_debug "GITHUB_PERSONAL_ACCESS_TOKEN not set, take it from creds.json"
  GITHUB_PERSONAL_ACCESS_TOKEN=$(cat creds.json | jq -r '.githubPersonalAccessToken')
  verify_variable "$GITHUB_PERSONAL_ACCESS_TOKEN" "GITHUB_PERSONAL_ACCESS_TOKEN is not defined in environment variable nor in creds.json file." 
fi

if [[ -z "${GITHUB_USER_EMAIL}" ]]; then
  print_debug "GITHUB_USER_EMAIL not set, take it from creds.json"
  GITHUB_USER_EMAIL=$(cat creds.json | jq -r '.githubUserEmail')
  verify_variable "$GITHUB_USER_EMAIL" "GITHUB_USER_EMAIL is not defined in environment variable nor in creds.json file." 
fi

if [[ -z "${GITHUB_ORGANIZATION}" ]]; then
  print_debug "GITHUB_ORGANIZATION not set, take it from creds.json"
  GITHUB_ORGANIZATION=$(cat creds.json | jq -r '.githubOrg')
  verify_variable "$GITHUB_ORGANIZATION" "GITHUB_USER_EMAIL is not defined in environment variable nor in creds.json file." 
fi

# Deploy uniform
kubectl apply -f ../manifests/keptn/uniform-services.yaml
verify_kubectl $? "Deploying keptn's uniform-services failed."
sleep 20
kubectl apply -f ../manifests/keptn/uniform-subscriptions.yaml
verify_kubectl $? "Deploying keptn's uniform-subscriptions failed."


# Clean-up working directory
rm -rf keptn-services
mkdir keptn-services
cd keptn-services

# Install jenkins-service
#git clone --branch develop https://github.com/keptn/jenkins-service.git --single-branch
#cd jenkins-service
#chmod +x deploy.sh
#./deploy.sh "" $JENKINS_USER $JENKINS_PASSWORD $GITHUB_USER_NAME $GITHUB_USER_EMAIL $GITHUB_ORGANIZATION $GITHUB_PERSONAL_ACCESS_TOKEN
#verify_install_step $? "Deploying jenkins-service failed."

#cd ../..

##############################################
## Start validation of keptn's uniform      ##
##############################################
wait_for_all_pods_in_namespace "keptn"

wait_for_deployment_in_namespace "jenkins-service" "keptn"
wait_for_deployment_in_namespace "github-service" "keptn"
wait_for_deployment_in_namespace "servicenow-service" "keptn"
wait_for_deployment_in_namespace "pitometer-service" "keptn"
