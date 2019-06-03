#!/bin/bash
source ./utils.sh

# Create namespace and container registry
# Needed for pull request Travis Build - will be removed
kubectl create namespace keptn #2> /dev/null

./setupContainerRegistry.sh
verify_install_step $? "Creating container registry failed."

# Install knative serving, eventing
kubectl apply --selector knative.dev/crd-install=true -f https://github.com/knative/serving/releases/download/v0.6.0/serving.yaml
verify_kubectl $? "Applying knative serving components failed."
wait_for_crds "certificates,clusteringresses,configurations,images,podautoscalers,revisions,routes,services,serverlessservices"
kubectl apply -f https://github.com/knative/serving/releases/download/v0.6.0/serving.yaml
verify_kubectl $? "Applying knative serving components failed."
wait_for_all_pods_in_namespace "knative-serving"

kubectl apply --selector knative.dev/crd-install=true -f https://github.com/knative/eventing/releases/download/v0.6.0/release.yaml
verify_kubectl $? "Applying knative eventing components failed."
kubectl apply --selector knative.dev/crd-install=true -f https://github.com/knative/eventing/releases/download/v0.6.0/eventing.yaml
verify_kubectl $? "Applying knative eventing components failed."
sleep 5
wait_for_crds "apiserversources,brokers,channels,clusterchannelprovisioners,containersources,cronjobsources,subscriptions,triggers"
kubectl apply -f https://github.com/knative/eventing/releases/download/v0.6.0/release.yaml
verify_kubectl $? "Applying knative eventing components failed."
kubectl apply -f https://github.com/knative/eventing/releases/download/v0.6.0/eventing.yaml
verify_kubectl $? "Applying knative eventing components failed."
kubectl apply -f https://github.com/knative/eventing/releases/download/v0.6.0/in-memory-channel.yaml
verify_kubectl $? "Applying knative eventing in-memory-channel failed."

# Install NATS
kubectl apply -f ../manifests/nats/natss-namespace.yaml
verify_kubectl $? "Applying natss namespace failed."
kubectl apply -f ../manifests/nats/natss.yaml
verify_kubectl $? "Applying natss config failed."
wait_for_all_pods_in_namespace "natss"
kubectl apply -f https://github.com/knative/eventing/releases/download/v0.6.0/natss.yaml
verify_kubectl $? "Applying knative eventing natss failed."
wait_for_all_pods_in_namespace "knative-eventing"

kubectl apply -f https://github.com/knative/serving/releases/download/v0.6.0/monitoring-logs-elasticsearch.yaml
verify_kubectl $? "Applying knative monitoring components failed."
sleep 5
wait_for_all_pods_in_namespace "knative-monitoring"

##############################################
## Start validation of Knative installation ##
##############################################
