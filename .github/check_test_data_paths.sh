#!/usr/bin/env bash

# Default values
num_paths=1
no_sub_workflows=false
num_paths_offset=0

# Function to display help message
show_help() {
  echo "Usage: $0 [-n number_of_offset_paths] [-n number_of_paths] [-s]"
  echo
  echo "  -n  Number of paths (requires an argument)"
  echo "  -o  Number of offset paths (requires an argument)"
  echo "  -s  No sub workflows (flag)"
}

# Parse arguments
while getopts "o:n:sh" opt; do
  case $opt in
    o)
      num_paths_offset=$OPTARG
      ;;
    n)
      num_paths=$OPTARG
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
for path in $(eval "find . $EXCLUDED_PATHS -name '*.nf.test'");
do
    result=$(grep 'params.test_data' $path)

    if [[ $? -ne 1 ]]; then
        echo "$path"
        echo "$result"

        if [ $paths_skipped -ne $num_paths_offset ]; then
            echo "Skip!"
            ((paths_skipped++))
            continue
        fi

        echo 'Trying to update the test data path...'

        nextflow run ./.github/get_test_data_path_update.nf \
            --old_paths "$result" \
            --test_file "$path" \
            -c ./tests/config/test_data.config

        chmod +x ./sed_commands.sh

        ./sed_commands.sh
        rm ./sed_commands.sh

        echo 'Done updating the test data path...'

        ((paths_processed++))

        if [ $paths_processed -eq $num_paths ]; then
            exit 1
        fi
    fi
done
