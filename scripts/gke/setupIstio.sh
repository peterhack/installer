#!/bin/bash
CLUSTER_IPV4_CIDR=$1
SERVICES_IPV4_CIDR=$2

source ./common/utils.sh

# Apply custom resource definitions for Istio
kubectl apply -f ../manifests/istio/istio-crds-knative.yaml
verify_kubectl $? "Creating istio custom resource definitions failed."
wait_for_crds "virtualservices,destinationrules,serviceentries,gateways,envoyfilters,policies,meshpolicies,httpapispecbindings,httpapispecs,quotaspecbindings,quotaspecs,rules,attributemanifests,bypasses,circonuses,deniers,fluentds,kubernetesenvs,listcheckers,memquotas,noops,opas,prometheuses,rbacs,redisquotas,servicecontrols,signalfxs,solarwindses,stackdrivers,statsds,stdios,apikeys,authorizations,checknothings,kuberneteses,listentries,logentries,edges,metrics,quotas,reportnothings,servicecontrolreports,tracespans,adapters,instances,templates,handlers,rbacconfigs,serviceroles,servicerolebindings"

# Apply Istio configuration
rm -f ../manifests/gen/istio-knative.yaml
cat ../manifests/istio/istio-knative.yaml | \
  sed 's~INCLUDE_OUTBOUND_IP_RANGES_PLACEHOLDER~'"$CLUSTER_IPV4_CIDR,$SERVICES_IPV4_CIDR"'~' >> ../manifests/gen/istio-knative.yaml

kubectl apply -f ../manifests/gen/istio-knative.yaml
verify_kubectl $? "Creating all istio components failed."
wait_for_all_pods_in_namespace "istio-system"
