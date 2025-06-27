#!/bin/bash
module load nextflow/24.04.3
nextflow run main.nf -profile singularity --input assets/samplesheet.csv --buscodb /scratch/references/busco_db/actinopterygii_odb10 --binddir /scratch --outdir /scratch/pawsey0964/lhuet/refgenomes -c pawsey_profile.config -resume --tempdir $MYSCRATCH/tmp