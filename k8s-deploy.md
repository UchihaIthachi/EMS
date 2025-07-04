# Kubernetes Deployment Guide

This guide provides comprehensive instructions for deploying the Employee Management System (EMS) to a Kubernetes cluster. It covers the CI/CD pipeline, Docker image management with GitHub Container Registry (GHCR), manual deployment steps, and GitOps deployment using ArgoCD.

## Deployment Overview

The deployment process involves the following key stages:

1.  **CI/CD Pipeline**: Automates building, testing, and packaging the application.
2.  **Docker Image Management**: Builds Docker images for each service and pushes them to GitHub Container Registry (GHCR).
3.  **Kubernetes Manifests**: Applying Kubernetes YAML configurations to deploy services, databases, and other components.
4.  **GitOps with ArgoCD**: (Recommended) Using ArgoCD to continuously synchronize the application state in Kubernetes with the manifests defined in a Git repository.

## Prerequisites for Kubernetes Deployment

*   **Kubernetes Cluster**: Access to a Kubernetes cluster (e.g., Oracle Kubernetes Engine (OKE), Minikube, kind, GKE, EKS, AKS).
*   **`kubectl` CLI**: Installed and configured to communicate with your cluster.
*   **Docker**: For building images locally if not solely relying on CI/CD.
*   **Git**: For version control and interacting with the repository.
*   **(Optional) Helm**: If you decide to package manifests as Helm charts in the future.
*   **(Optional) ArgoCD CLI**: For interacting with ArgoCD if used.

## CI/CD Pipeline

The project includes a `Jenkinsfile` that defines a CI/CD pipeline to automate the build, test, and deployment process.

### Pipeline Stages

1.  **Checkout**: Fetches the latest source code from the Git repository.
2.  **Build, Publish & Push All Services (Parallel Stage)**:
    *   **For each Java Microservice** (e.g., `department-service`, `api-gateway`):
        *   **Build & Test**: Compiles the application and runs tests (e.g., `./mvnw clean package`).
        *   **Publish to Nexus**: (Optional) Publishes JAR artifacts to a Nexus repository.
        *   **Build Docker Image**: Builds a Docker image using the service's `Dockerfile`.
        *   **Push Docker Image to GHCR**: Pushes the tagged image to GitHub Container Registry.
    *   **For the `frontend` service**:
        *   **Build**: Transpiles and bundles frontend assets (e.g., `npm install && npm run build`).
        *   **Build Docker Image**: Builds the frontend Docker image.
        *   **Push Docker Image to GHCR**: Pushes the tagged image to GitHub Container Registry.
3.  **Deploy to Kubernetes**:
    *   Applies the Kubernetes manifests from the `deploy/k8s/` directory using `kubectl apply`. This stage is typically used if not employing GitOps with ArgoCD for the final deployment step, or for deploying to a development/staging environment directly from Jenkins.

### Local CI/CD Environment
For testing the CI/CD pipeline locally, a `docker-compose-cicd.yml` file is provided to spin up Jenkins, Nexus, and a local Docker Registry. Refer to `local-deploy.md` for setup details.

## Docker Image Management with GitHub Container Registry (GHCR)

All custom service images should be stored in a container registry accessible by your Kubernetes cluster. GitHub Container Registry (GHCR) is a good option.

### Image Naming and Tagging
Images are tagged by the CI/CD pipeline with:
*   A unique build number: `ghcr.io/YOUR_GITHUB_USERNAME/ems-<service-name>:<build-number>`
*   A `latest` tag: `ghcr.io/YOUR_GITHUB_USERNAME/ems-<service-name>:latest`

Replace `YOUR_GITHUB_USERNAME` with your actual GitHub username or organization name.

### CI/CD Configuration for GHCR

In your Jenkins (or other CI/CD system) configuration:
1.  **Set Docker Registry URL**:
    *   `DOCKER_REGISTRY_URL` environment variable should be set to `ghcr.io/YOUR_GITHUB_USERNAME`.
