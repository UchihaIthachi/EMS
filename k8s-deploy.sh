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
  echo "  help                  Show this help message."
  echo
  echo "Available categories (in order of application):"
  for item in "${APPLY_ORDER[@]}"; do
    if [[ "$item" == "00-namespace.yaml" ]]; then
      echo "  namespace (applies 00-namespace.yaml)"
    else
      echo "  $item"
    fi
  done
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
ACTION=$1
shift # Remove action from arguments

if [[ -z "$ACTION" ]] || [[ "$ACTION" == "help" ]]; then
  print_usage
  exit 0
fi

case "$ACTION" in
  apply)
    if [[ $# -eq 0 ]]; then # Apply all
      echo "Applying all resources to namespace '$NAMESPACE'..."
      for item in "${APPLY_ORDER[@]}"; do
        path_item=$( [[ "$item" == "00-namespace.yaml" ]] && echo "$K8S_DIR/$item" || echo "$K8S_DIR/$item" )
        name_item=$( [[ "$item" == "00-namespace.yaml" ]] && echo "namespace" || echo "$item" )
        apply_category "$path_item" "$name_item"
      done
      echo "All resources applied."
    else # Apply specific categories
      for category_name_arg in "$@"; do
        found=0
        if [[ "$category_name_arg" == "namespace" ]]; then
            apply_category "$K8S_DIR/00-namespace.yaml" "namespace"
            found=1
        else
            for item_order in "${APPLY_ORDER[@]}"; do
                if [[ "$item_order" == "$category_name_arg" ]]; then
                    apply_category "$K8S_DIR/$category_name_arg" "$category_name_arg"
                    found=1
                    break
                fi
            done
        fi
        if [[ $found -eq 0 ]]; then
            echo "WARN: Category '$category_name_arg' not recognized or not in APPLY_ORDER. Skipping."
        fi
      done
      echo "Specified categories applied."
    fi
    ;;

  delete)
    if [[ $# -eq 0 ]]; then # Delete all (in reverse order, namespace handled specially)
      echo "Deleting all resources from namespace '$NAMESPACE' (excluding namespace itself by default)..."
      REVERSE_ORDER=()
      for i in $(seq $((${#APPLY_ORDER[@]} - 1)) -1 0); do
        REVERSE_ORDER+=("${APPLY_ORDER[i]}")
      done
      for item in "${REVERSE_ORDER[@]}"; do
        path_item=$( [[ "$item" == "00-namespace.yaml" ]] && echo "$K8S_DIR/$item" || echo "$K8S_DIR/$item" )
        name_item=$( [[ "$item" == "00-namespace.yaml" ]] && echo "namespace_placeholder" || echo "$item" ) # Special handling for namespace
        if [[ "$name_item" == "namespace_placeholder" ]]; then
            echo "Note: Namespace '$NAMESPACE' is not deleted by 'delete all'. Use '$0 delete namespace' to delete it specifically."
            continue
        fi
        delete_category "$path_item" "$name_item"
      done
      echo "All specified resources deleted."
    else # Delete specific categories
      for category_name_arg in "$@"; do
        found=0
        if [[ "$category_name_arg" == "namespace" ]]; then
            delete_category "$K8S_DIR/00-namespace.yaml" "namespace"
            found=1
        else
             # For specific deletion, order doesn't strictly matter as much as for apply-all
            delete_category "$K8S_DIR/$category_name_arg" "$category_name_arg"
            found=1 # Assume valid if user provides it, warning will come from delete_category if dir not found
        fi
         if [[ $found -eq 0 ]]; then # Should not happen with current logic but good check
            echo "WARN: Category '$category_name_arg' not recognized. Skipping."
        fi
      done
      echo "Specified categories deleted."
    fi
    ;;

  status)
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

  *)
    echo "Invalid action: $ACTION"
    print_usage
    exit 1
    ;;
esac

exit 0
```
