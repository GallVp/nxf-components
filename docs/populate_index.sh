#!/usr/bin/env bash

available=$(find . \
    -name 'main.nf' \
    -path "*/gallvp/*" \
    | xargs dirname \
    | sed 's|./||' \
    | sort -Vr \
    | sed 's|\(.*\)|<li><a href="https://github.com/gallvp/nxf-components/tree/main/\1">\1</a></li>|')

available_no_line=$(echo $available | tr -d '\n')

# Check sync status
existing_md5sum=$(md5sum <(cat docs/AVAILABLE.txt) | awk '{print $1}')
new_md5sum=$(md5sum <(echo "$available") | awk '{print $1}')

# Exit if there is no difference
if [ "$existing_md5sum" == "$new_md5sum" ]; then
    exit 0
fi

# Update then fail
echo "$available" \
    > docs/AVAILABLE.txt

sed "s|AVAILABLE_MODULES_AND_SUB_WORKFLOWS|$available_no_line|1" \
    docs/template.html \
    > docs/index.html

echo 'docs/index.html is not in sync. Run docs/populate_index.sh to sync.'
exit 1
