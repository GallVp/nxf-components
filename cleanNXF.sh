#!/usr/bin/env bash

rm -rf .nextflow*
echo "Cleaned .nextflow..."
rm -rf .nextflow.pid
echo "Cleaned .nextflow.pid..."
for i in $(ls work | grep -v "conda");
do
    rm -rf "work/$i"
done
echo "Cleaned work..."

rm -rf output
echo "Cleaned output..."

rm -rf .pytest_cache
echo "Cleaned .pytest_cache..."

rm -rf .nf-test
echo "Cleaned .nf-test..."

rm -rf ./.nf-test.log