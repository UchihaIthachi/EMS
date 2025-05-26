#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

# Define service names - these should match directory names and services in compose files
JAVA_SERVICES=("service-registry" "config-server" "api-gateway" "department-service" "employee-service")
# Add frontend or other services if they have a build step managed by this script

COMPOSE_FILES="-f deploy/docker-compose.yml -f deploy/docker-compose.dev.yml"
PROFILES=() # Array to hold selected profiles

# --- Helper Functions ---
build_service() {
  local service_name=$1
  if [[ -d "$service_name" ]] && [[ -f "$service_name/mvnw" ]]; then
    echo "Building $service_name..."
    (cd "$service_name" && ./mvnw clean package -DskipTests) # Skipping tests for faster dev build
  else
    echo "Skipping build for $service_name: Not a Java service with mvnw or directory not found."
  fi
}

build_all_java() {
  for service in "${JAVA_SERVICES[@]}"; do
    build_service "$service"
  done
}

print_usage() {
  echo "Usage: $0 [ACTION] [SERVICE_NAMES.../OPTIONS]"
  echo "Actions:"
  echo "  build [service...]   Build specified Java services (e.g., api-gateway department-service), or all if none specified."
  echo "  up [options]       Start services using Docker Compose with local JARs. Docker Compose options can be passed (e.g., -d, --scale)."
  echo "                     Use --profile <name> to activate profiles (e.g., --profile logging --profile monitoring)."
  echo "  down               Stop services."
  echo "  logs [service...]  Follow logs for specified services, or all."
  echo "  ps                 List running services."
  echo "  help               Show this help message."
  echo
  echo "Profiles for 'up' command:"
  echo "  --profile logging      Include logging stack (ELK)."
  echo "  --profile monitoring   Include monitoring stack (Prometheus, Grafana)."
  echo "  --profile "*"          Include all optional profiles."
}

# --- Main Logic ---
ACTION=$1
shift # Remove action from arguments, leaving service names or options

if [[ -z "$ACTION" ]] || [[ "$ACTION" == "help" ]]; then
  print_usage
  exit 0
fi

# Parse --profile options for 'up' command
if [[ "$ACTION" == "up" ]]; then
    NEW_ARGS=()
    while (( "$#" )); do
        case "$1" in
            --profile)
                if [[ -n "$2" ]]; then
                    PROFILES+=("--profile" "$2")
                    shift 2
                else
                    echo "Error: --profile requires an argument." >&2
                    exit 1
                fi
                ;;
            *)
                NEW_ARGS+=("$1")
                shift
                ;;
        esac
    done
    set -- "${NEW_ARGS[@]}" # Reset positional parameters
fi


case "$ACTION" in
  build)
    if [[ $# -eq 0 ]]; then
      build_all_java
    else
      for service_name in "$@"; do
        build_service "$service_name"
      done
    fi
    ;;
  up)
    echo "Starting services with local JARs (if built)..."
    echo "Using profiles: ${PROFILES[*]}"
    docker-compose $COMPOSE_FILES "${PROFILES[@]}" up "$@"
    ;;
  down)
    echo "Stopping services..."
    # Note: `down` command doesn't use profiles in the same way as `up` for stopping.
    # To remove resources for specific profiles, they are typically stopped when active.
    # `docker-compose down` will stop services defined in the base and dev override.
    docker-compose $COMPOSE_FILES down "$@"
    ;;
  logs)
    docker-compose $COMPOSE_FILES logs -f "$@"
    ;;
  ps)
    docker-compose $COMPOSE_FILES ps "$@"
    ;;
  *)
    echo "Invalid action: $ACTION"
    print_usage
    exit 1
    ;;
esac

exit 0
