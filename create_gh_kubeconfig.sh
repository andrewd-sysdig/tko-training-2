#!/bin/bash

SERVICE_ACCOUNT_NAME=github-actions-deploy-02
NAMESPACE=tko-app

CONTEXT=$(kubectl config current-context)

NEW_CONTEXT=${NAMESPACE}-context
KUBECONFIG_FILE=${NAMESPACE}-kubeconfig

kubectl create ns ${NAMESPACE}
kubectl create -n ${NAMESPACE} sa ${SERVICE_ACCOUNT_NAME}
kubectl create -n ${NAMESPACE} role ${SERVICE_ACCOUNT_NAME}-admin \
  --verb="*" --resource="*"
kubectl create -n ${NAMESPACE} rolebinding ${SERVICE_ACCOUNT_NAME}-admin-rb \
  --role=${SERVICE_ACCOUNT_NAME}-admin --serviceaccount=${NAMESPACE}:${SERVICE_ACCOUNT_NAME}

SECRET_NAME=$(kubectl get serviceaccount ${SERVICE_ACCOUNT_NAME} \
  --context ${CONTEXT} \
  --namespace ${NAMESPACE} \
  -o jsonpath='{.secrets[0].name}')

TOKEN_DATA=$(kubectl get secret ${SECRET_NAME} \
  --context ${CONTEXT} \
  --namespace ${NAMESPACE} \
  -o jsonpath='{.data.token}')

TOKEN=$(echo ${TOKEN_DATA} | base64 -d)

kubectl config view --raw > ${KUBECONFIG_FILE}.full.tmp
kubectl --kubeconfig ${KUBECONFIG_FILE}.full.tmp config use-context ${CONTEXT}
kubectl --kubeconfig ${KUBECONFIG_FILE}.full.tmp \
  config view --flatten --minify > ${KUBECONFIG_FILE}.tmp
kubectl config --kubeconfig ${KUBECONFIG_FILE}.tmp \
  rename-context ${CONTEXT} ${NEW_CONTEXT}
kubectl config --kubeconfig ${KUBECONFIG_FILE}.tmp \
  set-credentials ${CONTEXT}-${NAMESPACE}-token-user \
  --token ${TOKEN}
kubectl config --kubeconfig ${KUBECONFIG_FILE}.tmp \
  set-context ${NEW_CONTEXT} --user ${CONTEXT}-${NAMESPACE}-token-user
kubectl config --kubeconfig ${KUBECONFIG_FILE}.tmp \
  set-context ${NEW_CONTEXT} --namespace ${NAMESPACE}
kubectl config --kubeconfig ${KUBECONFIG_FILE}.tmp \
  view --flatten --minify > ${KUBECONFIG_FILE}
rm ${KUBECONFIG_FILE}.full.tmp
rm ${KUBECONFIG_FILE}.tmp
