#!/usr/bin/env bash
# Section E: prove the design under failure and load on the lab cluster.
#   1. NetworkPolicy: a stray pod can resolve DNS but cannot reach MySQL; employee-service can.
#   2. Circuit breaker: department-service down -> employee GET still 200 (without department).
#   3. Autoscaling: k6 load -> HPA scales employee-service; slow consumer -> KEDA scales department-service.
#   4. PodDisruptionBudget: draining api-gateway pods never takes the API down; a drain that would
#      break the budget is refused.
# Usage: bash ~/personal/EMS/deploy/drills/section-e.sh
set -uo pipefail
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/ems-lab}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NS=ems; B=http://127.0.0.1:18080
declare -a RESULTS=()
step()   { printf '\n== %s\n' "$*"; }
pass()   { RESULTS+=("PASS  $*"); printf '  PASS  %s\n' "$*"; }
fail()   { RESULTS+=("FAIL  $*"); printf '  FAIL  %s\n' "$*"; }
die()    { printf '\n!! STOPPED: %s\n' "$*"; exit 1; }
code()   { curl -g -s -o /tmp/e-body -w '%{http_code}' --max-time 5 "$@"; }
cleanup() {
  kill "${PF:-}" "${PROBE:-}" "${K6:-}" 2>/dev/null || true
  kubectl uncordon lima-w1 lima-w2 >/dev/null 2>&1 || true
  kubectl -n $NS annotate scaledobject department-service autoscaling.keda.sh/paused-replicas- >/dev/null 2>&1 || true
  kubectl -n $NS delete pod np-test --ignore-not-found --wait=false >/dev/null 2>&1 || true
}
trap cleanup EXIT

step "0. Prerequisites"
command -v k6 >/dev/null || brew install k6 || die "install k6"
for n in cp1 w1 w2; do limactl list "$n" 2>/dev/null | grep -q Running || limactl start "$n" >/dev/null; done
for i in $(seq 1 30); do kubectl get nodes >/dev/null 2>&1 && break; sleep 5; done
for d in api-gateway employee-service department-service frontend; do
  kubectl -n $NS rollout status deploy/$d --timeout=300s >/dev/null || die "$d not ready (run deploy/lab-deploy.sh)"
done
kubectl -n $NS port-forward svc/ems 18080:80 >/dev/null 2>&1 & PF=$!; sleep 4
[ "$(code $B/)" = 200 ] || die "Gateway not reachable through port-forward"
printf '{"firstName":"Drill","lastName":"Probe","email":"drill-%s@example.test","departmentCode":"ENG","position":"SRE","salary":1,"hireDate":"2026-11-14"}' "$(date +%s)" > /tmp/e-emp.json
[ "$(code -X POST -H 'Content-Type: application/json' --data-binary @/tmp/e-emp.json $B/api/v1/employee-service)" = 201 ] || die "cannot create probe employee"
EMP=$(sed -n 's/.*"id":\([0-9]*\).*/\1/p' /tmp/e-body); echo "  probe employee id $EMP"

step "1. NetworkPolicy (default deny)"
kubectl -n $NS run np-test --image=busybox:1.36 --restart=Never --labels=app.kubernetes.io/name=np-test \
  --command -- sleep 300 >/dev/null
kubectl -n $NS wait --for=condition=Ready pod/np-test --timeout=60s >/dev/null || die "np-test pod not ready"
kubectl -n $NS exec np-test -- nslookup mysql >/dev/null 2>&1 && pass "stray pod can resolve DNS (allow-dns-egress)" || fail "stray pod cannot resolve DNS"
kubectl -n $NS exec np-test -- nc -z -w 3 mysql 3306 >/dev/null 2>&1 && fail "stray pod reached MySQL (policy not enforced)" || pass "stray pod blocked from MySQL:3306"
kubectl -n $NS exec np-test -- nc -z -w 3 employee-service 8080 >/dev/null 2>&1 && fail "stray pod reached employee-service" || pass "stray pod blocked from employee-service:8080"
kubectl -n $NS exec deploy/employee-service -c app -- bash -c 'timeout 3 bash -c "</dev/tcp/mysql/3306"' >/dev/null 2>&1 \
  && pass "employee-service allowed to MySQL:3306" || fail "employee-service blocked from MySQL (policy too strict)"
kubectl -n $NS delete pod np-test --wait=false >/dev/null

step "2. Circuit breaker: department-service down"
kubectl -n $NS annotate scaledobject department-service autoscaling.keda.sh/paused-replicas="0" --overwrite >/dev/null
for i in $(seq 1 30); do [ "$(kubectl -n $NS get deploy department-service -o jsonpath='{.status.readyReplicas}')" = "" ] && break; sleep 2; done
c=$(code $B/api/v1/employee-service/$EMP)
if [ "$c" = 200 ] && grep -q '"departmentDTO":null' /tmp/e-body; then pass "employee GET 200 with departmentDTO null while department-service is down (fallback)"
else fail "employee GET returned $c: $(head -c 160 /tmp/e-body)"; fi
kubectl -n $NS annotate scaledobject department-service autoscaling.keda.sh/paused-replicas- >/dev/null
kubectl -n $NS rollout status deploy/department-service --timeout=240s >/dev/null
ok=no; for i in $(seq 1 12); do code $B/api/v1/employee-service/$EMP >/dev/null; grep -q '"departmentDTO":{' /tmp/e-body && { ok=yes; break; }; sleep 5; done
[ $ok = yes ] && pass "department details back after recovery (circuit closed)" || fail "department still missing after recovery"

