# Usage Guide

This document provides instructions for deploying and running the Employee Management System (EMS) application locally using Docker Compose and on a Minikube Kubernetes cluster.

## 1. Local Deployment (Docker Compose)

This project uses Docker Compose for local development and testing. The services are defined in `deploy/docker-compose.yml`.

### Prerequisites
- Docker Desktop installed and running.
- A `.env` file created in the `deploy/` directory (you can copy `deploy/.env.Example` and populate the values, especially for `MYSQL_ROOT_PASSWORD` and `GIT_PAT`).

### Running Services
1.  **Start Core Services:**
    Open a terminal in the `deploy/` directory and run:
    ```bash
    docker-compose up -d
    ```
    This will start all core microservices, databases, RabbitMQ, Zipkin, and the frontend.

2.  **Optional Services (Logging & Monitoring):**
    The logging stack (Elasticsearch, Logstash, Kibana) and monitoring stack (Prometheus, Grafana) are managed by Docker Compose profiles.
    *   To start the **logging stack**:
        ```bash
        docker-compose --profile logging up -d
        ```
    *   To start the **monitoring stack**:
        ```bash
        docker-compose --profile monitoring up -d
        ```
    *   To start both:
        ```bash
        docker-compose --profile logging --profile monitoring up -d
        ```
    *   To start all services including optional ones:
        ```bash
        docker-compose --profile "*" up -d
        ```

3.  **Accessing Services (Default Ports on localhost):**
    *   **Frontend:** http://localhost:3001
    *   **API Gateway (if accessed directly):** http://localhost:8080
    *   **Adminer (Database Management):** http://localhost:8085
    *   **RabbitMQ Management:** http://localhost:15672 (guest/guest)
    *   **Zipkin (Tracing):** http://localhost:9411
    *   **Kibana (Logging UI):** http://localhost:5601 (if `logging` profile is active)
    *   **Grafana (Monitoring UI):** http://localhost:3000 (if `monitoring` profile is active)
    *   **Prometheus:** http://localhost:9090 (if `monitoring` profile is active)

4.  **Stopping Services:**
    ```bash
    docker-compose down
    ```
    To stop services including specific profiles:
    ```bash
    docker-compose --profile logging --profile monitoring down
    ```

## 2. Kubernetes Deployment (Minikube)

This section describes how to deploy the application to a local Minikube Kubernetes cluster. The Kubernetes manifests are located in the `deploy/k8s/` directory, organized into subdirectories by resource type.

