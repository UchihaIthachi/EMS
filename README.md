Here's the updated README with additional design patterns included:

---

# **Employee Management System (EMS) - Backend**

This repository contains the backend implementation of an **Employee Management System (EMS)**. The project leverages **Spring Boot** in a modern microservices architecture, demonstrating advanced Spring Cloud capabilities, distributed systems design, and inter-service communication.

---

## **Table of Contents**

1. [Project Highlights](#project-highlights)
2. [System Architecture](#system-architecture)
3. [Design Patterns](#design-patterns)
4. [Microservices Overview](#microservices-overview)
5. [API Documentation](#api-documentation)
6. [Setup Instructions](#setup-instructions)
7. [Future Enhancements](#future-enhancements)
8. [Contributors](#contributors)

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

The project adopts a **microservices-based approach** with a modular and layered architecture.

### **Layered Architecture**

Currently, the backend exposes RESTful APIs accessible via **Postman**. A **front-end interface** using **Angular** is planned for future development. The backend architecture includes the following key components:

1. **Service Registry**: Centralized discovery of microservices.
2. **API Gateway**: Handles routing, authentication, and load balancing.
3. **Distributed Tracing**: Sleuth and Zipkin enable seamless debugging and monitoring of requests.
4. **Asynchronous Communication**: RabbitMQ facilitates event-driven messaging.

---

## **Design Patterns**

This project employs several key design patterns to ensure maintainability, scalability, and performance:

### **1. Repository Pattern**

The data access layer is abstracted using repositories to separate data access logic from business logic.

### **2. Data Transfer Object (DTO) Pattern**

DTOs encapsulate only the required fields for communication, reducing the payload size and improving performance.

### **3. Gateway Pattern**

An **API Gateway** is used to handle client requests and route them to the appropriate microservices. This pattern also centralizes:

- **Authentication**
- **Load balancing**
- **Routing logic**

### **4. Database per Service Pattern**

Each microservice has its own dedicated database to maintain:

- Loose coupling
- Data autonomy

### **5. Sidecar Pattern**

Dedicated **sidecar microservices** are attached for auxiliary tasks like:

- Monitoring
- Logging
- Authentication

### **6. Service Registry Pattern**

A **service registry** is implemented to:

- Automatically locate and register services
- Enable dynamic discovery for seamless inter-service communication

### **7. Circuit Breaker Pattern**

Resilience4j provides a **circuit breaker** to prevent cascading failures by:

- Temporarily stopping requests to failing services
- Providing fallback mechanisms

---

## **Microservices Overview**

1. **Service Registry**:

   - **Netflix Eureka** dynamically registers and discovers microservices.
   - URL: [http://localhost:8761](http://localhost:8761)

2. **API Gateway**:

   - Centralized entry point for client requests.
   - URL: [http://localhost:8080](http://localhost:8080)

3. **Config Server**:

   - Centralized configuration stored in a Git repository.
   - Repository: [Config Repo](https://github.com/dulaaann/CONFIG-REPO.git)
   - Port: `8888`

4. **Employee Service**:

   - CRUD operations for employee management.
   - Integrates Resilience4j for fault tolerance.

5. **Department Service**:

   - Handles department-related operations.
   - Communicates with Employee Service via Feign Clients.

6. **RabbitMQ**:

   - Enables asynchronous communication for event-driven microservices.
   - Management Console: [http://localhost:15672](http://localhost:15672)

7. **Zipkin**:
   - Tracks distributed requests for monitoring and debugging.
   - Dashboard: [http://localhost:9411](http://localhost:9411)

---

## **API Documentation**

### **Employee Service**

- **GET /employees/{id}**  
  Retrieves an employee's details by ID.
- **POST /employees**  
  Adds a new employee record.
- **PUT /employees/{id}**  
  Updates an employee record.
- **DELETE /employees/{id}**  
  Deletes an employee record.

### **Department Service**

- **GET /departments/{id}**  
  Retrieves a department by ID.
- **POST /departments**  
  Adds a new department record.

---

## **Setup Instructions**

### **Prerequisites**

- Docker
- JDK 11+
- Maven
- MySQL

### **Steps to Run**

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
   - **Service Registry**: [http://localhost:8761](http://localhost:8761)
   - **API Gateway**: [http://localhost:8080](http://localhost:8080)
   - **Config Server**: [http://localhost:8888](http://localhost:8888)

---

## **Future Enhancements**

- Integrate Redis for caching.
- Add centralized logging with the ELK stack.
- Implement Kubernetes for service scaling.
- Enhance API security using OAuth2.
- Develop a front-end interface using Angular.

---

## **Contributors**

**Harshana Lakshara**

- **Role**: Designer and Developer
- **Contact**: harshana@example.com
- **LinkedIn**: [Profile](https://linkedin.com/in/harshana)

---

## **License**

This project is licensed under the MIT License.

---
