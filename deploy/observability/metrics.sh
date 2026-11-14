#!/usr/bin/env bash
# Observability demo, part 1: Prometheus + Grafana scraping the three Spring services.
# Run on the Mac:  bash deploy/observability/metrics.sh      Remove:  bash deploy/observability/metrics.sh remove
set -eu
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/ems-lab}"
cd "$(git rev-parse --show-toplevel)"
O=deploy/observability; M=monitoring
step() { printf '\n== %s\n' "$*"; }
die()  { printf '\n!! STOPPED: %s\n' "$*"; exit 1; }

if [ "${1:-}" = remove ]; then
  helm -n $M uninstall grafana prometheus 2>/dev/null || true
  kubectl delete ns $M --wait=false; echo "removed (EMS keeps its scrape annotations; harmless)"; exit 0
fi

step "1. Headroom before"
kubectl top nodes

step "2. Prometheus (server only, ~250-400Mi)"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo add grafana-community https://grafana-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update prometheus-community grafana-community >/dev/null
helm upgrade -i prometheus prometheus-community/prometheus -n $M --create-namespace -f $O/prometheus-values.yaml --wait --timeout 5m

step "3. Grafana (~150Mi) with the JVM Micrometer dashboard"
helm upgrade -i grafana grafana-community/grafana -n $M -f $O/grafana-values.yaml \
  --set-file dashboards.default.ems-overview.json=$O/dashboards/ems-overview.json --wait --timeout 5m

step "4. EMS chart: scrape annotations + allow-metrics-scrape NetworkPolicy (rolls the Spring pods)"
bash deploy/lab-deploy.sh
kubectl -n ems get netpol allow-metrics-scrape >/dev/null || die "allow-metrics-scrape missing"

step "5. Targets (wait up to 2 min for the first scrapes)"
kubectl -n $M port-forward svc/prometheus-server 19090:80 >/dev/null 2>&1 & PF=$!; trap 'kill $PF 2>/dev/null || true' EXIT
sleep 4; up=0
for i in $(seq 1 12); do
  up=$(curl -s 'http://127.0.0.1:19090/api/v1/query' --data-urlencode 'query=count(up{app_kubernetes_io_part_of="ems"}==1)' | sed -n 's/.*"value":\[[^,]*,"\([0-9]*\)".*/\1/p')
  [ "${up:-0}" -ge 3 ] && break; sleep 10
done
curl -s 'http://127.0.0.1:19090/api/v1/query' --data-urlencode 'query=up{app_kubernetes_io_part_of="ems"}' \
  | grep -o '"app_kubernetes_io_name":"[^"]*"\|"value":\[[^]]*\]' | paste - - | sed 's/^/  /'
[ "${up:-0}" -ge 3 ] || die "fewer than 3 EMS targets up (check: kubectl -n ems describe netpol allow-metrics-scrape)"
echo "  $up EMS targets up"
for q in 'sum by (app_kubernetes_io_name) (jvm_memory_used_bytes{area="heap",app_kubernetes_io_part_of="ems"})/1024/1024' \
         'sum by (app_kubernetes_io_name) (rate(http_server_requests_seconds_count{app_kubernetes_io_part_of="ems"}[5m]))'; do
  echo "  query: $q"
  curl -s 'http://127.0.0.1:19090/api/v1/query' --data-urlencode "query=$q" | grep -o '"app_kubernetes_io_name":"[^"]*"\|"value":\[[^]]*\]' | paste - - | sed 's/^/    /'
done

step "6. Headroom after"
kubectl top nodes
kubectl -n $M top pods 2>/dev/null || true

PW=$(kubectl -n $M get secret grafana -o jsonpath='{.data.admin-password}' | base64 --decode)
cat <<MSG

DONE. Grafana:  kubectl -n $M port-forward svc/grafana 13000:80   ->  http://127.0.0.1:13000  (admin / password below)
Dashboard: EMS folder -> "JVM (Micrometer)". Run the k6 load test in another terminal to see it move.
Grafana admin password (also in Secret $M/grafana): $PW
MSG
