## Configuration and Secrets Management Report

This section reviews the current approach to managing application configuration and sensitive data (secrets) within the Docker Compose setup and provides recommendations for transitioning to a Kubernetes-native approach.

### Current Strategy

The existing system primarily relies on environment variables for configuration. These variables are typically defined in a `.env` file in the `deploy/` directory, which is then sourced by Docker Compose to inject values into the service containers. The `deploy/.env.Example` file serves as a template for users to create their actual `.env` file.

Key observations:
*   Service configurations (ports, external URIs, application names) are set via environment variables (e.g., `SERVICE_REGISTRY_PORT`, `CONFIG_REPO_URI`).
*   Sensitive information is also passed as environment variables.

### Examples of Sensitive Information Currently Managed via Environment Variables

Several pieces of sensitive information are managed this way, including but not limited to:

*   `MYSQL_ROOT_PASSWORD`: The root password for MySQL database instances.
*   `MYSQL_PASSWORD`: (If `MYSQL_USER` is not root) The password for the application-specific MySQL user. Currently, the services use `DATABASE_USERNAME: root` and `DATABASE_PASSWORD: ${MYSQL_ROOT_PASSWORD}`.
*   `RABBITMQ_PASSWORD`: The password for the RabbitMQ user (defaulting to `guest` if not overridden from `.env`).
*   `GIT_PAT`: The GitHub Personal Access Token used by the `config-server` to access the configuration repository.

Storing these directly in `.env` files, especially if committed to version control (even `.env.Example` with placeholder tokens can be risky if actual tokens are accidentally committed), is not secure for production or even shared development environments.

### Recommendations for Kubernetes Environments

When migrating to Kubernetes, a more robust and secure approach to configuration and secrets management should be adopted.

1.  **Catalog and Classify Environment Variables**:
    *   The first step is to thoroughly review all environment variables currently defined (as seen in `.env.Example` and Docker Compose files).
    *   Classify each variable as either:
        *   **Non-sensitive configuration**: E.g., service ports, application names, replica counts, feature flags, external service URLs (if not sensitive). These are candidates for Kubernetes ConfigMaps.
        *   **Sensitive data (Secrets)**: E.g., database passwords, API keys, tokens, TLS certificates. These must be managed using Kubernetes Secrets.
    *   The existing `deploy/.env.Example` file provides an excellent starting point for this cataloging effort.

2.  **Utilize Kubernetes ConfigMaps for Non-Sensitive Configuration**:
    *   ConfigMaps are Kubernetes objects designed to store non-confidential configuration data as key-value pairs.
    *   Applications can consume ConfigMaps as environment variables or as mounted files.
    *   This allows for better organization and management of configuration data within the Kubernetes cluster, separating it from application images.
    *   **Example**: Variables like `SERVICE_REGISTRY_PORT`, `API_GATEWAY_PORT`, `DEPARTMENT_DB`, `EMPLOYEE_DB`, `ZIPKIN_BASE_URL`, `EUREKA_SERVER` (if the URL itself is not sensitive) could be stored in ConfigMaps.

3.  **Employ Kubernetes Secrets for Sensitive Data**:
    *   Kubernetes Secrets are specifically designed to hold sensitive information like passwords, OAuth tokens, and SSH keys. They are stored with additional security considerations (e.g., etcd encryption at rest, if configured).
    *   **Creation**: Secrets can be created imperatively using `kubectl create secret generic <secret-name> --from-literal=KEY=VALUE` or declaratively from YAML files (often base64 encoded, though Kubernetes handles the encoding/decoding).
        ```bash
        # Example: Imperative creation for a database password
        kubectl create secret generic db-credentials --from-literal=MYSQL_ROOT_PASSWORD='supersecretpassword'

        # Example: Declarative (partial YAML)
        # apiVersion: v1
        # kind: Secret
        # metadata:
        #   name: git-pat-secret
        # type: Opaque
        # data:
        #   GIT_PAT: <base64_encoded_token>
        ```
    *   **Consumption**: Pods can consume Secrets as:
        *   **Environment variables**: The most common way for compatibility with existing applications expecting environment variables.
        *   **Volume mounts**: Secret values can be mounted as files into a Pod's filesystem. This is useful for configuration files that contain secrets or for TLS certificates.
    *   All sensitive data listed above (`MYSQL_ROOT_PASSWORD`, `RABBITMQ_PASSWORD`, `GIT_PAT`, application database passwords) should be migrated to Kubernetes Secrets.

4.  **Managing the `config-server`**:
    *   The Spring Cloud Config Server (`config-server`) is a valuable pattern for centralizing application configuration, especially for microservices. It can and should be retained.
    *   However, the `config-server` itself has sensitive configuration: the `GIT_PAT` used to access its backend Git repository. This token must be supplied to the `config-server` Pod securely via a Kubernetes Secret (e.g., mounted as an environment variable).

5.  **Database Credential Management**:
    *   **MySQL Container Credentials**: The `MYSQL_ROOT_PASSWORD` (and `MYSQL_USER`, `MYSQL_PASSWORD` if a non-root administrative user is set up for the MySQL containers themselves) should be provided via Kubernetes Secrets when deploying the MySQL instances.
    *   **Application Database Credentials**:
        *   The `department-service` and `employee-service` currently use `DATABASE_USERNAME: root` and `DATABASE_PASSWORD: ${MYSQL_ROOT_PASSWORD}`. **This is a significant security risk.** Applications should **never** connect to databases using the root user.
        *   **Recommendation**:
            1.  For each database (`department_db_1`, `employee_db_2`), create dedicated, less-privileged users with permissions only for the operations required by the respective service.
            2.  The credentials (username and password) for these dedicated users should be stored in Kubernetes Secrets.
            3.  The application services should then consume these dedicated credentials from the Secrets (e.g., as environment variables `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`). The `DATABASE_URL` might need to be adjusted or these specific Spring Boot properties used to override parts of it.
    *   This principle of least privilege drastically reduces the potential impact if an application's credentials are compromised.

6.  **Transitioning from `.env.Example`**:
    *   The existing `deploy/.env.Example` file is a valuable asset. It can be used as an inventory list to decide which variables become ConfigMap entries and which become Secret entries.
    *   For each variable, determine its sensitivity and assign it to the appropriate Kubernetes object.

By implementing these recommendations, the application's configuration will be more secure, manageable, and aligned with Kubernetes best practices, particularly for handling sensitive information. This separation of configuration and secrets from the application code and Docker images enhances portability and operational security.
