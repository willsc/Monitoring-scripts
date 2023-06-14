#!/usr/bin/env python3

import subprocess
import csv

def retrieve_pod_containers(namespace, output_file):
    # Retrieve pod names in the namespace
    pod_command = f"kubectl get pods -n {namespace} -o jsonpath='{{.items[*].metadata.name}}'"
    pod_names = subprocess.check_output(pod_command, shell=True).decode().split()

    with open(output_file, mode='w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(["Pod Name", "Container Name", "Filesystem", "Size", "Used", "Available", "Mounted On"])

        for pod_name in pod_names:
            # Check if the pod has containers
            container_command = f"kubectl get pod {pod_name} -n {namespace} -o jsonpath='{{.spec.containers[*].name}}'"
            containers = subprocess.check_output(container_command, shell=True).decode().split()

            if not containers:
                # If no containers exist, exec into the pod directly
                exec_command = f"kubectl exec -it {pod_name} -n {namespace} -- df -h | grep -E '^\./opt|/kafka'"
                output = subprocess.check_output(exec_command, shell=True).decode().splitlines()
                write_output_to_csv(writer, pod_name, None, output)
            else:
                # If containers exist, exec into each container
                for container_name in containers:
                    exec_command = f"kubectl exec -it {pod_name} -c {container_name} -n {namespace} -- df -h | grep -E '^\./opt|/kafka'"
                    output = subprocess.check_output(exec_command, shell=True).decode().splitlines()
                    write_output_to_csv(writer, pod_name, container_name, output)


def write_output_to_csv(writer, pod_name, container_name, output):
    for line in output:
        filesystem, size, used, available, percent, mounted_on = line.split()
        writer.writerow([pod_name, container_name, filesystem, size, used, available, mounted_on])


# Example usage
namespace = "your-namespace"
output_file = "disk_usage.csv"
retrieve_pod_containers(namespace, output_file)

