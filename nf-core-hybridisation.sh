#!/usr/bin/env bash

cp_hybrid_module() {
    mkdir -p "./modules/gallvp/$1"
    cp -r "./nf-core-modules/modules/nf-core/$1/"* "./modules/gallvp/$1"
    sed -i 's/modules_nfcore/modules_gallvp/1' "./modules/gallvp/$1/tests/main.nf.test"
}

# Modules for module testing
cp_hybrid_module "gunzip"
cp_hybrid_module "minimap2/align"
cp_hybrid_module "repeatmasker/repeatmasker"
cp_hybrid_module "meryl/count"

# Modules for hybrid sub-workflows
cp_hybrid_module "agat/spextractsequences"
cp_hybrid_module "agat/spfilterfeaturefromkilllist"
cp_hybrid_module "bwa/index"
cp_hybrid_module "bwa/mem"
cp_hybrid_module "cat/cat"
cp_hybrid_module "diamond/makedb"
cp_hybrid_module "eggnogmapper"
cp_hybrid_module "gffread"
cp_hybrid_module "gt/gff3"
cp_hybrid_module "gt/gff3validator"
cp_hybrid_module "gt/stat"
cp_hybrid_module "helitronscanner/draw"
cp_hybrid_module "helitronscanner/scan"
cp_hybrid_module "ltrfinder"
cp_hybrid_module "ltrharvest"
cp_hybrid_module "ltrretriever/ltrretriever"
cp_hybrid_module "ltrretriever/lai"
cp_hybrid_module "samtools/faidx"
cp_hybrid_module "samblaster"
cp_hybrid_module "seqkit/seq"
cp_hybrid_module "seqkit/sort"
cp_hybrid_module "paftools/sam2paf"
cp_hybrid_module "bedtools/makewindows"
cp_hybrid_module "bedtools/nuc"

# Modules for sub workflow testing
mkdir -p ./modules/nf-core/gunzip
cp -r ./nf-core-modules/modules/nf-core/gunzip/* ./modules/nf-core/gunzip
sed -i 's/modules_nfcore/modules_gallvp/1' ./modules/nf-core/gunzip/tests/main.nf.test
