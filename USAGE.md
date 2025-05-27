## 0. Local CI/CD Environment Setup (Optional)

For developers wanting to test the CI/CD pipeline locally, a Docker Compose file is provided to spin up Jenkins, Nexus, and a local Docker Registry.

**File:** `docker-compose-cicd.yml` (in the project root)

**Services:**
- **Jenkins:** Accessible at http://localhost:8080. Docker socket is mounted, allowing Jenkins to build Docker images. Persistent data in `jenkins_home` volume.
- **Nexus:** Accessible at http://localhost:8081. Persistent data in `nexus_data` volume.
- **Local Docker Registry:** Runs on port 5000. Accessible as `localhost:5000`. Persistent data in `local_registry_data` volume.

The Jenkins pipeline defined in `Jenkinsfile` (see details in `ci-cd.md`) is designed to integrate with such a local CI/CD setup and includes a stage to deploy the application to Kubernetes.

**To run:**
```bash
docker-compose -f docker-compose-cicd.yml up -d
```

**Initial Setup:**
- **Jenkins:**
    - Unlock Jenkins using the initial admin password: `docker exec local-jenkins cat /var/jenkins_home/secrets/initialAdminPassword`
    - Install suggested plugins or choose specific ones (Pipeline, Git, Docker Pipeline, etc.).
    - Configure agent (if needed), JDK, Maven.
    - Configure credentials for Nexus and your Docker registry (e.g., Docker Hub or `localhost:5000` if using the local one).
- **Nexus:**
    - Sign in (default admin/admin123, then change password).
    - Configure blob stores and repositories (e.g., a `maven-releases` hosted repository).
- **Local Docker Registry:**
    - To use `localhost:5000` with Docker, you might need to configure your Docker daemon to trust this insecure registry. See Docker documentation for "insecure-registries".
    - Minikube also needs to be able to access this registry if you intend to push images here for K8s deployment. (e.g., `minikube ssh -- 'echo "{\"insecure-registries\" : [\"$(minikube ip):5000\"]}" | sudo tee /etc/docker/daemon.json && sudo systemctl restart docker'`)

**Stopping CI/CD services:**
```bash
docker-compose -f docker-compose-cicd.yml down
```
---
# Usage Guide

This document provides instructions for deploying and running the Employee Management System (EMS) application locally using Docker Compose and on a Minikube Kubernetes cluster.

---
## Further Documentation

For more detailed information on specific aspects of this project, please refer to the following documents:

*   [`architecture-components.md`](./architecture-components.md): Detailed explanation of `config-server`, `api-gateway`, and `service-registry`.
*   [`architecture-diagrams.md`](./architecture-diagrams.md): Visual architecture diagrams for different deployment environments.
*   [`ci-cd.md`](./ci-cd.md): Overview of the Jenkins CI/CD pipeline, Nexus, and Docker Registry integration.
*   [`service-discovery.md`](./service-discovery.md): Explanation of the switchable service discovery mechanism (Eureka for local, Kubernetes DNS for K8s).
*   [`circuit-breaker-pattern.md`](./circuit-breaker-pattern.md): Information on the Circuit Breaker pattern and its potential application.

---

## 1. Local Deployment (Docker Compose)

This project uses Docker Compose for local development and testing. The services are defined in `deploy/docker-compose.yml`.

**Note on Service Discovery:** When running services with this default Docker Compose setup (`docker-compose up -d`), the Java microservices are configured to use **Netflix Eureka** for service discovery (via the `local-eureka` Spring profile activated by `SPRING_PROFILES_ACTIVE=local-eureka` in `deploy/docker-compose.yml`). The `service-registry` container acts as the Eureka server.

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

### Fast Development Loop (Using Local JARs)

For faster local development of Java microservices, you can build JARs locally and have Docker Compose run them directly, bypassing the Docker image build step for each change.

**Prerequisites:**
- Java Development Kit (JDK) and Maven installed locally for building JARs.

**How it Works:**
- The `deploy/docker-compose.dev.yml` override file is provided. When used with `deploy/docker-compose.yml`, it:
    - Mounts your local `service-name/target/` directory (where the JAR is built) into the respective service container at `/app/local-jar/`.
    - Changes the container's command to run the JAR found in this mounted directory.
