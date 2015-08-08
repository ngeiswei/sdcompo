#!/bin/bash

# You must execute the script from its directory. Once inside the
# tracker you must save the render under the same directory of the
# loaded file with the name
#
# render.wav
#
# (be careful not to produce render.wav.wav, as the tracker might
# append .wav to your file name).

set -u
# set -x

###################
# Program options #
###################

if [[ $# != 1 && $# != 2 ]]; then
    echo "Error: wrong usage"
    echo "Usage: $0 ROUND [AUTHOR]"
    exit 1
fi

ROUND=$1
if [[ $# == 2 ]]; then
    AUTHOR=$2
else
    AUTHOR=
fi

####################
# Source common.sh #
####################

PROG_PATH=$(readlink -f "$0")
PROG_DIR=$(dirname "$PROG_PATH")
CM_DIR="$PROG_DIR"
. "$CM_DIR/common.sh"

#############
# Constants #
#############

WIN32_PRG_DIR="/home/$USER/.wine/drive_c/Program Files (x86)"
WIN64_PRG_DIR="/home/$USER/.wine/drive_c/Program Files"

#############
# Functions #
#############

# Format a path to be compatible with wine
wine_path() {
    echo "Z:\\$(readlink -f "$1")"
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
    local rar_re='\.(rar|RAR)$'
    local zip_re='\.(zip|ZIP)$'
    local tgz_re='\.tar\.gz$'
    local gz_re='\.gz$'
    local tbz_re='\.tar\.bz$'
    local copy_re='\.(xrns|it|psy|sunvox)$'
    if [[ "$filename" =~ $rar_re ]]; then
        # Unrar
        unrar e "$filename" "$tmp_dir" &> /dev/null
    elif [[ "$filename" =~ $zip_re ]]; then
        # Unzip
        unzip -qq "$filename" -d "$tmp_dir"
    elif [[ "$filename" =~ $tgz_re ]]; then
        # Untar gz
        tar xvzf "$filename" -C "$tmp_dir" > /dev/null
    elif [[ "$filename" =~ $gz_re ]]; then
        # Gunzip
        stem="$(basename "$filename" .gz)"
        gunzip -c "$filename" > "$tmp_dir/$stem"
    elif [[ "$filename" =~ $tbz_re ]]; then
        # Untar bz
        tar xvjf "$filename" -C "$tmp_dir" > /dev/null
    elif [[ "$filename" =~ $copy_re ]]; then
        # Merely copy
        cp "$filename" "$tmp_dir"
    else
        fatalError "Cannot identify the format in $filename"
    fi
    echo "$tmp_dir"
}

# Parse a renoise file and return its doc_version
renoise_doc_version() {
    local filename="$1"
    local filedir="$(dirname "$filename")"
    unzip -qq "$filename" -d "$filedir"
    local re='<RenoiseSong doc_version="([[:digit:]]+)">'
    while read line; do
        if [[ $line =~ $re ]]; then
            echo ${BASH_REMATCH[1]}
            break
        fi
    done < "$filedir/Song.xml"
}

# Map Renoise file to Renoise program path
renoise_prg() {
    local doc_string="$(renoise_doc_version "$1")"
    case $doc_string in
        10) echo "wine \"$WIN32_PRG_DIR/Renoise 1.9.1/Renoise.exe\""
            ;;
        14) echo "wine \"$WIN32_PRG_DIR/Renoise 2.0.0/Renoise.exe\""
            ;;
        15) echo "wine \"$WIN32_PRG_DIR/Renoise 2.1.0/Renoise.exe\""
            ;;
        21) echo "wine \"$WIN32_PRG_DIR/Renoise 2.5.1/Renoise.exe\""
            ;;
        22) echo "wine \"$WIN32_PRG_DIR/Renoise 2.6.1/Renoise.exe\""
            ;;
        30) echo "wine \"$WIN32_PRG_DIR/Renoise 2.7.2/Renoise.exe\""
            ;;
        37) echo "wine \"$WIN64_PRG_DIR/Renoise 2.8.2/Renoise.exe\""
            ;;
        54) echo "wine \"$WIN64_PRG_DIR/Renoise 3.0.1/Renoise.exe\""
            ;;
        *)  fatalError "doc_string $doc_string not implemented"
            ;;
    esac
}

# Map Renoise file to Renoise program path
sunvox_prg() {
    echo "sunvox"
}

