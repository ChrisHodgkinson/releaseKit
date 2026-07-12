#!/bin/bash

clear

SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"

#-----------------------------------------------------------
# Load configuration
#-----------------------------------------------------------

source "$SCRIPT_DIR/config.sh"

#-----------------------------------------------------------
# Load libraries
#-----------------------------------------------------------

source "$SCRIPT_DIR/lib/colours.sh"
source "$SCRIPT_DIR/lib/util.sh"

source "$SCRIPT_DIR/lib/checks.sh"
source "$SCRIPT_DIR/lib/version.sh"
source "$SCRIPT_DIR/lib/signing.sh"
source "$SCRIPT_DIR/lib/archive.sh"
source "$SCRIPT_DIR/lib/notarize.sh"
source "$SCRIPT_DIR/lib/report.sh"
source "$SCRIPT_DIR/lib/dmg.sh"

#-----------------------------------------------------------
# Start
#-----------------------------------------------------------

header "OIDANOID RELEASE TOOL"

info "Game : $GAME_NAME"

#-----------------------------------------------------------
# Pipeline
#-----------------------------------------------------------

run_checks

prepare_release

sign_release

package_release

notarize_release     

create_dmg

finish_release

success "Release preparation complete."
