#!/bin/bash

source ./utils.sh

kubectl apply -f ../manifests/istio/crd-10.yaml
verify_kubectl $? "Creating istio custom resource definitions failed."

kubectl apply -f ../manifests/istio/crd-11.yaml
verify_kubectl $? "Creating istio custom resource definitions failed."

kubectl apply -f ../manifests/istio/crd-certmanager-10.yaml
verify_kubectl $? "Creating istio custom resource definitions failed."

kubectl apply -f ../manifests/istio/crd-certmanager-11.yaml
verify_kubectl $? "Creating istio custom resource definitions failed."

wait_for_crds "virtualservices,destinationrules,serviceentries,gateways,envoyfilters,clusterrbacconfigs,policies,meshpolicies,httpapispecbindings,httpapispecs,quotaspecbindings,quotaspecs,rules,attributemanifests,bypasses,circonuses,deniers,fluentds,kubernetesenvs,listcheckers,memquotas,noops,opas,prometheuses,rbacs,redisquotas,signalfxs,solarwindses,stackdrivers,statsds,stdios,apikeys,authorizations,checknothings,kuberneteses,listentries,logentries,edges,metrics,quotas,reportnothings,tracespans,rbacconfigs,serviceroles,servicerolebindings,adapters,instances,templates,handlers,cloudwatches,dogstatsds,sidecars,zipkins,clusterissuers,issuers,certificates,orders,challenges"

kubectl apply -f ../manifests/istio/istio-namespace.yaml
verify_kubectl $? "Creating istio namespace failed."

# Install istio without sidecar injection to keep the installation lean
kubectl apply -f ../manifests/istio/istio-lean.yaml
verify_kubectl $? "Creating all istio components failed."

kubectl apply -f ../manifests/istio/istio-local-gateway.yaml
verify_kubectl $? "Creating all istio local gateway failed."

wait_for_all_pods_in_namespace "istio-system"