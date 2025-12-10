# Local Kubernetes Deployment with Minikube & ArgoCD

This guide explains how to run the **Employee Management System (EMS)** locally on **Minikube** using **ArgoCD** for GitOps-style deployment — with **zero cloud cost**.

> ✅ Target: Run the same `deploy/k8s/` manifests locally, with a clean, isolated Minikube cluster.

---

## 1. Prerequisites

Make sure you have:

- **Docker Desktop** (Windows/macOS) or Docker Engine (Linux)
- **kubectl**
- **Minikube**
- **Git**

Recommended resources for the EMS stack (with observability):

- **CPU**: 4 cores
- **RAM**: 8 GB

> If your laptop is tight on RAM, see: [Running a lighter stack](#10-running-a-lighter-stack-without-observability).

---

## 2. Clone the Repository & Checkout `deploy` Branch

```bash
git clone https://github.com/<your-org-or-user>/EMS.git
cd EMS

# Use the deployment branch
git checkout deploy
```

> Replace the repo URL with your actual EMS repository if different.

---

## 3. Use a Dedicated Kubeconfig for Minikube (Avoid Conflicts)

If you also use a cloud cluster (e.g. OCI), keep Minikube **isolated** by using a separate kubeconfig.

### 3.1 Windows (Git Bash)

```bash
export KUBECONFIG=$HOME/.kube/config_minikube
```

### 3.2 PowerShell

```powershell
$env:KUBECONFIG="$HOME\.kube\config_minikube"
```

### 3.3 Linux / macOS

```bash
export KUBECONFIG=$HOME/.kube/config_minikube
```

You can verify later with:

```bash
kubectl config get-contexts
```

You should see a `minikube` context once the cluster is created.

---

## 4. Start Minikube

Start Minikube with enough resources for EMS:

```bash
minikube start --cpus=4 --memory=8192 --driver=docker
```

Verify the cluster:

```bash
minikube status
kubectl get nodes
```

Expected:

- `minikube` node in `Ready` state
- `kubectl` context set to `minikube`

---

## 5. Enable Ingress

The EMS uses an HTTP Ingress (host: `ems.localdev.me`).

```bash
minikube addons enable ingress
```

Check:

```bash
kubectl get pods -n ingress-nginx
```

Wait until all pods are `Running`.

---

## 6. Install ArgoCD

Create the `argocd` namespace and install ArgoCD:

```bash
kubectl create namespace argocd

kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Wait for the ArgoCD server to be ready:

```bash
kubectl wait --for=condition=available --timeout=600s \
  deployment/argocd-server -n argocd
```

---

## 7. Access ArgoCD UI

You have two main ways: **Port-forward** (recommended) or **NodePort**.

### 7.1 Port-forward (recommended)

In a **separate terminal** (with the same `KUBECONFIG`):

```bash
kubectl port-forward svc/argocd-server -n argocd 8081:443
```

Then open:

- **URL**: [https://localhost:8081](https://localhost:8081)
- Accept the browser’s self-signed certificate warning.

#### ArgoCD login

- **Username**: `admin`
- **Password**:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo
```

### 7.2 (Optional) Expose via NodePort

If port-forward is annoying:

```bash
kubectl patch svc argocd-server -n argocd \
  -p '{"spec": {"type": "NodePort"}}'

minikube service argocd-server -n argocd
```

Minikube will open the ArgoCD UI in your browser.

---

## 8. Configure EMS Application in ArgoCD

There are **two ways** to register the EMS app:

### Option A – CLI (using the existing manifest)

If the repo already contains `deploy/argo/ems-app.yaml`:

```bash
kubectl apply -f deploy/argo/ems-app.yaml
```

This manifest should:

- Point **source** to your Git repo / `deploy/k8s` folder.
- Point **destination** to your Minikube cluster + EMS namespace (e.g. `ems-app`).

Then in the ArgoCD UI you’ll see an application tile (e.g. `ems-app`).

---

### Option B – Use ArgoCD UI “New Application”

In the ArgoCD UI:

1. Click **NEW APP**.
2. Fill in the form:

#### GENERAL

- **Application Name**: `ems-app`
- **Project Name**: `default`
- **Sync Policy**: `Manual` (you can change to Auto later)
- (Optional) **Set Deletion Finalizer**: enabled

#### SOURCE

- **Repository URL**:
  `https://github.com/<your-org-or-user>/EMS.git`
- **Revision**: `deploy`
  (or `HEAD` / `main` if you prefer, but this guide assumes `deploy`)
- **Path**:
  `deploy/k8s`

#### DESTINATION

- **Cluster URL**:
  `https://kubernetes.default.svc` (the in-cluster API)
- **Namespace**:
  `ems-app`

> Note: ArgoCD will create the `ems-app` namespace if **Auto-Create Namespace** is enabled.

#### DIRECTORY

- **Directory Recurse**: enabled (so it will pick up all manifests under `deploy/k8s`)

#### SYNC OPTIONS (recommended)

- ✅ Auto-Create Namespace
- ✅ Prune Last
- (Optional) ✅ Apply Out of Sync Only

Click **Create**.

---

## 9. Sync EMS Application & Configure Local DNS

### 9.1 Sync in ArgoCD

1. In the ArgoCD UI, click your `ems-app` tile.
2. Click **Sync** → **Synchronize**.
3. Wait until:

- Most workloads show as **Healthy** & **Synced**.
- It may take a few minutes to pull images (especially the first time).

You can also check from CLI:

```bash
kubectl get pods -n ems-app
kubectl get svc -n ems-app
kubectl get ingress -n ems-app
```

> The namespace may be `ems-app` or whatever you configured as Destination.

---

### 9.2 Configure Hosts Entry for `ems.localdev.me`

The EMS Ingress expects the host: `ems.localdev.me`.

#### A. Start Minikube tunnel (Windows / macOS with Docker driver)

In a **separate terminal**:

```bash
minikube tunnel
```

Keep it running.

#### B. Add hosts entry

**Windows** – edit:

```text
C:\Windows\System32\drivers\etc\hosts
```

Add this line at the end:

```text
127.0.0.1   ems.localdev.me
```

**Linux** / **macOS** – edit `/etc/hosts`:

```text
# DNS override for EMS in Minikube
<MINIKUBE_IP>   ems.localdev.me
```

Find `<MINIKUBE_IP>` with:

```bash
minikube ip
```

---

## 10. Verify the System

Once everything is synced and pods are becoming `Running`:

### 10.1 Core pods status

```bash
kubectl get pods -n ems-app
```

You’re aiming for:

- `api-gateway` – `1/1 Running`
- `employee-service` – `1/1 Running`
- `department-service` – `1/1 Running`
- `config-server` – `1/1 Running`
- `service-registry` – `1/1 Running`
- `mysql-employee`, `mysql-department` – `1/1 Running`
- `rabbitmq` – `1/1 Running`
- `frontend` – `1/1 Running`

(Observability pods like Zipkin, Prometheus, Grafana, Elasticsearch, Kibana, Logstash, Adminer may also be present depending on your manifests.)

### 10.2 Ingress

```bash
kubectl get ingress -n ems-app
```

You should see something like:

```text
NAME   CLASS   HOSTS            ADDRESS   PORTS   AGE
ems    nginx   ems.localdev.me  ...       80      ...
```

> If this is missing, check that your ingress manifest has `namespace: ems-app` or **no namespace** (so ArgoCD applies it to the destination namespace).

### 10.3 Browser checks

With `minikube tunnel` running and `/etc/hosts` updated:

- **EMS Frontend**:
  [http://ems.localdev.me/](http://ems.localdev.me/)

- **API Gateway health**:
  [http://ems.localdev.me/api/actuator/health](http://ems.localdev.me/api/actuator/health)

- **Zipkin** (if enabled and pulling correctly):
  [http://ems.localdev.me/zipkin/](http://ems.localdev.me/zipkin/)

---

## 11. Running a Lighter Stack (Without Observability)

If your laptop struggles with RAM/CPU, you can temporarily **disable heavy observability components**:

- `zipkin`
- `elasticsearch` / `kibana` / `logstash`
- `prometheus` / `grafana`
- `adminer`

### 11.1 Proper way (GitOps-friendly)

Edit the manifests under `deploy/k8s/`:

- Comment out / remove Deployments/StatefulSets/Services for the above components.
- Commit to the `deploy` branch.
- Click **Sync** in ArgoCD.

ArgoCD will then delete those resources and your cluster will only run the **core EMS**.

### 11.2 Quick hack (not GitOps-pure, but fast)

From the CLI:

```bash
kubectl scale deployment zipkin -n ems-app --replicas=0
kubectl scale deployment grafana -n ems-app --replicas=0
kubectl scale deployment kibana -n ems-app --replicas=0
kubectl scale deployment logstash -n ems-app --replicas=0
kubectl scale deployment prometheus -n ems-app --replicas=0

kubectl delete statefulset elasticsearch -n ems-app
kubectl delete deployment adminer -n ems-app
```

ArgoCD will show these as `OutOfSync`, but your **core microservices** will have more breathing room.

---

## 12. Troubleshooting

### 12.1 Check app namespace resources

```bash
kubectl get pods,svc,ingress -n ems-app
kubectl get events -n ems-app --sort-by=.metadata.creationTimestamp
```

Look for:

- `ImagePullBackOff` → network / registry issues
- `CrashLoopBackOff` → application exception (check logs)
- `Pending` with PV errors → storage provisioning issues
- `Unhealthy` / probe failed → readiness or liveness probe failing

### 12.2 Inspect logs

Example: `config-server` and `employee-service` logs:

```bash
kubectl logs deployment/config-server -n ems-app
kubectl logs deployment/employee-service -n ems-app
```

Check for:

- Cannot reach Git config repo
- Cannot connect to MySQL
- Bad profile / wrong config server URL

### 12.3 ArgoCD itself

If the ArgoCD UI doesn’t work:

```bash
kubectl get pods -n argocd
kubectl logs deployment/argocd-server -n argocd
```

Ensure `argocd-server` is `1/1 Running` before relying on port-forward.

---

## 13. Cleanup

To stop Minikube but **keep** the cluster:

```bash
minikube stop
```

To delete the Minikube cluster entirely and free disk space:

```bash
minikube delete --all --purge
```

If you created a dedicated kubeconfig (`config_minikube`) and want to discard it:

```bash
rm $HOME/.kube/config_minikube
```

---

You now have a fully reproducible **local Kubernetes + ArgoCD** deployment flow for the EMS system, with the option to run either the **full** (observability-heavy) stack or a **lightweight core** setup depending on your machine’s resources.

```

```