2.  **Configure Credentials for GHCR**:
    *   Create a Personal Access Token (PAT) on GitHub with `write:packages` scope.
    *   Store this PAT as a secret credential in Jenkins (e.g., with ID `GHCR_TOKEN`).
    *   The `Jenkinsfile` uses `DOCKER_CREDENTIALS_ID` to refer to these credentials. The `docker.withRegistry()` step will use these to log in to GHCR.

### Kubernetes Manifest Configuration for GHCR
Your Kubernetes deployment YAML files (`deploy/k8s/deployments/*.yaml`, `deploy/k8s/statefulsets/*.yaml`) must reference these images.
*   Update the `image:` fields to point to your GHCR path, e.g.:
    ```yaml
    spec:
      template:
        spec:
          containers:
            - name: api-gateway
              image: ghcr.io/YOUR_GITHUB_USERNAME/ems-api-gateway:latest
              imagePullPolicy: Always # Recommended for :latest tags
    ```
*   Ensure your Kubernetes cluster is configured to pull images from GHCR. If your GHCR packages are private, you'll need to create an `imagePullSecret` in Kubernetes and attach it to your service accounts or Pods. For public packages, this is usually not necessary.

## Manual Kubernetes Deployment Steps

These steps describe how to deploy the application to Kubernetes manually using `kubectl`. This is useful for initial setup, testing, or environments without ArgoCD.

1.  **Start Minikube (for local testing)**:
    If testing locally, start Minikube with sufficient resources:
    ```bash
    minikube start --cpus 4 --memory 8192
    minikube addons enable ingress # Enable Nginx ingress controller
    ```

2.  **Ensure Images are Accessible**:
    Your Kubernetes cluster must be able to pull the Docker images from GHCR (or your chosen registry). Update image paths in all relevant YAML files in `deploy/k8s/` as described above.

3.  **Apply Kubernetes Manifests**:
    The manifests are located in `deploy/k8s/` and organized by resource type.
    *   **Using `k8s-deploy.sh` script (Recommended for manual application)**:
        The `k8s-deploy.sh` script in the project root helps apply or delete resources in a logical order.
        ```bash
        chmod +x k8s-deploy.sh

        # Apply all resources
        ./k8s-deploy.sh apply

        # Check status
        ./k8s-deploy.sh status
        ```
        Refer to `./k8s-deploy.sh help` for more options.

    *   **Applying manually by type (if not using script)**:
        Apply manifests in a logical order to respect dependencies:
        ```bash
        # 1. Namespace
        kubectl apply -f deploy/k8s/base/00-namespace.yaml

        # 2. ConfigMaps and Secrets (Populate actual secret values first!)
        kubectl apply -f deploy/k8s/configmaps/
        kubectl apply -f deploy/k8s/secrets/ # Ensure secrets are properly configured

        # 3. PersistentVolumeClaims (if any standalone)
        kubectl apply -f deploy/k8s/pvcs/

        # 4. Headless Services (for StatefulSets)
        kubectl apply -f deploy/k8s/headless-services/

        # 5. Services (ClusterIP, NodePort, LoadBalancer)
        kubectl apply -f deploy/k8s/services/

        # 6. StatefulSets (Databases, RabbitMQ, Elasticsearch)
        kubectl apply -f deploy/k8s/statefulsets/

        # 7. Deployments (Application services, tools)
        kubectl apply -f deploy/k8s/deployments/

        # 8. Ingress
        kubectl apply -f deploy/k8s/ingress/ingress.yaml
        ```

4.  **Verify Deployments**:
    Check the status of pods in the `ems-app` namespace:
    ```bash
    kubectl get pods -n ems-app -w
    ```
    Wait for all pods to be in the `Running` or `Completed` state. Use `kubectl logs <pod-name> -n ems-app` and `kubectl describe pod <pod-name> -n ems-app` for troubleshooting.

