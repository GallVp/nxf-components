#!/usr/bin/env bash

# Default values
search_path='.'
file_name_pattern='*.nf.test'
number_of_offset_paths=0
number_of_paths=1
no_sub_workflows=false

# Updated path
updater_path="$(dirname $(realpath $0))/update_testdata_paths.nf"

# Function to display help message
show_help() {
  echo "Usage: $0 [-p search_path] [-f file_name_pattern] [-n number_of_offset_paths] [-n number_of_paths] [-s]"
  echo
  echo "  -p  Search path (.)"
  echo "  -f  File name pattern (*.nf.test)"
  echo "  -n  Number of paths (1)"
  echo "  -o  Number of offset paths (0)"
  echo "  -s  No sub workflows (false)"
}

# Parse arguments
while getopts "p:f:o:n:sh" opt; do
  case $opt in
    p)
      search_path=$OPTARG
      ;;
    f)
      file_name_pattern=$OPTARG
      ;;
    o)
      number_of_offset_paths=$OPTARG
      ;;
    n)
      number_of_paths=$OPTARG
      ;;
    s)
      no_sub_workflows=true
      ;;
    h)
      show_help
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      show_help
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      show_help
      exit 1
      ;;
  esac
done

# Shift off the options and optional --
shift "$((OPTIND - 1))"

if [ $no_sub_workflows = "true" ]; then
    EXCLUDED_PATHS="-not -path './nf-core-modules/*' -not -path './subworkflows/*'"
else
    EXCLUDED_PATHS="-not -path './nf-core-modules/*'"
fi

paths_processed=0
paths_skipped=0
for path in $(eval "find $search_path $EXCLUDED_PATHS -name '$file_name_pattern'");
do
    result=$(grep 'params.test_data' $path)

    if [[ $? -ne 1 ]]; then

        if [ $paths_skipped -ne $number_of_offset_paths ]; then
            echo "Skip!"
            ((paths_skipped++))
            continue
        fi

        echo "[INFO] Trying to update the test data paths for $path"

        "$updater_path" \
            --main_nf "$path" \
            -c ./tests/config/test_data.config

        if [[ $? -ne 0 ]]; then
            echo "[ERROR] Path update failed"
            exit 1
        fi

        echo "[INFO] Updated $path"

        ((paths_processed++))

        if [ $paths_processed -eq $number_of_paths ]; then
            exit 1
        fi
    fi
done
