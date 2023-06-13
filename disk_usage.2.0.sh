#!/bin/bash

# Set the namespace name
NAMESPACE="your-namespace"

# Set the output CSV file
OUTPUT_FILE="pod_disk_usage.csv"

# Get all pods in the namespace
PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers -o custom-columns=":metadata.name")

# Initialize lists for pods and containers
POD_LIST=()
CONTAINER_LIST=()

# Loop through each pod
for pod in $PODS; do
  # Get the containers in the pod
  CONTAINERS=$(kubectl get pod "$pod" -n "$NAMESPACE" -o jsonpath='{.spec.containers[*].name}')

  # Check if containers exist
  if [[ -n "$CONTAINERS" ]]; then
    # Add pod to the pod list
    POD_LIST+=("$pod")
    
    # Add containers to the container list
    CONTAINER_LIST+=("$CONTAINERS")
  fi
done

# Write the output to CSV
echo "Pod,Container,Filesystem,Size,Used,Available,Mounted On" > "$OUTPUT_FILE"
for ((i=0; i<${#POD_LIST[@]}; i++)); do
  pod="${POD_LIST[i]}"
  containers="${CONTAINER_LIST[i]}"
  
  # Loop through each container
  while IFS= read -r container; do
    # Get disk usage using df -h
    disk_usage=$(kubectl exec -n "$NAMESPACE" "$pod" -c "$container" -- df -h 2>/dev/null)

    # If container not found, exec into the pod without container
    if [[ -z "$disk_usage" ]]; then
      disk_usage=$(kubectl exec -n "$NAMESPACE" "$pod" -- df -h)
    fi

    # Filter and format the output
    filtered_disk_usage=$(echo "$disk_usage" | awk 'NR>1 && ($6 ~ /.*opt.*|.*kafka.*/) {print " ," $2 ", " $3 ", " $4 ", " $6}')

    # Write to CSV
    while IFS= read -r line; do
      echo "$pod,$container,$line" >> "$OUTPUT_FILE"
    done <<< "$filtered_disk_usage"
  done <<< "$containers"
done

echo "Disk usage information written to $OUTPUT_FILE."

