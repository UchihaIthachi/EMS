#!/usr/bin/env bash
# Create EMS users with Kubernetes CSRs (CKA: certificates + RBAC) and verify their permissions.
# Keys and certs go to ~/personal/k8s-lab/users (never into the repo).
# Usage: bash ~/personal/EMS/deploy/drills/rbac-users.sh
set -euo pipefail
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/ems-lab}"
DIR="$HOME/personal/k8s-lab/users"; mkdir -p "$DIR"; cd "$DIR"; chmod 700 "$DIR"
CLUSTER=$(kubectl config view -o jsonpath='{.clusters[0].name}')

for u in ems-developer ems-operator; do
  echo "== $u"
  [ -f $u.key ] || openssl genrsa -out $u.key 2048 2>/dev/null
  chmod 600 $u.key
  openssl req -new -key $u.key -out $u.csr -subj "/CN=$u/O=ems"
  kubectl delete csr $u --ignore-not-found >/dev/null
  req=$(base64 < $u.csr | tr -d '\n')
  kubectl apply -f - <<YAML
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: $u
spec:
  request: $req
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 2592000
  usages: [client auth]
YAML
  kubectl certificate approve $u
  for i in $(seq 1 10); do
    cert=$(kubectl get csr $u -o jsonpath='{.status.certificate}'); [ -n "$cert" ] && break; sleep 1
  done
  [ -n "$cert" ] || { echo "certificate not issued for $u"; exit 1; }
  printf '%s' "$cert" | base64 --decode > $u.crt
  openssl x509 -in $u.crt -noout -subject -enddate | sed 's/^/  /'
  kubectl config set-credentials $u --client-key=$u.key --client-certificate=$u.crt --embed-certs >/dev/null
  kubectl config set-context $u --cluster="$CLUSTER" --user=$u --namespace=ems >/dev/null
  echo "  context $u ready"
done

check() { # check <context> <expected yes|no> <verb> <resource> [extra args]
  local ctx=$1 want=$2; shift 2
  local got; got=$(kubectl --context "$ctx" auth can-i "$@" 2>/dev/null || true)
  if [ "$got" = "$want" ]; then printf '  PASS  %-14s can-i %-32s = %s\n' "$ctx" "$*" "$got"
  else printf '  FAIL  %-14s can-i %-32s = %s (expected %s)\n' "$ctx" "$*" "${got:-error}" "$want"; FAILED=1; fi
}
FAILED=0
echo; echo "== permission checks"
check ems-developer yes list pods
check ems-developer yes get pods/log
check ems-developer no  get secrets
check ems-developer no  delete pods
check ems-developer no  list pods -n default
check ems-operator  yes patch deployments/scale
check ems-operator  yes create pods/exec
check ems-operator  yes delete pods
check ems-operator  no  get secrets
check ems-operator  no  delete deployments
echo; echo "== real request with the developer certificate (no impersonation)"
kubectl --context ems-developer get pods --no-headers | head -3
echo; [ $FAILED = 0 ] && echo "ALL RBAC CHECKS PASSED" || { echo "SOME CHECKS FAILED"; exit 1; }
