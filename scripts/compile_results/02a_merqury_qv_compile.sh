#!/bin/bash

output_file="merqury.qv.curated.stats.tsv"
base_dir="/scratch/pawsey0964/lhuet/post_curation/post-curation/*"
echo -e "sample\tunique_k_mers_assembly\tk_mers_total\tqv\terror" > "$output_file"

# Find all .curated.qv files
completeness_files=$(find $base_dir -name "*.curated.qv")

for file in $completeness_files; do
    sample_base=$(basename "$file" .curated.qv)

    while IFS=$'\t' read -r sample unique_k_mers k_mers_total qv error; do
        # Trim whitespace
        trimmed_sample=$(echo "$sample" | xargs)

        if [[ "$trimmed_sample" == "Both" ]]; then
            new_sample="${sample_base}.curated.dual"
        elif [[ "$trimmed_sample" =~ ^(OG[0-9]+_v[0-9]+)\.hic([0-9]+)[._]hap([12])\.chr_level(_new)?$ ]]; then
            og_id="${BASH_REMATCH[1]}"
            hic_part="hic${BASH_REMATCH[2]}"
            hap="hap${BASH_REMATCH[3]}"
            new_sample="${og_id}.${hic_part}.3.curated.${hap}"
        else
            echo "⚠️ Could not parse sample name: $trimmed_sample" >&2
            new_sample="$trimmed_sample"
        fi

        echo -e "${new_sample}\t${unique_k_mers}\t${k_mers_total}\t${qv}\t${error}" >> "$output_file"
    done < "$file"
done
