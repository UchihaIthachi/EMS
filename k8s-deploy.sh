#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

NAMESPACE="ems-app"
K8S_DIR="deploy/k8s"

# Define the order of resource categories for apply and reverse order for delete
# Note: 'headless-services' are just services, but often applied before StatefulSets that use them.
# Secrets and ConfigMaps should generally be first.
APPLY_ORDER=(
  "00-namespace.yaml" # Apply namespace file directly first
  "configmaps"
  "secrets"
  "pvcs"
  "headless-services"
  "services"
  "statefulsets"
  "deployments"
  "ingress"
)

print_usage() {
  echo "Usage: $0 [ACTION] [CATEGORY...]"
  echo "Manages application deployment on Kubernetes in the '$NAMESPACE' namespace."
  echo
  echo "Actions:"
  echo "  apply [category...]   Apply all Kubernetes manifests or only for specific categories."
  echo "                        Categories are applied in a predefined order."
  echo "                        If no category is specified, ALL are applied."
  echo "  delete [category...]  Delete all Kubernetes resources or only for specific categories."
  echo "                        Categories are deleted in reverse order of application."
  echo "                        If no category is specified, ALL are deleted."
  echo "  status                Show status of pods, services, and ingresses in the namespace."
  echo "  update_and_apply <tag> Update image tags in deployment YAMLs and apply all resources."
  echo "                        Example: $0 update_and_apply v1.2.3"
  echo "  help                  Show this help message."
  echo
  echo "Available categories (for apply/delete actions, in order of application):"
  for item in "${APPLY_ORDER[@]}"; do
    if [[ "$item" == "00-namespace.yaml" ]]; then
      echo "  namespace (applies 00-namespace.yaml)"
    else
      echo "  $item"
    fi
  done
}

# --- Configuration for Image Updates ---
# Services whose images need to be updated by update_and_apply
# These should match the service names used in the Docker image names and K8s deployment files.
SERVICES_TO_UPDATE_IMAGES=(
  "service-registry"
  "config-server"
  "api-gateway"
  "department-service"
  "employee-service"
  "frontend"
)

# Current image prefix in K8s YAMLs (e.g., Docker Hub username or current registry)
OLD_IMAGE_PREFIX="harshana2020"
# New image prefix (e.g., GHCR path: ghcr.io/your-github-username-or-org)
# IMPORTANT: Replace 'your-github-username-or-org' with your actual GitHub username or organization.
NEW_IMAGE_PREFIX="ghcr.io/your-github-username-or-org"


# --- Helper Functions ---

# Function to apply all manifests (used by 'apply' and 'update_and_apply')
apply_all_resources() {
  echo "Applying all resources to namespace '$NAMESPACE'..."
  for item in "${APPLY_ORDER[@]}"; do
    local path_item="$K8S_DIR/$item"
    local name_item="$item"
    if [[ "$item" == "00-namespace.yaml" ]]; then
      name_item="namespace" # Use 'namespace' for messaging for this special file
    fi
    apply_category "$path_item" "$name_item" # apply_category handles if it's the namespace file or a dir
  done
  echo "All resources applied."
}

# Function to apply manifests for a given category
apply_category() {
  local category_path=$1
  local category_name=$2 # For display purposes

  if [[ "$category_path" == "$K8S_DIR/00-namespace.yaml" ]]; then
    if [[ -f "$category_path" ]]; then
      echo "Applying Namespace: $category_path..."
      kubectl apply -f "$category_path"
    else
      echo "WARN: Namespace file $category_path not found."
    fi
  elif [[ -d "$category_path" ]]; then
    echo "Applying category '$category_name' from $category_path..."
    # Ensure kubectl is available
    if ! command -v kubectl &> /dev/null; then
        echo "ERROR: kubectl command not found. Please install kubectl."
        exit 1
    fi
    kubectl apply -n "$NAMESPACE" -R -f "$category_path"
  else
    echo "WARN: Directory $category_path for category '$category_name' not found. Skipping."
  fi
}

