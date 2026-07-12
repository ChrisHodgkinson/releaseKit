#!/bin/bash

############################################################
# Release Report
############################################################

REPORT_FILE=""

############################################################

init_report()
{
    REPORT_FILE="$RELEASE_PATH/release-report.txt"
}

############################################################

log()
{
    echo "$1" >> "$REPORT_FILE"
}

############################################################

write_log_header()
{
    init_report

    cat > "$REPORT_FILE" << EOF
============================================================
${GAME_NAME} RELEASE REPORT
============================================================

Game
----
Name          : $GAME_NAME
Version       : $VERSION
Bundle ID     : $BUNDLE_ID

Build
-----
Date          : $(date)
Developer ID  : $DEVELOPER_ID

EOF
}

############################################################

finish_release()
{
    log ""
    log "Archive"
    log "-------"
    log "File          : $(basename "$ZIP_FILE")"
    log "Size          : $ARCHIVE_SIZE"
    log "SHA256        : $ARCHIVE_SHA256"

    log ""
    log "Notarization"
    log "------------"
    log "Status        : $STATUS"

    log ""
    log "Files"
    log "-----"
    log "Application   : $(basename "$WORKING_APP")"
    log "ZIP           : $(basename "$ZIP_FILE")"

    if [[ -f "$DMG_FILE" ]]
    then
        log "DMG           : $(basename "$DMG_FILE")"
    fi

    log ""
    log "Result"
    log "------"
    log "SUCCESS"

    section "Release Complete"

    success "Release successful"

    info "Application : $WORKING_APP"
    info "ZIP         : $ZIP_FILE"

    if [[ -f "$DMG_FILE" ]]
    then
        info "DMG         : $DMG_FILE"
    fi

    info "Report      : $REPORT_FILE"
}
