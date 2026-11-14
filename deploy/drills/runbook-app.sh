#!/usr/bin/env bash
# Runbook drills 9-14 (application/namespace level). Each: break -> symptom -> diagnose -> fix -> verify.
# Every break is undone by the drill itself (and by the EXIT trap if you Ctrl-C).
# Run on the Mac:  bash deploy/drills/runbook-app.sh        (all)   |   ONLY=11 bash ...   (one)
set -eu
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/ems-lab}"
NS=ems; D=drill; ONLY="${ONLY:-9 10 11 12 13 14}"
step() { printf '\n== %s\n' "$*"; }
say()  { printf '   %s\n' "$*"; }
run()  { printf '   $ %s\n' "$*"; eval "$@" 2>&1 | sed 's/^/     /'; }
die()  { printf '\n!! STOPPED: %s\n' "$*"; exit 1; }
want() { case " $ONLY " in *" $1 "*) return 0;; esac; return 1; }
PF=
cleanup() {
  [ -n "$PF" ] && kill $PF 2>/dev/null || true
  kubectl -n $NS patch netpol allow-dns-egress --type=json -p '[{"op":"replace","path":"/spec/egress/0/ports","value":[{"protocol":"UDP","port":53},{"protocol":"TCP","port":53}]}]' >/dev/null 2>&1 || true
  kubectl -n $NS patch svc redis -p '{"spec":{"selector":{"app.kubernetes.io/name":"redis"}}}' >/dev/null 2>&1 || true
  kubectl -n $NS delete pod dnsprobe --ignore-not-found --wait=false >/dev/null 2>&1 || true
  kubectl delete ns $D --ignore-not-found --wait=false >/dev/null 2>&1 || true
}
trap cleanup EXIT

kubectl -n $NS get deploy >/dev/null || die "cluster not reachable"
kubectl create ns $D --dry-run=client -o yaml | kubectl apply -f - >/dev/null

if want 9; then
step "9. Wrong image tag (frontend)"
kubectl -n $NS set image deploy/frontend nginx=ghcr.io/uchihaithachi/ems-frontend:does-not-exist >/dev/null
sleep 25
say "SYMPTOM: rollout never finishes"
run "kubectl -n $NS rollout status deploy/frontend --timeout=5s || true"
run "kubectl -n $NS get pods -l app.kubernetes.io/name=frontend"
say "DIAGNOSE: events on the new pod"
p=$(kubectl -n $NS get pods -l app.kubernetes.io/name=frontend --no-headers | awk '$3!="Running"{print $1; exit}')
run "kubectl -n $NS describe pod $p | sed -n '/^Events:/,\$p' | grep -E 'Failed|BackOff' | head -3"
say "NOTE: old pod still serves (maxUnavailable 0) -> no outage"
say "FIX: kubectl rollout undo"
run "kubectl -n $NS rollout undo deploy/frontend"
kubectl -n $NS rollout status deploy/frontend --timeout=120s >/dev/null && say "VERIFY: rollout complete" || die "frontend did not recover"
fi

if want 10; then
step "10. Readiness probe failing (employee-service)"
kubectl -n $NS patch deploy employee-service --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/actuator/health/nope"}]' >/dev/null
say "waiting ~90s for the JVM to start and fail readiness"
sleep 90
say "SYMPTOM: pod Running but 0/1, rollout stuck"
run "kubectl -n $NS get pods -l app.kubernetes.io/name=employee-service"
say "DIAGNOSE: probe events + the Service's EndpointSlice excludes the not-ready pod"
p=$(kubectl -n $NS get pods -l app.kubernetes.io/name=employee-service --no-headers | awk '{split($2,a,"/"); if(a[1]!=a[2]){print $1; exit}}')
run "kubectl -n $NS describe pod $p | grep -E 'Readiness probe failed' | tail -1"
run "kubectl -n $NS get endpointslice -l kubernetes.io/service-name=employee-service -o jsonpath='{range .items[*].endpoints[*]}{.targetRef.name} ready={.conditions.ready}{\"\\n\"}{end}'"
say "FIX: rollout undo"
run "kubectl -n $NS rollout undo deploy/employee-service"
kubectl -n $NS rollout status deploy/employee-service --timeout=240s >/dev/null && say "VERIFY: rollout complete" || die "employee-service did not recover"
fi

