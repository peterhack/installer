#!/bin/bash
source ./common/utils.sh

kubectl create namespace keptn
# Domain used for routing to keptn services
DOMAIN=$(oc get route -n istio-system istio-ingressgateway -oyaml | yq r - spec.host)
if [[ $? != 0 ]]; then
  print_error "Failed to get ingress gateway information." && exit 1
fi

# Allow outbound traffic
CLUSTER_IPV4_CIDR=172.30.0.0/16
SERVICES_IPV4_CIDR=10.1.0.0/16
# kubectl get configmap config-network -n knative-serving -o=yaml | yq w - data['istio.sidecar.includeOutboundIPRanges'] "172.29.0.0/16" | kubectl apply -f - 
kubectl get configmap config-network -n knative-serving -o=yaml | yq w - data['istio.sidecar.includeOutboundIPRanges'] "$CLUSTER_IPV4_CIDR,$SERVICES_IPV4_CIDR" | kubectl apply -f - 

# Set up SSL
openssl req -nodes -newkey rsa:2048 -keyout key.pem -out certificate.pem  -x509 -days 365 -subj "/CN=$DOMAIN"

kubectl create --namespace istio-system secret tls istio-ingressgateway-certs --key key.pem --cert certificate.pem
#verify_kubectl $? "Creating secret for istio-ingressgateway-certs failed."

kubectl get gateway knative-ingress-gateway --namespace knative-serving -o=yaml | yq w - spec.servers[1].tls.mode SIMPLE | yq w - spec.servers[1].tls.privateKey /etc/istio/ingressgateway-certs/tls.key | yq w - spec.servers[1].tls.serverCertificate /etc/istio/ingressgateway-certs/tls.crt | kubectl apply -f -
verify_kubectl $? "Updating knative ingress gateway with private key failed."

rm key.pem
rm certificate.pem

# Add config map in keptn namespace that contains the domain - this will be used by other services as well
cat ../manifests/keptn/keptn-domain-configmap.yaml | \
  sed 's~DOMAIN_PLACEHOLDER~'"$DOMAIN"'~' >> ../manifests/gen/keptn-domain-configmap.yaml

kubectl apply -f ../manifests/gen/keptn-domain-configmap.yaml
verify_kubectl $? "Creating configmap keptn-domain in keptn namespace failed."

# Configure knative serving default domain
rm -f ../manifests/gen/config-domain.yaml

cat ../manifests/knative/config-domain.yaml | \
  sed 's~DOMAIN_PLACEHOLDER~'"$DOMAIN"'~' >> ../manifests/gen/config-domain.yaml

kubectl apply -f ../manifests/gen/config-domain.yaml
verify_kubectl $? "Creating configmap config-domain in knative-serving namespace failed."

# Creating cluster role binding
kubectl apply -f ../manifests/keptn/rbac.yaml
verify_kubectl $? "Creating cluster role for keptn failed."

# Creating config map to store registry to github repo mapping
kubectl apply -f ../manifests/keptn/configmap.yaml
verify_kubectl $? "Creating config map for keptn failed."

# Create keptn secret
KEPTN_API_TOKEN=$(head -c 16 /dev/urandom | base64)
verify_variable "$KEPTN_API_TOKEN" "KEPTN_API_TOKEN could not be derived." 
kubectl create secret generic -n keptn keptn-api-token --from-literal=keptn-api-token="$KEPTN_API_TOKEN"

# Deploy keptn channels
kubectl apply -f ../manifests/keptn/channels.yaml
verify_kubectl $? "Deploying keptn channels failed."

wait_for_channel_in_namespace "keptn-channel" "keptn"
wait_for_channel_in_namespace "new-artifact" "keptn"
wait_for_channel_in_namespace "configuration-changed" "keptn"
wait_for_channel_in_namespace "deployment-finished" "keptn"
wait_for_channel_in_namespace "tests-finished" "keptn"
wait_for_channel_in_namespace "evaluation-done" "keptn"
wait_for_channel_in_namespace "problem" "keptn"

# Deploy keptn core components
wait_for_hostname "keptn-channel" "keptn"
KEPTN_CHANNEL_URI=$(kubectl describe channel keptn-channel -n keptn | grep "Hostname:" | sed 's~[ \t]*Hostname:[ \t]*~~')
verify_variable "$KEPTN_CHANNEL_URI" "KEPTN_CHANNEL_URI could not be derived from keptn-channel description."

rm -f ../manifests/keptn/gen/core.yaml
cat ../manifests/keptn/core.yaml | \
  sed 's~CHANNEL_URI_PLACEHOLDER~'"$KEPTN_CHANNEL_URI"'~' >> ../manifests/keptn/gen/core.yaml
  
kubectl apply -f ../manifests/keptn/gen/core.yaml
verify_kubectl $? "Deploying keptn core components failed."

##############################################
## Start validation of keptn installation   ##
##############################################
wait_for_all_pods_in_namespace "keptn"

wait_for_deployment_in_namespace "event-broker" "keptn" # Wait function also waits for eventbroker-ext
wait_for_deployment_in_namespace "auth" "keptn"
wait_for_deployment_in_namespace "control" "keptn"

CONTROL_SERVICE_ID=$(kubectl get ksvc -n keptn control -oyaml | yq r - status.latestReadyRevisionName)
oc expose svc $CONTROL_SERVICE_ID-service  --name=control -n keptn
