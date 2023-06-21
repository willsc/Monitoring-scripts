#!/usr/bin/env python3

# ./disk_usage.3.0.py default  ~/.kube/config disk_usage_out.csv

import subprocess
import json
import sys
import csv

def execute_command(command):
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    output, error = process.communicate()
    if process.returncode != 0:
        raise Exception(f"Command execution failed: {error.decode('utf-8')}")
    return output.decode('utf-8')

def get_pods(namespace, kubeconfig):
    command = f"kubectl get pods --namespace={namespace} --kubeconfig={kubeconfig} -o json"
    output = execute_command(command)
    pods = json.loads(output)['items']
    return pods

def get_filesystem_usage(pod_name, container_name):
    command = f"kubectl exec {pod_name} --container={container_name} -- df -h  |grep -i -e '\/opt' -e '\/kafka' -e '\/mnt'"
    output = execute_command(command)
    filesystem_usage = output.strip().split("\n")[-1]
    print(filesystem_usage) 
    return filesystem_usage

def parse_filesystem_usage(usage):
    parts = usage.split()
    size = parts[1]
    used = parts[2]
    available = parts[3]
    use_percentage = parts[4]
    mounted_on = parts[5]
    return [size, used, available, use_percentage, mounted_on]

def write_to_csv(data, output_file):
    with open(output_file, mode='w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(['Pod', 'Container', 'Size', 'Used', 'Available', 'Use Percentage', 'Mounted On'])
        writer.writerows(data)

def main(namespace, kubeconfig, output_file):
    pods = get_pods(namespace, kubeconfig)
    output_data = []
    
    for pod in pods:
        pod_name = pod['metadata']['name']
        status = pod['status']['phase']
        
        if "lifecycle" in pod_name or status in ["Terminating", "ContainerCreating"]:
            continue
        
        containers = pod['spec']['containers']
        for container in containers:
            container_name = container['name']
            filesystem_usage = get_filesystem_usage(pod_name, container_name)
            parsed_usage = parse_filesystem_usage(filesystem_usage)
            output_data.append([pod_name, container_name] + parsed_usage)

    write_to_csv(output_data, output_file)

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python script.py <namespace> <kubeconfig> <output_file>")
        sys.exit(1)
    
    namespace = sys.argv[1]
    kubeconfig = sys.argv[2]
    output_file = sys.argv[3]
    main(namespace, kubeconfig, output_file)

