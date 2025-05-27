# CI/CD Pipeline

This document describes the Continuous Integration/Continuous Deployment (CI/CD) pipeline setup for the Employee Management System (EMS) application. The pipeline is defined in the `Jenkinsfile` located in the project root.

## Overview

The CI/CD pipeline automates the following key processes:
1.  **Source Code Checkout:** Fetches the latest code from the Git repository.
2.  **Build & Test:** Compiles the Java microservices and frontend application, and runs unit tests (tests are currently skipped in `local-dev.sh` builds for speed, but the main pipeline should ideally run them).
3.  **Artifact Publishing (Nexus):** Publishes build artifacts (e.g., JAR files for Java microservices) to a Nexus repository manager.
4.  **Docker Image Building:** Builds Docker images for each microservice and the frontend using their respective `Dockerfile`s.
5.  **Docker Image Pushing:** Pushes the built Docker images to a configured Docker registry (e.g., Docker Hub or a private registry).
6.  **Deployment:** The `Jenkinsfile` includes a stage for deploying the application to Kubernetes using `kubectl apply`.

## Jenkinsfile Structure

The `Jenkinsfile` uses a declarative pipeline syntax.

**Key Stages:**

*   **`agent any`**: Specifies that the pipeline can run on any available Jenkins agent. For specific requirements, this can be changed to a label for agents equipped with necessary tools (JDK, Maven, Node.js, Docker).
*   **`environment` block**:
    *   Defines placeholder environment variables for:
        *   `NEXUS_URL`: URL of the Nexus repository.
        *   `NEXUS_CREDENTIALS_ID`: Jenkins credential ID for authenticating with Nexus.
        *   `DOCKER_REGISTRY_URL`: URL of the Docker registry (e.g., Docker Hub username or private registry address).
        *   `DOCKER_CREDENTIALS_ID`: Jenkins credential ID for authenticating with the Docker registry.
    *   These variables should be configured within the Jenkins environment or job configuration.
*   **`Checkout` stage**: Clones the source code from the repository.
*   **`Build, Publish & Push All Services` stage**: This is a parallel stage that processes all microservices and the frontend simultaneously to improve efficiency.
    *   **For each Java Microservice** (e.g., `department-service`, `employee-service`, etc.):
        *   `Build & Test`: Executes `./mvnw clean package` within the service's directory to compile and package the application.
        *   `Publish to Nexus`: (Currently simulated with an `echo` statement). In a full setup, this stage would use Maven to deploy the JAR to Nexus. This requires the `pom.xml` of each service to have a `<distributionManagement>` section and Jenkins to be configured with a `settings.xml` for Nexus authentication (using `NEXUS_CREDENTIALS_ID`).
        *   `Build Docker Image`: Builds a Docker image using the service's `Dockerfile`. The image is tagged with both a unique build number (e.g., `${env.DOCKER_REGISTRY_URL}/<service-name>:${env.BUILD_NUMBER}`) and a static `latest` tag (e.g., `${env.DOCKER_REGISTRY_URL}/<service-name>:latest`).
        *   `Push Docker Image`: Pushes both the build-number-tagged and `latest`-tagged Docker images to the configured registry using `docker.withRegistry` for secure credential handling.
    *   **For the `frontend` service:**
        *   `Build`: Executes `npm install` and `npm run build` to prepare the frontend assets.
        *   `Build Docker Image`: Builds the frontend Docker image, tagged with both the build number and `latest`.
        *   `Push Docker Image`: Pushes both tagged frontend Docker images.
*   **`Deploy to Kubernetes` stage**:
    *   This stage applies the Kubernetes manifests from the `deploy/k8s/` subdirectories in a specific order (namespace, configmaps, secrets, pvcs, headless-services, services, statefulsets, deployments, ingress).
    *   It logs the current `kubectl` context and checks pod status in the `ems-app` namespace after applying manifests.
    *   This stage requires `kubectl` to be configured on the Jenkins agent with access to the target Kubernetes cluster.

## Nexus Integration (Artifact Management)

*   **Purpose:** Nexus is used to store and manage build artifacts (primarily JAR files for Java microservices). This allows for versioning, sharing, and reliable retrieval of dependencies and built applications.
*   **Jenkins Interaction:**
    *   The `Jenkinsfile` has a placeholder stage for publishing to Nexus.
    *   To fully enable Nexus publishing:
        1.  Each Java microservice's `pom.xml` needs a `<distributionManagement>` section pointing to the Nexus repository URL.
        2.  A `settings.xml` file needs to be configured in Jenkins (or provided to Maven builds) containing server credentials for Nexus, using the `NEXUS_CREDENTIALS_ID`.
        3.  The `sh './mvnw deploy ...'` command would then be used.
*   **Local Nexus Instance:** The `docker-compose-cicd.yml` file allows running a local Nexus instance for testing this integration. See `USAGE.md` for setup.

## Docker Registry Integration (Image Management)

*   **Purpose:** A Docker registry (like Docker Hub, a cloud provider's registry, or the local registry from `docker-compose-cicd.yml`) is used to store and distribute the Docker images built by the pipeline.
*   **Jenkins Interaction:**
    *   The `Jenkinsfile` uses `docker build` to create images and `docker push` (via `docker.withRegistry`) to upload them.
    *   The image is tagged with both a unique build number (e.g., `${env.DOCKER_REGISTRY_URL}/<service-name>:${env.BUILD_NUMBER}`) and a static `latest` tag (e.g., `${env.DOCKER_REGISTRY_URL}/<service-name>:latest`). Both tags are pushed to the registry.
    *   The `DOCKER_REGISTRY_URL` environment variable in Jenkins should be set to the target registry (e.g., your Docker Hub username, or `localhost:5000` if using the local registry from `docker-compose-cicd.yml`).
    *   The `DOCKER_CREDENTIALS_ID` environment variable in Jenkins should point to credentials configured in Jenkins for accessing this registry.
*   **Kubernetes Consumption:** The Kubernetes deployment manifests (`deploy/k8s/**/*.yaml`) are configured to use the `<service-name>:latest` tag for these images (e.g., `yourdockerregistry/api-gateway:latest`) and have `imagePullPolicy: Always` set. This ensures that Kubernetes always pulls the most recent image pushed as `:latest` by the CI/CD pipeline.

## Local CI/CD Environment (`docker-compose-cicd.yml`)

To facilitate local testing of the full CI/CD flow, the `docker-compose-cicd.yml` file is provided in the project root. This allows you to run local instances of:
-   Jenkins
-   Nexus
-   A Docker Registry

Refer to `USAGE.md` for instructions on setting up and using this local CI/CD environment. This is highly recommended for developing and testing the `Jenkinsfile` and integration points.

### Executing Docker Commands with Local Jenkins
The local Jenkins instance started via `docker-compose-cicd.yml` is able to execute `docker` commands (like `docker build` and `docker push`) because the host's Docker socket (`/var/run/docker.sock`) is mounted into the Jenkins container. This setup, often called Docker-outside-of-Docker (DooD), allows the Docker CLI within the Jenkins container to control the Docker daemon running on your host machine.
```
