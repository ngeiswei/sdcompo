#!/bin/bash

# Script to upload rounds to the internetarchive.com

set -u
set -x

###################
# Program options #
###################

if [[ $# == 0 ]]; then
    echo "Usage: $0 ROUND [ROUND ...]"
    exit 1
fi

####################
# Source common.sh #
####################

PROG_PATH=$(readlink -f "$0")
PROG_DIR=$(dirname "$PROG_PATH")
. "$PROG_DIR/common.sh"

########
# Main #
########

for rnd in $@; do
    pad_rnd=$(pad $rnd 3)
    identifier=SDCompo_Round_${pad_rnd}_UPLOAD_TEST_FIX_METADATA
    infoEcho "Upload rendered files to $identifier"
    ia upload $identifier "$RENDERS_DIR"/round${rnd}/*.flac \
        --metadata="mediatype:audio" \
        --metadata="collection:opensource_audio"
done
