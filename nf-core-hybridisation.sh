#!/usr/bin/env bash

cp_hybrid_module() {
    mkdir -p "./modules/gallvp/$1"
    cp -r "./nf-core-modules/modules/nf-core/$1/"* "./modules/gallvp/$1"
    sed -i 's/modules_nfcore/modules_gallvp/1' "./modules/gallvp/$1/tests/main.nf.test"
}

# Modules for hybrid subworkflows
cp_hybrid_module "gunzip"
cp_hybrid_module "cat/cat"
cp_hybrid_module "ltrfinder"
cp_hybrid_module "ltrharvest"
cp_hybrid_module "ltrretriever/ltrretriever"
cp_hybrid_module "ltrretriever/lai"
