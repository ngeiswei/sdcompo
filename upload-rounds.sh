#!/bin/bash

# Script to upload rounds to the internetarchive.com

if [[ $# == 0 ]]; then
    echo "Usage: $0 ROUND [ROUND ...]"
    exit 1
fi

RENDERS_DIR="../Renders"
METADATA="metadata_rnd_1_to_75.csv"

for rnd in $@; do
    pad_rnd=$(pad $rnd 3)
    identifier=SDCompo_Round_${pad_rnd}
    ia upload $identifier "$RENDERS_DIR"/round${rnd}/*.flac
done
