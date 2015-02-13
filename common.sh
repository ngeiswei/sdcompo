# Common definitions, to be sourced

#############
# Constants #
#############

readonly ENTRIES_DIR="entries"
readonly RENDERS_DIR="renders"
readonly METADATA="metadata_rnd_1_to_86.csv"

# Regular expression for parsing the CSV rows
readonly round_re='([[:digit:]]+)'
readonly date_re='([[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2})'
readonly place_re='([[:alnum:]]+)'
readonly author_re='([^,]+)'
readonly title_re='"(.+)"'
readonly file_re='"(.+)"'
readonly row_re="^$round_re,$date_re,$place_re,$author_re,$title_re,$file_re\$"

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

# Given
#
# 1) a row from a metadata CSV file
#
# 2) a field
#
# Return the value corresponding to that field. Possible fields are:
# round, date, place, author, title, filename
get_value() {
    local row="$1"
    local field="$2"
    if [[ $row =~ $row_re ]]; then
        if [[ $field == round ]]; then
            echo "${BASH_REMATCH[1]}"
        elif [[ $field == date ]]; then
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
