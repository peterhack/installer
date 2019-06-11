#!/bin/bash

source ./utils.sh

# Create Istio namespace
kubectl apply -f ../manifests/istio/istio-namespace.yaml
verify_kubectl $? "Creating istio namespace failed."

# Apply custom resource definitions for Istio
kubectl apply -f ../manifests/istio/crd-10.yaml
verify_kubectl $? "Creating istio custom resource definitions (crd-10) failed."

kubectl apply -f ../manifests/istio/crd-11.yaml
verify_kubectl $? "Creating istio custom resource definitions (crd-11) failed."

# Apply custom resource definition cert manager for Istio
kubectl apply -f ../manifests/istio/crd-certmanager-10.yaml
verify_kubectl $? "Creating istio custom resource definitions cert manager (10) failed."

kubectl apply -f ../manifests/istio/crd-certmanager-11.yaml
verify_kubectl $? "Creating istio custom resource definitions cert manager (11) failed."

wait_for_crds "virtualservices,destinationrules,serviceentries,gateways,envoyfilters,clusterrbacconfigs,policies,meshpolicies,httpapispecbindings,httpapispecs,quotaspecbindings,quotaspecs,rules,attributemanifests,bypasses,circonuses,deniers,fluentds,kubernetesenvs,listcheckers,memquotas,noops,opas,prometheuses,rbacs,redisquotas,signalfxs,solarwindses,stackdrivers,statsds,stdios,apikeys,authorizations,checknothings,kuberneteses,listentries,logentries,edges,metrics,quotas,reportnothings,tracespans,rbacconfigs,serviceroles,servicerolebindings,adapters,instances,templates,handlers,cloudwatches,dogstatsds,sidecars,zipkins,clusterissuers,issuers,certificates,orders,challenges"

# Apply Istio lean
kubectl apply -f ../manifests/istio/istio-lean.yaml
verify_kubectl $? "Creating all istio components failed."

# Apply Istio local gateway
kubectl apply -f ../manifests/istio/istio-local-gateway.yaml
verify_kubectl $? "Creating all istio local gateway failed."

wait_for_all_pods_in_namespace "istio-system"
