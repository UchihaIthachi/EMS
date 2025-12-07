# Observability

This project integrates a complete observability stack to monitor the health, performance, and behavior of the microservices.

## Components

### 1. Distributed Tracing (Zipkin)
*   **Role**: Traces requests as they propagate across microservices (Gateway -> Employee -> Department).
*   **Usage**:
    *   Enabled by default in `docker-compose.yml`.
    *   Access the UI at: `http://localhost:9411`
    *   Search for traces to visualize latency breakdowns and dependency graphs.

### 2. Logging (ELK Stack)
*   **Role**: Centralized log aggregation and analysis.
*   **Components**:
    *   **Elasticsearch**: Stores logs.
    *   **Logstash**: Ingests and parses logs.
    *   **Kibana**: Visualizes logs (`http://localhost:5601`).
*   **Configuration**:
    *   Services must be run with the `logging` profile to send logs to Logstash/Elasticsearch.
    *   Docker Compose services: `elasticsearch`, `logstash`, `kibana`.

### 3. Metrics (Prometheus & Grafana)
*   **Role**: Application and infrastructure metric collection.
*   **Components**:
    *   **Prometheus**: Scrapes `/actuator/prometheus` endpoints from services (`http://localhost:9090`).
    *   **Grafana**: Visualization dashboards (`http://localhost:3000`).
*   **Configuration**:
    *   Docker Compose services: `prometheus`, `grafana`.

## Running with Observability

The "Core" run (`./service-ops.sh --run`) typically starts the business logic services. To enable full observability, you may need to explicitly target the additional containers or ensure your script includes them.

**Not Required for Minimal Run:**
You do **not** need the ELK stack or Prometheus/Grafana to simply run and test the application features. These are heavy containers; omit them if you are resource-constrained.

**Enabling Observability:**
Uncomment or ensure the relevant services are active in `deploy/docker-compose.yml` or run them explicitly:

```bash
./service-ops.sh --run zipkin prometheus grafana elasticsearch logstash kibana
```
