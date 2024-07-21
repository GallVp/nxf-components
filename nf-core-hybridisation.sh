#!/usr/bin/env bash

cp_hybrid_module() {
    mkdir -p "./modules/gallvp/$1"
    cp -r "./nf-core-modules/modules/nf-core/$1/"* "./modules/gallvp/$1"
}

# Modules for tests
cp -r ./nf-core-modules/modules/nf-core/gunzip ./modules/nf-core/

# Modules for hybrid subworkflows
cp_hybrid_module "ltrfinder"
cp_hybrid_module "ltrharvest"
cp_hybrid_module "ltrretriever/ltrretriever"
cp_hybrid_module "ltrretriever/lai"
