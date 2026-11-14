#!/usr/bin/env bash
# Upgrade the Lima worker nodes one at a time (run on the Mac, after the control plane is upgraded).
# Usage: bash ~/personal/EMS/deploy/drills/upgrade-workers.sh [package-version]   e.g. 1.37.2-1.1
set -euo pipefail
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/ems-lab}"
V="${1:-1.37.2-1.1}"
MINOR="v$(echo "$V" | cut -d. -f1-2)"
[ "$(uname -s)" = Darwin ] || { echo "Run this on the Mac, not inside a VM."; exit 1; }
kubectl get nodes >/dev/null || { echo "kubectl can't reach the cluster"; exit 1; }
echo "Target kubelet $V (repo $MINOR)"
echo "MySQL/RabbitMQ live on: $(kubectl -n ems get pod mysql-0 rabbitmq-0 -o jsonpath='{range .items[*]}{.metadata.name}={.spec.nodeName} {end}')"
for n in w1 w2; do
  node=lima-$n
  echo; echo "===== $node: drain"
  kubectl drain "$node" --ignore-daemonsets --delete-emptydir-data --timeout=300s
  echo "===== $node: kubeadm upgrade node + kubelet $V"
  limactl shell --workdir / "$n" sudo bash -euc "
    sed -i 's#/v1\.[0-9]*/#/$MINOR/#' /etc/apt/sources.list.d/kubernetes.list
    curl -fsSL https://pkgs.k8s.io/core:/stable:/$MINOR/deb/Release.key | gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    apt-get update -q >/dev/null
    apt-mark unhold kubeadm kubelet kubectl >/dev/null
    apt-get install -y -q kubeadm=$V >/dev/null
    kubeadm upgrade node 2>&1 | tail -2
    apt-get install -y -q kubelet=$V kubectl=$V >/dev/null
    apt-mark hold kubeadm kubelet kubectl >/dev/null
    systemctl daemon-reload
    systemctl restart kubelet
    kubelet --version"
  sleep 15
  kubectl uncordon "$node"
  kubectl wait --for=condition=Ready "node/$node" --timeout=180s
  echo "===== $node: waiting for EMS to be whole again"
  kubectl -n ems rollout status statefulset/mysql --timeout=300s
  kubectl -n ems rollout status statefulset/rabbitmq --timeout=300s
  for d in redis frontend api-gateway employee-service department-service; do
    kubectl -n ems rollout status "deploy/$d" --timeout=300s
  done
done
echo; kubectl get nodes -o wide
