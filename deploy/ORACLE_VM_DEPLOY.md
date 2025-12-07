# Deploying EMS on Oracle VM with ArgoCD

This guide provides step-by-step instructions to deploy the Employee Management System (EMS) on a single Oracle Cloud Infrastructure (OCI) Compute Instance (VM) using K3s (a lightweight Kubernetes distribution) and ArgoCD.

## Prerequisites

1.  **Oracle VM Instance**:

    - **OS**: Oracle Linux 8/9 or Ubuntu 20.04/22.04.
    - **Shape**: `VM.Standard.E2.1.Micro` (Free Tier) might be too small. Recommended: `VM.Standard.A1.Flex` (ARM, 4 OCPUs, 24GB RAM - Free Tier eligible) or `VM.Standard2.2` (x86).
    - **Public IP**: Ensure the instance has a public IP address.
    - **SSH Key**: You must have the private key to SSH into the VM.

2.  **Network Security Group / Security List**:
    You need to open the following ports in your Oracle Cloud VCN Security List (Ingress Rules):
    - `22` (SSH) - Already open.
    - `80` (HTTP) - For the application Ingress.
    - `443` (HTTPS) - For the application Ingress (optional but recommended).
    - `6443` (Kubernetes API) - Only if you want to access `kubectl` from your local machine (restrict source IP).
    - `8080` (ArgoCD UI / API Gateway) - Optional, if you expose them via NodePort or port-forward.

## Step 1: Prepare the VM

SSH into your Oracle VM:

```bash
ssh -i /path/to/your/key opc@<VM_PUBLIC_IP>
# Or 'ubuntu@' if using Ubuntu image
```

### 1.1 Update System

```bash
sudo dnf update -y  # Oracle Linux
# sudo apt update && sudo apt upgrade -y # Ubuntu
```

### 1.2 Configure Firewall (Firewalld / IPTables)

Oracle Linux uses `firewalld` by default. You need to allow traffic.

```bash
# Allow necessary ports
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=6443/tcp # K3s API

# For Flannel/CNI (Internal K8s networking)
sudo firewall-cmd --permanent --zone=trusted --add-source=10.42.0.0/16 # Pods
sudo firewall-cmd --permanent --zone=trusted --add-source=10.43.0.0/16 # Services

sudo firewall-cmd --reload
```

_Note: If you encounter networking issues between pods, you might need to temporarily disable firewalld for testing: `sudo systemctl stop firewalld`._

## Step 2: Install K3s (Lightweight Kubernetes)

K3s is perfect for single-node deployments.

```bash
curl -sfL https://get.k3s.io | sh -
```

Check the status:

```bash
sudo kubectl get nodes
```

It should show one node in `Ready` status.

### 2.1 Access kubectl as non-root

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
echo "export KUBECONFIG=~/.kube/config" >> ~/.bashrc
source ~/.bashrc
```

## Step 3: Install ArgoCD

1.  **Create Namespace**:

    ```bash
    kubectl create namespace argocd
    ```

2.  **Install ArgoCD Manifests**:

    ```bash
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    ```

3.  **Watch Installation**:

    ```bash
    kubectl get pods -n argocd -w
    ```

    Wait until all pods are `Running`.

4.  **Expose ArgoCD Server**:
    By default, ArgoCD server is not exposed externally.

    _Option A: Patch to NodePort (Access via <VM_IP>:30080)_

    ```bash
    kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"port": 443, "targetPort": 8080, "nodePort": 30080}]}}'
    ```

    _Note: You need to open port 30080 in OCI Security List if you do this._

    _Option B: Port Forwarding (Secure)_
    Run this on your **local machine** (not the VM):

    ```bash
    ssh -i /path/to/key -L 8080:localhost:8080 opc@<VM_PUBLIC_IP>
    # Then on the VM:
    kubectl port-forward svc/argocd-server -n argocd 8080:443
    ```

    Now access `https://localhost:8080` on your local browser.

5.  **Get Admin Password**:
    ```bash
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
    ```
    User is `admin`.

## Step 4: Configure EMS Deployment

**IMPORTANT REVIEW NOTES**: Before deploying, you must address the following configuration items in this repository.

1.  **Fork the Repository**:
    ArgoCD needs to track _your_ changes. Fork `https://github.com/UchihaIthachi/EMS` to your GitHub account.

2.  **Edit `deploy/argo/ems-app.yaml`**:
    Update the `repoURL` to your forked repository URL.

    ```yaml
    repoURL: https://github.com/<YOUR_USERNAME>/EMS
    ```

3.  **Edit `deploy/k8s/ingress/ingress.yaml`**:
    Change the host from `ems.localdev.me` to your VM's public IP or a domain pointing to it (e.g., `<VM_IP>.nip.io`).

    ```yaml
    host: ems.<YOUR_VM_IP>.nip.io
    ```

4.  **Edit Secrets (`deploy/k8s/secrets/`)**:
    The provided secrets use default credentials (base64 of `mysql`, etc.). For security, generate new base64 values and update these files.

5.  **API Gateway Configuration**:
    The `api-gateway` expects routes to be defined in the Configuration Server repo. Ensure your config repo has the necessary `api-gateway.yml` or properties with routes pointing to the k8s service DNS names (e.g. `lb://department-service`).

## Step 5: Deploy the Application

Once you have pushed your changes to your fork:

1.  **Apply the ArgoCD Application**:

    ```bash
    kubectl apply -f deploy/argo/ems-app.yaml
    ```

    _Note: If you haven't forked and just want to test, you can apply it as is, but you won't be able to easily change the ingress host._

2.  **Monitor Deployment**:
    Login to ArgoCD UI or check via kubectl:
    ```bash
    kubectl get pods -n ems-app -w
    ```

## Step 6: Verify Access

Once deployment is synced and healthy:

1.  **Frontend**: Open `http://ems.<YOUR_VM_IP>.nip.io` (or whatever host you configured).
2.  **API Gateway**: `http://ems.<YOUR_VM_IP>.nip.io/api/`
3.  **Monitoring**:
    - Zipkin: `http://ems.<YOUR_VM_IP>.nip.io/zipkin/`
    - Grafana: `http://ems.<YOUR_VM_IP>.nip.io/grafana/`

## Troubleshooting

- **Pods Pending?** Check `kubectl describe pod <pod-name> -n ems-app`. It might be resource limits (CPU/Memory). If using a small VM, you may need to reduce resource requests in `deploy/k8s/deployments/*.yaml`.
- **Ingress 404?** Ensure your Host header matches the Ingress rule. `ems.localdev.me` only works if you map it in `/etc/hosts` or if you used a magic domain like `nip.io`.
- **Database Connection Failed?** Check logs of service pods. Ensure the `mysql` statefulsets are running and the secrets are correct.
