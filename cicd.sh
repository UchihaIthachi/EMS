#!/bin/bash

set -eo pipefail # Exit on error, treat unset variables as an error, and propagate exit status through pipes

# Default values - can be overridden by environment variables
REGISTRY="${REGISTRY:-ghcr.io}"                         # Default to GitHub Container Registry
IMAGE_NAME_PREFIX="${IMAGE_NAME_PREFIX:-${GITHUB_REPOSITORY_OWNER}}" # Default to GitHub repo owner
IMAGE_NAME_PREFIX="${IMAGE_NAME_PREFIX%/}"              # ✅ Remove trailing slash if present
GIT_COMMIT_SHA="${GIT_COMMIT_SHA:-latest}"              # Default to 'latest' if not provided
COMPOSE_FILE_LOCAL="deploy/docker-compose.yml"

# COMPOSE_FILE_CICD="deploy/docker-compose-cicd.yml" # Will be used later

# List of services to build. This should align with your docker-compose files
# and what you intend to deploy.
# Note: mysql*, rabbitmq, zipkin, etc., are usually pulled from Docker Hub.
# We only build our custom services.
SERVICES_TO_BUILD=(
  "service-registry"
  "config-server"
  "api-gateway"
  "department-service"
  "employee-service"
  "frontend"
  # "web-proxy" # web-proxy uses a standard nginx image, so no build needed unless customized
)

# --- Helper Functions ---
log() {
  echo "[CICD_SCRIPT] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

build_image() {
  local service_name=$1
  local image_tag="${REGISTRY}/${IMAGE_NAME_PREFIX,,}/${service_name}:${GIT_COMMIT_SHA}"
  local latest_tag="${REGISTRY}/${IMAGE_NAME_PREFIX,,}/${service_name}:latest"
  local dockerfile_path="./${service_name}/Dockerfile"
  local context_path="./${service_name}"

  if [ ! -f "${dockerfile_path}" ]; then
    dockerfile_path="../${service_name}/Dockerfile"
    context_path="../${service_name}"
    if [ ! -f "${dockerfile_path}" ]; then
      log "ERROR: Dockerfile not found for service ${service_name} in ./${service_name}/ or ../${service_name}/"
      return 1
    fi
  fi

  log "Building ${service_name} -> ${image_tag}"
  log "Context: ${context_path}, Dockerfile: ${dockerfile_path}"

  local build_args_str=""
  if [ "$service_name" == "config-server" ]; then
    if [ -z "$GIT_PAT" ]; then
      log "Warning: GIT_PAT is not set. Build for config-server might fail if it needs to clone private repos."
    else
      build_args_str="--build-arg GIT_PAT=${GIT_PAT}"
    fi
  fi

  if docker buildx build \
      --platform linux/amd64 \
      -t "${image_tag}" \
      -t "${latest_tag}" \
      -f "${dockerfile_path}" \
      ${build_args_str:+$build_args_str} \
      "${context_path}" \
      --push; then
    log "✅ Successfully built and pushed ${image_tag} (and latest)"
    return 0
  else
    log "❌ Build failed for ${image_tag}"
    return 1
  fi
}


push_image() {
  local service_name=$1
  local image_tag="${REGISTRY}/${IMAGE_NAME_PREFIX,,}/${service_name}:${GIT_COMMIT_SHA}"
  local latest_tag="${REGISTRY}/${IMAGE_NAME_PREFIX,,}/${service_name}:latest"

  log "Pushing ${image_tag}"
  if docker push "${image_tag}"; then
    log "Successfully pushed ${image_tag}"
  else
    log "ERROR: Failed to push ${image_tag}"
    exit 1
  fi

  log "Pushing ${latest_tag}"
  if docker push "${latest_tag}"; then
    log "Successfully pushed ${latest_tag}"
  else
    log "ERROR: Failed to push ${latest_tag}"
    exit 1
  fi
}

# --- Main Actions ---
action_build_and_push() {
  log "Starting build and push process..."
  log "Registry: ${REGISTRY}"
  log "Image Name Prefix: ${IMAGE_NAME_PREFIX}"
  log "Git Commit SHA (Tag): ${GIT_COMMIT_SHA}"

  # Login to registry (assuming already done by GitHub Action if running in CI)
  # If running locally and needing to push, you might need `docker login` here.

  for service in "${SERVICES_TO_BUILD[@]}"; do
    log "Processing service: ${service}"
    if build_image "${service}"; then
      log "Image already pushed during buildx step. Skipping separate push for ${service}."
      # push_image "${service}"
    else
      log "Skipping push for ${service} due to build failure."
      # Depending on policy, you might want to exit here:
      # exit 1
    fi
  done
  log "Build and push process completed."
  return 0 # Explicitly return success
}

action_build_local() {
  # This function is for building images locally without pushing
  # It might be useful for testing the build process.
  log "Starting local build process..."
  local all_builds_succeeded=true
  for service in "${SERVICES_TO_BUILD[@]}"; do
    log "Processing service: ${service}"
    if ! build_image "${service}"; then
      all_builds_succeeded=false
      # Decide if you want to stop on first failure or try to build all
      # log "Build failed for ${service}, stopping local build process."
      # return 1 # Or exit 1
    fi
  done

  if $all_builds_succeeded; then
    log "Local build process completed successfully."
    return 0
  else
    log "Local build process completed with one or more build failures."
    return 1
  fi
}

action_build_push_and_deploy() {
  log "Starting build, push, and deploy process..."

  if action_build_and_push; then
    log "Build and push successful. Proceeding to deploy."

    if [ -z "$GIT_COMMIT_SHA" ] || [ "$GIT_COMMIT_SHA" == "latest" ]; then
      log "ERROR: GIT_COMMIT_SHA is not set to a specific commit hash. Cannot proceed with deployment."
      log "Please ensure GIT_COMMIT_SHA is set to the actual commit SHA for deployments."
      return 1
    fi

    if [ ! -f "./k8s-deploy.sh" ]; then
      log "ERROR: ./k8s-deploy.sh script not found. Cannot proceed with deployment."
      return 1
    fi

    chmod +x ./k8s-deploy.sh # Ensure it's executable

    log "Calling k8s-deploy.sh update_and_apply ${GIT_COMMIT_SHA}"
    if ./k8s-deploy.sh update_and_apply "${GIT_COMMIT_SHA}"; then
      log "Deployment triggered successfully by k8s-deploy.sh."
    else
      log "ERROR: k8s-deploy.sh script reported an error during deployment."
      return 1
    fi
  else
    log "ERROR: Build and push process failed. Deployment will not be triggered."
    return 1
  fi
  log "Build, push, and deploy process completed."
}


# --- Script Entrypoint ---
main() {
  local action="${1:-help}" # Default to help if no action provided
  shift || true # Remove the action from the arguments list, ignore error if no args

  case "${action}" in
    build_and_push)
      action_build_and_push "$@"
      ;;
    build_local)
      action_build_local "$@"
      ;;
    build_push_and_deploy)
      action_build_push_and_deploy "$@"
      ;;
    help)
      log "Usage: $0 {build_and_push|build_local|build_push_and_deploy|help}"
      log "  build_and_push: Builds all service images and pushes them to the registry."
      log "  build_local: Builds all service images locally (no push)."
      log "  build_push_and_deploy: Builds, pushes images, then calls k8s-deploy.sh to deploy."
      log "  help: Shows this usage information."
      return 0
      ;;
    *)
      log "ERROR: Unknown action '${action}'."
      log "Usage: $0 {build_and_push|build_local|build_push_and_deploy|help}"
      exit 1
      ;;
  esac
}

# Call main function with all script arguments
main "$@"
