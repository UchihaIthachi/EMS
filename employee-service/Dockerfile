# Use an OpenJDK base image
FROM openjdk:17-jdk-slim

# Add a volume for logs (optional)
VOLUME /tmp

# Copy the built JAR file
COPY ./target/employee-service-*.jar app.jar

# Expose the port on which the service runs
EXPOSE 8084

# Run the application
ENTRYPOINT ["java", "-jar", "/app.jar"]
