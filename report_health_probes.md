## Health Checks and Kubernetes Probes Report

This section reviews the current usage of health checks in the Docker Compose setup and details how these translate to Kubernetes health probes, which are crucial for robust application lifecycle management in a Kubernetes environment.

### Current Health Check Implementation

The existing `docker-compose.yml` demonstrates good practice by defining `healthcheck` directives for several key services. This allows Docker to monitor the health of these containers and report their status.

Examples of current health checks include:

*   **Spring Boot Applications** (e.g., `service-registry`, `config-server`, `api-gateway`, `department-service`, `employee-service`):
    *   These services use `test: ["CMD", "curl", "-f", "http://localhost:<port>/actuator/health"]`. This leverages the Spring Boot Actuator `/health` endpoint, which provides a standardized way to check application health.
*   **MySQL Databases** (e.g., `mysql_department`, `mysql_employee`):
    *   These use `test: ["CMD", "mysqladmin", "ping", "-h", "127.0.0.1", "-u", "root", "--password=${MYSQL_ROOT_PASSWORD}"]` to ensure the MySQL server is responsive.
*   **RabbitMQ**:
    *   Uses `test: ["CMD", "rabbitmqctl", "status"]` to verify the operational status of the RabbitMQ node.

These health checks come with parameters like `interval`, `timeout`, and `retries` to control their execution frequency and failure conditions.

### Introduction to Kubernetes Health Probes

Kubernetes provides a more sophisticated system for health checking through "probes," which are configured on Pods. There are three main types:

1.  **Liveness Probes**:
    *   **Purpose**: To determine if a container is still running correctly.
    *   **Action**: If a liveness probe fails (exceeds its `failureThreshold`), the kubelet (the Kubernetes agent on the node) kills the container, and the container is subjected to its restart policy (typically, Kubernetes will try to restart it).
    *   **Use Case**: Helps recover from deadlocks or situations where an application is running but not responding or processing requests.

2.  **Readiness Probes**:
    *   **Purpose**: To determine if a container is ready to start accepting traffic.
    *   **Action**: If a readiness probe fails, the Pod's IP address is removed from the endpoints of all Services that select that Pod. This means no new traffic will be routed to it. Once the readiness probe succeeds, the Pod is added back to the Service endpoints.
    *   **Use Case**: Crucial during startup (ensuring an app only receives traffic after it's fully initialized, e.g., warmed up caches, established DB connections) and also during runtime if an application becomes temporarily overloaded or unable to process new requests but is still "live."

3.  **Startup Probes** (Optional, but relevant for some applications):
    *   **Purpose**: To allow applications with long startup times to complete their initialization before liveness and readiness probes take effect.
    *   **Action**: If a startup probe is configured, liveness and readiness probes are disabled until the startup probe succeeds. If the startup probe fails beyond its `failureThreshold`, the container is killed and follows its restart policy.
    *   **Use Case**: Protects slow-starting applications from being killed prematurely by aggressive liveness probes.

### Translating Docker Health Checks to Kubernetes Probes

The existing Docker Compose `healthcheck` configurations provide an excellent foundation for defining Kubernetes probes.

*   **For Spring Boot Applications**:
    *   The current command `curl -f http://localhost:<port>/actuator/health` is a perfect candidate for both **liveness** and **readiness probes**.
    *   **Liveness**: If the `/actuator/health` endpoint fails, it often means the application is in a non-recoverable state and should be restarted.
    *   **Readiness**: If the `/actuator/health` endpoint is down, the application is certainly not ready to serve traffic. Spring Boot Actuator also provides `/actuator/health/liveness` and `/actuator/health/readiness` specific endpoints which offer more fine-grained control if needed (e.g. an app might be live but not ready if a downstream dependency is unhealthy). Using the base `/actuator/health` is a good starting point.

*   **For MySQL Databases**:
    *   The `mysqladmin ping` command can serve as a good **liveness probe**. If the database server is not responding to pings, restarting it might resolve the issue.
    *   For **readiness**, especially for the initial startup, a more comprehensive check might be needed (e.g., ensuring it's ready to accept connections, not just pingable). However, `mysqladmin ping` is a reasonable starting point for readiness too.

*   **For RabbitMQ**:
    *   `rabbitmqctl status` can be used for both **liveness** and **readiness probes**. If the status is not nominal, the node might need a restart (liveness) or shouldn't be part of the service endpoint (readiness).

### Mapping Health Check Parameters

Docker Compose `healthcheck` parameters map conceptually to Kubernetes probe parameters:

| Docker Compose        | Kubernetes Probe           | Description                                                                 |
| --------------------- | -------------------------- | --------------------------------------------------------------------------- |
| `interval`            | `periodSeconds`            | How often (in seconds) to perform the probe.                                |
| `timeout`             | `timeoutSeconds`           | Number of seconds after which the probe times out.                           |
| `retries`             | `failureThreshold`         | Number of consecutive failures after which the probe is considered failed.    |
| (Not directly in DC)  | `initialDelaySeconds`      | Number of seconds after the container has started before probes are initiated. |
| (Not directly in DC)  | `successThreshold`         | Minimum consecutive successes for the probe to be considered successful after having failed. Defaults to 1. |

**Example (Conceptual Kubernetes Probe for a Spring Boot service):**

```yaml
# In a Kubernetes Deployment spec for a Pod:
# ...
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080 # Or whatever port the app serves HTTP on
          initialDelaySeconds: 60 # Give app time to start
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 30 # Can be shorter than liveness initial delay
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
# ...
```
The `initialDelaySeconds` is particularly important to prevent containers from being restarted before they have a chance to fully initialize.

### Importance in Kubernetes

Properly configured liveness and readiness probes are critical in Kubernetes for:

*   **Automated Restarts**: Liveness probes enable Kubernetes to automatically restart unhealthy containers, promoting self-healing.
*   **Safe Deployments (Rolling Updates)**: Readiness probes ensure that updated versions of an application only start receiving traffic when they are fully ready. This prevents downtime during deployments. If new Pods fail their readiness checks, the deployment can be paused or rolled back.
*   **Reliable Scaling**: Readiness probes ensure that scaled-up Pods only receive traffic once they are prepared, preventing errors due to requests hitting uninitialized instances.
*   **Improved Stability**: By automatically managing the lifecycle of unhealthy or unready Pods, probes contribute significantly to the overall stability and resilience of the application.

It's also important to define probes for third-party images (like Elasticsearch, Zipkin etc.) if meaningful health endpoints or commands are available, to integrate them fully into Kubernetes's lifecycle management.

By thoughtfully translating the existing health checks and implementing comprehensive probes, the application will be more robust and reliable when deployed on Kubernetes.
