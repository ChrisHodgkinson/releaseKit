#!/bin/bash

############################################################
# Archive Creation
############################################################

ARCHIVE_SIZE=""
ARCHIVE_SHA256=""

############################################################

create_zip()
{
    section "Creating Archive"

    remove_if_exists "$ZIP_FILE"

    step "Compressing application"

    ditto -c -k --keepParent \
        "$WORKING_APP" \
        "$ZIP_FILE"

    require_file "$ZIP_FILE"

    success "Archive created"

    info "$(basename "$ZIP_FILE")"
}

############################################################

calculate_archive_info()
{
    section "Calculating Archive Information"

    ARCHIVE_SIZE=$(du -h "$ZIP_FILE" | awk '{print $1}')

    ARCHIVE_SHA256=$(shasum -a 256 "$ZIP_FILE" | awk '{print $1}')

    success "Archive verified"

    info "Size   : $ARCHIVE_SIZE"
    info "SHA256 : $ARCHIVE_SHA256"
}

############################################################

log_archive()
{
    log ""
    log "Archive"
    log "-------"

    log "File   : $(basename "$ZIP_FILE")"
    log "Size   : $ARCHIVE_SIZE"
    log "SHA256 : $ARCHIVE_SHA256"

    log ""
}

############################################################

package_release()
{
    create_zip

    calculate_archive_info

    log_archive
}
