#!/usr/bin/env bash
# Observability demo, part 2: Jaeger + the OpenTelemetry Java agent already baked into the images.
# Run on the Mac:  bash deploy/observability/tracing.sh
# Only check traces: bash deploy/observability/tracing.sh check
# Turn off:        bash deploy/observability/tracing.sh off   (redeploys EMS without the agent, deletes Jaeger)
set -eu
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/ems-lab}"
cd "$(git rev-parse --show-toplevel)"
O=deploy/observability; M=monitoring
step() { printf '\n== %s\n' "$*"; }
die()  { printf '\n!! STOPPED: %s\n' "$*"; exit 1; }
maxw() { kubectl top nodes --no-headers | awk '$1!="lima-cp1"{gsub("%","",$5); if($5>m)m=$5} END{print m+0}'; }

if [ "${1:-}" = off ]; then
  bash deploy/lab-deploy.sh
  kubectl delete -f $O/jaeger.yaml --ignore-not-found; exit 0
fi

if [ "${1:-}" != check ]; then
step "1. Headroom (stop if a worker is above 80%)"
kubectl top nodes
[ "$(maxw)" -le 80 ] || die "a worker is above 80% memory; remove Prometheus/Grafana first: bash $O/metrics.sh remove"

step "2. Jaeger v2 all-in-one"
kubectl create ns $M --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl apply -f $O/jaeger.yaml
kubectl -n $M rollout status deploy/jaeger --timeout=180s

step "3. EMS with the OTel agent (+ allow-tracing-egress NetworkPolicy); rolls the Spring pods"
HELM_ARGS="--set tracing.enabled=true" bash deploy/lab-deploy.sh
kubectl -n ems get netpol allow-tracing-egress >/dev/null || die "allow-tracing-egress missing"
kubectl -n ems get cm employee-service -o jsonpath='{.data.JAVA_TOOL_OPTIONS}' | grep -q javaagent || die "agent not in JAVA_TOOL_OPTIONS"
kubectl -n ems logs deploy/employee-service -c app | grep -m1 'opentelemetry-javaagent' || echo "  (agent banner not found in logs; checking traces anyway)"
fi

step "4. One request with our own trace id, then fetch exactly that trace"
# Search by service is useless here: kubelet probes are traced every 5s and fill the most-recent-N results.
# Instead send a W3C traceparent header; the proxy passes it on and api-gateway continues our trace. (runbook 20)
kubectl -n ems port-forward svc/ems 18080:80 >/dev/null 2>&1 & P1=$!
kubectl -n $M port-forward svc/jaeger 16686:16686 >/dev/null 2>&1 & P2=$!
trap 'kill $P1 $P2 2>/dev/null || true' EXIT; sleep 4
TID=$(openssl rand -hex 16); SID=$(openssl rand -hex 8)
RP=$(kubectl -n ems get secret mysql -o jsonpath='{.data.root-password}' | base64 --decode)
EMP=$(kubectl -n ems exec mysql-0 -- env MYSQL_PWD="$RP" mysql -uroot -N -e 'SELECT MAX(id) FROM employee_db.employees' 2>/dev/null | tr -d '\r')
[ -n "$EMP" ] && [ "$EMP" != NULL ] || die "no employees yet: run deploy/lab-deploy.sh (its smoke test creates one)"
code=$(curl -s -o /dev/null -w '%{http_code}' -H "traceparent: 00-$TID-$SID-01" http://127.0.0.1:18080/api/v1/employee-service/$EMP)
echo "  trace id $TID   GET employee $EMP -> HTTP $code"
out=
for i in 1 2 3 4 5 6; do
  sleep 10
  out=$(curl -s "http://127.0.0.1:16686/api/v3/traces/$TID" | python3 -c '
import json,sys
d=json.load(sys.stdin); rs=d.get("result",d).get("resourceSpans",[])
if not rs: sys.exit(1)
rows=[]
for r in rs:
    svc=next((a["value"]["stringValue"] for a in r["resource"]["attributes"] if a["key"]=="service.name"),"?")
    for ss in r.get("scopeSpans",[]):
        for s in ss["spans"]:
            rows.append((int(s["startTimeUnixNano"]),svc,s["name"],(int(s["endTimeUnixNano"])-int(s["startTimeUnixNano"]))/1e6))
rows.sort(); t0=rows[0][0]
print(len({r[1] for r in rows}))
print(f"  services: {sorted({r[1] for r in rows})}   spans: {len(rows)}")
for st,svc,name,ms in rows: print(f"  +{(st-t0)/1e6:7.1f}ms {ms:7.1f}ms  {svc:20} {name}")
' 2>/dev/null) && break
done
[ -n "$out" ] || die "trace $TID not in Jaeger after 60s (check: kubectl -n ems logs deploy/api-gateway -c app | grep -i otel)"
n=$(echo "$out" | head -1); echo "$out" | tail -n +2
[ "$n" -ge 3 ] && echo "  gateway -> employee -> department in ONE trace: ok" || die "only $n service(s) in the trace"
echo "  UI: http://127.0.0.1:16686/trace/$TID (while a port-forward to svc/jaeger runs)"

step "5. Headroom after"
kubectl top nodes
kubectl -n ems top pods --no-headers | awk '{print "  "$1, $3}'
cat <<MSG

DONE. Jaeger UI:  kubectl -n $M port-forward svc/jaeger 16686:16686  ->  http://127.0.0.1:16686
Pick service api-gateway, find a POST /api/v1/employee... trace, open it: the Feign call to department-service
and the RabbitMQ publish -> consume hop are child spans. Screenshot it for the README.
MSG
