# -------- STAGE 1: Build --------
FROM maven:3.9.6-eclipse-temurin-17 AS builder

WORKDIR /app

# Copy all source code
COPY . .

# Build the JAR (skip tests to speed up)
RUN mvn clean package -DskipTests

# -------- STAGE 2: Run --------
FROM openjdk:17-jdk-slim

# Use a volume for logs if needed
VOLUME /tmp

# Copy the generated jar from the builder stage
COPY --from=builder /app/target/*.jar app.jar

# Expose port (you can override this in docker-compose)
EXPOSE 8888

# Run the app
ENTRYPOINT ["java", "-jar", "/app.jar"]