if want 11; then
step "11. NetworkPolicy blocks DNS (port typo 53 -> 5353)"
kubectl -n $NS apply -f - >/dev/null <<'Y'
apiVersion: v1
kind: Pod
metadata: { name: dnsprobe, labels: { app: dnsprobe } }
spec:
  securityContext: { runAsNonRoot: true, runAsUser: 65534, seccompProfile: { type: RuntimeDefault } }
  containers:
  - name: c
    image: busybox:1.36
    command: [sleep, "3600"]
    securityContext: { allowPrivilegeEscalation: false, capabilities: { drop: [ALL] } }
    resources: { requests: { cpu: 10m, memory: 16Mi }, limits: { memory: 32Mi } }
Y
kubectl -n $NS wait --for=condition=Ready pod/dnsprobe --timeout=90s >/dev/null
q() { kubectl -n $NS exec dnsprobe -- timeout 5 nslookup mysql.ems.svc.cluster.local >/dev/null 2>&1 && echo resolves || echo FAILS; }
say "before: mysql.ems.svc.cluster.local $(q)"
kubectl -n $NS patch netpol allow-dns-egress --type=json -p '[{"op":"replace","path":"/spec/egress/0/ports","value":[{"protocol":"UDP","port":5353},{"protocol":"TCP","port":5353}]}]' >/dev/null
sleep 3
say "SYMPTOM: after the change: $(q)  (apps see UnknownHostException on new connections)"
say "DIAGNOSE: which policies select the pod, and what egress they allow"
run "kubectl -n $NS get netpol"
run "kubectl -n $NS get netpol allow-dns-egress -o jsonpath='{.spec.egress[0].ports}{\"\\n\"}'"
say "FIX: restore port 53 (in real life: helm upgrade, the chart is the source of truth)"
kubectl -n $NS patch netpol allow-dns-egress --type=json -p '[{"op":"replace","path":"/spec/egress/0/ports","value":[{"protocol":"UDP","port":53},{"protocol":"TCP","port":53}]}]' >/dev/null
sleep 3
r=$(q); say "VERIFY: $r"; [ "$r" = resolves ] || die "DNS still broken"
kubectl -n $NS delete pod dnsprobe --wait=false >/dev/null
fi

if want 12; then
step "12. PVC Pending (StorageClass that doesn't exist)"
kubectl -n $D apply -f - >/dev/null <<'Y'
apiVersion: v1
kind: PersistentVolumeClaim
metadata: { name: data }
spec: { storageClassName: fast-ssd, accessModes: [ReadWriteOnce], resources: { requests: { storage: 50Mi } } }
Y
sleep 3
say "SYMPTOM:"; run "kubectl -n $D get pvc data"
say "DIAGNOSE:"; run "kubectl -n $D describe pvc data | sed -n '/^Events:/,\$p' | tail -2"; run "kubectl get storageclass"
say "FIX: storageClassName is immutable -> delete and recreate with local-path"
kubectl -n $D delete pvc data --wait=true >/dev/null
kubectl -n $D apply -f - >/dev/null <<'Y'
apiVersion: v1
kind: PersistentVolumeClaim
metadata: { name: data }
spec: { storageClassName: local-path, accessModes: [ReadWriteOnce], resources: { requests: { storage: 50Mi } } }
---
apiVersion: v1
kind: Pod
metadata: { name: user }
spec:
  containers: [{ name: c, image: busybox:1.36, command: [sleep, "600"], volumeMounts: [{ name: d, mountPath: /d }] }]
  volumes: [{ name: d, persistentVolumeClaim: { claimName: data } }]