# Function to delete manifests for a given category
delete_category() {
  local category_path=$1
  local category_name=$2 # For display purposes

  if [[ "$category_path" == "$K8S_DIR/00-namespace.yaml" ]]; then
    # Deleting the namespace itself is a big step, often done last or manually.
    # This script will not delete the namespace by default with "delete all".
    # It can be deleted by explicitly calling "delete namespace".
    if [[ "$category_name" == "namespace" ]]; then # Only if explicitly requested
        if [[ -f "$category_path" ]]; then
            echo "Deleting Namespace: $category_path..."
            kubectl delete -f "$category_path" --wait=false # Don't wait for namespace to be fully gone
        else
            echo "WARN: Namespace file $category_path not found."
        fi
    else
        echo "Skipping namespace deletion for category '$category_name'. Delete explicitly if needed."
    fi
  elif [[ -d "$category_path" ]]; then
    echo "Deleting category '$category_name' from $category_path..."
    kubectl delete -n "$NAMESPACE" -R -f "$category_path" --wait=false
  else
    echo "WARN: Directory $category_path for category '$category_name' not found. Skipping."
  fi
}

# --- Main Logic ---
ACTION=${1:-help} # Default to help if no action is provided
shift || true # Shift arguments, ignore error if no arguments left

# Ensure K8S_DIR is set (it's defined at the top)
if [ -z "$K8S_DIR" ]; then
  echo "ERROR: K8S_DIR is not set. Script cannot proceed."
  exit 1
fi


