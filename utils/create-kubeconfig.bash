#!/bin/bash

if [ "${K8S_TOKEN_SECRET}" = '' ]; then
    echo "Env [K8S_TOKEN_SECRET] is required!!!"
    exit 1
fi

if [ "${K8S_SERVER}" = '' ]; then
    echo "Env [K8S_SERVER] is required!!!"
    exit 1
fi

GCP_PROJECT=$(echo "${K8S_TOKEN_SECRET}" | cut -d: -f1)
SECRET_NAME=$(echo "${K8S_TOKEN_SECRET}" | cut -d: -f2)
SA_USER=devops-cicd
CONTEXT_NAME=default-context
CLUSTER_NAME=k8s-cluster

echo "Getting JWT from project [${GCP_PROJECT}], secret [${SECRET_NAME}]..."
JWT=$(gcloud secrets versions access latest --project="${GCP_PROJECT}" --secret="${SECRET_NAME}")

#export KUBECONFIG=kubeconfig-cicd

kubectl config set-credentials "${SA_USER}" --token="${JWT}"

kubectl config set-cluster ${CLUSTER_NAME} \
--server=${K8S_SERVER} \
--insecure-skip-tls-verify=true \
--user="${SA_USER}"
kubectl config set-context "${CONTEXT_NAME}" --cluster="${CLUSTER_NAME}" --user="${SA_USER}" 
kubectl config use-context "${CONTEXT_NAME}"