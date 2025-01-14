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

# Generate a formatted diff report
write_diff_report() {
    local dir1="$1"
    local dir2="$2"
    local report_file="diff_report_$(date +%Y%m%d%H%M%S).txt"

    echo "Comparing directories: $dir1 and $dir2" > "$report_file"
    echo "=========================================" >> "$report_file"
    diff -q "$dir1" "$dir2" >> "$report_file" 2>&1

    if [ $? -eq 0 ]; then
        echo "No differences found between $dir1 and $dir2." >> "$report_file"
    else
        echo "Detailed differences:" >> "$report_file"
        echo "-----------------------------------------" >> "$report_file"
        diff "$dir1" "$dir2" >> "$report_file" 2>&1
    fi

    echo "" >> "$report_file"
    echo "Report saved to: $report_file"
}

# Process YAML file
process_yaml() {
    local yaml_file="$1"

    if [ ! -f "$yaml_file" ]; then
        echo "YAML file '$yaml_file' not found!"
        exit 1
    fi

    # Parse list_directories
    local skip_list_dirs=$(yq e '.skip_list_directories' "$yaml_file")
    if [ "$skip_list_dirs" != "true" ]; then
        local list_dirs=$(yq e '.list_directories[]' "$yaml_file")
        for directory in $list_dirs; do
            execute_shell_command "ls -ltr $directory"
        done
    else
        echo "Skipping list_directories as per YAML configuration."
    fi

    # Parse diff_directories
    local skip_diff_dirs=$(yq e '.skip_diff_directories' "$yaml_file")
    if [ "$skip_diff_dirs" != "true" ]; then
        local diff_dirs_count=$(yq e '.diff_directories | length' "$yaml_file")
        for ((i=0; i<diff_dirs_count; i++)); do
            local dir1=$(yq e ".diff_directories[$i][0]" "$yaml_file")
            local dir2=$(yq e ".diff_directories[$i][1]" "$yaml_file")
            write_diff_report "$dir1" "$dir2"
        done
    else
        echo "Skipping diff_directories as per YAML configuration."
    fi

    # Parse checksum_files
    local skip_checksum_files=$(yq e '.skip_checksum_files' "$yaml_file")
    if [ "$skip_checksum_files" != "true" ]; then
        local checksum_files_count=$(yq e '.checksum_files | length' "$yaml_file")
        for ((i=0; i<checksum_files_count; i++)); do
            local files=$(yq e ".checksum_files[$i][]" "$yaml_file")
            for file in $files; do
                execute_shell_command "md5sum $file"
            done
        done
    else
        echo "Skipping checksum_files as per YAML configuration."
    fi
}

# Main script
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <yaml_file>"
    exit 1
fi

yaml_file="$1"
process_yaml "$yaml_file"
