#!/usr/bin/env bash
set -euo pipefail
mkdir -p evidence
kubectl get nodes -o wide > evidence/nodes.txt
kubectl get pods -A > evidence/pods.txt
kubectl get networkpolicy -A > evidence/network-policies.txt
kubectl get validatingpolicy -A > evidence/kyverno-policies.txt 2>/dev/null || true
kubectl get applications.argoproj.io -A > evidence/argocd-applications.txt 2>/dev/null || true
kubectl get gateway,httproute -A > evidence/gateway-api.txt
kubectl get certificate -A > evidence/certificates.txt
kubectl get hpa -A > evidence/autoscaling.txt
kubectl wait --for=condition=Available apiservice/v1beta1.metrics.k8s.io --timeout=2m
kubectl top pods -A > evidence/pod-metrics.txt
