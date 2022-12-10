#!/bin/bash

ARGO_VERSION="v3.4.4"

# Download the binary
wget -O /tmp/argo-linux-amd64-${ARGO_VERSION}.gz https://github.com/argoproj/argo-workflows/releases/download/${ARGO_VERSION}/argo-linux-amd64.gz

# Unzip
gunzip -f /tmp/argo-linux-amd64-${ARGO_VERSION}.gz

# Make binary executable
chmod +x /tmp/argo-linux-amd64-${ARGO_VERSION}

# Move binary to path
sudo mv /tmp/argo-linux-amd64-${ARGO_VERSION} /usr/local/bin/argo

# Test installation
argo version
