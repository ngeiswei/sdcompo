#!/bin/bash

# Script to upload rounds to the internetarchive.com

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

fatalError "TODO: set right attributes, mediatype:audio, collection:opensource_audio, date:ROUND_DATE, licenseurl:???. PER TITLE ATTRIBUTES: Album:???, Creator:???"

for rnd in $@; do
    pad_rnd=$(pad $rnd 3)
    identifier=SDCompo_Round_${pad_rnd}_UPLOAD_TEST
    ia upload $identifier "$RENDERS_DIR"/round${rnd}/*.flac
done