5.  **Accessing Services**:
    *   If using Minikube and Ingress:
        ```bash
        minikube ip
        ```
        Add `<minikube-ip> ems.localdev.me` to your `/etc/hosts` file.
        Access via: `http://ems.localdev.me/` (Frontend), `http://ems.localdev.me/api/` (API Gateway), etc. as per `deploy/k8s/ingress/ingress.yaml`.
    *   For cloud deployments, the Ingress controller (if type `LoadBalancer`) will provision an external IP. Configure your DNS accordingly.

## GitOps with ArgoCD

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. It allows you to define your application's desired state in Git (using Kubernetes manifests) and ArgoCD ensures that the live state in the cluster matches this desired state.

### ArgoCD Application Manifest (`deploy/argo/ems-app.yaml`)

The project includes an ArgoCD Application manifest:
```yaml
# deploy/argo/ems-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ems-app
  namespace: argocd # Deployed into argocd namespace
spec:
  project: default # ArgoCD project
  source:
    repoURL: https://github.com/UchihaIthachi/EMS # YOUR Git repository URL
    targetRevision: HEAD # Branch or tag to sync from
    path: deploy/k8s     # Path within the repo containing K8s manifests
    directory:
      recurse: true      # Process subdirectories
  destination:
    server: https://kubernetes.default.svc # Target K8s cluster API
    namespace: ems-app                     # Target namespace for EMS app
  syncPolicy:
    automated:
      selfHeal: true # Automatically sync if live state deviates from Git
      prune: true    # Delete resources from cluster if removed from Git
```
**Note**: Update `repoURL` to point to your forked repository if necessary.

### Setting up ArgoCD

1.  **Install ArgoCD**: Follow the [ArgoCD documentation](https://argo-cd.readthedocs.io/en/stable/getting_started/) to install ArgoCD in your Kubernetes cluster. This typically involves applying a manifest:
    ```bash
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    ```
2.  **Access ArgoCD UI**: Follow instructions to access the ArgoCD UI, often via port-forwarding or an Ingress. Get the initial admin password.
3.  **Configure Repository Access (if private)**: If your Git repository is private, configure repository credentials in ArgoCD.

### Deploying EMS via ArgoCD

1.  **Apply the Application Manifest**:
    Once ArgoCD is running, apply the `ems-app.yaml` manifest to your cluster (where ArgoCD is installed):
    ```bash
    kubectl apply -f deploy/argo/ems-app.yaml
    ```
    This tells ArgoCD to start managing the EMS application.

2.  **Monitor Sync Status**:
    *   Use the ArgoCD UI to view the `ems-app` application.
    *   You can see the sync status, health status of Kubernetes resources, and logs.
    *   ArgoCD will automatically detect the manifests in `deploy/k8s` and apply them to the `ems-app` namespace in your cluster.

### ArgoCD Sync Policy Explained

*   **`automated`**:
    *   **`selfHeal: true`**: If there's any drift between the live state in the cluster and the state defined in Git (e.g., someone manually changes a resource), ArgoCD will automatically revert the changes to match Git.
    *   **`prune: true`**: If you remove a manifest from the `deploy/k8s` directory in Git, ArgoCD will automatically delete the corresponding resource from the Kubernetes cluster.
*   **Manual Sync**: If you prefer manual control, you can disable the `automated` policy and trigger syncs manually through the ArgoCD UI or CLI.

### GitOps Workflow

1.  Make changes to your application code or Kubernetes manifests in your Git repository.
2.  Push changes to the `targetRevision` branch (e.g., `main` or `HEAD`).
3.  If using automated sync, ArgoCD will detect these changes and automatically apply them to your Kubernetes cluster.
4.  Monitor the deployment progress and health via the ArgoCD UI.

This GitOps approach provides a robust, auditable, and automated way to manage your Kubernetes deployments.
