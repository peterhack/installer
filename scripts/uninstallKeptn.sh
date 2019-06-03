# Clean up dynatrace namespace
kubectl delete services,deployments,pods --all -n dynatrace --ignore-not-found
kubectl delete namespace dynatrace --ignore-not-found
kubectl delete secret dynatrace -n keptn --ignore-not-found

# Clean up keptn namespace
kubectl delete services,deployments,pods,secrets --all -n keptn --ignore-not-found
kubectl delete namespace keptn --ignore-not-found

# Clean up knative components
kubectl delete -f https://github.com/knative/serving/releases/download/v0.6.0/serving.yaml --ignore-not-found
kubectl delete -f https://github.com/knative/eventing/releases/download/v0.6.0/release.yaml --ignore-not-found
kubectl delete -f https://github.com/knative/eventing/releases/download/v0.6.0/eventing.yaml --ignore-not-found
kubectl delete -f https://github.com/knative/eventing/releases/download/v0.6.0/in-memory-channel.yaml --ignore-not-found
kubectl delete -f https://github.com/knative/serving/releases/download/v0.6.0/monitoring-logs-elasticsearch.yaml --ignore-not-found
kubectl delete -f https://github.com/knative/eventing/releases/download/v0.6.0/natss.yaml --ignore-not-found
kubectl delete -f ../manifests/nats/natss-namespace.yaml --ignore-not-found
kubectl delete -f ../manifests/nats/natss.yaml --ignore-not-found

# Clean up istio namespace
kubectl delete -f ../manifests/istio/istio-lean.yaml --ignore-not-found
kubectl delete -f ../manifests/istio/crd-10.yaml --ignore-not-found
kubectl delete -f ../manifests/istio/crd-11.yaml --ignore-not-found
kubectl delete -f ../manifests/istio/crd-certmanager-10.yaml --ignore-not-found
kubectl delete -f ../manifests/istio/crd-certmanager-11.yaml --ignore-not-found
kubectl delete services,deployments,pods --all -n istio-system --ignore-not-found
kubectl delete namespace istio-system --ignore-not-found

# Delete tiller
kubectl delete serviceaccount tiller -n kube-system --ignore-not-found
kubectl delete clusterrolebinding tiller --ignore-not-found

# Delete cluster role bindings
kubectl delete clusterrolebinding keptn-cluster-admin-binding --ignore-not-found
kubectl delete clusterrolebindings.rbac.authorization.k8s.io jenkins-rbac --ignore-not-found
kubectl delete -f https://raw.githubusercontent.com/Dynatrace/dynatrace-oneagent-operator/master/deploy/kubernetes.yaml --ignore-not-found
