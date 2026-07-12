#!/bin/bash

############################################################
# Environment Checks
############################################################

check_command()
{
    local CMD="$1"

    if command -v "$CMD" >/dev/null 2>&1
    then
        success "$CMD"
    else
        fatal "Required command not found:

$CMD"
    fi
}

############################################################

check_developer_id()
{
    step "Checking Developer ID certificate"

    if security find-identity -v -p codesigning \
        | grep -Fq "$DEVELOPER_ID"
    then
        success "Developer ID certificate found"
    else
        fatal "Developer ID certificate not found:

$DEVELOPER_ID"
    fi
}

############################################################

check_source_app()
{
    step "Checking GameMaker build"

    require_directory "$SOURCE_APP_PATH"

    success "GameMaker application found"
}

############################################################

run_checks()
{
    section "Environment Checks"

    check_command xcodebuild
    check_command codesign
    check_command ditto
    check_command spctl
    check_command security
    check_command plutil
    check_command xcrun

    check_developer_id

    check_source_app

    success "Environment OK"
}
