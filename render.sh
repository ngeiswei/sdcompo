#!/bin/bash

if [[ $# != 1 ]]; then
    echo "Error: wrong usage"
    echo "Usage: $0 ROUND"
fi

##############
# Parameters #
##############

ROUND=$1
ENTRY_DIR="../Entries"
METADATA="metadata_rnd_1_to_75.csv"

#############
# Functions #
#############

# Given an error message, display that error on stderr and exit
fatalError() {
    echo "[ERROR] $@" 1>&2
    exit 1
}

# pad $1 symbol with up to $2 0s
pad() {
    pad_expression="%0${2}d"
    printf "$pad_expression" "$1"    
}

# Format place correctly, 1st returns 01, AV returns AV, etc.
fmt_place() {
    local place=$1
    if [[ $place =~ ([[:digit:]]{1,2})(st|nd|rd|th) ]]; then
        pad ${BASH_REMATCH[1]} 2
    elif [[ $place == AV ]]; then
        echo AV
    else
        fatalError "$place doesn't match any pattern"
    fi
}

# Given the entry file, unpack it in a temporary directory and return
# the path of the temporary directory
unpack() {
    local filename="$1"

    # make temporary dir to hold the uncompressed entry
    local tmp_dir=$(mktemp -d SDCompo.XXXXX)

    # Unpack the entry in that directory
    if [[ $filename =~ ^.+\.(rar|RAR)\$ ]]; then
        # Unrar
        fataError "RAR format not implemented yet"
    elif [[ $filename =~ ^.+\.(zip|ZIP)\$ ]]; then
        # Unzip
        unzip $filename -d $tmp_dir
    elif [[ $filename =~ ^.+\.(tar\.gz)\$ ]]; then
        # Untar gz
        tar xvjf $filename -C $tmp_dir
    elif [[ $filename =~ ^.+\.tar\.bz\$ ]]; then
        # Untar bz
        fataError "tar.bz format not implemented yet"
    elif [[ $filename =~ ^.+\.(xrns|it|psy)\$ ]]; then
        # Merely copy
        cp $filename $tmp_dir
    else
        fataError "Cannot identify the format in $filename"
    fi
    echo "$tmp_dir"
}

# Parse a renoise file and return its doc_version
renoise_doc_version() {
    local filename="$1"
    local filedir="$(dirname "$filename")"
    unzip $filename -d "$filedir"
    local sed_re='s/<RenoiseSong doc_version=\"\([[:digit:]]+\)\">/\1/'
    sed $sed_re "$filedir/Song.xml"
}

# Map Renoise file to Renoise program path
renoise_pgr() {
    local pgr_dir="~/.wine/drive_c/Program Files (x86)"
    local doc_string="$(renoise_doc_version "$1")"
    switch($doc_string) {
        case 10:
            echo "wine $pgr_dir/Renoise 1.9.1/Renoise.exe"
            break
        case 14:
            echo "wine $pgr_dir/Renoise 2.0.0/Renoise.exe"
            break
        case 21:
            echo "wine $pgr_dir/Renoise 2.5.1/Renoise.exe"
            break
        default:
            fatalError "doc_string $doc_string not implemented"
    }
}

# Parse an IT file and return its Cwt and Cmwt, whitespace separated.
it_cwt_cmwt() {
    local filename="$1"
    local cwt=$(xxd -p -l 2 -seek 0x28 $filename)
    local cmwt=$(xxd -p -l 2 -seek 0x2A $filename)
    echo "$cwt $cmwt"
}

# Map IT file to IT player program path
it_pgr() {
    local re='([[:digit:]]+) ([[:digit:]]+)'
    cwt_cmwt="$(it_cwt_cmwt "$1")"
    if [[ $cwt_cmwt =~ $re ]]; then
        local cwt=${BASH_REMATCH[1]}
        local cmwt=${BASH_REMATCH[2]}
        # TODO return different versions based on cwt and cmwt
        echo "schism"
    else
        fatalError "cwt and cmwt cannot be parsed out of $cwt_cmwt"
    fi
}

# Given the directory with the song, previously unpacked, identify the
# entry, identify the tracker, return the tracker and the entry file
# separated by whitespace.
find_unpacked_entry() {
    local TMP_DIR="$1"
    xrns_files="$(ls $TMP_DIR/*.xrns)" # Renoise
    psy_files="$(ls $TMP_DIR/*.psy)"   # Psycle
    it_files="$(ls $TMP_DIR/*.it)"     # Impulse Tracker
    if [[ "$xrns_files" ]]; then
        echo $(renoise_pgr "$xrns_files") "$xrns_files"
    elif
        TODO
    fi
}

########
# Main #
########

