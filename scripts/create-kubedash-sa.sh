#!/bin/bash

export NAMESPACE=${1}
export SERVICE_ACCT=${2}

if ! command -v envsubst &> /dev/null
then
  echo "ERROR: envsubst isn't installed/can't be found. Get it installed on your machine before proceeding. https://www.google.com/search?q=envsubst+command+not+found"
  exit 2
fi

usage() {
  echo ""
  echo "Usage: ${0} <namespace> <service_acct>"
  exit 1
}

createSA() {
  echo ""
  echo "===> Creating SA ${SERVICE_ACCT} in namespace ${NAMESPACE} ..."
  kubectl create sa ${SERVICE_ACCT} -n ${NAMESPACE}
  envsubst < secret-service-acct-token.yaml | kubectl apply -f -
}

if [ -z "${NAMESPACE}" ] || [ -z "${SERVICE_ACCT}" ]
then
  echo "ERROR: NAMESPACE and SERVICE_ACCT are required."
  usage
fi

echo ""
echo "===> Creating namespace ${NAMESPACE} (if it doesn't exist) ..."
kubectl get ns | grep -q "^${NAMESPACE} " || kubectl create ns ${NAMESPACE}

# Check existence of SA in the namespace. If not, create it
kubectl get sa ${SERVICE_ACCT} -n ${NAMESPACE} > /dev/null 2>&1
test $? -eq 0 || createSA

echo ""
echo "===> Creating ClusterRoles (if they don't exist) ..."
kubectl get clusterrole kube-dash-extras > /dev/null 2>&1
test $? -eq 0 || kubectl apply -f clusterroles-kube-dash-extras.yaml

echo ""
echo "===> Applying rolebinding-workflow.yaml in namespace ${NAMESPACE} ..."
envsubst < rolebinding-kubedash.yaml | kubectl apply -n ${NAMESPACE} -f -

SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
${SCRIPT_DIR}/get-sa-token.sh ${NAMESPACE} ${SERVICE_ACCT}
