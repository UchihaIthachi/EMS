## Networking Preparation for Kubernetes Report

This section outlines the current networking setup within the Docker Compose environment and discusses how these concepts translate to Kubernetes, providing recommendations for a smooth transition.

### Current Networking Setup in Docker Compose

1.  **Custom Bridge Network (`ems-network`)**:
    *   All services defined in the `docker-compose.yml` are attached to a custom Docker bridge network named `ems-network`.
    *   This network facilitates communication between services. Docker's embedded DNS server allows containers on this network to resolve each other by their service names as defined in the Docker Compose file (e.g., `department-service` can reach `mysql_department` at `mysql_department:3306`).

2.  **Port Mappings**:
    *   Many services utilize the `ports` directive (e.g., `- "HOST_PORT:CONTAINER_PORT"`) to expose container ports to the host machine's network. This makes services accessible from outside the Docker host, including databases, service UIs, and the main application entry points like `web-proxy` (port `80`) and `frontend` (port `3001`).
    *   For example, `web-proxy` is exposed on port `80` of the Docker host, serving as the primary entry point for user traffic. `frontend` is exposed on `3001`, and backend services like `api-gateway` and databases also have their ports mapped.

### Kubernetes Networking Model Basics

Kubernetes networking is fundamentally different but provides analogous capabilities:

1.  **Flat Pod Network**:
    *   Every Pod in a Kubernetes cluster gets its own unique IP address.
    *   All Pods can communicate with all other Pods directly using these IP addresses, regardless of the node they are running on (assuming no Network Policies restrict this). This creates a flat network space.

2.  **Services for Stable Endpoints**:
    *   Pod IPs are ephemeral; Pods can be created and destroyed, changing their IPs.
    *   A Kubernetes `Service` provides a stable IP address (called `ClusterIP`) and a DNS name for a set of Pods (selected by labels). Applications connect to the `Service`, and Kubernetes load-balances traffic to the healthy Pods backing that `Service`.

### Internal Service-to-Service Communication: Docker Bridge to Kubernetes ClusterIP

*   **Current**: In Docker Compose, services like `employee-service` connect to `department-service` using `http://department-service:<port>` because they are on the same `ems-network`. Databases are accessed similarly (e.g., `mysql_department:3306`).
*   **Kubernetes Translation**:
    *   For each microservice (e.g., `department-service`, `employee-service`, `mysql_department`), you will define a Kubernetes `Service` of type `ClusterIP` (this is the default type).
    *   This `Service` gets an internal, stable IP address and a DNS name (e.g., `department-service`).
    *   Other Pods within the cluster can then reach this service using its DNS name (e.g., `http://department-service:<service-port>`). This is very similar to how Docker service names work on a custom bridge network.
    *   If the service discovery migration (from Eureka to Kubernetes DNS) is also performed, applications will use these Kubernetes DNS names directly.

### External Service Exposure: Docker `ports` to Kubernetes Services and Ingress

Services need to be accessible from outside the Kubernetes cluster.

1.  **Kubernetes `Service` Types for External Exposure**:
    *   `NodePort`: Exposes the Service on each Node's IP at a static port (the `NodePort`). Traffic to `NodeIP:NodePort` is routed to the Service. Useful for development or when an external load balancer isn't available.
    *   `LoadBalancer`: Provisions an external load balancer (if supported by the cloud provider or environment) and assigns it a public IP. Traffic to this public IP is routed to the Service. This is the standard way to expose services directly with an external IP.

2.  **Kubernetes `Ingress` Resources**:
    *   For HTTP/S applications, `Ingress` is the most common and flexible way to manage external access. An Ingress resource defines rules for routing external HTTP/S traffic to Services within the cluster.
    *   It requires an Ingress controller (like Nginx, Traefik, HAProxy) to be running in the cluster. The controller watches for Ingress resources and configures itself accordingly.
    *   Capabilities include:
        *   Hostname-based routing (e.g., `api.example.com` -> `api-gateway-service`).
        *   Path-based routing (e.g., `example.com/ui` -> `frontend-service`, `example.com/api` -> `api-gateway-service`).
        *   SSL/TLS termination.
    *   **Relation to `web-proxy` and `frontend`**:
        *   The current `web-proxy` (Nginx) service, which listens on port `80`, acts as a reverse proxy. Its functionality (routing, potentially SSL termination if added) directly maps to what an Ingress controller and Ingress resources provide.
        *   Instead of deploying your own `web-proxy` Nginx container, you would typically deploy a standard Ingress controller (e.g., `ingress-nginx`) and then create Ingress rules to direct traffic:
            *   Traffic to a specific host/path (e.g., `/`) could be routed to the `frontend` Service.
            *   Traffic to another path (e.g., `/api/`) could be routed to the `api-gateway` Service.

### Translating Docker Compose `ports` Mappings

*   **For Internal Communication**:
    *   The `CONTAINER_PORT` part of a Docker `ports` mapping (e.g., `3306` in `3307:3306` for `mysql_department`) becomes the `targetPort` in the Kubernetes `Service` definition for that backend service. The `Service` itself will have a `port` (e.g., port `3306`) that other services use to connect.
    *   Example: `mysql-department-service` might have `port: 3306` and `targetPort: 3306` (pointing to Pods listening on 3306).

*   **For External Exposure**:
    *   The `HOST_PORT` part of a Docker `ports` mapping is handled by `NodePort`, `LoadBalancer` Service types, or Ingress configurations.
    *   If `adminer` is exposed via `ports: ["8085:8080"]` in Docker Compose:
        *   Using `NodePort`: A Service for `adminer` might expose port `8080` and map it to a `nodePort` like `30085`. Access would be via `NodeIP:30085`.
        *   Using `LoadBalancer`: A Service for `adminer` would get an external IP, and traffic to `ExternalIP:8080` would be routed to it.
        *   Using `Ingress`: An Ingress rule could map `adminer.example.com` to the `adminer` Service on port `8080`.

### Optional: Kubernetes Network Policies

*   For enhanced security, Kubernetes `NetworkPolicy` resources can be used to control traffic flow between Pods at the IP address or port level (OSI layer 3 or 4).
*   This is analogous to firewall rules. You could define policies such that, for example, only the `department-service` Pods can connect to the `mysql_department` Pods on port 3306, and all other connections are denied.
*   This is a more advanced topic but important for securing applications in a shared cluster environment. It can be considered after the initial migration.

By understanding these translations, the networking aspects of the application can be effectively mapped from the Docker Compose setup to a Kubernetes deployment, ensuring correct service-to-service communication and appropriate external accessibility.
