#!/bin/bash

mkdir -p $MYSCRATCH/tmp

nextflow run main.nf -profile singularity --input assets/samplesheet_sealion.csv --buscodb /scratch/references/busco_db/actinopterygii_odb10 --binddir /scratch --outdir /scratch/pawsey0964/$USER/post_curation -c pawsey_profile.config -resume --tempdir $MYSCRATCH/tmp