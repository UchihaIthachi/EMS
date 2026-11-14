# EMS on Kubernetes: system design

Employee Management System rebuilt as a Kubernetes-native platform project. The domain is small on
purpose; the point is how it runs: discovery, configuration, resilience, events, scaling and operations.

## Architecture

```mermaid
flowchart LR
  user([Browser]) -->|HTTP| gw[Gateway API<br/>kgateway / Envoy]
  gw -->|/| fe[frontend<br/>nginx + React]
  gw -->|/api, /employee-service,<br/>/department-service| ag[api-gateway<br/>Spring Cloud Gateway]

  ag --> es[employee-service]
  ag --> ds[department-service]

  es -->|Feign + circuit breaker,<br/>time limiter, fallback| ds
  es -->|JPA| edb[(MySQL<br/>employee_db)]
  ds -->|JPA| ddb[(MySQL<br/>department_db)]
  ds -->|cache-aside| redis[(Redis)]

  es -->|publish employee.created| ex{{RabbitMQ<br/>ems.events}}
  ex --> q[[department.employee-events]]
  q -->|consume, idempotent| ds
  q -.->|after 3 failed attempts| dlq[[...employee-events.dlq]]

  keda[KEDA] -.->|queue length| q
  keda -.->|scales| ds
  hpa[HPA] -.->|CPU| es
```

## Request and event flow

```mermaid
sequenceDiagram
  participant C as Client
  participant G as api-gateway
  participant E as employee-service
  participant D as department-service
  participant R as Redis
  participant Q as RabbitMQ

  C->>G: POST /api/v1/employee-service
  G->>E: forward
  E->>E: save employee (employee_db)
  E-)Q: employee.created {eventId}
  E-->>C: 201 Created
  Q-)D: deliver (at-least-once)
  D->>D: INSERT IGNORE processed_events(eventId)<br/>+ upsert department_stats (one transaction)

  C->>G: GET /api/v1/employee-service/{id}
  G->>E: forward
  E->>D: GET department (circuit breaker, 3 s limit)
  D->>R: cache lookup
  alt cache miss
    D->>D: read department_db
    D->>R: store (TTL 10 min)
  end
  D-->>E: department
  E-->>C: employee + department (or employee only, if department-service is down)
```

## Patterns used

| Pattern | Where | Why |
|---|---|---|
| API gateway | Gateway API (kgateway) at the edge, Spring Cloud Gateway for API routing | One entry point; routing and timeouts out of the services |
| Database per service | `employee_db`, `department_db`, separate users | Services own their data; no cross-service joins |
| Platform service discovery | Kubernetes Services + CoreDNS (Eureka removed) | The platform already does registry, DNS and load balancing |
| Externalized configuration | ConfigMaps + Secrets as environment variables (config server removed) | Same image in every environment |
| Health check API | `/actuator/health/liveness`, `/readiness` (DB, RabbitMQ) | Kubernetes restarts dead pods and stops routing to unready ones |
| Circuit breaker, timeout, fallback | Resilience4j on the employee → department call | A slow or failed dependency degrades one field, not the whole request |
| Publish/subscribe events | `employee.created` on a topic exchange | Services stay decoupled; consumers are added without touching the producer |
| Idempotent consumer | `processed_events` keyed by `eventId`, in the same transaction as the update | RabbitMQ delivers at least once; duplicates must not count twice |
| Dead-letter queue | `department.employee-events.dlq` after 3 attempts | Poison messages don't block the queue; they can be inspected and replayed |
| CQRS read model | `department_stats` built from events, `GET /{code}/stats` | Fast reads without querying another service's database |
| Cache-aside | Redis in front of department lookups, TTL + evict on write; Redis failure falls back to MySQL | The hottest read path; the cache is an optimisation, never a dependency |
| Event-driven autoscaling | KEDA on queue length (department-service), HPA on CPU (employee-service) | Scale on the signal that actually measures backlog |
| Graceful shutdown | `server.shutdown=graceful` + PodDisruptionBudgets | Rolling updates and node drains don't drop requests |
| Observability | Prometheus metrics, stdout logs, OpenTelemetry agent (off by default) | Lab-sized: tracing is switched on for demos only |

**Deliberately elsewhere:** saga, transactional outbox and idempotency keys for payments are in the
order-and-payments project, where money makes them matter. The employee event here is published
best-effort (a lost event is logged); the outbox pattern is the fix and is shown there.

## Lab sizing

Three Lima VMs on a 16 GB laptop (control plane 2.5 GB, two workers 3 GB). Measured headroom for apps is
about 3.2 GB, so services run one replica each, JVMs are capped at 448 MiB, and Elasticsearch/Kibana are
out of scope.
