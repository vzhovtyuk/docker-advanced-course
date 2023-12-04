#!/bin/bash

curl -LO https://dl.k8s.io/release/v1.28.3/bin/linux/amd64/kubectl
curl -LO "https://dl.k8s.io/release/v1.28.3/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check