#!/bin/bash
export NXF_HOME=$MYSCRATCH/.nextflow

# Override Singularity cache directory variables
unset SINGULARITY_CACHEDIR
unset NXF_SINGULARITY_CACHEDIR
export SINGULARITY_CACHEDIR=/scratch/pawsey0964/lhuet/cache
export NXF_SINGULARITY_CACHEDIR=/scratch/pawsey0964/lhuet/cache

# Debugging: Print cache paths to verify
echo "SINGULARITY_CACHEDIR is set to: $SINGULARITY_CACHEDIR"
echo "NXF_SINGULARITY_CACHEDIR is set to: $NXF_SINGULARITY_CACHEDIR"

mkdir -p $MYSCRATCH/tmp

nextflow run main.nf \
-profile singularity \
--input assets/samplesheet.csv \
--buscodb /scratch/references/busco_db/actinopterygii_odb10 \
--binddir /scratch \
--outdir /scratch/pawsey0964/$USER/post_curation \
-c pawsey_profile.config \
-resume \
--tempdir $MYSCRATCH/tmp