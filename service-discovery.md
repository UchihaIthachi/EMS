# Service Discovery

The Employee Management System (EMS) application employs a switchable service discovery mechanism to adapt to different environments: local Docker Compose development and Kubernetes deployments. This is primarily managed using Spring Profiles.

## Overview of Mechanisms

1.  **Local Docker Compose Environment (Profile: `local-eureka`):**
    *   Uses **Netflix Eureka** for service registration and discovery.
    *   The `service-registry` application instance acts as the Eureka server.
    *   All other microservices (`config-server`, `api-gateway`, `department-service`, `employee-service`) act as Eureka clients. They register with the Eureka server and can discover each other by querying it.
    *   This mode is activated when the `local-eureka` Spring profile is active for the Java microservices.

2.  **Kubernetes Environment (Profile: `kubernetes` - Default):**
    *   Uses **Kubernetes native DNS-based service discovery**.
    *   Netflix Eureka is **disabled** in this mode.
    *   Microservices discover each other using their Kubernetes service names (e.g., `http://department-service:8081`, `http://config-server:8888`). These DNS names are automatically resolved by Kubernetes' internal DNS system.
    *   This mode is active by default or when the `kubernetes` Spring profile is explicitly activated.

## Implementation via Spring Profiles

Spring Boot profiles are used to segregate configurations and enable the switchable behavior. Each Java microservice includes profile-specific property files:

*   **`application-kubernetes.properties`:**
    *   Activated when the `kubernetes` profile is active (or by default).
    *   Disables the Eureka client: `eureka.client.enabled=false`.
    *   Configures service communication URLs (e.g., for Feign clients, Spring Cloud Gateway routes, `spring.config.import`) to use direct Kubernetes service DNS names (e.g., `http://config-server:8088`, `http://department-service:8081`).
    *   For `api-gateway`, it disables Eureka-based route discovery: `spring.cloud.gateway.discovery.locator.enabled=false`.

*   **`application-local-eureka.properties`:**
    *   Activated when the `local-eureka` profile is active.
    *   Enables the Eureka client: `eureka.client.enabled=true`.
    *   Sets the Eureka server address: `eureka.client.serviceUrl.defaultZone=http://service-registry:8761/eureka` (points to the `service-registry` container in Docker Compose).
    *   Configures service communication to use Eureka service IDs (e.g., `http://DEPARTMENT-SERVICE`, `http://CONFIG-SERVER`).
        *   For `api-gateway`, this enables Eureka-based route discovery: `spring.cloud.gateway.discovery.locator.enabled=true`. Routes are expected to use `lb://SERVICE-ID` format.
        *   For Feign clients (e.g., in `employee-service` calling `department-service`), the explicit `.url` property is typically removed, and the `@FeignClient(name = "SERVICE-ID")` uses the Eureka service ID.
        *   For finding `config-server` via Eureka, properties like `spring.cloud.config.discovery.enabled=true` and `spring.cloud.config.discovery.service-id=CONFIG-SERVER` are used.

*   **Main `application.properties` (or `bootstrap.properties`):**
    *   Sets the default active profile to Kubernetes: `spring.profiles.default=kubernetes`. This ensures that if no specific profile is activated via environment variables, the Kubernetes-friendly configuration is used.
    *   Contains common configurations or default K8s-specific configurations (like the `config-server` URI pointing to K8s DNS).

## Activating Profiles

*   **Local Docker Compose (`deploy/docker-compose.yml`):**
    *   The `service-registry` container is configured to run as a Eureka server.
    *   Other Java microservices (`config-server`, `api-gateway`, `department-service`, `employee-service`) have the environment variable `SPRING_PROFILES_ACTIVE=local-eureka` set. This activates their Eureka client behavior.

*   **Kubernetes Deployments (`deploy/k8s/deployments/*.yaml`):**
    *   Java microservice Deployments have the environment variable `SPRING_PROFILES_ACTIVE=kubernetes` set. This ensures they use Kubernetes DNS and disable Eureka. If this variable were omitted, the `spring.profiles.default=kubernetes` setting in the application would achieve the same.

## Benefits of Switchable Discovery

*   **Flexibility:** Allows developers to use a familiar Eureka-based discovery for local development if preferred, or for specific testing scenarios.
*   **Cloud-Native Alignment:** Ensures that when deploying to Kubernetes, the application leverages the platform's native service discovery, which is generally more robust and integrated within that ecosystem.
*   **Single Codebase:** The same application code (JARs) can adapt to different environments through externalized configuration and Spring Profiles, reducing the need for separate build artifacts for local vs. K8s.
```
