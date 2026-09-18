# Threat model

## Assets

Cluster credentials, workload identity, secrets, container images, GitOps state, service traffic, and observability data.

## Trust boundaries

Developer to Git; CI runner to registry; Argo CD to Git and Kubernetes API; Gateway to workload; workload to DNS and dependencies; administrator to control plane.

## Principal threats and controls

| Threat | Preventive control | Detective control |
|---|---|---|
| Privileged workload | Restricted PSA, Kyverno | Admission events |
| Lateral movement | Default-deny NetworkPolicy | Hubble flows |
| Supply-chain substitution | Immutable tags; add signature verification in production | Trivy CI results |
| Configuration drift | Argo CD self-heal | Argo CD health/status |
| Secret theft | No token automount; external secret manager required for production | Audit logs |
| Availability loss | HPA, PDB, multi-replica workload | Prometheus alerts |

## Residual risk

Kind is not a hardened control plane. This lab does not claim cloud IAM, KMS-backed secret encryption, off-cluster backups, or multi-zone resilience.
