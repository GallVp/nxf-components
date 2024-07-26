#!/usr/bin/env bash

for path in $(find . -name '*.nf.test');
do
    result=$(grep 'params.test_data' $path)

    if [[ $? -ne 1 ]]; then
        echo "$path"
        echo "$result"
        exit 1
    fi
done
