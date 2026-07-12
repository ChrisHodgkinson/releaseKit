#!/bin/bash

############################################################
# General Utility Functions
############################################################

#
# Ensure a file exists
#

require_file()
{
    local FILE="$1"

    [[ -f "$FILE" ]] || fatal "Required file not found:

$FILE"
}

############################################################

#
# Ensure a directory exists
#

require_directory()
{
    local DIR="$1"

    [[ -d "$DIR" ]] || fatal "Required directory not found:

$DIR"
}

############################################################

#
# Create a directory if necessary
#

ensure_directory()
{
    mkdir -p "$1"
}

############################################################

#
# Remove a file or directory if it exists
#

remove_if_exists()
{
    [[ -e "$1" ]] && rm -rf "$1"
}

############################################################

#
# Execute a command and abort if it fails
#

run()
{
    local DESCRIPTION="$1"
    shift

    step "$DESCRIPTION"

    "$@"

    if [[ $? -ne 0 ]]
    then
        fatal "$DESCRIPTION failed."
    fi

    success "$DESCRIPTION"
}

############################################################

#
# Save command output to a file
#

save_output()
{
    local FILE="$1"
    shift

    "$@" > "$FILE" 2>&1
}

############################################################

#
# Ask a Yes / No question
#

confirm()
{
    local PROMPT="$1"

    echo
    read -p "$PROMPT (y/N): " ANSWER

    [[ "$ANSWER" =~ ^[Yy]$ ]]
}

############################################################

#
# Run a long command with a spinner
#
# Usage:
#   run_with_spinner "Message" output_file command args...
#

run_with_spinner()
{
    local MESSAGE="$1"
    local OUTPUT_FILE="$2"

    shift 2

    local SPINNER_PID
    local COMMAND_PID
    local EXIT_CODE

    "$@" > "$OUTPUT_FILE" 2>&1 &
    COMMAND_PID=$!

    (
        local FRAMES=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
        local INDEX=0
        local START_TIME
        local NOW
        local ELAPSED

        START_TIME=$(date +%s)

        while kill -0 "$COMMAND_PID" >/dev/null 2>&1
        do
            NOW=$(date +%s)
            ELAPSED=$((NOW - START_TIME))

            printf "\r%s %s  elapsed: %02d:%02d" \
                "${FRAMES[$INDEX]}" \
                "$MESSAGE" \
                $((ELAPSED / 60)) \
                $((ELAPSED % 60))

            INDEX=$(( (INDEX + 1) % ${#FRAMES[@]} ))

            sleep 0.1
        done
    ) &

    SPINNER_PID=$!

    wait "$COMMAND_PID"
    EXIT_CODE=$?

    kill "$SPINNER_PID" >/dev/null 2>&1
    wait "$SPINNER_PID" 2>/dev/null

    if [[ $EXIT_CODE -eq 0 ]]
    then
        printf "\r✓ %s complete                         \n" "$MESSAGE"
    else
        printf "\r✖ %s failed                           \n" "$MESSAGE"
    fi

    return $EXIT_CODE
}