# Parse an IT file and return its Cwt and Cmwt, whitespace separated
it_cwt_cmwt() {
    local filename="$1"
    local cwt=$(xxd -p -l 2 -seek 0x28 "$filename")
    local cmwt=$(xxd -p -l 2 -seek 0x2A "$filename")
    # Convert from big-endian to little-endian, because most
    # information on the internet about Cwt and Cmwt use little-endian
    cwt=${cwt#??}${cwt%??}
    cmwt=${cmwt#??}${cmwt%??}
    echo "$cwt $cmwt"
}

# Map Psycle file to Psycle player program path
psy_prg() {
    # It seems there is no difference in rendering between different
    # versions of psycle. Nevertheless it is adviced to tried the last
    # version and the one just before the song was submitted and
    # compare (subtracting the signal), just in case.
    echo "wine \"$WIN32_PRG_DIR/Psycle Modular Music Studio/psycle.exe\""
}

# Map IT file to IT player program path
it_prg() {
    cwt_cmwt="$(it_cwt_cmwt "$1")"

    # Info gathered about cwt and cmwt
    #
    # 1. OpenMPT 1.17 wrote the value 0888 in both the Cwt/v and Cmwt fields
    #
    # 2. OpenSPC  Cwt/v is 0214, Cmwt is 0200.
    #
    # 3. UNMO3 Cwt/v is 0214, Cmwt is 0214
    #
    # 4. The IT header contains a field, Cwt/v, which is used to
    # identify the application that was used to create the
    # file. The following custom tracker IDs (read as
    # little-endian hexadecimal numbers) are known to be found in
    # the Cwt/v field:
    #
    # 0xyy - Impulse Tracker x.yy - Many other trackers, like
    # ModPlug Tracker, disguise as various versions of Impulse
    # Tracker, so this is not a reliable way to tell if a file was
    # really made with Impulse Tracker. See below for detecting
    # such trackers.
    #
    # 1xyy - Schism Tracker x.yy (up to Schism Tracker v0.50,
    # later versions encode a timestamp in the version number -
    # see Schism Tracker’s version.c)
    #
    # 5xyy - OpenMPT x.yy
    #
    # 6xyy - BeRoTracker x.yy
    #
    # 7xyz - ITMCK x.y.z (N.B. the user can override the value of
    # the Cwt/v header by the -w command-line switch or the
    # #TRACKER-VERSION command in the input file)
    #
    # 5. Note: Because Schism Tracker started a few years ago to
    # use the CWT TrackerVersion ID 0x4000 (after a 0xf000
    # bitmask) for S3M and IT modules which originally BeRoTracker
    # was using since 2004 for S3M modules (0x4100), BeRoTracker
    # is now using a new CWT TrackerVerson ID 0x6000 for S3M "and"
    # IT modules, which means from now on all saved S3M and IT
    # modules will have the new CWT TrackerVersion ID.
    case "$cwt_cmwt" in
        "0888 0888") echo "wine \"$WIN32_PRG_DIR/OpenMPT/mptrack.exe\""
            ;;
        "0214 0200") echo "TODO: OpenSPC"
            ;;
        "0214 0214") echo "TODO: UNMO3"
            ;;
        0*) echo "TODO: Impulse Tracker"
            ;;
        1*) echo "schism"
            ;;
        5*) echo "wine \"$WIN32_PRG_DIR/OpenMPT/mptrack.exe\""
            ;;
        6*) echo "TODO: BeRoTracker"
            ;;
        7*) echo "TODO: ITMCK"
            ;;
        *) fatalError "cwt cmw $cwt_cmwt not implemented"
            ;;
    esac
}

# Giveb an XM filepath, return the tracker program name, with the
# revision numbers (hi-byte, then low-byte) all separated by
# whitespaces
xm_tracker_revision() {
    local filename="$1"
    local tracker=$(xxd -c 20 -l 20 -seek 0x26 "$filename" | cut -f 13 -d ' ')
    local hirev=$(xxd -p -l 1 -seek 0x3A "$filename") 
    local lowrev=$(xxd -p -l 1 -seek 0x3B "$filename")
    echo "$tracker $hirev $lowrev"
}

# Map XM file to the right XM player program path
xm_prg() {
    local tracker_hirev_lowrev=$(xm_tracker_revision "$1")
    case $tracker_hirev_lowrev in
        MilkyTrack*) echo "milkytracker"
            ;;
        *)  fatalError "tracker_hirev_lowrev $tracker_hirev_lowrev not implemented"
            ;;
    esac
}

# Map bnx file to buzz player program path
bmx_prg() {
    echo "wine \"$WIN32_PRG_DIR/Jeskola Buzz/Buzz.exe\""
}

# Map mt2 file to madtracker 2 program path
mt2_prg() {
    echo "wine \"$WIN32_PRG_DIR/MadTracker/MT2.exe\""
}

mp3_prg() {
    echo "mpg123 -w $1/render.wav"
}

