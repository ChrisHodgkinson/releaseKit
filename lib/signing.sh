#!/bin/bash

############################################################
# Code Signing
############################################################

BINARIES=()

############################################################

scan_binaries()
{
    section "Scanning Application"

    BINARIES=()

    while IFS= read -r FILE
    do
        BINARIES+=("$FILE")

        info "$(basename "$FILE")"

    done < <(

        find "$WORKING_APP" -type f \
        | while read -r FILE
        do
            if file "$FILE" | grep -q "Mach-O"
            then
                echo "$FILE"
            fi
        done

    )

    success "${#BINARIES[@]} binary file(s) found"
}

############################################################

sign_file()
{
    local FILE="$1"

    info "$(basename "$FILE")"

    codesign \
        --force \
        --options runtime \
        --timestamp \
        --sign "$DEVELOPER_ID" \
        "$FILE"

    if [[ $? -ne 0 ]]
    then
        fatal "Failed to sign:

$FILE"
    fi
}

############################################################

sign_binaries()
{
    section "Signing Embedded Binaries"

    for FILE in "${BINARIES[@]}"
    do
        sign_file "$FILE"
    done

    success "Embedded binaries signed"
}

############################################################

sign_application()
{
    section "Signing Application"

    codesign \
        --force \
        --deep \
        --options runtime \
        --timestamp \
        --sign "$DEVELOPER_ID" \
        "$WORKING_APP"

    if [[ $? -ne 0 ]]
    then
        fatal "Application signing failed."
    fi

    success "Application signed"
}

############################################################

verify_signature()
{
    section "Verifying Signature"

    codesign \
        --verify \
        --deep \
        --strict \
        --verbose=2 \
        "$WORKING_APP"

    if [[ $? -ne 0 ]]
    then
        fatal "Signature verification failed."
    fi

    success "Signature verified"
}

############################################################

log_binaries()
{
    log ""
    log "Signed Binaries"
    log "---------------"

    for FILE in "${BINARIES[@]}"
    do
        log "  - $(basename "$FILE")"
    done

    log ""
}

############################################################

sign_release()
{
    scan_binaries

    sign_binaries

    sign_application

    verify_signature

    log_binaries
}