### Prerequisites
- **Minikube:** Installed (refer to [Minikube installation guide](https://minikube.sigs.k8s.io/docs/start/)).
- **kubectl:** Installed and configured to interact with Minikube.
- **Docker CLI:** (Optional, for image management if using Minikube's Docker daemon).
- **(Optional) Helm:** If you choose to package these manifests as a Helm chart later.

### Setup Steps

1.  **Start Minikube:**
    Ensure Minikube is running with sufficient resources (e.g., 4 CPUs, 8GB RAM is a good start):
    ```bash
    minikube start --cpus 4 --memory 8192
    ```

2.  **Enable Ingress Controller:**
    The provided Ingress resource (`deploy/k8s/ingress/ingress.yaml`) relies on an Ingress controller. Enable the Nginx Ingress controller in Minikube:
    ```bash
    minikube addons enable ingress
    ```
    Verify it's running:
    ```bash
    kubectl get pods -n ingress-nginx
    ```

3.  **Docker Images:**
    The Kubernetes manifests reference Docker images like `your-docker-registry/service-name:latest`. You need to ensure your Minikube cluster can access these images.
    *   **Using a Public Registry (e.g., Docker Hub):**
        - The Jenkins pipeline (see `Jenkinsfile`) should be configured to push images to your chosen registry (e.g., `yourdockerhubusername/service-name:tag`).
        - Update the `image:` fields in all `Deployment` and `StatefulSet` YAML files within `deploy/k8s/deployments/` and `deploy/k8s/statefulsets/` to point to your actual image path and tag. For example, change `your-docker-registry/api-gateway:latest` to `yourdockerhubusername/api-gateway:some-tag`.
    *   **Using Minikube's Internal Docker Registry:**
        - You can build images directly into Minikube's Docker daemon:
          ```bash
          # Point your local Docker client to Minikube's Docker daemon
          eval $(minikube -p minikube docker-env)
          # Then, from each service directory (e.g., api-gateway/):
          # docker build -t your-docker-registry/api-gateway:latest .
          # Or, more simply, use a consistent name like api-gateway:latest
          # docker build -t api-gateway:latest .
          ```
        - If you use simple names like `api-gateway:latest`, ensure `imagePullPolicy: IfNotPresent` or `Never` is set in the Kubernetes Deployment YAMLs so it uses the local image. The current manifests mostly default to `IfNotPresent` implicitly if no tag or `:latest` is used.
    *   **Loading Images into Minikube:**
        Alternatively, build images locally and then load them into Minikube:
        ```bash
        # Build your image locally first (e.g., docker build -t my-api-gateway:latest api-gateway/)
        minikube image load my-api-gateway:latest
        ```
        Then update the YAMLs to use `my-api-gateway:latest` and set `imagePullPolicy: IfNotPresent` or `Never`.

4.  **Apply Kubernetes Manifests:**
    The manifests are organized by type. Apply them in a logical order:
    ```bash
    # 1. Namespace
    kubectl apply -f deploy/k8s/00-namespace.yaml

    # 2. ConfigMaps and Secrets (Secrets are placeholders, populate them first if needed)
    kubectl apply -f deploy/k8s/configmaps/
    kubectl apply -f deploy/k8s/secrets/

    # 3. PersistentVolumeClaims (standalone ones)
    kubectl apply -f deploy/k8s/pvcs/

    # 4. Headless Services (for StatefulSets)
    kubectl apply -f deploy/k8s/headless-services/

    # 5. Services (ClusterIP services for Deployments and StatefulSets)
    kubectl apply -f deploy/k8s/services/

    # 6. StatefulSets (Databases, RabbitMQ, Elasticsearch)
    kubectl apply -f deploy/k8s/statefulsets/

    # 7. Deployments (Application services, tools, other stack components)
    kubectl apply -f deploy/k8s/deployments/

    # 8. Ingress
    kubectl apply -f deploy/k8s/ingress/ingress.yaml
    ```
    Alternatively, to apply everything (ensure order if there are strict dependencies not handled by K8s itself, though the above order is generally good):
    ```bash
    kubectl apply -R -f deploy/k8s/
    ```
    The `-R` or `--recursive` flag applies files in subdirectories. However, applying by type gives more control over the initial creation order.

5.  **Verify Deployments:**
    Check the status of pods in the `ems-app` namespace:
    ```bash
    kubectl get pods -n ems-app
    ```
    Wait for all pods to be in the `Running` state. You can check logs using `kubectl logs <pod-name> -n ems-app`.

### Accessing Services in Minikube

1.  **Get Minikube IP:**
    ```bash
    minikube ip
    ```
    This will be your `<minikube-ip>`.

2.  **Configure /etc/hosts (or equivalent for your OS):**
    The Ingress resource is configured with the hostname `ems.localdev.me`. To access services using this hostname, add an entry to your local `hosts` file:
    ```
    <minikube-ip> ems.localdev.me
    ```

3.  **Access Endpoints:**
    *   **Frontend:** http://ems.localdev.me/
    *   **API Gateway (via Ingress):** http://ems.localdev.me/api/
    *   **Grafana:** http://ems.localdev.me/grafana/
    *   **Kibana:** http://ems.localdev.me/kibana/
    *   **Zipkin:** http://ems.localdev.me/zipkin/
    *   **Adminer:** http://ems.localdev.me/adminer/

    If you need to access a service that is not exposed via Ingress or uses a `NodePort` (not configured in current manifests), you can use `minikube service <service-name> -n ems-app` or `kubectl port-forward`.

### Troubleshooting
- Use `kubectl describe pod <pod-name> -n ems-app` to get details if a pod is not starting.
- Use `kubectl logs <pod-name> -n ems-app` to view container logs.
- For Ingress issues, check logs of the Nginx Ingress controller pods: `kubectl logs -n ingress-nginx <ingress-nginx-pod-name>`.

---
This guide provides a starting point for deploying and managing the EMS application.