# Given the directory with the song, previously unpacked, identify the
# entry, identify the tracker, return the tracker and the entry file
# separated by whitespace.
find_unpacked_entry() {
    local TMP_DIR="$1"
    xrns_files="$(find $TMP_DIR -name "*.xrns")"     # Renoise
    sunvox_files="$(find $TMP_DIR -name "*.sunvox")" # Sunvox
    psy_files="$(find $TMP_DIR -name "*.psy")"       # Psycle
    it_files="$(find $TMP_DIR -name "*.it")"         # Impulse Tracker
    xm_files="$(find $TMP_DIR -name "*.xm")"         # Fasttracker 2
    bmx_files="$(find $TMP_DIR -name "*.bmx")"       # Buzz Tracker
    mt2_files="$(find $TMP_DIR -name "*.mt2")"       # MadTracker 2
    mp3_files="$(find $TMP_DIR -name "*.mp3")"       # MP3 (WTF! Yes!)
    if [[ "$xrns_files" ]]; then
        echo "$(renoise_prg "$xrns_files")" "\"$(wine_path "$xrns_files")\""
    elif [[ "$sunvox_files" ]]; then
        echo "$(sunvox_prg "$sunvox_files")" "$sunvox_files"
    elif [[ "$psy_files" ]]; then
        echo "$(psy_prg "$psy_files")" "\"$(wine_path "$psy_files")\""
    elif [[ "$it_files" ]]; then
        prg_path="$(it_prg "$it_files")"
        if [[ $prg_path == schism ]]; then
            echo "$prg_path" "$it_files"
        else
            echo "$prg_path" "\"$(wine_path "$it_files")\""
        fi
    elif [[ "$xm_files" ]]; then
        echo "$(xm_prg "$xm_files")" "$xm_files"
    elif [[ "$bmx_files" ]]; then
        echo "$(bmx_prg "$bmx_files")" "\"$(wine_path "$bmx_files")\""
    elif [[ "$mt2_files" ]]; then
        echo "$(mt2_prg "$mt2_files")" "\"$(wine_path "$mt2_files")\""
    elif [[ "$mp3_files" ]]; then
        echo "$(mp3_prg "$TMP_DIR")" \""$mp3_files\""
    else
        fatalError "Unknown tracker files in directory $TMP_DIR"
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

    # If the entry is produced by SDCTester (typically blank), skip it
    if [[ $row_author == SDCTester ]]; then
        continue
    fi

    # Get the rest of the metadata
    row_date=$(get_value "$row" date)
    row_place=$(get_value "$row" place)
    row_title="$(get_value "$row" title)"
    row_filename="$(get_value "$row" filename)"

    echo "=== Process round $row_round, $row_title by $row_author ==="

    # Define round directory name
    RND="round${row_round}"

    # Define the output flac file
    of_place=$(fmt_place $row_place)
    of_title=${row_title// /_}
    pad_rnd=$(pad $row_round 3)
    mkdir -p "$RENDERS_DIR/$RND"
    ofile="$RENDERS_DIR/$RND/SDC${pad_rnd}-${of_place}_${row_author}_-_${of_title}.flac"

    # Check whether the flac file has already been created and ask the
    # user whether to skip
    if [[ -f "$ofile" ]]; then
        read -e -p "$ofile exists, $row_filename has probably already been rendered, do you want to skip it [Y/n]? " answer </dev/tty
        if [[ -z $answer || $answer =~ Y|y ]]; then
            continue
        fi
    fi

    # Get the actual path
    filename="$(find "$ENTRIES_DIR/$RND" -name "$row_filename")"

    if [[ -z "$filename" ]]; then
        fatalError "Cannot find entry $row_filename anywhere under $ENTRIES_DIR/$RND"
    fi

    # Unpack the entry into a temporary directory
    tmp_dir="$(unpack "$filename")"

    # Launch tracker. The user should save a wav file of the
    # render entitled render.wav, in the same temporary directory
    CMD="$(find_unpacked_entry "$tmp_dir")"
    echo "$CMD"
    echo "Please render the song in 44KHz 24-bit and save the result under $tmp_dir as a wav file. If some wav files are already there then you may save it as render.wav to disambiguate"
    eval "$CMD 1> $tmp_dir/tracker.stdout 2> $tmp_dir/tracker.stderr"

    # if [[ $? != 0 ]]; then
    #     fatalError "$CMD failed. You may have a look at $tmp_dir/tracker.stderr to understand what went wrong"
    # fi

    # Look for the rendered file
    if [[ -f "$tmp_dir/render.wav" ]]; then
        RENDER_FILE="$tmp_dir/render.wav"
    else
        RENDER_FILE=$(ls $tmp_dir/*.wav)
        if [[ $RENDER_FILE ]]; then
            echo "There is no $tmp_dir/render.wav, instead $RENDER_FILE will be used"
        else
            fatalError "Cannot find any render file"
        fi
    fi

    # Normalize and convert to the right format
    # TODO DC offset
    sox "$RENDER_FILE" --norm -b 16 -r 44100 "$tmp_dir/render_fmt.wav"

    # Encode in flac with the tags
    flac -f "$tmp_dir/render_fmt.wav" -5 -o "$ofile" \
        -T "ARTIST=$row_author" \
        -T "TITLE=$row_title" \
        -T "ALBUM=SDCompo Round ${pad_rnd}" \
        -T "DATE=$row_date" \
        -T "TRACKNUMBER=$track_num"

    # Delete temporary
    rm -r "$tmp_dir"
done < <(tail -n+2 $METADATA)

infoEcho "All entries have been rendered. You may run"
infoEcho "./upload-rounds.sh $ROUND"
