# Employee Management System (EMS)

This repository contains the Employee Management System (EMS), a comprehensive application demonstrating a modern microservices architecture. It includes backend services built with Spring Boot and a frontend application built with React/TypeScript.

## Project Overview

The Employee Management System (EMS) is designed to manage employee and department data through a set of interconnected microservices. It showcases best practices in distributed systems, including service discovery, centralized configuration, API gateway patterns, fault tolerance, and containerization for local and Kubernetes deployments.

## Features

*   **Microservices Architecture**: Modular design with independent services for employees, departments, configuration, service discovery, and API gateway.
*   **Employee Management**: CRUD operations for employee records.
*   **Department Management**: CRUD operations for department records.
*   **Centralized Configuration**: Using Spring Cloud Config Server to manage externalized configurations for all microservices.
*   **Service Discovery**: Employs Netflix Eureka for local deployments and Kubernetes DNS for cluster deployments.
*   **API Gateway**: Single entry point for all client requests, handled by Spring Cloud Gateway, providing routing and potential for cross-cutting concerns.
*   **Inter-Service Communication**: Synchronous communication using Feign Clients and asynchronous communication via RabbitMQ.
*   **Distributed Tracing**: Integrated with Zipkin and Sleuth for monitoring and debugging requests across services.
*   **Fault Tolerance**: Demonstrates Circuit Breaker patterns (Resilience4j) for improved system resilience.
*   **Containerized Deployment**: Dockerized services for easy local setup using Docker Compose and production-like deployments on Kubernetes.
*   **CI/CD Ready**: Includes a Jenkinsfile for building, testing, and deploying the application.
*   **Comprehensive Logging & Monitoring**: Support for ELK Stack (Elasticsearch, Logstash, Kibana) for logging and Prometheus/Grafana for metrics and monitoring.
*   **Reactive Frontend**: A user interface built with React, TypeScript, and Vite.

## Technologies Used

### Backend
*   Java 17+
*   Spring Boot 3.x
*   Spring Cloud
*   Spring Data JPA (Hibernate)
*   Spring Cloud Config Server
*   Spring Cloud Gateway
*   Spring Cloud OpenFeign
*   Netflix Eureka (for local discovery)
*   Resilience4j (Circuit Breaker)
*   Spring Sleuth & Zipkin (Distributed Tracing)
*   RabbitMQ (Message Broker)
*   MySQL (Databases)

### Frontend
*   React
*   TypeScript
*   Vite
*   Nginx (for serving frontend static files)

### DevOps & Deployment
*   Docker & Docker Compose
*   Kubernetes (OKE - Oracle Kubernetes Engine targeted)
*   Jenkins (CI/CD)
*   Nexus (Artifact Repository)
*   GitHub Container Registry (GHCR) (intended for K8s images)
*   ArgoCD (for GitOps deployment to Kubernetes)
*   Prometheus & Grafana (Monitoring)
*   ELK Stack (Logging)

## Folder Structure

```
.
├── api-gateway/        # Spring Cloud API Gateway service
├── config-server/      # Spring Cloud Config Server
├── department-service/ # Department microservice
├── employee-service/   # Employee microservice
├── service-registry/   # Eureka Service Registry (for local)
├── frontend/           # React/TypeScript frontend application
├── deploy/             # Deployment scripts and configurations
│   ├── .env.Example    # Example environment variables for Docker Compose
│   ├── docker-compose.yml # Main Docker Compose file for local deployment
│   ├── docker-compose.dev.yml # Docker Compose override for local JAR development
│   ├── k8s/            # Kubernetes manifests
│   │   ├── base/
│   │   ├── configmaps/
│   │   ├── deployments/
│   │   ├── ... (other Kubernetes resources)
│   ├── argo/           # ArgoCD application definition
│   └── init/           # Database initialization scripts
├── .github/            # GitHub specific files (e.g., workflows)
├── Jenkinsfile         # CI/CD pipeline definition for Jenkins
├── cicd.sh             # Helper script for CI/CD tasks
├── k8s-deploy.sh       # Helper script for Kubernetes deployments
├── local-dev.sh        # Helper script for local development loop
└── README.md           # This file
```

## Getting Started

This project can be run locally using Docker Compose or deployed to a Kubernetes cluster.

### Local Deployment Summary
For a quick local setup:
1.  Ensure Docker and Docker Compose are installed.
2.  Clone the repository.
3.  Navigate to the `deploy/` directory and create a `.env` file from `.env.Example`, updating necessary credentials (like `GIT_PAT` if your config repo is private).
4.  Run `docker-compose up -d` from the `deploy/` directory.

For detailed instructions on local deployment, including prerequisites, environment setup, running services with different profiles (e.g., logging, monitoring), and troubleshooting, please refer to:
*   **[Local Deployment Guide (local-deploy.md)](local-deploy.md)**

### Kubernetes Deployment Summary
The application is designed to be deployed on Kubernetes (specifically targeting Oracle Kubernetes Engine - OKE). This involves building Docker images, pushing them to a container registry (like GHCR), and applying Kubernetes manifests.

For comprehensive steps on Kubernetes deployment, CI/CD flow, GitHub Container Registry usage, and ArgoCD integration, please see:
*   **[Kubernetes Deployment Guide (k8s-deploy.md)](k8s-deploy.md)**

## Documentation Links

For more detailed information on specific aspects of this project, please refer to the following documents:

*   **[API Documentation (API_DOC.md)](API_DOC.md)**: Detailed information about the available API endpoints.
*   **[Local Deployment Guide (local-deploy.md)](local-deploy.md)**: Step-by-step instructions for running the application locally using Docker Compose.
*   **[Kubernetes Deployment Guide (k8s-deploy.md)](k8s-deploy.md)**: Comprehensive guide for deploying the application to Kubernetes.
*   **[Kubernetes Configuration Details (kubernetes.md)](kubernetes.md)**: OKE-specific configurations, node architecture, resource tuning, and best practices for Kubernetes.
*   **[System Architecture (architecture.md)](architecture.md)**: In-depth explanation of the system architecture, microservice interactions, design patterns, and best practices.

---
*This README was consolidated from multiple project documentation files.*
