# Local Deployment Guide

This guide provides detailed instructions for deploying and running the Employee Management System (EMS) application locally using Docker Compose.

## Prerequisites

Before you begin, ensure you have the following installed on your system:

*   **Docker Desktop**: For running Docker containers and Docker Compose.
*   **Java Development Kit (JDK)**: Version 11 or newer (required if you plan to use the Fast Development Loop for Java services).
*   **Apache Maven**: For building Java projects (required for the Fast Development Loop).
*   **Git**: For cloning the repository.
*   **(Optional) MySQL Client**: For directly interacting with the databases if needed.

## Environment Configuration (`.env` file)

The local Docker Compose setup requires an `.env` file for sensitive or environment-specific configurations.

1.  **Navigate to the `deploy/` directory** in the project.
2.  **Create a `.env` file**: You can do this by copying the provided example file:
    ```bash
    cp .env.Example .env
    ```
3.  **Edit the `.env` file** and provide necessary values. Key variables to check:
    *   `MYSQL_ROOT_PASSWORD`: The root password for the MySQL database instances. **Set a strong password.**
    *   `GIT_USERNAME`: Your Git username (required by Config Server if fetching from a private repo).
    *   `GIT_PAT`: Your Git Personal Access Token with read access to the configuration repository (e.g., `https://github.com/dulaaann/CONFIG-REPO.git`). This is crucial for the `config-server` to fetch configurations.
    *   `CONFIG_REPO_URI`: The URI of your Spring Cloud Config Server's Git repository. Defaults to `https://github.com/dulaaann/CONFIG-REPO.git`.
    *   `RABBITMQ_DEFAULT_USER` & `RABBITMQ_DEFAULT_PASS`: Credentials for RabbitMQ (default to `guest`/`guest` if not set, but overriding is good practice).
    *   Other variables like service ports can usually be left as default unless you have port conflicts.

## Standard Local Deployment (Using Docker Images)

This method builds Docker images for each custom service (if not already built) and runs them.

1.  **Clone the Repository**:
    ```bash
    git clone <repository-url>
    cd <repository-name>
    ```

2.  **Navigate to the Deployment Directory**:
    ```bash
    cd deploy/
    ```

3.  **Start Core Services**:
    To start all core microservices, databases, RabbitMQ, Zipkin, and the frontend:
    ```bash
    docker-compose up -d
    ```
    The `-d` flag runs the containers in detached mode.

4.  **Optional Services (Logging & Monitoring)**:
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

