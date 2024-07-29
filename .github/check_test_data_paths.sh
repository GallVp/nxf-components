#!/usr/bin/env bash

for path in $(find ./modules -name '*.nf.test');
do
    result=$(grep 'params.test_data' $path)

    if [[ $? -ne 1 ]]; then
        echo "$path"
        echo "$result"

        echo 'Trying to update the test data path...'

        nextflow run ./.github/get_test_data_path_update.nf \
            --old_paths "$result" \
            --test_file "$path" \
            -c ./tests/config/test_data.config

        chmod +x ./sed_commands.sh

        ./sed_commands.sh
        rm ./sed_commands.sh

        echo 'Done updating the test data path...'
        exit 1
    fi
done
