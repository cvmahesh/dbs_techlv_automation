#!/bin/bash

# API URL and Bearer Token
API_URL="https://email-api-provider.com/send"
BEARER_TOKEN="your_bearer_token_here"

# Email fields
FROM="sender@example.com"
TO="recipient@example.com"
CC="ccrecipient@example.com"
SUBJECT="Test Email"
BODY="This is a test email sent using an API."

# Send the email
response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$API_URL" \
    -H "Authorization: Bearer $BEARER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "from": "'"$FROM"'",
        "to": "'"$TO"'",
        "cc": "'"$CC"'",
        "subject": "'"$SUBJECT"'",
        "body": "'"$BODY"'"
    }')

# Extract HTTP status code
http_status=$(echo "$response" | grep "HTTP_STATUS" | awk -F: '{print $2}')
response_body=$(echo "$response" | sed '/HTTP_STATUS/d')

# Display response or handle errors
if [[ $http_status -eq 200 ]]; then
    echo "Email sent successfully!"
    echo "Response: $response_body"
else
    echo "Failed to send email. HTTP Status: $http_status"
    echo "Response: $response_body"
fi
