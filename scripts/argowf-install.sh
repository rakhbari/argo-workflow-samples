#!/bin/bash

# helm repo add argo https://argoproj.github.io/argo-helm
# helm repo update

SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE}")")
helm install argo-workflows argo/argo-workflows -n argo -f ${SCRIPT_DIR}/../install/workflows-values.yaml
