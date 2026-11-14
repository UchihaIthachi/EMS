# EMS Helm chart

Deploys the whole EMS stack into one namespace: api-gateway, employee-service, department-service,
frontend, MySQL (one server, two databases), RabbitMQ, Redis, the Gateway + HTTPRoute, KEDA ScaledObject,
NetworkPolicies (default deny), RBAC roles, ResourceQuota/LimitRange, PriorityClasses and a nightly
MySQL backup CronJob. Design: [docs/design.md](../../../docs/design.md).

Prerequisites in the cluster: a default StorageClass, metrics-server, Gateway API CRDs + kgateway, KEDA.

```bash
cp secrets.local.yaml.example secrets.local.yaml   # git-ignored; fill in passwords
kubectl create namespace ems
kubectl label namespace ems pod-security.kubernetes.io/enforce=baseline pod-security.kubernetes.io/warn=restricted
helm upgrade --install ems . -n ems -f secrets.local.yaml --set image.tag=<commit-sha or branch>
```

Pod Security starts at `baseline` enforced with `restricted` warnings; switching enforcement to
`restricted` once no warnings appear is a hardening step in the runbook.