Y
say "NOTE: local-path is WaitForFirstConsumer -> Pending is normal until a pod uses it"
kubectl -n $D wait --for=jsonpath='{.status.phase}'=Bound pvc/data --timeout=120s >/dev/null && say "VERIFY: $(kubectl -n $D get pvc data --no-headers | awk '{print $1, $2, $3}')" || die "PVC not Bound"
fi

if want 13; then
step "13. ResourceQuota exceeded (pods)"
kubectl -n $D delete pod user --ignore-not-found --wait=true >/dev/null
kubectl -n $D create quota tiny --hard=pods=2 >/dev/null
kubectl -n $D create deployment web --image=busybox:1.36 --replicas=3 -- sleep 3600 >/dev/null
sleep 10
say "SYMPTOM: deployment wants 3, has 2, no failing pod to look at"
run "kubectl -n $D get deploy web"
say "DIAGNOSE: the error is on the ReplicaSet, not on a pod"
run "kubectl -n $D describe rs -l app=web | grep -m1 'exceeded quota'"
run "kubectl -n $D describe quota tiny | tail -2"
say "FIX: raise the quota (or lower replicas / requests)"
kubectl -n $D patch quota tiny -p '{"spec":{"hard":{"pods":"5"}}}' >/dev/null
if ! kubectl -n $D rollout status deploy/web --timeout=30s >/dev/null 2>&1; then
  say "STILL 2/3 after raising the quota: the ReplicaSet controller is in rate-limited back-off"
  say "after the failed creates, and a quota change is not an event on the ReplicaSet."
  say "It would retry by itself later; nudge it by touching the ReplicaSet:"
  run "kubectl -n $D annotate rs -l app=web drill/nudge=\$(date +%s) --overwrite"
fi
kubectl -n $D rollout status deploy/web --timeout=90s >/dev/null && say "VERIFY: $(kubectl -n $D get deploy web --no-headers | awk '{print $1, $2}')" || die "web not 3/3"
fi

if want 14; then
step "14. Service selector typo (redis) -> empty EndpointSlice"
kubectl -n $NS port-forward svc/ems 18080:80 >/dev/null 2>&1 & PF=$!; sleep 3
code() { curl -g -s -o /dev/null -w '%{http_code}' --max-time 10 http://127.0.0.1:18080/api/v1/department-controller/ENG; }
kubectl -n $NS patch svc redis -p '{"spec":{"selector":{"app.kubernetes.io/name":"redis-typo"}}}' >/dev/null
sleep 2
say "SYMPTOM: GET department -> HTTP $(code) (cache is fail-open, so it still works but every read hits MySQL)"
say "DIAGNOSE: Service has no endpoints; selector doesn't match the pod labels"
run "kubectl -n $NS get endpointslice -l kubernetes.io/service-name=redis"
run "kubectl -n $NS get svc redis -o jsonpath='{.spec.selector}'"
run "kubectl -n $NS get pods -l app.kubernetes.io/name=redis --show-labels | cut -c1-120"
run "kubectl -n $NS logs deploy/department-service --since=1m | grep -iE 'redis|cache' | tail -2"
say "FIX: correct the selector"
kubectl -n $NS patch svc redis -p '{"spec":{"selector":{"app.kubernetes.io/name":"redis"}}}' >/dev/null
sleep 2
n=$(kubectl -n $NS get endpointslice -l kubernetes.io/service-name=redis -o jsonpath='{.items[*].endpoints[*].targetRef.name}')
say "VERIFY: endpoints=$n, GET -> HTTP $(code)"; [ -n "$n" ] || die "redis still has no endpoints"
kill $PF 2>/dev/null; PF=
fi

step "Cleanup"
kubectl delete ns $D --wait=false >/dev/null
run "kubectl -n $NS get deploy"
printf '\nRUNBOOK DRILLS (%s) DONE\n' "$ONLY"
