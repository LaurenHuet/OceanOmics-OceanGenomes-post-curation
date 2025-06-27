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

if [[ -z "$OG" || ! -d $OG ]]; then
  echo "Error: Missing or invalid input directory: $OG"
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
cp "${OG}/rapid-curation/Hap_1/${asm_ver}_hap1.chr_level.fa" "${OG}/rapid-curation/Hap_1/${asm_ver}.3.curated.hap1.chr_level.fa"

rclone copy "${OG}/update_mapping/${asm_ver}.3.curated.hap2.chr_level.fa" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/assembly" --checksum --progress
rclone copy "${OG}/rapid-curation/Hap_1/${asm_ver}.3.curated.hap1.chr_level.fa" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/assembly" --checksum --progress

# AGP files
cp "${OG}/rapid-curation/Hap_1/hap.agp" "${OG}/rapid-curation/Hap_1/${asm_ver}.3.curated.hap1.agp"
cp "${OG}/rapid-curation/Hap_2/hap.agp" "${OG}/rapid-curation/Hap_2/${asm_ver}.3.curated.hap2.agp"

rclone copy "${OG}/rapid-curation/Hap_1/${asm_ver}.3.curated.hap1.agp" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/agp" --checksum --progress
rclone copy "${OG}/rapid-curation/Hap_2/${asm_ver}.3.curated.hap2.agp" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/agp" --checksum --progress

# BAMs
rclone copy "${OG}/omnic_hap1" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/bam/omnic_hap1" --checksum --progress
rclone copy "${OG}/omnic_hap2" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/bam/omnic_hap2" --checksum --progress

# Pretext maps
rclone copy "${OG}/pretextmap_hap_1" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/pretext/hap1" --checksum --progress
rclone copy "${OG}/pretextmap_hap_2" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/pretext/hap2" --checksum --progress
rclone copy "${OG}/pretextsnapshot_hap1" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/pretext_snapshots/hap1" --checksum --progress
rclone copy "${OG}/pretextsnapshot_hap2" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/pretext_snapshots/hap2" --checksum --progress

# Stats
rclone copy "${OG}/calculate_stats/${asm_ver}.stats_output.txt" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/stats" --checksum --progress

mv ${OG}/calculate_stats/percentage_stats_output.txt" ${OG}/calculate_stats/${asm_ver}.percentage_stats_output.txt"

rclone copy "${OG}/calculate_stats/${asm_ver}.percentage_stats_output.txt" "pawsey0964:oceanomics-refassemblies/${sample}/${asm_ver}/stats" --checksum --progress

# MultiQC (assuming fixed location)
#rclone copy multiqc "pawsey0964:oceanomics-refassemblies/postcuration_multiqc" --checksum --progress
