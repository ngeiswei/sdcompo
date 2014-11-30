#!/bin/bash

# Script to upload rounds to the internetarchive.com

set -u
# set -x

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

# Given a prefix, pipe in and append the prefix to each line
append() {
    while read line; do
        echo "${1}$line"
    done
}

# Remove \r (convert end of line Windows format to unix, cause
# internet archive returns lines in Windows format)
d2u() {
    tr -d '\r'
}

# Determine what files to upload (as to not duplicate the existing
# ones). Happens the whole path while at it.
files_to_upload() {
    local render_path="$RENDERS_DIR/round$1"
    comm -2 -3 \
        <(ls "$render_path"/*.flac) \
        <(ia list $identifier | d2u | grep '\.flac' | append "$render_path/")
}

########
# Main #
########

for rnd in $@; do
    pad_rnd=$(pad $rnd 3)
    date=$(get_date $rnd)
    year=${date%%-*}
    identifier=SDCompo_Round_${pad_rnd}
    infoEcho "Upload rendered (not uploaded yet) files to $identifier"
    ufiles=($(files_to_upload $rnd))
    ia upload $identifier "${ufiles[@]}" \
        --metadata="creator:Various" \
        --metadata="mediatype:audio" \
        --metadata="collection:opensource_audio" \
        --metadata="date:$date" \
        --metadata="licenseurl:http://creativecommons.org/licenses/by-nc-nd/3.0/" \
        --metadata="description:Round $rnd of the SounDevotion Competition, visit http://sdcompo.com for details on songs and artists." \
        --metadata="subject:SounDevotion" \
        --metadata="subject:compo" \
        --metadata="subject:tracker" \
        --metadata="subject:demoscene" \
        --metadata="year:$year"

    infoEcho "Round $rnd has been uploaded, wait for a few hours then run"
    infoEcho "./correct-ia-titles.py $rnd"
done
