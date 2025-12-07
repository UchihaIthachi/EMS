# Local Deployment Guide

This guide provides detailed instructions for deploying and running the Employee Management System (EMS) application locally using Docker Compose.

## Prerequisites

Before you begin, ensure you have the following installed on your system:

*   **Docker Desktop**: For running Docker containers and Docker Compose.
*   **Java Development Kit (JDK)**: Version 17 or newer (required for building Java services).
*   **Apache Maven**: For building Java projects (or use the included `mvnw` wrapper).
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

## Deployment with `service-ops.sh`

The `service-ops.sh` script is the primary tool for managing the local lifecycle of the EMS application. It handles building the Java services, creating Docker images, and running the stack with Docker Compose.

### Basic Usage

*   **Build all services**:
    ```bash
    ./service-ops.sh --build
    ```
    This will compile the Java code (skipping tests for speed) and build the Docker images.

*   **Run all services**:
    ```bash
    ./service-ops.sh --run
    ```
    This will start all services, including the core microservices, databases, RabbitMQ, and the observability stack (monitoring & logging).

*   **Build and Run**:
    ```bash
    ./service-ops.sh --build --run
    ```

### Targeted Usage

You can target specific services by appending their names to the command.

*   **Build specific service**:
    ```bash
    ./service-ops.sh --build api-gateway department-service
    ```

*   **Run specific service**:
    ```bash
    ./service-ops.sh --run api-gateway
    ```

### Observability Services

The `service-ops.sh` script automatically includes observability services when running without arguments or if you explicitly include them.

These services include:
*   **Zipkin**: Distributed tracing.
*   **Elasticsearch, Logstash, Kibana (ELK)**: Centralized logging.
*   **Prometheus**: Metrics collection.
*   **Grafana**: Metrics visualization.
*   **Nginx Exporter**: Metrics for the web proxy.

To run *only* the observability stack (e.g., for debugging):
```bash
./service-ops.sh --run zipkin elasticsearch logstash kibana prometheus grafana
```

## Accessing Services

Once the services are up and running, you can access them via your browser or API tools at the following default `localhost` ports:

*   **Web Proxy (Main Entry)**: [http://localhost:80](http://localhost:80) (Routes to frontend and API Gateway)
*   **Frontend UI**: [http://localhost:3001](http://localhost:3001) or via Proxy at [http://localhost:80](http://localhost:80)
*   **API Gateway** (Direct): [http://localhost:9191/api/](http://localhost:9191/api/)
*   **Service Registry (Eureka)**: [http://localhost:8761](http://localhost:8761)
*   **Config Server**: [http://localhost:8888](http://localhost:8888)
*   **Adminer** (Database Management UI): [http://localhost:8085](http://localhost:8085)
*   **RabbitMQ Management Console**: [http://localhost:15672](http://localhost:15672)
*   **Zipkin** (Distributed Tracing): [http://localhost:9411](http://localhost:9411)
*   **Kibana** (Logging UI): [http://localhost:5601](http://localhost:5601)
*   **Grafana** (Monitoring UI): [http://localhost:3000](http://localhost:3000)
*   **Prometheus**: [http://localhost:9090](http://localhost:9090)

## Viewing Logs

To view logs for running services, use standard Docker Compose commands from the `deploy/` directory:

```bash
cd deploy/
docker-compose logs -f                  # All logs
docker-compose logs -f department-service # Specific service logs
```

## Stopping Services

To stop all services:

```bash
cd deploy/
docker-compose down
```

## Common Issues and Troubleshooting

*   **Port Conflicts**:
    *   **Issue**: `Error starting userland proxy: listen tcp4 0.0.0.0:XXXX: bind: address already in use.`
    *   **Fix**: Check if another application is using the port. Stop it or modify `deploy/docker-compose.yml` to map to a different host port.
*   **Service Startup Order**:
    *   **Issue**: Services fail because dependencies (like Config Server or RabbitMQ) aren't ready.
    *   **Fix**: The `docker-compose.yml` includes healthchecks and `depends_on` conditions to mitigate this. However, if a service fails immediately, try restarting it: `./service-ops.sh --run <service-name>`.
*   **Database Connection Issues**:
    *   **Issue**: Services cannot connect to MySQL.
    *   **Fix**: Verify `mysql_department` and `mysql_employee` are healthy. Check `deploy/.env` matches the `MYSQL_ROOT_PASSWORD` expected by the services.