case "$ACTION" in
  apply)
    if [[ $# -eq 0 ]]; then # Apply all
      apply_all_resources
    else # Apply specific categories
      echo "Applying specific categories to namespace '$NAMESPACE'..."
      for category_name_arg in "$@"; do
        local found=0
        local category_path_to_apply=""
        local category_name_to_apply="$category_name_arg"

        if [[ "$category_name_arg" == "namespace" ]]; then
            category_path_to_apply="$K8S_DIR/00-namespace.yaml"
            found=1
        else
            # Check if the arg is a valid category directory
            if [[ " ${APPLY_ORDER[*]} " =~ " ${category_name_arg} " ]] && [[ -d "$K8S_DIR/$category_name_arg" ]]; then
                category_path_to_apply="$K8S_DIR/$category_name_arg"
                found=1
            fi
        fi

        if [[ $found -eq 1 ]]; then
            apply_category "$category_path_to_apply" "$category_name_to_apply"
        else
            echo "WARN: Category '$category_name_arg' not recognized, not in APPLY_ORDER, or directory not found. Skipping."
        fi
      done
      echo "Specified categories applied."
    fi
    ;;

  update_and_apply)
    NEW_IMAGE_TAG="$1"
    if [ -z "$NEW_IMAGE_TAG" ]; then
      echo "ERROR: New image tag must be provided for update_and_apply."
      echo "Usage: $0 update_and_apply <new_image_tag>"
      exit 1
    fi

    echo "Updating images to tag '$NEW_IMAGE_TAG' with new prefix '${NEW_IMAGE_PREFIX}'..."

    if ! command -v sed &> /dev/null; then
        echo "ERROR: sed command not found. Please install sed."
        exit 1
    fi

    for service_name in "${SERVICES_TO_UPDATE_IMAGES[@]}"; do
      # Construct the path to the Kubernetes deployment YAML file
      # Assumes a naming convention like 'service-name-deployment.yaml'
      yaml_file="${K8S_DIR}/deployments/${service_name}-deployment.yaml"

      if [ -f "$yaml_file" ]; then
        echo "Updating image in $yaml_file for service $service_name..."
        # The sed command needs to be robust.
        # It looks for 'image: <OLD_IMAGE_PREFIX>/<service_name>:.*'
        # and replaces it with 'image: <NEW_IMAGE_PREFIX>/<service_name>:<NEW_IMAGE_TAG>'
        # Using | as a delimiter for sed to avoid issues with slashes in paths/URLs.
        # sed -i will modify the file in place. For macOS, sed -i '' is needed.
        # Using a temporary variable for sed command for clarity
        local sed_command="s|image: ${OLD_IMAGE_PREFIX}/${service_name}:.*|image: ${NEW_IMAGE_PREFIX}/${service_name}:${NEW_IMAGE_TAG}|g"

        # Check OS for sed in-place edit syntax
        local sed_inplace_opt="-i"
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed_inplace_opt="-i ''"
        fi

        if sed $sed_inplace_opt "$sed_command" "$yaml_file"; then
          echo "Successfully updated image for $service_name in $yaml_file."
        else
          echo "ERROR: Failed to update image for $service_name in $yaml_file using sed."
          # Optionally, exit here or continue with other files
        fi
      else
        echo "WARN: YAML file $yaml_file not found for service $service_name. Skipping image update for this service."
      fi
    done

    echo "Image updates complete. Proceeding to apply all resources..."
    apply_all_resources
    ;;

  delete)
    if [[ $# -eq 0 ]]; then # Delete all (in reverse order, namespace handled specially)
      echo "Deleting all resources from namespace '$NAMESPACE' (excluding namespace itself by default)..."
      REVERSE_ORDER=()
      # Correct way to reverse APPLY_ORDER
      for i in $(seq $((${#APPLY_ORDER[@]} - 1)) -1 0); do
        REVERSE_ORDER+=("${APPLY_ORDER[i]}")
      done

      for item in "${REVERSE_ORDER[@]}"; do
        local path_item="$K8S_DIR/$item"
        local name_item="$item" # Original item name from APPLY_ORDER

        if [[ "$item" == "00-namespace.yaml" ]]; then
          echo "Note: Namespace '$NAMESPACE' is not deleted by 'delete all'. Use '$0 delete namespace' to delete it specifically."
          continue # Skip deleting namespace in 'delete all'
        fi
        delete_category "$path_item" "$name_item"
      done
      echo "All specified non-namespace resources deleted."
    else # Delete specific categories
      echo "Deleting specific categories from namespace '$NAMESPACE'..."
      for category_name_arg in "$@"; do
        local found=0
        local category_path_to_delete=""
        local category_name_to_delete="$category_name_arg"

        if [[ "$category_name_arg" == "namespace" ]]; then
            category_path_to_delete="$K8S_DIR/00-namespace.yaml"
            found=1
        else
            # Check if the arg is a valid category directory or file from APPLY_ORDER
            if [[ " ${APPLY_ORDER[*]} " =~ " ${category_name_arg} " ]]; then
                 category_path_to_delete="$K8S_DIR/$category_name_arg"
                 found=1 # Assume it's a directory or the namespace file
            fi
        fi

        if [[ $found -eq 1 ]]; then
            delete_category "$category_path_to_delete" "$category_name_to_delete"
        else
            echo "WARN: Category '$category_name_arg' not recognized or not in APPLY_ORDER. Skipping deletion."
        fi
      done
      echo "Specified categories deletion process initiated."
    fi
    ;;

  status)
    echo "Status for namespace '$NAMESPACE':"
    echo "--- Pods ---"
    # Ensure kubectl is available
    if ! command -v kubectl &> /dev/null; then
        echo "ERROR: kubectl command not found. Please install kubectl."
        exit 1
    fi
    echo "Status for namespace '$NAMESPACE':"
    echo "--- Pods ---"
    kubectl get pods -n "$NAMESPACE" -o wide
    echo ""
    echo "--- Services ---"
    kubectl get services -n "$NAMESPACE"
    echo ""
    echo "--- Ingresses ---"
    kubectl get ingress -n "$NAMESPACE"
    echo ""
    echo "--- PersistentVolumeClaims ---"
    kubectl get pvc -n "$NAMESPACE"
    ;;

  help)
    print_usage
    exit 0
    ;;

  *)
    echo "Invalid action: $ACTION"
    print_usage
    exit 1
    ;;
esac

exit 0
```
