# Runbook

Twenty-two incidents from moving EMS onto a kubeadm cluster. Incidents 1–8 and 18–22 happened for real during the work. Incidents 9–17 are drills: the scripts break something on purpose, show the symptom, then diagnose, fix and verify it.

| Script | Incidents |
|---|---|
| `deploy/drills/runbook-app.sh` (`ONLY=11` for one) | 9–14 |
| `deploy/drills/runbook-node.sh` (Mac only, uses `limactl`) | 15–17 |
| `deploy/drills/section-e.sh` | NetworkPolicy, circuit breaker, HPA/KEDA, PDB drain |
| `deploy/drills/upgrade-workers.sh`, `deploy/drills/rbac-users.sh` | upgrade, RBAC |

Each row reads **symptom → cause → fix**.

## Application and configuration

| # | Incident |
|---|---|
| 1 | **Old manifests on Kubernetes:** Eureka and config-server pods crash-loop, and the apps print no logs → logback sent everything to Logstash, and the services needed a config server that needed a Git token → removed Eureka and config-server, plain console logs |
| 2 | **Event never published:** `Failed to convert Message content`, while the HTTP request still returned 201 → `Instant` field without the Java time module in the AMQP converter → use Boot's `ObjectMapper` in `Jackson2JsonMessageConverter`. Publishing is best-effort by design, so the request kept succeeding |
| 3 | **`GET department` returns 500 `NonUniqueResultException`** → two `ENG` rows → unique `department_code`, 409 on duplicate, cleanup SQL. Employee GET stayed 200 because the circuit-breaker fallback kicked in |
| 4 | **Stats never move and `rabbitmqctl list_queues` is empty** → lazy initialization meant the `@RabbitListener` and RabbitAdmin beans were never created → lazy init off |
| 19 | **Tracing switched on → all three new JVM pods `CrashLoopBackOff`, exit 1, `Error opening zip file ... /otel/opentelemetry-javaagent.jar`;** old pods kept serving → `ADD --chmod=644` also gave the missing parent `/otel` mode 644, so the non-root user could not enter it (`drw-r--r--`) → `RUN mkdir -p /otel` before the `ADD`. Also: `kubectl logs deploy/X` printed the *healthy old* pod; read the failing pod with `--previous` |
| 20 | **Trace search shows only health checks** → kubelet probes every 5 s are traced too and fill the newest-N search results → send a request with your own W3C `traceparent` and fetch that trace by ID. In Jaeger v2, `/api/v3` is the query API; the old `/api/services` returns 404 |
| 22 | **Grafana JVM dashboard (grafana.com 4701): every panel "No data"**, while Prometheus had the metrics → the dashboard filters on an `application` label the services didn't set, and its datasource is a `${DS_PROMETHEUS}` placeholder → `MANAGEMENT_METRICS_TAGS_APPLICATION` per service, map the placeholder, and build our own dashboard whose queries were checked against Prometheus first |

## Workloads and scheduling

| # | Incident |
|---|---|
| 9 | **Wrong image tag:** the new pod shows `ImagePullBackOff` (`not found` in events), and the old pod keeps serving because `maxUnavailable: 0` → `kubectl rollout undo` |
| 10 | **Readiness path wrong:** pod `Running` but `0/1`, 404 in probe events, EndpointSlice shows `ready=false` → `rollout undo` |
| 12 | **PVC `Pending`:** `storageclass "fast-ssd" not found`. `storageClassName` can't be changed → recreate on `local-path`. `WaitForFirstConsumer` keeps it `Pending` until a pod mounts it, which is normal |
| 13 | **Quota `pods=2` and the Deployment stuck at 2/3:** the error is only on the ReplicaSet (`exceeded quota`). Even after the quota was raised it stayed 2/3: the controller was waiting longer between retries after the failures, and a quota change doesn't wake it up → annotate the ReplicaSet to make it try again |
| 5 | **`keda-operator` `CrashLoopBackOff` after an etcd restore** (`context canceled`) → the API server was unavailable while it started → delete the pod to reset the back-off |
| 6 | **Drain refused:** pods use an `emptyDir` for `/tmp` → `--delete-emptydir-data`. Also: busybox `nslookup` with short names is misleading → use the full name (FQDN) |
| 21 | **`ImagePullBackOff` on a new api-gateway pod**, although the image existed on GHCR and the node had no disk or memory pressure → a transient pull failure. The kubelet retried with back-off and the next pull succeeded. Read the pod events for the real error (`describe pod`) before changing tags or pruning images |

## Networking and DNS

| # | Incident |
|---|---|
| 11 | **DNS NetworkPolicy port typo (5353):** `nslookup` fails from a test pod → `kubectl get netpol -o jsonpath='{.spec.egress[0].ports}'` → restore 53 (the chart is the source of truth) |
| 14 | **Service selector typo:** EndpointSlice empty, yet department GET stays 200 with no Redis errors → the Redis client's existing TCP connection survives the endpoint removal, and only new connections fail. A broken Service can look healthy until pods restart |
| 16 | **CoreDNS scaled to 0:** `nslookup` fails; the `kube-dns` Service (10.96.0.10) still exists but its EndpointSlice is empty → scale back |

## Cluster and nodes

| # | Incident |
|---|---|
| 15 | **kubelet stopped on a worker:** `NotReady`, `Ready Unknown` "Kubelet stopped posting node status", `unreachable` taints. Pods still listed `Running`, because the containers keep running and eviction only starts after 300 s → `journalctl -u kubelet` → `systemctl enable --now kubelet` |
| 17 | **Certificate expiry:** `kubeadm certs check-expiration` → `kubeadm certs renew apiserver` → the file is renewed, but `:6443` keeps serving the old cert until the static pod restarts → move the manifest out of `/etc/kubernetes/manifests` and back → the served `notAfter` matches the file |
| 7 | **Pod Security `restricted` rejects the Gateway proxy** (no seccomp profile). kgateway creates that pod, not the chart → `GatewayParameters` `podTemplate.securityContext.seccompProfile`. Label with `--dry-run=server` first, then enforce, then delete the pod to prove it gets admitted |

## Tooling

| # | Incident |
|---|---|
| 8 | **Kustomize overlay put every chart object in `default`.** `kubectl diff` showed brand-new objects, each with a `uid` → kubectl 1.37 embeds kustomize v5.8.1, which no longer adds `namespace:` to `helmCharts` output ([kustomize#6058](https://github.com/kubernetes-sigs/kustomize/issues/6058)) → the chart sets `namespace: {{ $.Release.Namespace }}` (`$`, because `.` is rebound inside `range`), and `verify.sh` checks the namespace. Diff before you apply |
| 18 | **Helm 4 upgrade fails with `conflict with "kubectl" ... .image`** → Helm 4 uses server-side apply, and the drills' `kubectl set image` and `patch` made kubectl the owner of those fields → `helm upgrade --force-conflicts` in `lab-deploy.sh`. Don't hand-edit Helm-managed objects, or reclaim the fields on purpose |
