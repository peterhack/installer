#!/bin/bash

LOG_LOCATION=./logs
exec > >(tee -i $LOG_LOCATION/installKeptn.log)
exec 2>&1

source ./openshift/installationFunctions.sh
source ./common/utils.sh

install_olm
install_catalogsources
install_istio

wait_for_all_pods_in_namespace "istio-system"
install_knative serving
install_knative eventing
oc adm policy add-cluster-role-to-user cluster-admin -z knative-eventing-operator -n knative-eventing
oc adm policy add-scc-to-user privileged -z elasticsearch-logging -n knative-monitoring

kubectl apply -f https://github.com/knative/serving/releases/download/v0.4.0/monitoring.yaml
#verify_kubectl $? "Applying knative monitoring components failed."
sleep 5
#wait_for_all_pods_in_namespace "knative-monitoring"


wait_for_deployment_in_namespace "controller" "knative-serving"
wait_for_all_pods_in_namespace "knative-serving"
wait_for_deployment_in_namespace "eventing-controller" "knative-eventing"
wait_for_deployment_in_namespace "in-memory-channel-controller" "knative-eventing"
wait_for_deployment_in_namespace "in-memory-channel-dispatcher" "knative-eventing"

# Install keptn core services - Install keptn channels
print_info "Installing keptn"
./openshift/setupKeptn.sh
verify_install_step $? "Installing keptn failed."
print_info "Installing keptn done"

# Install keptn services
print_info "Wear uniform"
./common/wearUniform.sh
verify_install_step $? "Installing keptn's uniform failed."
print_info "Keptn wears uniform"

# Install done
print_info "Installation of keptn complete."

# Retrieve keptn endpoint and api-token
KEPTN_ENDPOINT=http://$(oc get route -n keptn control -oyaml | yq r - spec.host)
KEPTN_API_TOKEN=$(kubectl get secret keptn-api-token -n keptn -o=yaml | yq - r data.keptn-api-token | base64 --decode)

print_info "keptn endpoint: $KEPTN_ENDPOINT"
print_info "keptn api-token: $KEPTN_API_TOKEN"



