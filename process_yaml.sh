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

# Process YAML file
process_yaml() {
    local yaml_file="$1"

    if [ ! -f "$yaml_file" ]; then
        echo "YAML file '$yaml_file' not found!"
        exit 1
    fi

    # Parse list_directories
    local list_dirs=$(yq e '.list_directories[]' "$yaml_file")
    for directory in $list_dirs; do
        execute_shell_command "ls -ltr $directory"
    done

    # Parse diff_directories
    local diff_dirs_count=$(yq e '.diff_directories | length' "$yaml_file")
    for ((i=0; i<diff_dirs_count; i++)); do
        local dir1=$(yq e ".diff_directories[$i][0]" "$yaml_file")
        local dir2=$(yq e ".diff_directories[$i][1]" "$yaml_file")
        execute_shell_command "diff $dir1 $dir2"
    done

    # Parse checksum_files
    local checksum_files_count=$(yq e '.checksum_files | length' "$yaml_file")
    for ((i=0; i<checksum_files_count; i++)); do
        local files=$(yq e ".checksum_files[$i][]" "$yaml_file")
        for file in $files; do
            execute_shell_command "md5sum $file"
        done
    done
}

# Main script
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <yaml_file>"
    exit 1
fi

yaml_file="$1"
process_yaml "$yaml_file"
