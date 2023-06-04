#!/bin/bash

# Function to check if a command is available
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to extract filesystem usage using df -h from a pod
extract_filesystem_usage() {
  local pod="$1"
  local namespace="$2"
  local output

  output=$(kubectl exec "$pod" -n "$namespace" -- df -h |grep -i mnt | awk '{print $3"\t" $4"\t" $5"\t" $6}' 2>/dev/null)
  if [ $? -eq 0 ]; then
    echo "$pod,$output" >> filesystem_usage_tmp.txt
  else
    echo "Error: Unable to extract filesystem usage from pod: $pod"
  fi
}

# Main script

# Check if kubectl is available
if ! command_exists kubectl; then
  echo "Error: kubectl command not found. Please ensure it is installed and available in the PATH."
  exit 1
fi

# Check if namespace is provided as an argument
if [ $# -lt 1 ]; then
  echo "Usage: $0 <namespace>"
  exit 1
fi

namespace="$1"

# Get the list of pods in the given namespace
pods=$(kubectl get pods -n "$namespace" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "Error: Unable to retrieve the list of pods in namespace: $namespace"
  exit 1
fi

# Create a new CSV file with a header
echo "Pod,Used,Avail,Use%,Mounted" > filesystem_usage_tmp.txt

# Iterate over each pod and extract filesystem usage
for pod in $pods; do
  extract_filesystem_usage "$pod" "$namespace"
done


sed 's/\t/,/g' filesystem_usage_tmp.txt > filesystem_usage.csv
rm filesystem_usage_tmp.txt
echo "Filesystem usage extracted successfully. Output saved to filesystem_usage.csv."

