#!/bin/bash
source ./utils.sh

REGISTRY_URL=$(kubectl describe svc docker-registry -n keptn | grep IP: | sed 's~IP:[ \t]*~~')

# Creating cluster role binding
kubectl apply -f ../manifests/keptn/rbac.yaml
verify_kubectl $? "Creating cluster role for keptn failed."

# Creating config map to store registry to github repo mapping
kubectl apply -f ../manifests/keptn/org-configmap.yaml
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
KEPTN_CHANNEL_URI=$(kubectl describe channel keptn-channel -n keptn | grep "Hostname:" | sed 's~[ \t]*Hostname:[ \t]*~~')
verify_variable "$KEPTN_CHANNEL_URI" "KEPTN_CHANNEL_URI could not be derived from keptn-channel description." 

rm -f ../manifests/keptn/gen/core.yaml
cat ../manifests/keptn/core.yaml | \
  sed 's~CHANNEL_URI_PLACEHOLDER~'"$KEPTN_CHANNEL_URI"'~' >> ../manifests/keptn/gen/core.yaml
  
kubectl apply -f ../manifests/keptn/gen/core.yaml
verify_kubectl $? "Deploying keptn core components failed."

# Mark internal docker registry as insecure registry for knative controller
VAL=$(kubectl -n knative-serving get cm config-controller -o=json | jq -r .data.registriesSkippingTagResolving | awk '{print $1",'$REGISTRY_URL':5000"}')
kubectl -n knative-serving get cm config-controller -o=yaml | yq w - data.registriesSkippingTagResolving $VAL | kubectl apply -f -
verify_kubectl $? "Marking internal docker registry as insecure failed."

# Set up SSL
ISTIO_INGRESS_IP=$(kubectl describe svc istio-ingressgateway -n istio-system | grep "LoadBalancer Ingress:" | sed 's~LoadBalancer Ingress:[ \t]*~~')
verify_variable "$ISTIO_INGRESS_IP" "ISTIO_INGRESS_IP is empty and could not be derived from the Istio ingress gateway." 

openssl req -nodes -newkey rsa:2048 -keyout key.pem -out certificate.pem  -x509 -days 365 -subj "/CN=$ISTIO_INGRESS_IP.xip.io"

kubectl create --namespace istio-system secret tls istio-ingressgateway-certs --key key.pem --cert certificate.pem
#verify_kubectl $? "Creating secret for istio-ingressgateway-certs failed."

kubectl get gateway knative-ingress-gateway --namespace knative-serving -o=yaml | yq w - spec.servers[1].tls.mode SIMPLE | yq w - spec.servers[1].tls.privateKey /etc/istio/ingressgateway-certs/tls.key | yq w - spec.servers[1].tls.serverCertificate /etc/istio/ingressgateway-certs/tls.crt | kubectl apply -f -
verify_kubectl $? "Updating knative ingress gateway with private key failed."

rm key.pem
rm certificate.pem

##############################################
## Start validation of keptn installation   ##
##############################################
wait_for_all_pods_in_namespace "keptn"

wait_for_deployment_in_namespace "event-broker" "keptn" # Wait function also waits for eventbroker-ext
wait_for_deployment_in_namespace "auth" "keptn"
wait_for_deployment_in_namespace "control" "keptn"
