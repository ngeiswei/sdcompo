#/!bin/bash

# Given round interval, build a table in CSV format with the following
# metadata for each entry:
#
# round,year,place,author,title,filename
#
# title and filename are between double quotes as they may contain
# commas.

# set -x

###################
# Program options #
###################

if [[ $# != 2 ]]; then
    echo "Wrong usage"
    echo "Usage: $0 LOW_ROUND UP_ROUND"
    echo "Build metadata for all rounds from LOW_ROUND to UP_ROUND, both included"
    exit 1
fi

LOW_ROUND=$1
UP_ROUND=$2

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

# Regex pattern for place and score
readonly ps_re='<td class="results_table_ps.*">(.+)</td>'

# Regex pattern for author, title and filename
readonly at_re='<td class="results_table_at"><.+>(.+)</a></td>'

#############
# Functions #
#############

# Download the html file with metadata given the round number
downloadMT() {
    local rnd=$1
    wget "http://www.sdcompo.com/results.php?r=$rnd" -O - 2> /dev/null
}

# Fix HTML special characters (to be piped in)
HTML2TXT() {
    sed -e 's/&quot;/\\\"/g' \
        -e 's/&amp;/\&/g' \
        -e 's/&gt;/>/g' \
        -e 's/&#365;/ŭ/g'
}

monthNumber() {
    local monthNum
    case $1 in
        January)
            echo 01
            ;;
        February)
            echo 02
            ;;
        March)
            echo 03
            ;;
        April)
            echo 04
            ;;
        May)
            echo 05
            ;;
        June)
            echo 06
            ;;
        July)
            echo 07
            ;;
        August)
            echo 08
            ;;
        September)
            echo 09
            ;;
        October)
            echo 10
            ;;
        November)
            echo 11
            ;;
        December)
            echo 12
            ;;
        *)
            fatalError "No case for $1"
            ;;
    esac
}

dayNumber() {
    local day=$1
    echo $(pad ${day%??} 2)
}

########
# Main #
########

# Build map round -> date
declare -A rnd2date
up_rnd_body="$(downloadMT $UP_ROUND)"
for rnd in $(seq $LOW_ROUND $UP_ROUND); do
    re="Round $rnd \(Ended ([[:alpha:]]+) ([[:alnum:]]+), ([[:digit:]]{4})\)"
    if [[ $up_rnd_body =~ $re ]]; then
        YYYY=${BASH_REMATCH[3]}
        MM=$(monthNumber ${BASH_REMATCH[1]})
        DD=$(dayNumber ${BASH_REMATCH[2]})
        rnd2date[$rnd]=$YYYY-$MM-$DD
    else
        fatalError "[RND $rnd] $up_rnd_body does not match regex $re"
    fi
done

# Write header
header="round,date,place,author,title,filename"
echo $header

# write content
for rnd in $(seq $LOW_ROUND $UP_ROUND); do
    place=""; author=""; title=""; filename=""
    while read line; do
        # Convert to utf-8
        line="$(iconv -f iso-8859-1 -t utf-8 <<< "$line")"
        # Fix HTML special characters
        line="$(HTML2TXT <<< "$line")" 
        if [[ $line =~ $ps_re ]]; then
            if [[ -z $place ]]; then
                place=${BASH_REMATCH[1]}
            else
                if [[ -z $place ]]; then
                    fatalError "[RND $rnd] place is empty, yet line $line wants to echo content"
                elif [[ -z $author ]]; then
                    fatalError "[RND $rnd] author is empty, yet line $line wants to echo content"
                elif [[ -z $title ]]; then
                    fatalError "[RND $rnd] title is empty, yet line $line wants to echo content"
                elif [[ -z $filename ]]; then
                    fatalError "[RND $rnd] filename is empty, yet line $line wants to echo content"
                else
                    echo "$rnd,${rnd2date[$rnd]},$place,$author,\"$title\",\"$filename\""
                    place=""; author=""; title=""; filename=""
                fi
            fi
        elif [[ $line =~ $at_re ]]; then
            token="${BASH_REMATCH[1]}"
            if [[ -z $author ]]; then
                if [[ $token ]]; then
                    author="$token"
                else
                    fataError "[RND $rnd] Author token is empty but supposed to be in $line"
                fi
            elif [[ -z $title ]]; then
                if [[ $token ]]; then
                    title="$token"
                else
                    fataError "[RND $rnd] Title token is empty but supposed to be in $line"
                fi
            elif [[ -z $filename ]]; then
                if [[ $token ]]; then
                    filename="$token"
                else
                    fatalError "[RND $rnd] Filename token is empty but supposed to be in $line"
                fi
            else
                fatalError "[RND $rnd] Something went very wrong with line $line"
            fi
        fi
    done < <(downloadMT $rnd)
done
