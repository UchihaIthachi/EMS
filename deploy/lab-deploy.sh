#!/usr/bin/env bash
# Deploy EMS to the Lima lab cluster with the Helm chart, then smoke-test it through the Gateway.
# Usage (from anywhere):  bash ~/personal/EMS/deploy/lab-deploy.sh [image-tag]
# Default image tag = the current commit SHA (CI publishes it). Needs deploy/helm/ems/secrets.local.yaml.
set -euo pipefail
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/ems-lab}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHART="$ROOT/deploy/helm/ems"
NS=ems
TAG="${1:-$(git -C "$ROOT" rev-parse HEAD)}"
step() { printf '\n== %s\n' "$*"; }
die()  { printf '\n!! STOPPED: %s\n' "$*"; exit 1; }

[ -f "$CHART/secrets.local.yaml" ] || die "create $CHART/secrets.local.yaml from secrets.local.yaml.example"

step "1. Images for tag ${TAG:0:12} on GHCR (waits up to 15 min for CI)"
for s in api-gateway employee-service department-service frontend; do
  for i in $(seq 1 90); do
    tok=$(curl -s "https://ghcr.io/token?scope=repository:uchihaithachi/ems-$s:pull" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
    code=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $tok" \
      -H 'Accept: application/vnd.oci.image.index.v1+json' "https://ghcr.io/v2/uchihaithachi/ems-$s/manifests/$TAG")
    [ "$code" = 200 ] && break
    [ "$i" = 1 ] && printf '  waiting for ems-%s:%s' "$s" "${TAG:0:12}"
    printf '.'; sleep 10
  done
  [ "$code" = 200 ] || die "ems-$s:$TAG not on GHCR (check the Actions run)"
  echo "  ems-$s ✓"
done

step "2. Cluster up"
for n in cp1 w1 w2; do limactl list "$n" 2>/dev/null | grep -q Running || limactl start "$n"; done
for i in $(seq 1 30); do kubectl get nodes >/dev/null 2>&1 && break; sleep 5; done
ready=$(kubectl get nodes --no-headers | awk '$2=="Ready"' | wc -l | tr -d ' ')
[ "$ready" = 3 ] || die "expected 3 Ready nodes, got $ready"
kubectl get crd scaledobjects.keda.sh gateways.gateway.networking.k8s.io >/dev/null || die "KEDA or Gateway API missing (run k8s-lab/addons.sh)"

step "3. Namespace with Pod Security (enforce baseline, warn restricted)"
kubectl create namespace $NS --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace $NS --overwrite \
  pod-security.kubernetes.io/enforce=baseline pod-security.kubernetes.io/warn=restricted pod-security.kubernetes.io/audit=restricted

step "4. helm upgrade --install"
helm upgrade --install ems "$CHART" -n $NS -f "$CHART/secrets.local.yaml" --set image.tag="$TAG"

step "5. Data tier"
kubectl -n $NS rollout status statefulset/mysql --timeout=300s
kubectl -n $NS rollout status statefulset/rabbitmq --timeout=300s
kubectl -n $NS rollout status deploy/redis --timeout=120s

step "6. Apps (JVMs need 1-2 minutes)"
for d in frontend department-service employee-service api-gateway; do
  kubectl -n $NS rollout status deploy/$d --timeout=420s || {
    kubectl -n $NS get pods -l app.kubernetes.io/name=$d
    kubectl -n $NS logs deploy/$d --all-containers --tail=30 || true
    die "$d did not become ready"; }
done

step "7. Gateway proxy"
for i in $(seq 1 30); do kubectl -n $NS get svc ems >/dev/null 2>&1 && break; sleep 5; done
echo "proxy pod labels:"; kubectl -n $NS get pods -o name | grep -v -E 'mysql|rabbitmq|redis|frontend|service|api-gateway' | xargs -r kubectl -n $NS get --show-labels --no-headers || true
match=$(kubectl -n $NS get pods -l gateway.networking.k8s.io/gateway-name=ems --no-headers 2>/dev/null | wc -l | tr -d ' ')
[ "$match" -ge 1 ] || die "no pod has label gateway.networking.k8s.io/gateway-name=ems: set gateway.proxyPodLabels in values.yaml to the labels above"
kubectl -n $NS wait --for=condition=Programmed gateway/ems --timeout=180s

step "8. Smoke test through the Gateway"
kubectl -n $NS port-forward svc/ems 18080:80 >/dev/null 2>&1 & PF=$!
trap 'kill $PF 2>/dev/null || true' EXIT
sleep 4
B=http://127.0.0.1:18080
j='Content-Type: application/json'
c() { curl -g -s -o /tmp/ems-body -w '%{http_code}' "$@"; }
row() { printf '  %-46s %s\n' "$1" "$2"; }
row "GET  / (frontend)" "$(c $B/)"
printf '%s' '{"departmentName":"Engineering","departmentDescription":"Builds things","departmentCode":"ENG"}' > /tmp/ems-dept.json
row "POST department ENG" "$(c -X POST -H "$j" --data-binary @/tmp/ems-dept.json $B/api/v1/department-controller)"
row "GET  department ENG (cache-aside)" "$(c $B/api/v1/department-controller/ENG)"
before=$(curl -g -s $B/api/v1/department-controller/ENG/stats | sed -n 's/.*"employeeCount":\([0-9]*\).*/\1/p')
printf '{"firstName":"Smoke","lastName":"Test","email":"smoke-%s@example.test","departmentCode":"ENG","position":"SRE","salary":1000,"hireDate":"2026-11-14"}' "$(date +%s)" > /tmp/ems-emp.json
row "POST employee" "$(c -X POST -H "$j" --data-binary @/tmp/ems-emp.json $B/api/v1/employee-service)"
id=$(sed -n 's/.*"id":\([0-9]*\).*/\1/p' /tmp/ems-body)
[ -n "$id" ] || die "employee was not created: $(head -c 300 /tmp/ems-body)"
row "GET  employee $id (+ department via Feign)" "$(c $B/api/v1/employee-service/$id)"
echo "    $(head -c 260 /tmp/ems-body)"
grep -q '"departmentDTO":{' /tmp/ems-body || echo "    !! department missing: circuit breaker fallback? check department-service"
after=$before
for i in $(seq 1 10); do
  after=$(curl -g -s $B/api/v1/department-controller/ENG/stats | sed -n 's/.*"employeeCount":\([0-9]*\).*/\1/p')
  [ "${after:-0}" -gt "${before:-0}" ] && break; sleep 2
done
row "ENG stats via employee.created event" "${before:-0} -> ${after:-0}"
[ "${after:-0}" -gt "${before:-0}" ] || echo "    !! event not applied: kubectl -n ems logs deploy/employee-service | grep -i publish"

step "9. Footprint"
kubectl top nodes || true
kubectl -n $NS top pods 2>/dev/null | sort -k3 -h -r || true
kubectl -n $NS get resourcequota ems
printf '\nDONE: EMS %s is up. Browse: kubectl -n %s port-forward svc/ems 18080:80, then http://127.0.0.1:18080/\n' "${TAG:0:12}" "$NS"
