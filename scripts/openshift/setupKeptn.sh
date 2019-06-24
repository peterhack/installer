#!/bin/bash
CLUSTER_IPV4_CIDR=$1
SERVICES_IPV4_CIDR=$2

source ./common/utils.sh

kubectl create namespace keptn

# allow wildcard domains
oc project default
oc adm router --replicas=0
verify_kubectl $? "Scaling down router failed"
oc set env dc/router ROUTER_ALLOW_WILDCARD_ROUTES=true
verify_kubectl $? "Configuration of openshift router failed"
oc scale dc/router --replicas=1
verify_kubectl $? "Upscaling of router failed"

# create wildcard route for istio ingress gateway
oc project istio-system

BASE_URL=$(oc get route -n istio-system istio-ingressgateway -oyaml | yq r - spec.host | sed 's~istio-ingressgateway-istio-system.~~')

oc create route edge istio-wildcard-ingress --service=istio-ingressgateway --hostname="www.ingress-gateway.$BASE_URL" --port=http2 --wildcard-policy=Subdomain --insecure-policy='Allow'
verify_kubectl $? "Creation of ingress route failed."
oc create route edge istio-wildcard-ingress-secure-keptn --service=istio-ingressgateway --hostname="www.keptn.ingress-gateway.$BASE_URL" --port=http2 --wildcard-policy=Subdomain --insecure-policy='Allow'
verify_kubectl $? "Creation of keptn ingress route failed."

oc adm policy  add-cluster-role-to-user cluster-admin system:serviceaccount:keptn:default
verify_kubectl $? "Adding cluster-role failed."

# Domain used for routing to keptn services
DOMAIN="ingress-gateway.$BASE_URL"

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
  sed 's~DOMAIN_PLACEHOLDER~'"$DOMAIN"'~' > ../manifests/gen/keptn-domain-configmap.yaml

kubectl apply -f ../manifests/gen/keptn-domain-configmap.yaml
verify_kubectl $? "Creating configmap keptn-domain in keptn namespace failed."

# Configure knative serving default domain
rm -f ../manifests/gen/config-domain.yaml

cat ../manifests/knative/config-domain.yaml | \
  sed 's~DOMAIN_PLACEHOLDER~'"$DOMAIN"'~' > ../manifests/gen/config-domain.yaml

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

helm init
oc adm policy  add-cluster-role-to-user cluster-admin system:serviceaccount:kube-system:default
