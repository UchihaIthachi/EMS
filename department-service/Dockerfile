# Use an OpenJDK base image
FROM openjdk:17-jdk-slim

# Add a volume for logs (optional)
VOLUME /tmp

# Copy the built JAR file
COPY ./target/department-service-*.jar app.jar

# Expose the port on which the service runs
EXPOSE 8083

# Run the application
ENTRYPOINT ["java", "-jar", "/app.jar"]