5.  **Accessing Services**:
    Once the services are up and running, you can access them via your browser or API tools at the following default `localhost` ports:
    *   **Frontend UI**: [http://localhost:3001](http://localhost:3001)
    *   **API Gateway** (if accessing directly): [http://localhost:8080/api/](http://localhost:8080/api/)
    *   **Service Registry (Eureka)**: [http://localhost:8761](http://localhost:8761)
    *   **Config Server**: [http://localhost:8888](http://localhost:8888) (e.g., [http://localhost:8888/api-gateway/default](http://localhost:8888/api-gateway/default))
    *   **Adminer** (Database Management UI): [http://localhost:8085](http://localhost:8085)
    *   **RabbitMQ Management Console**: [http://localhost:15672](http://localhost:15672) (default user/pass from `.env` or `guest`/`guest`)
    *   **Zipkin** (Distributed Tracing): [http://localhost:9411](http://localhost:9411)
    *   **Kibana** (Logging UI): [http://localhost:5601](http://localhost:5601) (if `logging` profile is active)
    *   **Grafana** (Monitoring UI): [http://localhost:3000](http://localhost:3000) (if `monitoring` profile is active)
    *   **Prometheus**: [http://localhost:9090](http://localhost:9090) (if `monitoring` profile is active)

6.  **Viewing Logs**:
    To view logs for all running services:
    ```bash
    docker-compose logs -f
    ```
    To view logs for a specific service:
    ```bash
    docker-compose logs -f <service-name>
    # e.g., docker-compose logs -f department-service
    ```

7.  **Stopping Services**:
    To stop all services defined in `docker-compose.yml` (and remove containers):
    ```bash
    docker-compose down
    ```
    If you started services with profiles, include those profiles when stopping:
    ```bash
    docker-compose --profile logging --profile monitoring down
    ```
    To stop without removing containers (so they can be started again quickly):
    ```bash
    docker-compose stop
    ```

## Fast Development Loop (Using Local JARs)

For faster local development of Java microservices, you can build JARs locally and have Docker Compose run them directly. This bypasses the Docker image build step for each code change in a Java service.

**How it Works**:
*   The `deploy/docker-compose.dev.yml` override file is used.
*   It mounts your local `service-name/target/` directory (where the JAR is built) into the respective service container.
*   The container's command is changed to run the JAR from this mounted directory.
*   Service discovery still uses Netflix Eureka as per the base `docker-compose.yml`.

**Option 1: Manual Steps**
1.  **Build a specific Java microservice**:
    Navigate to the service's directory (e.g., `cd ../department-service`) and run:
    ```bash
    ./mvnw clean package -DskipTests
    ```
    (Using `-DskipTests` speeds up the build for local dev iterations).
2.  **Run services with the development override**:
    In the `deploy/` directory, run:
    ```bash
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d [service-name...]
    ```
    Replace `[service-name...]` with the services you want to start (e.g., `department-service api-gateway`). If you omit service names, all services defined in these files will start.
    You can also use profiles:
    ```bash
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml --profile logging up -d
    ```

**Option 2: Using `local-dev.sh` Script**
A helper script `local-dev.sh` (in the project root) automates this process. Ensure it's executable (`chmod +x local-dev.sh`).

*   **Build services**:
    ```bash
    ./local-dev.sh build                    # Build all Java services
    ./local-dev.sh build <service-name>     # Build a specific Java service (e.g., api-gateway)
    ```
*   **Start services (using local JARs)**:
    ```bash
    ./local-dev.sh up -d                    # Start all services in detached mode
    ./local-dev.sh up <service-name>        # Start specific service(s)
    ./local-dev.sh up --profile logging -d  # Start with profiles
    ```
*   **Stop services**:
    ```bash
    ./local-dev.sh down
    ```
*   **View logs**:
    ```bash
    ./local-dev.sh logs <service-name>      # Follow logs for a service
    ./local-dev.sh logs                     # Follow logs for all services
    ```
*   **View running services**:
    ```bash
    ./local-dev.sh ps
    ```
*   **Help**:
    ```bash
    ./local-dev.sh help
    ```

## Common Issues and Troubleshooting

*   **Port Conflicts**:
    *   **Issue**: `Error starting userland proxy: listen tcp4 0.0.0.0:XXXX: bind: address already in use.`
    *   **Fix**: Another application on your host machine is using one of the ports defined in `docker-compose.yml`. Identify and stop the conflicting application, or change the host port mapping in your `docker-compose.yml` (e.g., change `"8080:8080"` to `"8081:8080"` if port 8080 is taken).
*   **`config-server` Fails to Start / Services Can't Get Configuration**:
    *   **Issue**: Often due to the `config-server` not being able to access the Git repository specified by `CONFIG_REPO_URI`.
    *   **Fix**:
        *   Ensure `CONFIG_REPO_URI` in your `deploy/.env` file is correct.
        *   If the repository is private, ensure `GIT_PAT` (Personal Access Token) is correctly set in `deploy/.env` and has the necessary read permissions for the repository.
        *   Check `config-server` logs: `docker-compose logs -f config-server`.
*   **Services Fail to Register with Eureka (`service-registry`)**:
    *   **Issue**: Services cannot find or register with the `service-registry`.
    *   **Fix**:
        *   Ensure `service-registry` started correctly: `docker-compose logs -f service-registry`.
        *   Verify that `SPRING_PROFILES_ACTIVE=local-eureka` is set for the Java microservices in `docker-compose.yml` (or not overridden to something else).
        *   Check network connectivity within the Docker network. Usually, Docker Compose handles this.
*   **Database Connection Issues**:
    *   **Issue**: Application services (e.g., `department-service`) report errors connecting to their MySQL database.
    *   **Fix**:
        *   Ensure the MySQL containers (`mysql_department`, `mysql_employee`) are running and healthy: `docker-compose ps`, `docker-compose logs -f mysql_department`.
        *   Verify `MYSQL_ROOT_PASSWORD` in your `deploy/.env` matches what the services expect (they use this password to connect as root, as per current config).
        *   Check database initialization scripts in `deploy/init/` if tables are missing.
*   **Insufficient Docker Resources**:
    *   **Issue**: Docker runs out of memory or CPU, causing containers to crash or perform poorly.
    *   **Fix**: In Docker Desktop settings, increase the allocated memory and CPU resources.
*   **Volume Mount Issues (Permission Denied)**:
    *   **Issue**: Docker reports errors related to volume mounts, often due to file permission problems on the host system (especially on Linux).
    *   **Fix**: Ensure the user running Docker has the correct permissions for the directories being mounted. For SELinux systems, you might need to append `:z` or `:Z` to volume mounts.
*   **Outdated Docker Images**:
    *   **Issue**: Services behave unexpectedly due to using stale, locally cached Docker images.
    *   **Fix**: Periodically run `docker-compose build --no-cache` for services built from Dockerfiles, or `docker-compose pull` for pre-built images to get updates. Use `docker-compose up -d --force-recreate --build` to force recreation of containers with fresh images.

For more specific issues, always check the logs of the failing service first: `docker-compose logs -f <service-name>`.
