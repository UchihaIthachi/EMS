# # -------- STAGE 1: Build --------
#     FROM maven:3.9.6-eclipse-temurin-17 AS builder

#     WORKDIR /app
    
#     # 1. Copy just the Maven build files first (to leverage Docker layer caching)
#     COPY pom.xml .
#     COPY mvnw .
#     COPY .mvn .mvn
    
#     # 2. Download dependencies (this layer is cached unless pom.xml changes)
#     RUN mvn dependency:go-offline
    
#     # 3. Now copy the rest of the source code
#     COPY . .
    
#     # 4. Build the JAR (skip tests to speed up)
#     RUN mvn clean package -DskipTests
    
#     # -------- STAGE 2: Run --------
#     FROM openjdk:17-jdk-slim
    
#     VOLUME /tmp
    
#     COPY --from=builder /app/target/*.jar app.jar
    
#     EXPOSE 8083
    
#     ENTRYPOINT ["java", "-jar", "/app.jar"]
FROM openjdk:17-jdk-slim
VOLUME /tmp
COPY target/*.jar app.jar
EXPOSE 8083
ENTRYPOINT ["java", "-jar", "/app.jar"]