- Service discovery between microservices in this mode will also use **Netflix Eureka**, as the base `deploy/docker-compose.yml` (which sets the `local-eureka` profile) is still active. The primary purpose of this mode is to run locally compiled JARs quickly.

**Option 1: Manual Steps**
1.  **Build a specific Java microservice:**
    Navigate to the service's directory (e.g., `cd department-service`) and run:
    ```bash
    ./mvnw clean package -DskipTests 
    ```
    (Using `-DskipTests` speeds up the build for local dev iterations).
2.  **Run services with the development override:**
    In the `deploy/` directory, run:
    ```bash
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d [service-name...]
    ```
    Replace `[service-name...]` with the services you want to start. If you omit service names, all services defined in these files will start.
    You can also use profiles with this setup:
    ```bash
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml --profile logging up -d
    ```

**Option 2: Using `local-dev.sh` Script**
A helper script `local-dev.sh` (in the project root) automates this process. Ensure it's executable (`chmod +x local-dev.sh`).

*   **Build services:**
    ```bash
    ./local-dev.sh build                    # Build all Java services
    ./local-dev.sh build <service-name>     # Build a specific Java service (e.g., api-gateway)
    ```
*   **Start services (using local JARs):**
    ```bash
    ./local-dev.sh up -d                    # Start all services in detached mode
    ./local-dev.sh up <service-name>        # Start specific service(s)
    ./local-dev.sh up --profile logging -d  # Start with profiles
    ```
*   **Stop services:**
    ```bash
    ./local-dev.sh down
    ```
*   **View logs:**
    ```bash
    ./local-dev.sh logs <service-name>      # Follow logs for a service
    ./local-dev.sh logs                     # Follow logs for all services
    ```
*   **View running services:**
    ```bash
    ./local-dev.sh ps
    ```
*   **Help:**
    ```bash
    ./local-dev.sh help
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
    *   **Image Source and CI/CD Integration:**
        The Kubernetes manifests are designed to work with images built and pushed by the Jenkins CI/CD pipeline (see `Jenkinsfile` and `ci-cd.md`).
        - The pipeline tags images with both a unique build number (e.g., `yourdockerregistry/service-name:build-123`) and a static `latest` tag (e.g., `yourdockerregistry/service-name:latest`). Both are pushed to the configured Docker registry.
        - The Kubernetes YAML files in `deploy/k8s/deployments/` and `deploy/k8s/statefulsets/` for custom-built services are configured to use the `:latest` tag (e.g., `image: yourdockerregistry/api-gateway:latest`) and have `imagePullPolicy: Always` set.
        - **Action Required:** Before deploying to Kubernetes (manually or allowing Jenkins to deploy), you **must** update the placeholder `yourdockerregistry/` prefix in the `image:` fields within these YAML files to your actual Docker registry URL/username that Jenkins uses.
        - If you are not using the Jenkins pipeline to build and push images, you will need to ensure that images with the correct names and `:latest` tag are available in your Minikube environment or chosen registry, and that the `yourdockerregistry/` prefix in the YAMLs is updated accordingly.
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

#### Using the `k8s-deploy.sh` Script (Recommended for Automation)

As an alternative to applying manifests manually by type, you can use the `k8s-deploy.sh` script located in the project root. This script helps apply or delete resources in the correct order. Ensure it's executable (`chmod +x k8s-deploy.sh`).

*   **Apply all resources:**
    ```bash
    ./k8s-deploy.sh apply
    ```
*   **Apply specific categories (e.g., configmaps then secrets then deployments):**
    ```bash
    ./k8s-deploy.sh apply configmaps secrets deployments
    ```
*   **Delete all resources (namespace `ems-app` itself is not deleted by default):**
    ```bash
    ./k8s-deploy.sh delete
    ```
*   **Delete specific categories:**
    ```bash
    ./k8s-deploy.sh delete deployments ingress
    ```
*   **Delete the namespace `ems-app` (use with caution):**
    ```bash
    ./k8s-deploy.sh delete namespace 
    ```
*   **Check status of deployed resources:**
    ```bash
    ./k8s-deploy.sh status
    ```
*   **Help:**
    ```bash
    ./k8s-deploy.sh help
    ```
Using this script can simplify the deployment process and reduce the chance of errors from applying manifests in an incorrect order.

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
