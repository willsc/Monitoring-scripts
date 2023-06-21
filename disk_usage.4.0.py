#!/usr/bin/env python3

import subprocess
import csv

# Get all running pods
cmd = "kubectl get pods --no-headers=true"
pods_output = subprocess.check_output(cmd, shell=True, text=True).strip()
pods = pods_output.split("\n")

# Prepare CSV file
csv_file = "pod_disk_usage.csv"
headers = ["Pod", "Container", "Size", "Used", "Available", "Use Percentage", "Mounted On"]
with open(csv_file, "w", newline="") as file:
    writer = csv.writer(file)
    writer.writerow(headers)

    # Retrieve disk usage information for each pod
    for pod in pods:
        fields = pod.split()
        pod_name = fields[0]
        pod_status = fields[2]

        # Check if pod is in desired state
        if pod_status not in ["Terminating", "CrashLoopBackOff", "ContainerCreating"]:
            # Check if pod has containers
            cmd = f"kubectl get pod {pod_name} -o json"
            output = subprocess.check_output(cmd, shell=True, text=True)

            if '"containers": []' not in output:
                # Get all containers in the pod
                containers = subprocess.check_output(f"kubectl get pod {pod_name} -o jsonpath='{{.spec.containers[*].name}}'", shell=True, text=True).strip().split()

                # Retrieve disk usage information for each container
                for container in containers:
                    cmd = f"kubectl exec {pod_name} -c {container} -- df -H | grep -e  '\/opt' -e '\/kafka' -e '\/mnt' -e 'overlay'"
                    output = subprocess.check_output(cmd, shell=True, text=True)

                    # Parse and extract relevant information
                    lines = output.strip().split("\n")
                    for line in lines:
                        usage_fields = line.split()
                        if len(usage_fields) >= 6:
                            row = [pod_name, container] + usage_fields[1:6]
                            writer.writerow(row)

print(f"Disk usage information saved in {csv_file}.")
