#!/bin/bash

############################################################
# DMG Creation
############################################################

TEMP_DMG=""
FINAL_DMG=""
MOUNT_POINT=""
MOUNTED_VOLUME_NAME=""
BACKGROUND_NAME="background.png"

############################################################

init_dmg()
{
    TEMP_DMG="$BUILD_PATH/temp.dmg"
    FINAL_DMG="$DMG_FILE"
    MOUNT_POINT=""
    MOUNTED_VOLUME_NAME=""
}

############################################################

create_temp_dmg()
{
    section "Creating DMG"

    local SIZE
    SIZE=$(du -sm "$WORKING_APP" | awk '{print $1}')
    SIZE=$((SIZE + 50))

    remove_if_exists "$TEMP_DMG"
    remove_if_exists "$FINAL_DMG"

    step "Creating writable image"

    hdiutil create \
        -quiet \
        -size "${SIZE}m" \
        -fs HFS+ \
        -volname "$DMG_VOLUME_NAME" \
        "$TEMP_DMG"

    require_file "$TEMP_DMG"

    success "Writable image created"
}

############################################################

mount_dmg()
{
    step "Mounting image"

    local MOUNT_OUTPUT

    MOUNT_OUTPUT=$(hdiutil attach "$TEMP_DMG" -nobrowse)

    MOUNT_POINT=$(echo "$MOUNT_OUTPUT" | awk '/\/Volumes\// { for (i=3; i<=NF; i++) printf "%s%s", $i, (i<NF ? " " : "") }')

    if [[ -z "$MOUNT_POINT" || ! -d "$MOUNT_POINT" ]]
    then
        fatal "Failed to detect DMG mount point."
    fi

    MOUNTED_VOLUME_NAME=$(basename "$MOUNT_POINT")

    success "Mounted at $MOUNT_POINT"
}

############################################################

copy_to_dmg()
{
    step "Copying application"

    cp -R "$WORKING_APP" "$MOUNT_POINT/"

    require_directory "$MOUNT_POINT/$(basename "$WORKING_APP")"

    success "Application copied"
}

############################################################

add_applications_link()
{
    step "Adding Applications shortcut"

    ln -s /Applications "$MOUNT_POINT/Applications"

    success "Applications shortcut added"
}

############################################################

add_background_image()
{
    if [[ ! -f "$DMG_BACKGROUND_IMAGE" ]]
    then
        warning "Background image not found, skipping."
        info "$DMG_BACKGROUND_IMAGE"
        return
    fi

    section "Adding Background Image"

    step "Copying background image"

    mkdir -p "$MOUNT_POINT/.background"

    cp "$DMG_BACKGROUND_IMAGE" "$MOUNT_POINT/.background/$BACKGROUND_NAME"

    require_file "$MOUNT_POINT/.background/$BACKGROUND_NAME"

    success "Background image copied"
}

############################################################

polish_finder_window()
{
    section "Polishing DMG Window"

    local APP_BASENAME
    APP_BASENAME=$(basename "$WORKING_APP")

    step "Applying Finder layout"

    osascript <<EOF
tell application "Finder"
    activate

    set dmgDisk to disk "$MOUNTED_VOLUME_NAME"
    open dmgDisk

    delay 1

    set dmgWindow to container window of dmgDisk

    set current view of dmgWindow to icon view
    set toolbar visible of dmgWindow to false
    set statusbar visible of dmgWindow to false
    set bounds of dmgWindow to {200, 120, 900, 520}

    set viewOptions to icon view options of dmgWindow
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 104

    try
        set background picture of viewOptions to file ".background:$BACKGROUND_NAME" of dmgDisk
    end try

    delay 1

    set position of item "$APP_BASENAME" of dmgWindow to {220, 220}
    set position of item "Applications" of dmgWindow to {500, 220}

    update dmgDisk without registering applications

    delay 2

    close dmgWindow
end tell
EOF

    if [[ $? -ne 0 ]]
    then
        warning "Finder layout could not be applied."
    else
        success "Finder layout applied"
    fi

    step "Saving Finder layout"

    sync
    sleep 2

    success "Finder layout saved"
}

############################################################

unmount_dmg()
{
    step "Unmounting image"

    sync
    sleep 2

    hdiutil detach "$MOUNT_POINT" -force -quiet

    success "Unmounted"
}

############################################################

compress_dmg()
{
    step "Compressing DMG"

    hdiutil convert \
        "$TEMP_DMG" \
        -quiet \
        -format UDZO \
        -o "$FINAL_DMG"

    require_file "$FINAL_DMG"

    success "DMG created"

    info "$FINAL_DMG"
}

############################################################

cleanup_dmg()
{
    remove_if_exists "$TEMP_DMG"
}

############################################################

create_dmg()
{
    init_dmg

    create_temp_dmg

    mount_dmg

    copy_to_dmg

    add_applications_link

    add_background_image

    polish_finder_window

    unmount_dmg

    compress_dmg

    cleanup_dmg
}
