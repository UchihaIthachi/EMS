# Employee Management System (EMS) - Backend

This repository contains the backend implementation of an **Employee Management System (EMS)**. The project is built using **Spring Boot** with a modern microservices architecture to showcase the use of advanced Spring Cloud features, distributed systems design, and inter-service communication.

---

## **Project Highlights**

### **Technology Stack**

- **Backend**: Spring Boot, Spring Cloud, Hibernate, MySQL, RabbitMQ, Resilience4j, Sleuth, Zipkin, Feign Client.
- **Tools**: Docker, Postman for API testing.
- **Service Registry**: Netflix Eureka for service discovery.
- **Configuration Management**: Spring Cloud Config Server for centralized configuration.
- **Circuit Breaker**: Implemented using Resilience4j and Spring Cloud Bus.

---

## **System Architecture**

The project follows a **microservices-based approach** with a modular and layered architecture.

### **Layered Architecture**

Since the **presentation layer** is not yet developed, a future Angular-based implementation is planned for a front-end interface. Currently, the backend provides RESTful APIs accessible via **Postman**.

1. **Service Registry/Discovery**:

   - **Netflix Eureka** is used for dynamic service discovery, enabling seamless communication between services without hardcoded URLs.

2. **Configuration Management**:

   - A **Spring Cloud Config Server** pulls configuration files from a Git-based repository for centralized configuration.

3. **Circuit Breaker**:

   - Built using **Resilience4j** for fault tolerance.
   - Integrated with **Spring Cloud Bus** for event-driven communication and **RabbitMQ** as a message broker.

4. **Gateway Layer**:
   - Uses Spring Cloud Gateway to handle API routing, load balancing, and centralized request management.

---

## **Key Patterns Used**

### 1. **Service Registry/Discovery Pattern**

- **Netflix Eureka** provides dynamic registration and discovery of microservices.
- Services register themselves with Eureka and interact seamlessly.

### 2. **Config Server Pattern**

- Centralized configuration management using **Spring Cloud Config Server**.
- Configurations are versioned and stored in a Git repository, allowing dynamic updates.

### 3. **Circuit Breaker Pattern**

- Resilience4j prevents cascading failures and manages fallback responses.
- Integrated with Spring Cloud Bus to propagate failure events.

### 4. **API Gateway Pattern**

- Centralized routing and management of all service requests.
- Implements load balancing and enables monitoring of traffic.

---

## **Microservices Overview**

1. **Service Registry**:

   - **Netflix Eureka** for dynamic service registration and discovery.
   - [http://localhost:8761](http://localhost:8761)

2. **API Gateway**:

   - Routes requests to appropriate services and provides entry-point functionality.
   - [http://localhost:8080](http://localhost:8080)

3. **Config Server**:

   - Centralized configuration for all services.
   - Repository: `https://github.com/dulaaann/CONFIG-REPO.git`
   - Default Label: `main`
   - Port: `8888`

4. **Employee Service**:

   - CRUD operations for employee management.
   - Implements a circuit breaker for fault tolerance.

5. **Department Service**:

   - Handles department-related operations.
   - Integrates with Employee Service via Feign Client.

6. **RabbitMQ**:

   - Asynchronous messaging for inter-service communication.
   - Management Console: [http://localhost:15672](http://localhost:15672)

7. **Zipkin**:
   - Distributed tracing for tracking service requests.
   - Dashboard: [http://localhost:9411](http://localhost:9411)

---

## **API Testing**

- **Postman Collection**:  
  Postman is used for testing the REST APIs.  
  You can import the provided `Postman Collection` to explore and test endpoints.

---

## **Setup Instructions**

### Prerequisites

- Docker
- JDK 11+
- Maven
- MySQL

### Steps to Run

1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo.git
   cd your-repo
   ```
2. Build the project:
   ```bash
   mvn clean package
   ```
3. Start services with Docker Compose:
   ```bash
   docker-compose up --build
   ```
4. Access the services:
   - Service Registry: [http://localhost:8761](http://localhost:8761)
   - API Gateway: [http://localhost:8080](http://localhost:8080)
   - Config Server: [http://localhost:8888](http://localhost:8888)

---

## **Future Enhancements**

- Implement a **presentation layer** using **Angular**.
- Add caching using Redis for frequently accessed data.
- Scale microservices with Kubernetes.
- Integrate **Spring Security** with OAuth2 for secure APIs.
- Implement a centralized logging solution with **ELK Stack**.

---

## **Contributors**

Harshana Lakshara

- **Role**: Designer and Developer
- **Contact**: harshana@example.com
- **LinkedIn**: [Profile](https://linkedin.com/in/harshana)

---

**License**: This project is licensed under the MIT License.
