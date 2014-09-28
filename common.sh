# Common definitions, to be sourced

#############
# Constants #
#############

readonly ENTRIES_DIR="entries"
readonly RENDERS_DIR="renders"
readonly METADATA="metadata_rnd_1_to_85.csv"

#############
# Functions #
#############

infoEcho() {
    echo "[INFO] $@"
}

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
