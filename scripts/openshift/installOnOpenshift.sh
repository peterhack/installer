+#!/bin/bash

source ./openshift/installationFunctions.sh
source ./common/utils.sh

if [[ -z "${CLUSTER_IPV4_CIDR}" ]]; then
  print_debug "CLUSTER_IPV4_CIDR is not set, take it from creds.json"
  CLUSTER_ZONE=$(cat creds.json | jq -r '.clusterIpv4Cidr')
  verify_variable "$CLUSTER_IPV4_CIDR" "CLUSTER_IPV4_CIDR is not defined in environment variable nor in creds.json file." 
fi

if [[ -z "${SERVICES_IPV4_CIDR}" ]]; then
  print_debug "SERVICES_IPV4_CIDR is not set, take it from creds.json"
  CLUSTER_ZONE=$(cat creds.json | jq -r '.servicesIpv4Cidr')
  verify_variable "$SERVICES_IPV4_CIDR" "SERVICES_IPV4_CIDR is not defined in environment variable nor in creds.json file." 
fi

print_info "Installing Operator"
install_olm
print_info "Installing Operator done"
install_catalogsources
print_info "Installing Istio"
install_istio
print_info "Installing Istio done"

wait_for_all_pods_in_namespace "istio-system"
print_info "Installing knative"
install_knative serving
install_knative eventing
oc adm policy add-cluster-role-to-user cluster-admin -z knative-eventing-operator -n knative-eventing
print_info "Installing knative done"

# configure the host path volume plugin (needed for fluentd)
#kubectl create -f ../manifests/openshift/oc-scc-hostpath.yaml
#verify_kubectl $? "Deploying hostpath SCC failed."
#oc patch scc hostpath -p '{"allowHostDirVolumePlugin": true}'
#verify_install_step "Patching hostpath plugin failed."
#oc adm policy add-scc-to-group hostpath system:authenticated
#verify_install_step "Creating hostpath SCC failed."

# Install monitoring
#oc adm policy add-scc-to-user privileged -z elasticsearch-logging -n knative-monitoring
#oc adm policy add-scc-to-user anyuid system:serviceaccount:knative-monitoring:fluentd-ds
#oc adm policy add-scc-to-user privileged system:serviceaccount:knative-monitoring:fluentd-ds
#kubectl label nodes --all beta.kubernetes.io/fluentd-ds-ready="true"
#verify_kubectl $? "Labelling nodes failed."
#kubectl apply -f ../manifests/knative/monitoring.yaml
#verify_kubectl $? "Applying knative monitoring components failed."
#wait_for_all_pods_in_namespace "knative-monitoring"


wait_for_deployment_in_namespace "controller" "knative-serving"
wait_for_all_pods_in_namespace "knative-serving"
wait_for_deployment_in_namespace "eventing-controller" "knative-eventing"
wait_for_deployment_in_namespace "in-memory-channel-controller" "knative-eventing"
wait_for_deployment_in_namespace "in-memory-channel-dispatcher" "knative-eventing"

# Install tiller for helm
print_info "Installing Tiller"
kubectl apply -f ../manifests/tiller/tiller.yaml
helm init --service-account tiller
print_info "Installing Tiller done"
oc adm policy add-cluster-role-to-user system:serviceaccount:kube-system:tiller

# Install keptn core services - Install keptn channels
print_info "Installing keptn"
./openshift/setupKeptn.sh $CLUSTER_IPV4_CIDR $SERVICES_IPV4_CIDR
verify_install_step $? "Installing keptn failed."
print_info "Installing keptn done"

# Install keptn services
print_info "Wear uniform"
./common/wearUniform.sh
verify_install_step $? "Installing keptn's uniform failed."
print_info "Keptn wears uniform"

# Install additional keptn services for openshift
print_info "Wear Openshift uniform"
./openshift/wearUniform.sh
verify_install_step $? "Installing keptn's Openshift uniform failed."
print_info "Keptn wears Openshift uniform"

# Install done
print_info "Installation of keptn complete."

# Retrieve keptn endpoint and api-token
KEPTN_ENDPOINT=https://$(kubectl get ksvc -n keptn control -o=yaml | yq r - status.domain)
KEPTN_API_TOKEN=$(kubectl get secret keptn-api-token -n keptn -o=yaml | yq - r data.keptn-api-token | base64 --decode)

print_info "keptn endpoint: $KEPTN_ENDPOINT"
print_info "keptn api-token: $KEPTN_API_TOKEN"



