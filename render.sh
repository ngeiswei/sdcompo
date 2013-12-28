#!/bin/bash

# You must execute the script from its directory

set -u
set -x

if [[ $# != 1 && $# != 2 ]]; then
    echo "Error: wrong usage"
    echo "Usage: $0 ROUND [AUTHOR]"
    exit 1
fi

##############
# Parameters #
##############

ROUND=$1
if [[ $# == 2 ]]; then
    AUTHOR=$2
else
    AUTHOR=
fi
ENTRY_DIR="../Entries"
RENDERS_DIR="../Renders"
METADATA="metadata_rnd_1_to_75.csv"

#############
# Functions #
#############

warning() {
    echo "[WARN] $@" 1>&2
}

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
    local rar_re='(rar|RAR)$'
    local zip_re='(zip|ZIP)$'
    local tgz_re='tar\.gz$'
    local tbz_re='tar\.bz$'
    local copy_re='(xrns|it|psy)$'
    if [[ $filename =~ $rar_re ]]; then
        # Unrar
        fatalError "RAR format not implemented yet"
    elif [[ $filename =~ $zip_re ]]; then
        # Unzip
        unzip -qq $filename -d $tmp_dir
    elif [[ $filename =~ $tgz_re ]]; then
        # Untar gz
        tar xvjf $filename -C $tmp_dir
    elif [[ $filename =~ $tbz_re ]]; then
        # Untar bz
        fatalError "tar.bz format not implemented yet"
    elif [[ $filename =~ $copy_re ]]; then
        # Merely copy
        cp $filename $tmp_dir
    else
        fatalError "Cannot identify the format in $filename"
    fi
    echo "$tmp_dir"
}

# Parse a renoise file and return its doc_version
renoise_doc_version() {
    local filename="$1"
    local filedir="$(dirname "$filename")"
    unzip -qq $filename -d "$filedir"
    local re='<RenoiseSong doc_version="([[:digit:]]+)">'
    while read line; do
        if [[ $line =~ $re ]]; then
            echo ${BASH_REMATCH[1]}
            break
        fi
    done < "$filedir/Song.xml"
}

# Map Renoise file to Renoise program path
renoise_pgr() {
    local pgr_dir="/home/$USER/.wine/drive_c/Program Files (x86)"
    local doc_string="$(renoise_doc_version "$1")"
    case $doc_string in
        10) echo "wine \"$pgr_dir/Renoise 1.9.1/Renoise.exe\""
            ;;
        14) echo "wine \"$pgr_dir/Renoise 2.0.0/Renoise.exe\""
            ;;
        21) echo "wine \"$pgr_dir/Renoise 2.5.1/Renoise.exe\""
            ;;
        *)  fatalError "doc_string $doc_string not implemented"
            ;;
    esac
}

# Parse an IT file and return its Cwt and Cmwt, whitespace separated.
it_cwt_cmwt() {
    local filename="$1"
    local cwt=$(xxd -p -l 2 -seek 0x28 $filename)
    local cmwt=$(xxd -p -l 2 -seek 0x2A $filename)
    echo "$cwt $cmwt"
}

# Map Psycle file to Psycle player program path
psy_pgr() {
    echo "psycle"
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
    xrns_files="$(ls $TMP_DIR/*.xrns 2> /dev/null)" # Renoise
    psy_files="$(ls $TMP_DIR/*.psy 2> /dev/null)"   # Psycle
    it_files="$(ls $TMP_DIR/*.it 2> /dev/null)"     # Impulse Tracker
    if [[ "$xrns_files" ]]; then
        echo $(renoise_pgr "$xrns_files") "$xrns_files"
    elif [[ "$psy_files" ]]; then
        echo $(psy_pgr "$psy_files") "$psy_files"
    elif [[ "$it_files" ]]; then
        echo $(it_pgr "$it_files") "$it_files"
    else
        fatalError "Unknown tracker files in directory $TMP_DIR"
    fi
}

# Given
#
# 1) a row from a metadata CSV file
#
# 2) a field
#
# Return the value corresponding to that field. Possible fields are:
# round, year, place, author, title, filename
get_value() {
    row="$1"
    field="$2"
    row_re='([[:digit:]]+),([[:digit:]]{4}),([[:alnum:]]+),([^,]+),"([^"]+)","([^"]+)"'
    if [[ $row =~ $row_re ]]; then
        if [[ $field == round ]]; then
            echo "${BASH_REMATCH[1]}"
        elif [[ $field == year ]]; then
            echo "${BASH_REMATCH[2]}"
        elif [[ $field == place ]]; then
            echo "${BASH_REMATCH[3]}"
        elif [[ $field == author ]]; then
            echo "${BASH_REMATCH[4]}"
        elif [[ $field == title ]]; then
            echo "${BASH_REMATCH[5]}"
        elif [[ $field == filename ]]; then
            echo "${BASH_REMATCH[6]}"
        else
            fatalError "Field $field is not recognized"
        fi
    else
        fatalError "Row $row does not match regex $row_re"
    fi
}

########
# Main #
########

track_num=-1
while read row; do
    row_round=$(get_value "$row" round)
    row_author=$(get_value "$row" author)

    # If the round doesn't match, skip that entry. Or break if it's
    # passed the target round
    if [[ $row_round -gt $ROUND ]]; then
        break
    elif [[ $row_round -lt $ROUND ]]; then
        continue
    fi

    # If the round matches then we must increase the track_num to get
    # it right for that entry
    ((track_num++))

    # If the author doesn't match (if provided), skip that entry
    if [[ $AUTHOR && $row_author != $AUTHOR ]]; then
        continue
    fi

    # Get the rest of the metadata
    row_year=$(get_value "$row" year)
    row_place=$(get_value "$row" place)
    row_title="$(get_value "$row" title)"
    row_filename="$(get_value "$row" filename)"

    # Define round directory name
    RND="round${row_round}"

    # Get the actual path
    filename="$(find "$ENTRY_DIR/$RND" -name "$row_filename")"
    
    # Unpack the entry into a temporary directory
    tmp_dir="$(unpack "$filename")"

    # Launch tracker. The user should save a wav file of the
    # render entitled render.wav, in the same temporary directory
    CMD="$(find_unpacked_entry "$tmp_dir")"
    eval "$CMD"
        
    # Normalize and convert to the right format
    # TODO DC offset
    sox --norm -b 16 -r 44100 "$tmp_dir/render.wav" "$tmp_dir/render_fmt.wav"

    # Define the output flac file
    of_place=$(fmt_place $row_place)
    of_title=${row_title// /_}
    pad_rnd=$(pad $row_round 3)
    mkdir -p "$RENDERS_DIR/$RND"
    ofile="$RENDERS_DIR/$RND/SDC${pad_rnd}-${of_place}_${row_author}_-_${of_title}.flac"
    
    # Encode in flac with the tags
    flac "$tmp_dir/render_fmt.wav" -5 -o "$ofile" \
        -T "Artist Name=$row_author" \
        -T "Track Title=$row_title" \
        -T "Album Title=SDCompo Round {pad_rnd}" \
        -T "Year=$row_year" \
        -T "Track Number=$track_num"

    # # Delete temporary
    # rm -r "$tmp_dir"
done < <(tail -n+2 $METADATA)