step "3. Autoscaling under load (about 3 minutes)"
helm upgrade ems "$ROOT/deploy/helm/ems" -n $NS --reuse-values \
  --set services.department-service.env.EMS_EVENTS_CONSUMERDELAYMS=100 >/dev/null || die "helm upgrade failed"
kubectl -n $NS rollout status deploy/department-service --timeout=240s >/dev/null
k6 run -q -e PROFILE=drill -e BASE=$B "$ROOT/loadtest/k6/load.js" > /tmp/e-k6.txt 2>&1 & K6=$!
maxE=1; maxD=1; maxQ=0
printf '  %-8s %-10s %-12s %s\n' time employee department queue
while kill -0 $K6 2>/dev/null; do
  e=$(kubectl -n $NS get deploy employee-service -o jsonpath='{.status.readyReplicas}'); d=$(kubectl -n $NS get deploy department-service -o jsonpath='{.status.readyReplicas}')
  q=$(kubectl -n $NS exec rabbitmq-0 -- rabbitmqctl list_queues -q name messages 2>/dev/null | awk '$1=="department.employee-events"{print $2}')
  cpu=$(kubectl -n $NS get hpa employee-service -o jsonpath='{.status.currentMetrics[0].resource.current.averageUtilization}' 2>/dev/null)
  printf '  %-8s %-10s %-12s %s\n' "$(date +%H:%M:%S)" "${e:-0} (cpu ${cpu:-?}%)" "${d:-0}" "${q:-?}"
  [ "${e:-0}" -gt $maxE ] && maxE=$e; [ "${d:-0}" -gt $maxD ] && maxD=$d; [ "${q:-0}" -gt $maxQ ] && maxQ=$q
  sleep 15
done
grep -E 'http_req_failed|http_req_duration|iterations' /tmp/e-k6.txt | sed 's/^/  k6 /' | head -4
[ $maxE -ge 2 ] && pass "HPA scaled employee-service to $maxE" || fail "HPA did not scale employee-service (max $maxE; check kubectl -n ems describe hpa employee-service)"
[ $maxD -ge 2 ] && pass "KEDA scaled department-service to $maxD (queue peaked at $maxQ)" || fail "KEDA did not scale department-service (queue peaked at $maxQ)"
helm upgrade ems "$ROOT/deploy/helm/ems" -n $NS --reuse-values \
  --set services.department-service.env.EMS_EVENTS_CONSUMERDELAYMS=0 >/dev/null
q=0; for i in $(seq 1 24); do q=$(kubectl -n $NS exec rabbitmq-0 -- rabbitmqctl list_queues -q name messages 2>/dev/null | awk '$1=="department.employee-events"{print $2}'); [ "${q:-1}" = 0 ] && break; sleep 5; done
[ "${q:-1}" = 0 ] && pass "queue drained to 0 after load" || fail "queue still has $q messages"
dlq=$(kubectl -n $NS exec rabbitmq-0 -- rabbitmqctl list_queues -q name messages 2>/dev/null | awk '$1=="department.employee-events.dlq"{print $2}')
[ "${dlq:-0}" = 0 ] && pass "DLQ empty (no poison messages under load)" || fail "DLQ has $dlq messages"

step "4. PodDisruptionBudget during node drains"
( while true; do printf '%s\n' "$(code $B/api/v1/department-controller/ENG)" >> /tmp/e-probe; sleep 0.5; done ) & PROBE=$!
: > /tmp/e-probe
kubectl drain lima-w1 --pod-selector=app.kubernetes.io/name=api-gateway --ignore-daemonsets --timeout=120s >/dev/null 2>&1 \
  && pass "drained api-gateway from lima-w1 (1 of 2 allowed by PDB)" || fail "first drain failed"
kubectl -n $NS rollout status deploy/api-gateway --timeout=180s >/dev/null
kubectl -n $NS get pods -l app.kubernetes.io/name=api-gateway -o wide --no-headers | awk '{print "    "$1" on "$7}'
out=$(kubectl drain lima-w2 --pod-selector=app.kubernetes.io/name=api-gateway --ignore-daemonsets --timeout=40s 2>&1)
echo "$out" | grep -qi "disruption budget" && pass "second drain refused: would violate PodDisruptionBudget" || fail "second drain not blocked by PDB: $(echo "$out" | tail -1)"
kubectl uncordon lima-w1 lima-w2 >/dev/null
kubectl -n $NS rollout status deploy/api-gateway --timeout=180s >/dev/null
kill $PROBE 2>/dev/null; PROBE=
total=$(wc -l < /tmp/e-probe | tr -d ' '); bad=$(grep -vc '^200$' /tmp/e-probe)
[ "$bad" = 0 ] && pass "API answered 200 to all $total requests during the drains" || fail "$bad of $total requests failed during the drains"

step "Summary"
printf '  %s\n' "${RESULTS[@]}"
printf '\n%s passed, %s failed\n' "$(printf '%s\n' "${RESULTS[@]}" | grep -c '^PASS')" "$(printf '%s\n' "${RESULTS[@]}" | grep -c '^FAIL')"
