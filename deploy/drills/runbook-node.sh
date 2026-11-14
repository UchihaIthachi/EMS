#!/usr/bin/env bash
# Runbook drills 15-17 (node/control-plane level). Mac only: uses limactl to reach the VMs.
# 15 kubelet stopped -> node NotReady | 16 CoreDNS at 0 replicas | 17 certificate expiry + renew apiserver cert
# Run:  bash deploy/drills/runbook-node.sh      or  ONLY=16 bash deploy/drills/runbook-node.sh
set -eu
[ "$(uname)" = Darwin ] || { echo "run this on the Mac, not inside a VM"; exit 1; }
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/ems-lab}"
ONLY="${ONLY:-15 16 17}"; D=drill
step() { printf '\n== %s\n' "$*"; }
say()  { printf '   %s\n' "$*"; }
run()  { printf '   $ %s\n' "$*"; eval "$@" 2>&1 | sed 's/^/     /'; }
die()  { printf '\n!! STOPPED: %s\n' "$*"; exit 1; }
want() { case " $ONLY " in *" $1 "*) return 0;; esac; return 1; }
vm()   { limactl shell --workdir / "$1" sudo bash -c "$2"; }
DNSREP=$(kubectl -n kube-system get deploy coredns -o jsonpath='{.spec.replicas}')
cleanup() {
  vm w2 'systemctl is-active -q kubelet || systemctl start kubelet' >/dev/null 2>&1 || true
  [ "$(kubectl -n kube-system get deploy coredns -o jsonpath='{.spec.replicas}' 2>/dev/null)" = "$DNSREP" ] || kubectl -n kube-system scale deploy coredns --replicas="$DNSREP" >/dev/null 2>&1 || true
  kubectl delete ns $D --ignore-not-found --wait=false >/dev/null 2>&1 || true
}
trap cleanup EXIT
[ "$(kubectl get nodes --no-headers | awk '$2=="Ready"' | wc -l | tr -d ' ')" = 3 ] || die "need 3 Ready nodes first"

if want 15; then
step "15. kubelet stopped on lima-w2 -> node NotReady"
vm w2 'systemctl stop kubelet'
say "kubelet stopped; the node controller marks the node after the grace period (~40-50s)"
for i in $(seq 1 24); do kubectl get node lima-w2 --no-headers | grep -q NotReady && break; sleep 5; done
say "SYMPTOM:"; run "kubectl get nodes"
say "DIAGNOSE: conditions say Unknown, 'Kubelet stopped posting node status'; taint added"
run "kubectl describe node lima-w2 | grep -E 'Ready +Unknown|Taints|unreachable' | head -3"
say "pods on it still show their last state; eviction starts after tolerationSeconds 300"
run "kubectl get pods -A -o wide --field-selector spec.nodeName=lima-w2 --no-headers | awk '{print \$1, \$2, \$4}' | head -6"
say "on the node: is kubelet running, and why not?"
run "vm w2 'systemctl is-active kubelet; journalctl -u kubelet --no-pager -n 3 | cut -c1-140'"
say "FIX: start kubelet (and enable it, in case it was disabled)"
vm w2 'systemctl enable --now kubelet' >/dev/null 2>&1
kubectl wait --for=condition=Ready node/lima-w2 --timeout=120s >/dev/null && say "VERIFY: $(kubectl get node lima-w2 --no-headers | awk '{print $1, $2}')" || die "lima-w2 not Ready"
fi

if want 16; then
step "16. CoreDNS scaled to 0"
kubectl create ns $D --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl -n $D run probe --image=busybox:1.36 --restart=Never -- sleep 600 >/dev/null
kubectl -n $D wait --for=condition=Ready pod/probe --timeout=90s >/dev/null
q() { kubectl -n $D exec probe -- timeout 5 nslookup kubernetes.default.svc.cluster.local >/dev/null 2>&1 && echo resolves || echo FAILS; }
say "before: $(q)"
kubectl -n kube-system scale deploy coredns --replicas=0 >/dev/null
kubectl -n kube-system wait --for=delete pod -l k8s-app=kube-dns --timeout=60s >/dev/null 2>&1 || true
say "SYMPTOM: $(q)  (Service IP exists, nobody answers)"
say "DIAGNOSE: the kube-dns Service has no endpoints"
run "kubectl -n kube-system get svc kube-dns"
run "kubectl -n kube-system get endpointslice -l kubernetes.io/service-name=kube-dns"
run "kubectl -n kube-system get deploy coredns"
run "kubectl -n $D exec probe -- cat /etc/resolv.conf | head -2"
say "FIX: scale back to $DNSREP"
kubectl -n kube-system scale deploy coredns --replicas="$DNSREP" >/dev/null
kubectl -n kube-system rollout status deploy/coredns --timeout=120s >/dev/null
sleep 3; r=$(q); say "VERIFY: $r"; [ "$r" = resolves ] || die "DNS still broken"
kubectl delete ns $D --wait=false >/dev/null
fi

if want 17; then
step "17. Certificate expiry: check, renew the apiserver cert, restart the static pod"
run "vm cp1 'kubeadm certs check-expiration' | sed -n '1,/^CERTIFICATE AUTHORITY/p' | grep -E 'CERTIFICATE|apiserver |admin.conf'"
before=$(vm cp1 'openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -enddate')
say "apiserver.crt $before"
run "vm cp1 'openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -ext subjectAltName' | tail -1"
say "RENEW (keeps SANs from the kubeadm-config ClusterConfiguration, incl. 127.0.0.1)"
run "vm cp1 'kubeadm certs renew apiserver'"
say "a static pod only re-reads its cert on restart: move the manifest out and back"
vm cp1 'mv /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/ && sleep 20 && mv /etc/kubernetes/kube-apiserver.yaml /etc/kubernetes/manifests/'
for i in $(seq 1 36); do kubectl get --raw /readyz >/dev/null 2>&1 && break; sleep 5; done
kubectl get --raw /readyz >/dev/null 2>&1 || die "API server not back (check: limactl shell cp1 sudo crictl ps -a | grep apiserver)"
after=$(vm cp1 'openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -enddate')
served=$(echo | openssl s_client -connect 127.0.0.1:6443 2>/dev/null | openssl x509 -noout -enddate)
say "VERIFY: file $after | served by :6443 $served"
[ "$after" = "$served" ] || die "API server still serves the old cert"
say "NOTE: kubelet client certs rotate automatically; admin.conf (your kubeconfig) does not -> check-expiration yearly"
fi

step "Cluster after drills"
run "kubectl get nodes"
run "kubectl -n ems get pods --no-headers | awk '{print \$1, \$2, \$3}'"
printf '\nNODE DRILLS (%s) DONE\n' "$ONLY"
