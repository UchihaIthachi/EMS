#!/usr/bin/env bash
# Observability demo, part 2: Jaeger + the OpenTelemetry Java agent already baked into the images.
# Run on the Mac:  bash deploy/observability/tracing.sh
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

step "4. Traces (the smoke test above made requests; wait for the batch exporter)"
kubectl -n $M port-forward svc/jaeger 16686:16686 >/dev/null 2>&1 & PF=$!; trap 'kill $PF 2>/dev/null || true' EXIT
sleep 15
curl -s http://127.0.0.1:16686/api/services | python3 -c 'import json,sys; print("  services:", sorted(json.load(sys.stdin)["data"] or []))'
ok=0
for i in 1 2 3 4 5 6; do
  r=$(curl -s 'http://127.0.0.1:16686/api/traces?service=api-gateway&limit=50&lookback=1h' | python3 -c '
import json,sys
best=None
for t in json.load(sys.stdin)["data"] or []:
    svcs={p["serviceName"] for p in t["processes"].values()}
    if best is None or len(svcs)>len(best[1]): best=(t,svcs)
if best:
    t,svcs=best
    root=min(t["spans"],key=lambda s:s["startTime"])
    print(len(svcs), t["traceID"], ",".join(sorted(svcs)), len(t["spans"]), root["operationName"].replace("|","/"), round(root["duration"]/1000,1), sep="|")
' 2>/dev/null || true)
  [ -n "$r" ] && [ "${r%%|*}" -ge 3 ] && { ok=1; break; }
  sleep 10
done
[ -n "$r" ] || die "no traces for api-gateway (check: kubectl -n ems logs deploy/api-gateway | grep -i otel)"
IFS='|' read -r n tid svcs spans rootop dur <<< "$r"
echo "  widest trace: $tid"
echo "  services in it ($n): $svcs"
echo "  spans: $spans   root: $rootop   duration: ${dur}ms"
[ "$ok" = 1 ] && echo "  gateway -> employee -> department in ONE trace: ok" || echo "  only $n service(s) in the widest trace so far"

step "5. Headroom after"
kubectl top nodes
kubectl -n ems top pods --no-headers | awk '{print "  "$1, $3}'
cat <<MSG

DONE. Jaeger UI:  kubectl -n $M port-forward svc/jaeger 16686:16686  ->  http://127.0.0.1:16686
Pick service api-gateway, find a POST /api/v1/employee... trace, open it: the Feign call to department-service
and the RabbitMQ publish -> consume hop are child spans. Screenshot it for the README.
MSG
