#!/usr/bin/env bash
set -euo pipefail

helm lint charts/demo-api
helm template demo charts/demo-api --namespace app-dev > /tmp/secure-platform-rendered.yaml
helm template demo-dev charts/demo-api --namespace app-dev -f environments/dev/values.yaml > /tmp/secure-platform-dev.yaml
helm template demo-prod charts/demo-api --namespace app-prod -f environments/prod/values.yaml > /tmp/secure-platform-prod.yaml
kubectl kustomize platform/base > /tmp/secure-platform-base.yaml

if command -v kubeconform >/dev/null; then
  kubeconform -strict -summary -ignore-missing-schemas /tmp/secure-platform-rendered.yaml /tmp/secure-platform-dev.yaml /tmp/secure-platform-prod.yaml /tmp/secure-platform-base.yaml
fi
if command -v checkov >/dev/null; then checkov -d . --framework kubernetes; fi
if command -v trivy >/dev/null; then trivy config --exit-code 1 --severity HIGH,CRITICAL .; fi
