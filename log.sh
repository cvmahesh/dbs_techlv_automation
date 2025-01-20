#!/bin/bash

# Generate log file name with current date and time
LOG_FILE="/var/log/custom_script_$(date '+%Y%m%d_%H%M%S').log"
LOG_LEVEL="INFO" # Possible values: DEBUG, INFO, WARNING, ERROR

# Function to write logs
write_log() {
    local LOG_LEVEL_PRIORITY=("DEBUG" "INFO" "WARNING" "ERROR")
    local LOG_LEVEL_THRESHOLD=$1
    local LOG_MESSAGE=$2

    local CURRENT_PRIORITY=$(printf "%s\n" "${LOG_LEVEL_PRIORITY[@]}" | grep -n "^$LOG_LEVEL$" | cut -d':' -f1)
    local THRESHOLD_PRIORITY=$(printf "%s\n" "${LOG_LEVEL_PRIORITY[@]}" | grep -n "^$LOG_LEVEL_THRESHOLD$" | cut -d':' -f1)

    if [ "$THRESHOLD_PRIORITY" -ge "$CURRENT_PRIORITY" ]; then
        local TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
        echo "${TIMESTAMP} [${LOG_LEVEL_THRESHOLD}] ${LOG_MESSAGE}" >> "$LOG_FILE"
    fi
}

# Ensure the log file exists and has the correct permissions
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
fi

# Example usage of logging with controlled log levels
write_log "DEBUG" "This is a debug message."
write_log "INFO" "Script started."
write_log "WARNING" "This is a warning message."
write_log "ERROR" "An error occurred."
write_log "INFO" "Script completed successfully."

# Display log content to the user (optional)
echo "Logs written to $LOG_FILE:"
cat "$LOG_FILE"
