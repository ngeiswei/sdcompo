#/!bin/bash

# Given round interval, build a table in CSV format with the following
# metadata for each entry:
#
# round,year,place,author,title,filename
#
# title and filename are between double quotes as they may contain
# commas.

# set -x

#######################
# Parse CLI arguments #
#######################

if [[ $# != 2 ]]; then
    echo "Wrong usage"
    echo "Usage: $0 LOW_ROUND UP_ROUND"
    exit 1
fi

LOW_ROUND=$1
UP_ROUND=$2

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

# Given an error message, display that error on stderr and exit
fatalError() {
    echo "[ERROR] $@" 1>&2
    exit 1
}

########
# Main #
########

# Build map round -> year
declare -A rnd2year
up_rnd_body="$(downloadMT $UP_ROUND)"
for rnd in $(seq $LOW_ROUND $UP_ROUND); do
    re="Round $rnd \(Ended [[:alpha:]]+ [[:alnum:]]+, ([[:digit:]]{4})\)"
    if [[ $up_rnd_body =~ $re ]]; then
        rnd2year[$rnd]=${BASH_REMATCH[1]}
    else
        fatalError "[RND $rnd] $up_rnd_body does not match regex $re"
    fi
done

# Write header
header="round,year,place,author,title,filename"
echo $header

# write content
for rnd in $(seq $LOW_ROUND $UP_ROUND); do
    place=""; author=""; title=""; filename=""
    while read line; do
        line="$(iconv -f iso-8859-1 -t utf-8 <<< "$line")"
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
                    echo "$rnd,${rnd2year[$rnd]},$place,$author,\"$title\",\"$filename\""
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
