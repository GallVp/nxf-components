#!/usr/bin/env bash

cp_hybrid_module() {
    mkdir -p "./modules/gallvp/$1"
    cp -r "./nf-core-modules/modules/nf-core/$1/"* "./modules/gallvp/$1"
    sed -i 's/modules_nfcore/modules_gallvp/1' "./modules/gallvp/$1/tests/main.nf.test"
}

# Modules for module testing
cp_hybrid_module "gunzip"

# Modules for hybrid sub-workflows
cp_hybrid_module "cat/cat"
cp_hybrid_module "ltrfinder"
cp_hybrid_module "ltrharvest"
cp_hybrid_module "ltrretriever/ltrretriever"
cp_hybrid_module "ltrretriever/lai"

# Modules for sub workflow testing
mkdir -p ./modules/nf-core/gunzip
cp -r ./nf-core-modules/modules/nf-core/gunzip/* ./modules/nf-core/gunzip
sed -i 's/modules_nfcore/modules_gallvp/1' ./modules/nf-core/gunzip/tests/main.nf.test
