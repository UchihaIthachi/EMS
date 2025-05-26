# Architecture Components

This document describes the key architectural components of the Employee Management System (EMS) application, focusing on the `config-server`, `api-gateway`, and `service-registry`.

## 1. Config Server (`config-server`)

The `config-server` is a Spring Cloud Config Server instance responsible for centralizing configuration management for all microservices.

**Key Features & Workings:**

*   **Backend Storage:** It is currently configured to use a Git repository (`https://github.com/UchihaIthachi/configuration-server-repo`) as its backend. Configuration files for each microservice (e.g., `api-gateway.properties`, `department-service.yml`) are stored in this Git repository.
*   **Serving Configurations:** Microservices (clients of the config-server) fetch their configurations from the `config-server` upon startup. This allows for dynamic configuration updates without needing to rebuild or redeploy the services themselves (though a refresh mechanism might be needed for services to pick up changes without restarting).
*   **Environment & Profile Support:** Spring Cloud Config allows defining common configurations (`application.properties`) and environment/profile-specific configurations (e.g., `application-dev.properties`, `application-prod.yml`, `api-gateway-kubernetes.properties`).
*   **Security:** Access to the Git repository backend is secured using a Git Personal Access Token (PAT), which is provided to the `config-server` via environment variables (and managed as a Kubernetes Secret in the K8s deployment).

**In Different Environments:**

*   **Local Docker Compose (`local-eureka` profile active):**
    *   The `config-server` itself registers with the Eureka `service-registry`.
    *   Client microservices (like `api-gateway`, `department-service`, etc.) can discover the `config-server` via Eureka using its service ID (e.g., `CONFIG-SERVER`) if `spring.cloud.config.discovery.enabled=true` is set in their `application-local-eureka.properties`.
*   **Kubernetes (`kubernetes` profile active):**
    *   Client microservices discover the `config-server` via its Kubernetes service DNS name (e.g., `http://config-server:8888`). `spring.cloud.config.discovery.enabled` is false in this profile.

## 2. API Gateway (`api-gateway`)

The `api-gateway` service is built using Spring Cloud Gateway and acts as the single entry point for all client requests to the backend microservices.

**Key Features & Workings:**

*   **Request Routing:** It routes incoming requests to the appropriate downstream microservices (e.g., `department-service`, `employee-service`) based on defined predicates (e.g., path patterns, hostnames).
*   **Cross-Cutting Concerns:** It serves as a central place to implement cross-cutting concerns such as:
    *   **Security:** Authentication, authorization (though not fully implemented in this example project, it's a typical gateway responsibility).
    *   **Rate Limiting:** Protecting services from being overwhelmed (not currently implemented).
    *   **Request/Response Transformation:** Modifying requests or responses if needed.
    *   **Resilience:** Can integrate with circuit breakers (e.g., Resilience4j) for downstream service calls.
*   **Dynamic Routing:**
    *   **Local Docker Compose (`local-eureka` profile active):** When `spring.cloud.gateway.discovery.locator.enabled=true`, the API Gateway can automatically discover and create routes to services registered with Eureka. Routes are typically defined using Eureka service IDs (e.g., `lb://DEPARTMENT-SERVICE`).
    *   **Kubernetes (`kubernetes` profile active):** `spring.cloud.gateway.discovery.locator.enabled=false`. Routes are defined using direct Kubernetes service DNS names and ports (e.g., `uri: http://department-service:8081`). These routes are typically externalized and managed by the `config-server`.
*   **Integration with Tracing:** It integrates with Zipkin for distributed tracing, allowing requests to be traced as they flow through the gateway to other services.

## 3. Service Registry (`service-registry`)

The `service-registry` component plays a crucial role in service discovery, primarily in the local Docker Compose environment when Eureka is active.

**Key Features & Workings:**

*   **Eureka Server (Local Docker Compose):**
    *   When the `local-eureka` Spring profile is active in the microservices, the `service-registry` container runs as a **Netflix Eureka Server**.
    *   Its environment variables `REGISTER_WITH_EUREKA="false"` and `FETCH_REGISTRY="false"` configure it to act as a server, not a client registering with another Eureka instance.
    *   Other microservices (including `config-server` and `api-gateway`) register themselves with this Eureka server.
    *   Services then query Eureka to find the network locations (IP and port) of other services they need to communicate with.
    *   The API Gateway uses Eureka to dynamically route requests to backend services.
    *   The Config Server's clients can use Eureka to find the Config Server.

*   **Role in Kubernetes (`kubernetes` profile active):**
    *   In the Kubernetes environment, **Netflix Eureka is not used** for service discovery.
    *   Kubernetes provides its own robust, DNS-based service discovery mechanism.
    *   The `service-registry` application, when deployed to Kubernetes:
        *   Has its Eureka client capabilities disabled (`eureka.client.enabled=false`).
        *   Does not act as a Eureka server.
        *   Essentially behaves like any other Spring Boot application. Its original purpose (Eureka server) is superseded by Kubernetes DNS.
        *   It still might act as a client to `config-server` (using K8s DNS) to fetch its own configuration if it has any.
    *   The Kubernetes manifests for `service-registry` deploy it as a standard Spring Boot application, ensuring all services are accounted for, but its service discovery role is inactive in K8s.

This switchable behavior allows developers to use Eureka for local development convenience (if familiar with it or for specific local network setups) while leveraging Kubernetes-native service discovery for cloud-native deployments.
```
