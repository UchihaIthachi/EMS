#!/usr/bin/env bash
# Section D check: render both Kustomize overlays and diff the lab one against what Helm deployed.
# Changes nothing on the cluster (kubectl diff is a server-side dry run).
# Run on the Mac:  bash deploy/kustomize/verify.sh
set -eu
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/ems-lab}"
cd "$(git rev-parse --show-toplevel)"
[ "$(basename "$PWD")" = EMS ] || { echo "!! not in the EMS repo"; exit 1; }
K=deploy/kustomize
R="kubectl kustomize --enable-helm --load-restrictor=LoadRestrictionsNone"
step() { printf '\n== %s\n' "$*"; }

step "1. secrets.env (git-ignored)"
if [ ! -f $K/base/secrets.env ]; then
  get() { kubectl -n ems get secret "$1" -o jsonpath="{.data.$2}" | base64 --decode; }
  umask 077
  {
    echo "MYSQL_ROOT_PASSWORD=$(get mysql root-password)"
    echo "MYSQL_EMPLOYEE_PASSWORD=$(get mysql employee-password)"
    echo "MYSQL_DEPARTMENT_PASSWORD=$(get mysql department-password)"
    echo "RABBITMQ_PASSWORD=$(get rabbitmq password)"
    echo "RABBITMQ_AMQP_URI=$(get rabbitmq amqp-uri)"
  } > $K/base/secrets.env
  echo "created from the live Secrets (so the diff below is about structure, not passwords)"
else
  echo "exists, using it"
fi
git check-ignore -q $K/base/secrets.env && echo "git ignores it: ok" || { echo "!! secrets.env is NOT ignored"; exit 1; }

step "2. Render lab overlay"
$R $K/overlays/lab > /tmp/ems-lab.yaml
grep -c '^kind:' /tmp/ems-lab.yaml | sed 's/^/objects: /'
grep '^kind:' /tmp/ems-lab.yaml | sort | uniq -c
grep -q 'name: mysql$' /tmp/ems-lab.yaml && echo "Secrets present (from secretGenerator)"
grep 'image: ghcr' /tmp/ems-lab.yaml | sort -u

step "3. kubectl diff lab vs the live (Helm) state"
set +e
kubectl diff -f /tmp/ems-lab.yaml > /tmp/ems-lab.diff 2>&1; rc=$?
set -e
case $rc in
  0) echo "NO DIFFERENCES: Kustomize renders exactly what Helm deployed";;
  1) echo "differences (review):"; grep -E '^[-+] ' /tmp/ems-lab.diff | grep -vE 'generation:|resourceVersion|managedFields' | head -40
     echo "(full diff: /tmp/ems-lab.diff)";;
  *) echo "!! kubectl diff failed:"; tail -20 /tmp/ems-lab.diff; exit 1;;
esac

step "4. Render full overlay and spot-check"
$R $K/overlays/full > /tmp/ems-full.yaml
grep -c '^kind:' /tmp/ems-full.yaml | sed 's/^/objects: /'
kubectl apply --dry-run=server -f /tmp/ems-full.yaml >/dev/null && echo "server dry-run accepts it: ok"
python3 - <<'PY' || grep -nE '^kind: (HorizontalPodAutoscaler|ScaledObject|ResourceQuota)|replicas:|minReplica|maxReplica|requests.memory|limits.memory' /tmp/ems-full.yaml
import yaml  # PyYAML; if missing, the grep fallback prints the same facts
docs=[d for d in yaml.safe_load_all(open('/tmp/ems-full.yaml')) if d]
for d in docs:
    k,n=d['kind'],d['metadata']['name']
    if k=='Deployment':
        c=d['spec']['template']['spec']['containers'][0]
        print(f"  Deployment {n:20} replicas={d['spec'].get('replicas','-')} memLimit={c.get('resources',{}).get('limits',{}).get('memory')}")
    elif k=='HorizontalPodAutoscaler': print(f"  HPA {n}: {d['spec']['minReplicas']}-{d['spec']['maxReplicas']}")
    elif k=='ScaledObject': print(f"  ScaledObject {n}: {d['spec']['minReplicaCount']}-{d['spec']['maxReplicaCount']}")
    elif k=='ResourceQuota': print(f"  Quota {n}: {d['spec']['hard']}")
PY
printf '\nSECTION D CHECK DONE (nothing was applied).\n'
