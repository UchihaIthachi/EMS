# syntax=docker/dockerfile:1
# Build the JAR once on the build machine's own architecture (a JAR is platform-independent),
# then copy it into a small JRE image for each target platform.
FROM --platform=$BUILDPLATFORM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /src
COPY pom.xml .
COPY src ./src
RUN --mount=type=cache,target=/root/.m2 mvn -B -q -DskipTests package && cp target/*.jar /app.jar

FROM eclipse-temurin:17-jre
RUN useradd --system --uid 10001 --no-create-home app
# OpenTelemetry agent is shipped but OFF by default. Turn tracing on by appending
# "-javaagent:/otel/opentelemetry-javaagent.jar" to JAVA_TOOL_OPTIONS and setting OTEL_* env vars.
ARG OTEL_AGENT_VERSION=2.10.0
ADD --chmod=644 https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${OTEL_AGENT_VERSION}/opentelemetry-javaagent.jar /otel/opentelemetry-javaagent.jar
WORKDIR /app
COPY --from=build /app.jar /app/app.jar
USER 10001
EXPOSE 8080
# Sized for small pods: heap follows the container memory limit.
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=70 -XX:+UseSerialGC -Xss512k -XX:+ExitOnOutOfMemoryError"
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
