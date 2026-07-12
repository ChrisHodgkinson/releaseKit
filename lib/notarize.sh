#!/bin/bash

############################################################
# Notarization
############################################################

NOTARY_JSON=""
STAPLER_LOG=""
GATEKEEPER_LOG=""

############################################################

init_notarization()
{
    NOTARY_JSON="$BUILD_PATH/notarization.json"
    STAPLER_LOG="$BUILD_PATH/stapler.log"
    GATEKEEPER_LOG="$BUILD_PATH/gatekeeper.log"
}

############################################################

submit_for_notarization()
{
    section "Submitting for Notarization"

    info "Archive : $(basename "$ZIP_FILE")"

    if [[ -n "$ARCHIVE_SIZE" ]]
    then
        info "Size    : $ARCHIVE_SIZE"
    fi

    run_with_spinner \
        "Uploading and waiting for Apple" \
        "$NOTARY_JSON" \
        xcrun notarytool submit \
            "$ZIP_FILE" \
            --keychain-profile "$NOTARY_PROFILE" \
            --wait \
            --output-format json

    if [[ $? -ne 0 ]]
    then
        fatal "Notarization failed.

See:

$NOTARY_JSON"
    fi

    success "Submission complete"
}

############################################################

log_notarization()
{
    section "Reading Result"

    STATUS=$(plutil -extract status raw "$NOTARY_JSON")

    SUMMARY=$(plutil -extract statusSummary raw "$NOTARY_JSON")

    info "Status  : $STATUS"
    info "Summary : $SUMMARY"

    log ""
    log "Notarization"
    log "------------"
    log "Status  : $STATUS"
    log "Summary : $SUMMARY"
    log ""

    if [[ "$STATUS" != "Accepted" ]]
    then
        fatal "Apple rejected the archive.

See:

$NOTARY_JSON"
    fi

    success "Accepted"
}

############################################################

staple_application()
{
    section "Stapling Ticket"

    xcrun stapler staple "$WORKING_APP" \
        > "$STAPLER_LOG" 2>&1

    if [[ $? -ne 0 ]]
    then
        fatal "Stapling failed.

See:

$STAPLER_LOG"
    fi

    success "Stapled"
}

############################################################

verify_gatekeeper()
{
    section "Gatekeeper Verification"

    spctl -a -t exec -vv "$WORKING_APP" \
        > "$GATEKEEPER_LOG" 2>&1

    if [[ $? -ne 0 ]]
    then
        fatal "Gatekeeper verification failed.

See:

$GATEKEEPER_LOG"
    fi

    success "Gatekeeper passed"
}

############################################################

notarize_release()
{
    init_notarization

    submit_for_notarization

    log_notarization

    staple_application

    verify_gatekeeper
}
