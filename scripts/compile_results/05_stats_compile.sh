#!/bin/bash

output_file="stats_compiled.tsv"
base_dir="/scratch/pawsey0964/lhuet/refgenomes/post-curation_1/OG*"

# Write header
echo -e "file\tformat\ttype\tnum_seqs\tsum_len\tmin_len\tavg_len\tmax_len" > "$output_file"

# Find and process each stats_output.txt file
find $base_dir -name "*.stats_output.txt" | while read -r file; do

  tail -n +2 "$file" | while read -r line; do

    # Extract full filename (first column)
    original_filename=$(echo "$line" | awk '{print $1}')

    haplo=""
    if [[ "$original_filename" == *hap1* ]]; then
      haplo="hap1"
    elif [[ "$original_filename" == *hap2* ]]; then
      haplo="hap2"
    fi

    if [[ "$original_filename" =~ ^(OG[0-9]+_v[0-9]+)\.hic([0-9]+)[._](.*)$ ]]; then
      og_id="${BASH_REMATCH[1]}"
      hic_part="hic${BASH_REMATCH[2]}"
      # Reconstruct the filename with "3.curated" and haplo
      corrected_name="${og_id}.${hic_part}.3.curated.${haplo}"
    else
      echo "⚠️ Could not match pattern in: $original_filename" >&2
      corrected_name="$original_filename"
    fi

    # Extract remaining columns after the filename
    rest_of_line=$(echo "$line" | sed "s/^${original_filename}//" | tr -s ' ' | sed 's/^[ \t]*//')

    # Write full row
    echo -e "${corrected_name}\t${rest_of_line}" >> "$output_file"
  done
done
