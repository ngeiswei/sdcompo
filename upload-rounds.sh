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

#############
# Functions #
#############

# Given a round return the date of that round
get_date() {
    local ROUND=$1
    while read row; do
        row_round=$(get_value "$row" round)

        # If the round doesn't match, skip that entry. Or break if it's
        # passed the target round
        if [[ $row_round -gt $ROUND ]]; then
            fatalError "Round $ROUND cannot be found in file $METADATA"
        elif [[ $row_round -lt $ROUND ]]; then
            continue
        fi

        # Get the rest of the metadata
        echo $(get_value "$row" date)
        break
    done < <(tail -n+2 $METADATA)
}

########
# Main #
########

for rnd in $@; do
    pad_rnd=$(pad $rnd 3)
    identifier=SDCompo_Round_${pad_rnd}_UPLOAD_TEST_GIGAFIX
    infoEcho "Upload rendered files to $identifier"
    ia upload $identifier "$RENDERS_DIR"/round${rnd}/*.flac \
        --metadata="mediatype:audio" \
        --metadata="collection:opensource_audio" \
        --metadata="date:$(get_date $rnd)" \
        --metadata="licenseurl:http://creativecommons.org/licenses/by-nc-nd/3.0/" \
        --metadata="description:Fill this with something useful" \
        --metadata="subject:what" \
        --metadata="subject:tags" \
        --metadata="subject:?"
done
