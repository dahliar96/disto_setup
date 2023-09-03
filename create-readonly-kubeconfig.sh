#!/bin/bash

# Create service account
kubectl -n default create serviceaccount disto-readonly

# Create cluster role
kubectl create clusterrole disto-readonly --verb=get,list,watch --resource="*"

# Create cluster role binding
kubectl create clusterrolebinding disto-readonly --clusterrole=disto-readonly --serviceaccount=default:disto-readonly

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: disto-readonly-secret
  namespace: default
  annotations:
    kubernetes.io/service-account.name: disto-readonly
type: kubernetes.io/service-account-token
EOF

# Get secret name
#SECRET_NAME=$(kubectl get serviceaccount disto-readonly -n default -o jsonpath='{.secrets[0].name}')
SECRET_NAME=disto-readonly-secret

# Get token
TOKEN=$(kubectl get secret $SECRET_NAME -n default -o jsonpath='{.data.token}' | base64 --decode)

# Get CA certificate
CA_CERTIFICATE=$(kubectl get secret $SECRET_NAME -n default -o jsonpath='{.data.ca\.crt}')

# Get API server
APISERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

# Create config file
KUBECONFIG_DATA=$(cat <<EOF
apiVersion: v1
kind: Config
users:
- name: disto-readonly
  user:
    token: $TOKEN
clusters:
- cluster:
    certificate-authority-data: $CA_CERTIFICATE
    server: $APISERVER
  name: disto-cluster
contexts:
- context:
    cluster: disto-cluster
    user: disto-readonly
  name: disto-readonly-context
current-context: disto-readonly-context
EOF
)

echo "$KUBECONFIG_DATA" > disto-readonly-kubeconfig.yaml






