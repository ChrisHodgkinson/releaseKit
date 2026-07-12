#!/bin/bash

############################################################
#          Release Tool Configuration
############################################################

#
# Game Information
#

GAME_NAME="MyGame"
BUNDLE_ID="com.example.mygame"

#
# Location of the .app produced by GameMaker
#

SOURCE_APP_PATH="/Users/yourname/path/to/GameMakerBuild/MyGame.app"

#
# Where release folders are created
#

RELEASE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/Releases"

#
# Apple Developer information
#

DEVELOPER_ID="Developer ID Application: Your Name (TEAMID1234)"
TEAM_ID="TEAMID1234"

#
# Stored notarytool profile
#

NOTARY_PROFILE="notary-profile"

#
# DMG settings
#

DMG_VOLUME_NAME="MyGame"

#
# DMG background image
#

DMG_BACKGROUND_IMAGE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assets/dmg-background.png"
