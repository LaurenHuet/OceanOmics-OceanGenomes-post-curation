#!/bin/bash

output_file="merqury.completeness.stats.tsv"
base_dir="/scratch/pawsey0964/lhuet/post_curation/post-curation/OG*"

# Write header
echo -e "sample\tsolid_k_mers\ttotal_k_mers\tcompleteness" > "$output_file"

# Find all curated.completeness.stats files
completeness_files=$(find $base_dir -name "*curated.completeness.stats")

for file in $completeness_files; do
    sample_base=$(basename "$file" curated.completeness.stats)

    while IFS=$'\t' read -r sample _ solid_kmers total_kmers completeness; do
        trimmed_sample=$(echo "$sample" | xargs)

        if [[ "$trimmed_sample" == "both" || "$trimmed_sample" == "Both" ]]; then
            new_sample="${sample_base}curated.dual"
        elif [[ "$trimmed_sample" =~ ^(OG[0-9]+_v[0-9]+)\.hic([0-9]+)[._]hap([12])\.chr_level(_new)?$ ]]; then
            og_id="${BASH_REMATCH[1]}"
            hic_part="hic${BASH_REMATCH[2]}"
            hap="hap${BASH_REMATCH[3]}"
            new_sample="${og_id}.${hic_part}.3.curated.${hap}"
        else
            echo "⚠️ Could not parse sample name: $trimmed_sample" >&2
            new_sample="$trimmed_sample"
        fi

        echo -e "${new_sample}\t${solid_kmers}\t${total_kmers}\t${completeness}" >> "$output_file"
    done < "$file"
done
