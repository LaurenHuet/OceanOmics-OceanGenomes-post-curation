scripts=/scratch/pawsey0964/lhuet/refgenomes/OceanOmics-OceanGenomes-post-curation/scripts/backup_scripts

csv_file="$scripts/backup.csv"

# Loop through each line of the CSV
tail -n +2 "$csv_file" | while IFS=',' read -r OG date ver; do
    # Submit the backup script, passing OG and asm_version as arguments
    sbatch $scripts/backup.sh "$OG" "$date" "$ver"
    echo $OG $date $ver
done