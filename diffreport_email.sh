#!/bin/bash

# Function to execute a shell command
execute_shell_command() {
    local command="$1"
    echo "Executing: $command"
    eval "$command"
    if [ $? -ne 0 ]; then
        echo "Error executing command: $command"
    fi
}

# Generate a formatted HTML diff report
write_html_diff_report() {
    local dir1="$1"
    local dir2="$2"
    local report_file="diff_report_$(date +%Y%m%d%H%M%S).html"

    echo "<html><head><title>Diff Report</title></head><body>" > "$report_file"
    echo "<h1>Comparison Report</h1>" >> "$report_file"
    echo "<p>Directories: $dir1 and $dir2</p>" >> "$report_file"

    diff -q "$dir1" "$dir2" > /tmp/diff_summary.txt 2>&1
    if [ $? -eq 0 ]; then
        echo "<p>No differences found between <b>$dir1</b> and <b>$dir2</b>.</p>" >> "$report_file"
    else
        echo "<p>Differences found:</p><pre>" >> "$report_file"
        diff "$dir1" "$dir2" >> "$report_file"
        echo "</pre>" >> "$report_file"
    fi

    echo "</body></html>" >> "$report_file"
    echo "HTML report saved to $report_file"
    echo "$report_file"
}

# Send email using API
send_email() {
    local api_url=$(yq e '.email.api_url' "$yaml_file")
    local api_key=$(yq e '.email.api_key' "$yaml_file")
    local from=$(yq e '.email.from' "$yaml_file")
    local to=$(yq e '.email.to' "$yaml_file")
    local subject="Diff Report"
    local report_file="$1"

    if [ "$(yq e '.email.enabled' "$yaml_file")" != "true" ]; then
        echo "Email sending is disabled in YAML configuration."
        return
    fi

    echo "Sending email to $to..."
    curl -X POST "$api_url" \
         -H "Authorization: Bearer $api_key" \
         -H "Content-Type: application/json" \
         -d '{
            "from": "'"$from"'",
            "to": "'"$to"'",
            "subject": "'"$subject"'",
            "html": "'"$(cat "$report_file" | sed 's/"/\\"/g')"'" 
         }'
    if [ $? -eq 0 ]; then
        echo "Email sent successfully."
    else
        echo "Failed to send email."
    fi
}

# Process YAML file
process_yaml() {
    local yaml_file="$1"

    if [ ! -f "$yaml_file" ]; then
        echo "YAML file '$yaml_file' not found!"
        exit 1
    fi

    # Parse diff_directories
    local skip_diff_dirs=$(yq e '.skip_diff_directories' "$yaml_file")
    if [ "$skip_diff_dirs" != "true" ]; then
        local diff_dirs_count=$(yq e '.diff_directories | length' "$yaml_file")
        for ((i=0; i<diff_dirs_count; i++)); do
            local dir1=$(yq e ".diff_directories[$i][0]" "$yaml_file")
            local dir2=$(yq e ".diff_directories[$i][1]" "$yaml_file")
            local report_file
            report_file=$(write_html_diff_report "$dir1" "$dir2")
            send_email "$report_file"
        done
    else
        echo "Skipping diff_directories as per YAML configuration."
    fi
}

# Main script
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <yaml_file>"
    exit 1
fi

yaml_file="$1"
process_yaml "$yaml_file"


