#!/bin/bash

# Email configuration
SMTP_SERVER='your_smtp_server'
SMTP_PORT=587
SENDER_EMAIL='sender@example.com'
RECIPIENT_EMAIL='recipient@example.com'

# Path to the CSV file
CSV_FILE='path/to/your/csv_file.csv'

# Temporary file to store found lines
FOUND_LINES_FILE=$(mktemp)

# Function to send email
send_email() {
  local line_number=$1
  local line_content=$2
  local subject="FA, ST, or SU Found on Line ${line_number}"
  local message="Line ${line_number}: ${line_content}"

  echo -e "Subject: $subject\n\n$message" | \
    sendmail -t "$RECIPIENT_EMAIL"
}

# Function to check lines for FA, ST, or SU
check_lines() {
  while IFS= read -r line; do
    case $line in
      *,FA)
        echo "$line" >> "$FOUND_LINES_FILE"
        ;;
      *,ST)
        echo "$line" >> "$FOUND_LINES_FILE"
        ;;
      *,SU)
        echo "$line" >> "$FOUND_LINES_FILE"
        ;;
      *)
        ;;
    esac
  done < "$CSV_FILE"
}

# Function to check if the CSV file is new
is_new_file() {
  local current_time=$(date +%s)
  local file_creation_time=$(date -r "$CSV_FILE" +%s)
  local time_diff=$((current_time - file_creation_time))

  if ((time_diff <= 300)); then
    return 0
  else
    return 1
  fi
}

# Function to check flag and file creation time
check_flag_and_file() {
  if [[ -f sent_email.flag && ! $(is_new_file) ]]; then
    # Flag file exists and file is not new, indicating that the email has already been sent
    return 1
  fi
}

# Main script
main() {
  check_flag_and_file || exit 0

  check_lines

  # Send email if found lines exist
  if [[ -s $FOUND_LINES_FILE ]]; then
    while IFS= read -r found_line; do
      line_number=$(grep -nF "$found_line" "$CSV_FILE" | cut -d: -f1)
      send_email "$line_number" "$found_line"
    done < "$FOUND_LINES_FILE"

    # Create the flag file
    touch sent_email.flag
  fi

  # Clean up temporary file
  rm "$FOUND_LINES_FILE"
}

# Call the main function
main

