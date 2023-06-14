#!/usr/bin/env python3
import csv
import subprocess

class CSVReader:
    def __init__(self, file_path, recipient_email):
        self.file_path = file_path
        self.recipient_email = recipient_email

    def read_csv_and_send_emails(self):
        with open(self.file_path, 'r') as file:
            csv_reader = csv.reader(file)
            for row in csv_reader:
                line_text = ','.join(row)
                if line_text.endswith('FA'):
                    subject = line_text
                    message = line_text
                    self.send_email(subject, message)

    def send_email(self, subject, message):
        try:
            sendmail_cmd = f"/usr/sbin/sendmail -t -oi"
            sendmail_process = subprocess.Popen(sendmail_cmd.split(), stdin=subprocess.PIPE)
            sendmail_process.communicate(f"Subject: {subject}\n\n{message}\n")
            print("Email sent successfully.")
        except Exception as e:
            print("An error occurred while sending the email:", str(e))


# Example usage
csv_reader = CSVReader(
    file_path='data.csv',
    recipient_email='recipient@example.com'
)
csv_reader.read_csv_and_send_emails()

