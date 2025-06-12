#!/bin/bash --login
#SBATCH --account=pawsey0964
#SBATCH --job-name=ocean-genomes-backup
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=12:00:00
#SBATCH --export=NONE
#SBATCH --mail-type=BEGIN,END
#SBATCH --mail-user=lauren.huet@uwa.edu.au

OG=$1
date=$2
ver=$3
asm_ver=${OG}_${date}.${ver}
sample=$OG

# Input validation
if [[ -z "$OG" ]]; then
  echo "Error: OG variable is empty or not set. Exiting."
  exit 1
fi

if [[ ! -d $OG ]]; then
  echo "Error: Directory $OG does not exist. Exiting."
  exit 1
fi

# BUSCO
rclone copy "${OG}/busco/" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/busco" --checksum --progress

# Gfastats
rclone copy "${OG}/gfastats/${asm_ver}.3.curated.hap1.assembly_summary.txt" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/gfastats" --checksum --progress
rclone copy "${OG}/gfastats/${asm_ver}.3.curated.hap2.assembly_summary.txt" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/gfastats" --checksum --progress

# Merqury
rclone copy "${OG}/merqury/" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/merqury" --checksum --progress

# Curated assemblies
cp "${OG}/update_mapping/${asm_ver}.hap2.chr_level_new.fa" "${OG}/update_mapping/${asm_ver}.3.curated.hap2.chr_level.fa"
cp "${OG}/Hap_1/${asm_ver}_hap1.chr_level.fa" "${OG}/Hap_1/${asm_ver}.3.curated.hap1.chr_level.fa"

rclone copy "${OG}/update_mapping/${asm_ver}.3.curated.hap2.chr_level.fa" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/assembly" --checksum --progress
rclone copy "${OG}/Hap_1/${asm_ver}.3.curated.hap1.chr_level.fa" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/assembly" --checksum --progress

# AGP files
cp "${OG}/rapid-curation/Hap_1/hap.agp" "${OG}/rapid-curation/Hap_1/${asm_ver}.3.curated.hap1.agp"
cp "${OG}/rapid-curation/Hap_2/hap.agp" "${OG}/rapid-curation/Hap_2/${asm_ver}.3.curated.hap2.agp"

rclone copy "${OG}/rapid-curation/Hap_1/${asm_ver}.3.curated.hap1.agp" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/agp" --checksum --progress
rclone copy "${OG}/rapid-curation/Hap_2/${asm_ver}.3.curated.hap2.agp" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/agp" --checksum --progress

# BAM files
rclone copy "${OG}/omnic" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/bam" --checksum --progress

# Pretext maps
rclone copy "${OG}/pretextsnapshot/${asm_ver}.3.curated.hap1.pretext_snapshotFullMap.png" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/pretext" --checksum --progress
rclone copy "${OG}/pretextsnapshot/${asm_ver}.3.curated.hap2.pretext_snapshotFullMap.png" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/pretext" --checksum --progress

cp "${OG}/${asm_ver}.3.curated..hap1.map.pretext" "${OG}/${asm_ver}.3.curated.hap1.map.pretext"

rclone copy "${OG}/${asm_ver}.3.curated.hap1.map.pretext" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/pretext" --checksum --progress
rclone copy "${OG}/${asm_ver}.3.curated.hap2.map.pretext" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/pretext" --checksum --progress

# Stats
rclone copy "${OG}/${asm_ver}.percentage_stats_output.txt" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/stats" --checksum --progress
rclone copy "${OG}/${asm_ver}.stats_output.txt" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/stats" --checksum --progress

# MultiQC
rclone copy multiqc "pawsey0964:oceanomics-refassemblies/postcuration_multiqc" --checksum --progress