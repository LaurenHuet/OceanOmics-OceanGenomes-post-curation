#!/bin/bash --login
#SBATCH --account=pawsey0812
#SBATCH --job-name=ocean-genomes-backup
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00
#SBATCH --export=NONE
#SBATCH --mail-type=BEGIN,END
#SBATCH --mail-user=lauren.huet@uwa.edu.au
#-----------------
#Loading the required modules

OG=$1
date=$2
asm_ver=$date.hic1
if [[ $OG == '' ]]
then
echo "Error: OG variable is empty or not set. Exiting."
exit
fi

# Ensure OG directory exists
if [[ ! -d $OG ]]; then
  echo "Error: Directory $OG does not exist. Exiting."
  exit 1
fi

# Back up BUSCO

rclone copy ${OG}/busco/ pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/busco --checksum --progress

#Back up gfastats

rclone copy "${OG}/gfastats/${sample}_${ver}.3.curated.hap1.assembly_summary.txt" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/gfastats --checksum --progress
rclone copy "${OG}/gfastats/${sample}_${ver}.3.curated.hap2.chr_level.summary.txt" pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/gfastats --checksum --progress

#Back merqury

rclone copy ${OG}/merqury/ pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/merqury --checksum --progress

# Back up curated assemblies
cp ${OG}/update_mapping/${sample}_${ver}.hap2.chr_level_new.fa ${OG}/update_mapping/${sample}_${ver}.3.curated.hap2.chr_level.fa --checksum --progress
cp ${OG}/Hap_1/${sample}_${ver}_hap1.chr_level.fa ${OG}/Hap_1/${sample}_${ver}.3.curated.hap1.chr_level.fa --checksum --progress

rclone copy ${OG}/update_mapping/${sample}_${ver}.3.curated.hap2.chr_level.fa pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/assembly --checksum --progress
rclone copy ${OG}/Hap_1/${sample}_${ver}.3.curated.hap1.chr_level.fa pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/assembly --checksum --progress

# AGP file
cp "${OG}/rapid-curation/Hap_1/hap.agp" ${OG}/rapid-curation/Hap_1/${sample}_${ver}.3.curated.hap1.agp
cp "${OG}/rapid-curation/Hap_2/hap.agp" ${OG}/rapid-curation/Hap_2/${sample}_${ver}.3.curated.hap2.agp

rclone copy ${OG}/rapid-curation/Hap_1/${sample}_${ver}.3.curated.hap1.agp pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/agp
rclone copy ${OG}/rapid-curation/Hap_2/${sample}_${ver}.3.curated.hap2.agp pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/agp

#-------
# back up bam files 
echo "Backing up bam files.. "

rclone copy ${OG}/omnic pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/bam --checksum --progress

#-------
# pretext maps and snapshots
rclone copy ${OG}/pretextsnapshot/${sample}_${ver}.3.curated.hap1.pretext_snapshotFullMap.png pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/pretext --checksum --progress
rclone copy ${OG}/pretextsnapshot/${sample}_${ver}.3.curated.hap2.pretext_snapshotFullMap.png pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/pretext --checksum --progress

rclone copy ${OG}/${sample}_${ver}.3.curated..hap1.map.pretext pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/pretext --checksum --progress
rclone copy ${OG}/${sample}_${ver}.3.curated..hap2.map.pretext pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/pretext --checksum --progress


# stats

rclone copy${OG}/${sample}_${ver}.percentage_stats_output.txt pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/stats --checksum --progress
rclone copy${OG}/${sample}_${ver}.stats_output.txt pawsey0812:oceanomics-assemblies/${sample}/${sample}_${ver}/stats --checksum --progress



