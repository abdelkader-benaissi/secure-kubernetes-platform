#!/usr/bin/env bash
set -euo pipefail

HELM=${HELM:-helm}
CILIUM_VERSION=${CILIUM_VERSION:-1.18.2}
ARGOCD_VERSION=${ARGOCD_VERSION:-8.5.6}
CERT_MANAGER_VERSION=${CERT_MANAGER_VERSION:-v1.18.2}
KYVERNO_VERSION=${KYVERNO_VERSION:-3.5.2}
METRICS_SERVER_VERSION=${METRICS_SERVER_VERSION:-3.13.0}
PROMETHEUS_STACK_VERSION=${PROMETHEUS_STACK_VERSION:-77.11.1}
GATEWAY_API_VERSION=${GATEWAY_API_VERSION:-v1.3.0}
REPO_URL=${REPO_URL:-$(git config --get remote.origin.url 2>/dev/null || true)}

for command_name in kubectl "$HELM"; do
  command -v "$command_name" >/dev/null || { printf 'missing required command: %s\n' "$command_name" >&2; exit 1; }
done

if [[ ! "$REPO_URL" =~ ^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(\.git)?$ ]]; then
  printf '%s\n' 'Set REPO_URL to this repository HTTPS URL, for example:' >&2
  printf '%s\n' 'REPO_URL=https://github.com/OWNER/secure-kubernetes-platform.git make bootstrap' >&2
  exit 1
fi

$HELM repo add cilium https://helm.cilium.io/
$HELM repo add argo https://argoproj.github.io/argo-helm
$HELM repo add jetstack https://charts.jetstack.io
$HELM repo add kyverno https://kyverno.github.io/kyverno/
$HELM repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
$HELM repo add prometheus-community https://prometheus-community.github.io/helm-charts
$HELM repo update

kubectl apply -f "https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/standard-install.yaml"

$HELM upgrade --install cilium cilium/cilium -n kube-system --version "$CILIUM_VERSION" \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=secure-platform-control-plane \
  --set k8sServicePort=6443 \
  --set gatewayAPI.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true
kubectl rollout status -n kube-system ds/cilium --timeout=5m

$HELM upgrade --install cert-manager jetstack/cert-manager -n cert-manager --create-namespace \
  --version "$CERT_MANAGER_VERSION" --set crds.enabled=true
$HELM upgrade --install kyverno kyverno/kyverno -n kyverno --create-namespace --version "$KYVERNO_VERSION"
$HELM upgrade --install metrics-server metrics-server/metrics-server -n kube-system \
  --version "$METRICS_SERVER_VERSION" --set 'args={--kubelet-insecure-tls}'
$HELM upgrade --install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace \
  --version "$PROMETHEUS_STACK_VERSION" --set grafana.adminPassword=local-lab-only
$HELM upgrade --install argocd argo/argo-cd -n platform-system --create-namespace \
  --version "$ARGOCD_VERSION"

kubectl rollout status -n cert-manager deployment/cert-manager-webhook --timeout=5m
kubectl rollout status -n kyverno deployment/kyverno-admission-controller --timeout=5m
kubectl rollout status -n platform-system deployment/argocd-repo-server --timeout=5m

kubectl apply -k platform/base
sed "s|REPO_URL|${REPO_URL}|g" gitops/root.yaml | kubectl apply -f -
