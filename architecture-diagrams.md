# Architecture Diagrams

This document contains architecture diagrams for the Employee Management System (EMS) application, rendered using MermaidJS syntax. You can copy the Mermaid code blocks into a compatible renderer (e.g., online editors, some Markdown editors, or plugins) to view the diagrams.

## 1. Local Docker Compose Architecture (with Eureka)

This diagram illustrates the high-level architecture when running the application locally using `docker-compose -f deploy/docker-compose.yml` (which activates the `local-eureka` profile for services).

```mermaid
graph TD
    subgraph "User's Browser"
        U[User]
    end

    subgraph "Docker Network (ems-network)"
        LB[web-proxy/nginx:80] --> FE[frontend:80/nginx]
        LB --> APIGW[api-gateway:8080]

        APIGW -->|Eureka discovery or direct Docker DNS| CS[config-server:8888]
        APIGW -->|Eureka discovery| DS[department-service:8081]
        APIGW -->|Eureka discovery| ES[employee-service:8082]

        CS -->|Registers with| SR[service-registry/Eureka:8761]
        DS -->|Registers with & gets config from| SR
        DS -->|Config via| CS
        ES -->|Registers with & gets config from| SR
        ES -->|Config via| CS
        APIGW -->|Registers with & gets config from| SR
        APIGW -->|Config via| CS


        DS --> DB_DEPT[mysql_department:3306]
        ES --> DB_EMP[mysql_employee:3308]
        
        DS --> RMQ[rabbitmq:5672]
        ES --> RMQ

        subgraph "Supporting Services (Local Docker Compose)"
            SR
            CS --> GIT[Git Repo (External)]
            DB_DEPT
            DB_EMP
            RMQ
            ZIPKIN[zipkin:9411]
            ADMINER[adminer:8085]
            direction LR
        end
        
        APIGW --> ZIPKIN
        DS --> ZIPKIN
        ES --> ZIPKIN

        subgraph "Optional: Logging (Profile)"
            LOGSTASH[logstash:5000] --> ELASTIC[elasticsearch:9200]
            KIBANA[kibana:5601] --> ELASTIC
            direction LR
        end
        
        subgraph "Optional: Monitoring (Profile)"
            PROM[prometheus:9090]
            GRAFANA[grafana:3000] --> PROM
            direction LR
        end
        %% Service interactions with logging/monitoring not shown for brevity
    end

    U --> LB

    classDef springService fill:#lightgreen,stroke:#333,stroke-width:2px;
    classDef db fill:#lightblue,stroke:#333,stroke-width:2px;
    classDef mq fill:#orange,stroke:#333,stroke-width:2px;
    classDef tool fill:#lightgrey,stroke:#333,stroke-width:2px;
    classDef eureka fill:#MistyRose,stroke:#333,stroke-width:2px;

    class APIGW,CS,DS,ES springService;
    class DB_DEPT,DB_EMP db;
    class RMQ mq;
    class SR eureka;
    class ZIPKIN,ADMINER,LOGSTASH,ELASTIC,KIBANA,PROM,GRAFANA,FE,LB tool;
```

**Key for Local Diagram:**
*   Arrows indicate primary request flow or registration/discovery.
*   `service-registry` acts as the Eureka server.
*   Microservices (`config-server`, `api-gateway`, `department-service`, `employee-service`) register with Eureka and use it to discover each other (especially `api-gateway` discovering backends, and all services discovering `config-server`).
*   `web-proxy` (Nginx) acts as the main entry point, routing to `frontend` or `api-gateway`.

## 2. Kubernetes Deployment Architecture (Minikube)

This diagram illustrates the high-level architecture when deploying the application to Kubernetes (using manifests in `deploy/k8s/`). Service discovery is handled by Kubernetes DNS.

