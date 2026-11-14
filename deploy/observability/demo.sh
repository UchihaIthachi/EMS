#!/usr/bin/env bash
# Screenshot session: k6 load + Grafana JVM dashboard + one Jaeger trace, opened in the browser.
# Run on the Mac:  bash deploy/observability/demo.sh      (Enter stops everything)
# Needs: metrics.sh and tracing.sh already run (Prometheus, Grafana, Jaeger, agent on).
set -eu
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/ems-lab}"
cd "$(git rev-parse --show-toplevel)"
M=monitoring
die() { printf '\n!! %s\n' "$*"; exit 1; }
kubectl -n $M get svc grafana jaeger >/dev/null 2>&1 || die "Grafana or Jaeger missing: run metrics.sh and tracing.sh first"
command -v k6 >/dev/null || brew install k6

PIDS=
kubectl -n ems port-forward svc/ems 18080:80 >/dev/null 2>&1 & PIDS="$PIDS $!"
kubectl -n $M port-forward svc/grafana 13000:80 >/dev/null 2>&1 & PIDS="$PIDS $!"
kubectl -n $M port-forward svc/jaeger 16686:16686 >/dev/null 2>&1 & PIDS="$PIDS $!"
trap 'kill $PIDS 2>/dev/null || true' EXIT
sleep 4

# One request with our own trace id (see runbook 20)
TID=$(openssl rand -hex 16); SID=$(openssl rand -hex 8)
RP=$(kubectl -n ems get secret mysql -o jsonpath='{.data.root-password}' | base64 --decode)
EMP=$(kubectl -n ems exec mysql-0 -- env MYSQL_PWD="$RP" mysql -uroot -N -e 'SELECT MAX(id) FROM employee_db.employees' 2>/dev/null | tr -d '\r')
curl -s -o /dev/null -H "traceparent: 00-$TID-$SID-01" http://127.0.0.1:18080/api/v1/employee-service/$EMP

# Load for the dashboard (lab-sized profile, ~3 min)
k6 run -q -e PROFILE=drill -e BASE=http://127.0.0.1:18080 loadtest/k6/load.js >/tmp/demo-k6.txt 2>&1 & PIDS="$PIDS $!"

DASH=$(curl -s -u "admin:$(kubectl -n $M get secret grafana -o jsonpath='{.data.admin-password}' | base64 --decode)" \
  'http://127.0.0.1:13000/api/search?query=JVM' | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d[0]["url"] if d else "/dashboards")')
mkdir -p docs/img
cat <<MSG

Grafana login: admin / (kubectl -n $M get secret grafana -o jsonpath='{.data.admin-password}' | base64 --decode)
Opening:
  Grafana  http://127.0.0.1:13000$DASH?from=now-15m&to=now&refresh=10s
  Jaeger   http://127.0.0.1:16686/trace/$TID

Screenshots (k6 is running for ~3 min; wait ~1 min so the graphs move):
  Cmd+Shift+4, then Space, click the browser window  -> saved on the Desktop
  then:  mv ~/Desktop/Screenshot*.png  into  docs/img/grafana.png  and  docs/img/trace.png
MSG
open "http://127.0.0.1:13000$DASH?from=now-15m&to=now&refresh=10s"
open "http://127.0.0.1:16686/trace/$TID"
read -r -p $'\nPress Enter when both screenshots are saved... ' _
ls -la docs/img/ 2>/dev/null
