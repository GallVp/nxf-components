#!/usr/bin/env bash

cp_hybrid_module() {
    mkdir -p "./modules/gallvp/$1"
    cp -r "./nf-core-modules/modules/nf-core/$1/"* "./modules/gallvp/$1"
    sed -i 's/modules_nfcore/modules_gallvp/1' "./modules/gallvp/$1/tests/main.nf.test"
}

# Modules for module testing
cp_hybrid_module "gunzip"
cp_hybrid_module "minimap2/align"

# Modules for hybrid sub-workflows
cp_hybrid_module "cat/cat"
cp_hybrid_module "ltrfinder"
cp_hybrid_module "ltrharvest"
cp_hybrid_module "ltrretriever/ltrretriever"
cp_hybrid_module "ltrretriever/lai"
cp_hybrid_module "busco/busco"
cp_hybrid_module "busco/generateplot"
cp_hybrid_module "gffread"
cp_hybrid_module "seqkit/seq"

# Modules for sub workflow testing
mkdir -p ./modules/nf-core/gunzip
cp -r ./nf-core-modules/modules/nf-core/gunzip/* ./modules/nf-core/gunzip
sed -i 's/modules_nfcore/modules_gallvp/1' ./modules/nf-core/gunzip/tests/main.nf.test