```mermaid
graph TD
    subgraph "User's Browser/Client"
        U[User]
    end

    subgraph "Kubernetes Cluster (ems-app Namespace)"
        INGRESS[Ingress (ems.localdev.me)]

        subgraph "Deployments & StatefulSets"
            APIGW_P[Pod: api-gateway]
            CS_P[Pod: config-server]
            DS_P[Pod: department-service]
            ES_P[Pod: employee-service]
            FE_P[Pod: frontend]
            
            SR_P[Pod: service-registry (Eureka disabled)]

            DB_DEPT_STS[STS: mysql-department] --> PVC_DEPT[PVC: department-db]
            DB_EMP_STS[STS: mysql-employee] --> PVC_EMP[PVC: employee-db]
            RMQ_STS[STS: rabbitmq] --> PVC_RMQ[PVC: rabbitmq-data]
            
            ZIPKIN_P[Pod: zipkin]
            ADMINER_P[Pod: adminer]

            subgraph "Logging Stack"
                LOGSTASH_P[Pod: logstash] --> ELASTIC_STS[STS: elasticsearch]
                ELASTIC_STS --> PVC_ELASTIC[PVC: elastic-data]
                KIBANA_P[Pod: kibana] --> ELASTIC_STS
                direction LR
            end

            subgraph "Monitoring Stack"
                PROM_P[Pod: prometheus] --> PVC_PROM[PVC: prometheus-data]
                GRAFANA_P[Pod: grafana] --> PVC_GRAFANA[PVC: grafana-data]
                GRAFANA_P --> PROM_P
                direction LR
            end
        end

        subgraph "Services (ClusterIP)"
            APIGW_SVC[Svc: api-gateway]
            CS_SVC[Svc: config-server]
            DS_SVC[Svc: department-service]
            ES_SVC[Svc: employee-service]
            FE_SVC[Svc: frontend]
            SR_SVC[Svc: service-registry]

            DB_DEPT_SVC[Svc: mysql-department]
            DB_EMP_SVC[Svc: mysql-employee]
            RMQ_SVC[Svc: rabbitmq]
            
            ZIPKIN_SVC[Svc: zipkin]
            ADMINER_SVC[Svc: adminer]
            ELASTIC_SVC[Svc: elasticsearch]
            LOGSTASH_SVC[Svc: logstash]
            KIBANA_SVC[Svc: kibana]
            PROM_SVC[Svc: prometheus]
            GRAFANA_SVC[Svc: grafana]
        end

        INGRESS --> FE_SVC
        INGRESS -- Path /api --> APIGW_SVC
        INGRESS -- Path /grafana --> GRAFANA_SVC
        INGRESS -- Path /kibana --> KIBANA_SVC
        INGRESS -- Path /zipkin --> ZIPKIN_SVC
        INGRESS -- Path /adminer --> ADMINER_SVC
        
        APIGW_P -->|K8s DNS| CS_SVC
        APIGW_P -->|K8s DNS| DS_SVC
        APIGW_P -->|K8s DNS| ES_SVC

        DS_P -->|K8s DNS| CS_SVC
        ES_P -->|K8s DNS| CS_SVC
        SR_P -->|K8s DNS| CS_SVC %% If service-registry is a client of config-server

        DS_P -->|K8s DNS| DB_DEPT_SVC
        ES_P -->|K8s DNS| DB_EMP_SVC
        
        DS_P -->|K8s DNS| RMQ_SVC
        ES_P -->|K8s DNS| RMQ_SVC
        
        CS_P --> GIT[Git Repo (External)]

        %% Pods connect to services
        APIGW_P -.-> APIGW_SVC
        CS_P -.-> CS_SVC
        DS_P -.-> DS_SVC
        ES_P -.-> ES_SVC
        FE_P -.-> FE_SVC
        SR_P -.-> SR_SVC
        DB_DEPT_STS -.-> DB_DEPT_SVC
        DB_EMP_STS -.-> DB_EMP_SVC
        RMQ_STS -.-> RMQ_SVC
        ZIPKIN_P -.-> ZIPKIN_SVC
        ADMINER_P -.-> ADMINER_SVC
        LOGSTASH_P -.-> LOGSTASH_SVC
        KIBANA_P -.-> KIBANA_SVC
        ELASTIC_STS -.-> ELASTIC_SVC
        PROM_P -.-> PROM_SVC
        GRAFANA_P -.-> GRAFANA_SVC

        %% Logging and Monitoring data flow (conceptual)
        %% APIGW_P -- logs --> LOGSTASH_P (via node log collector typically)
        %% DS_P -- metrics --> PROM_P (via /actuator/prometheus)
    end
    U --> INGRESS

    classDef k8sDeployment fill:#lightgreen,stroke:#333,stroke-width:2px;
    classDef k8sStatefulSet fill:#PaleTurquoise,stroke:#333,stroke-width:2px;
    classDef k8sService fill:#Gold,stroke:#333,stroke-width:2px;
    classDef k8sPVC fill:#Wheat,stroke:#333,stroke-width:2px;
    classDef k8sTool fill:#lightgrey,stroke:#333,stroke-width:2px;
    classDef k8sIngress fill:#Plum,stroke:#333,stroke-width:2px;

    class APIGW_P,CS_P,DS_P,ES_P,FE_P,SR_P,ZIPKIN_P,ADMINER_P,LOGSTASH_P,KIBANA_P,PROM_P,GRAFANA_P k8sDeployment;
    class DB_DEPT_STS,DB_EMP_STS,RMQ_STS,ELASTIC_STS k8sStatefulSet;
    class APIGW_SVC,CS_SVC,DS_SVC,ES_SVC,FE_SVC,SR_SVC,DB_DEPT_SVC,DB_EMP_SVC,RMQ_SVC,ZIPKIN_SVC,ADMINER_SVC,ELASTIC_SVC,LOGSTASH_SVC,KIBANA_SVC,PROM_SVC,GRAFANA_SVC k8sService;
    class PVC_DEPT,PVC_EMP,PVC_RMQ,PVC_ELASTIC,PVC_PROM,PVC_GRAFANA k8sPVC;
    class INGRESS k8sIngress;
```

**Key for Kubernetes Diagram:**
*   `Ingress` is the main entry point from outside the cluster.
*   Services (`Svc`) provide stable internal endpoints (ClusterIPs) and DNS names.
*   Pods (Deployments like `APIGW_P` or StatefulSets like `DB_DEPT_STS`) run the actual application containers.
*   Service discovery is via Kubernetes DNS (e.g., `api-gateway` Pod calls `department-service` Service).
*   `service-registry` Pod runs with Eureka disabled; its original discovery role is handled by K8s DNS.
*   PersistentVolumeClaims (PVCs) provide storage for stateful applications.

These diagrams are simplified and focus on key interactions. More detailed views could be created for specific flows.
```
