#!/bin/bash

# Define the YAML file path
yaml_file="config.yaml"

# Function to extract values from the YAML file
extract_value() {
    key="$1"
    grep -A 100 "$key:" "$yaml_file" |
    awk -v RS="" -v key="$key" '/^ *- / {sub(key":", ""); print}' |
    sed -n "/^ *- / {s/^- //; p;}"
}

# extract_list_directories() {
#     grep -A 100 "^list_directories:" "$yaml_file" |
#     awk '/^  - / {print $2}'
# }

extract_list_directories() {
    grep -A 100 "^list_directories:" "$yaml_file" | 
    awk 'NF {print $0} /^$/ {exit}'   # Stop when an empty line is encountered
    #awk '/^  - / {print $2}'           # Extract lines starting with "  - "
}

extract_diff_directories() {
    grep -A 100 "^diff_directories:" "$yaml_file" | 
    awk 'NF {print $0} /^$/ {exit}' | # Stop when an empty line is encountered
    awk '/^  - / {print $2}'           # Extract lines starting with "  - "
}


# Parse the values from the YAML file
skip_list_directories=$(grep "skip_list_directories" "$yaml_file" | awk '{print $2}')
list_directories=$(extract_list_directories )

skip_diff_directories=$(grep "skip_diff_directories" "$yaml_file" | awk '{print $2}')
diff_directories=$(extract_diff_directories  )

skip_checksum_files=$(grep "skip_checksum_files" "$yaml_file" | awk '{print $2}')
checksum_files=$(extract_value "checksum_files")

# Function to list directories
list_dirs() {
    echo "Listing directories:"
    for dir in $list_directories; do
        echo ">>>>>>>>> Contents of $dir:"
        ls -l "$dir"
    done
}

# Function to perform diff between directories
diff_dirs() {
    echo "Performing diff on directories:"
    echo "$diff_directories" | while read -r pair; do
        dir1=$(echo "$pair" | cut -d',' -f1 | sed 's/[\[\]]//g')
        dir2=$(echo "$pair" | cut -d',' -f2 | sed 's/[\[\]]//g')
        echo "Diff between $dir1 and $dir2:"
        diff -rq "$dir1" "$dir2"
    done
}

# Function to compute checksum for files
checksum_files_fn() {
    echo "Computing checksums for files:"
    echo "$checksum_files" | while read -r pair; do
        file1=$(echo "$pair" | cut -d',' -f1 | sed 's/[\[\]]//g')
        file2=$(echo "$pair" | cut -d',' -f2 | sed 's/[\[\]]//g')
        echo "Checksum for $file1:"
        sha256sum "$file1"
        echo "Checksum for $file2:"
        sha256sum "$file2"
    done
}

# Execute based on parsed configuration
if [ "$skip_list_directories" = "false" ]; then
    list_dirs
else
    echo "Skipping directory listing."
fi

if [ "$skip_diff_directories" = "false" ]; then
    diff_dirs
else
    echo "Skipping directory diff."
fi

# if [ "$skip_checksum_files" = "false" ]; then
#     checksum_files_fn
# else
#     echo "Skipping checksum calculation."
# fi
