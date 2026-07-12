#!/bin/bash

############################################################
# Release Preparation
############################################################

VERSION=""
RELEASE_NAME=""
RELEASE_PATH=""
BUILD_PATH=""

WORKING_APP=""
ZIP_FILE=""
DMG_FILE=""

############################################################

ask_version()
{
    section "Release Information"

    while true
    do
        read -rp "Version (e.g. 1.2.3): " VERSION

        if [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
        then
            break
        fi

        warning "Please use the format x.y.z"
    done

    RELEASE_NAME="${GAME_NAME}-v${VERSION}"

    RELEASE_PATH="${RELEASE_ROOT}/${RELEASE_NAME}"
    BUILD_PATH="${RELEASE_PATH}/.build"

    WORKING_APP="${RELEASE_PATH}/$(basename "$SOURCE_APP_PATH")"

    ZIP_FILE="${RELEASE_PATH}/${RELEASE_NAME}-mac.zip"
    DMG_FILE="${RELEASE_PATH}/${RELEASE_NAME}.dmg"
}

############################################################

create_release_folder()
{
    step "Preparing release folder"

    if [[ -d "$RELEASE_PATH" ]]
    then
        warning "Release already exists."

        if ! confirm "Overwrite it?"
        then
            fatal "Release cancelled."
        fi

        remove_if_exists "$RELEASE_PATH"
    fi

    ensure_directory "$RELEASE_PATH"
    ensure_directory "$BUILD_PATH"

    success "Release folder ready"

    info "$RELEASE_PATH"
}

############################################################

show_release_summary()
{
    section "Release Summary"

    info "Game      : $GAME_NAME"
    info "Version   : $VERSION"
    info "Bundle ID : $BUNDLE_ID"
    info "Folder    : $RELEASE_NAME"

    echo
}

############################################################

copy_app()
{
    echo "SOURCE_APP_PATH = $SOURCE_APP_PATH"

    step "Copying GameMaker application"

    require_directory "$SOURCE_APP_PATH"

    cp -R "$SOURCE_APP_PATH" "$WORKING_APP"

    require_directory "$WORKING_APP"

    success "Application copied"
}

############################################################

prepare_release()
{
    ask_version

    create_release_folder

    show_release_summary

    write_log_header

    copy_app
}
