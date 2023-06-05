#!/bin/bash

# Function to execute commands remotely using SSH
execute_ssh_command() {
  local host="$1"
  local user="$2"
  local private_key="$3"
  local command="$4"

  ssh -i "$private_key" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$user@$host" "$command"
}

# Function to compress and copy the log file
compress_and_copy_log() {
  local source_host="$1"
  local source_user="$2"
  local source_private_key="$3"
  local log_file="$4"
  local destination_host="$5"
  local destination_user="$6"
  local destination_private_key="$7"
  local destination_directory="$8"

  local log_file_name=$(basename "$log_file")
  local destination_directory_with_timestamp="$destination_directory/$(date +'%Y%m%d%H%M%S')"

  # Create the timestamped directory on the destination host
  execute_ssh_command "$destination_host" "$destination_user" "$destination_private_key" "mkdir -p $destination_directory_with_timestamp"

  # Compress the log file
  tar -czf - "$log_file" | execute_ssh_command "$destination_host" "$destination_user" "$destination_private_key" "cat > $destination_directory_with_timestamp/$log_file_name.tar.gz"
}

# Main script

# Check if log file, destination host, and destination directory arguments are provided
if [ $# -lt 4 ]; then
  echo "Usage: $0 <log_file> <destination_host> <destination_directory>"
  exit 1
fi

log_file="$1"
destination_host="$2"
destination_directory="$3"

# Check if the log file exists
if [ ! -f "$log_file" ]; then
  echo "Error: Log file $log_file not found."
  exit 1
fi

# Check if the destination host and directory are provided
if [ -z "$destination_host" ] || [ -z "$destination_directory" ]; then
  echo "Error: Destination host or directory not provided."
  exit 1
fi

# Prompt for source host SSH connection details
read -p "Enter source user@host: " source_user_host
read -p "Enter path to source private key: " source_private_key

# Prompt for destination host SSH connection details
read -p "Enter destination user@host: " destination_user_host
read -p "Enter path to destination private key: " destination_private_key

# Parse source user and host
source_user=$(echo "$source_user_host" | cut -d "@" -f1)
source_host=$(echo "$source_user_host" | cut -d "@" -f2)

# Parse destination user and host
destination_user=$(echo "$destination_user_host" | cut -d "@" -f1)
destination_host=$(echo "$destination_user_host" | cut -d "@" -f2)

# Compress and copy the log file
compress_and_copy_log "$source_host" "$source_user" "$source_private_key" "$log_file" "$destination_host" "$destination_user" "$destination_private_key" "$destination_directory"

echo "Log file compressed and copied successfully to $destination_host:$destination_directory_with_timestamp."

