#!/bin/bash

output_file="stats_compiled.tsv"
base_dir="/scratch/pawsey0964/lhuet/post-curation/OG*"

# Write header
echo -e "file\tformat\ttype\tnum_seqs\tsum_len\tmin_len\tavg_len\tmax_len" > "$output_file"

# Find and process each stats_output.txt file
find $base_dir -name "*.stats_output.txt" | while read -r file; do

  tail -n +2 "$file" | while read -r line; do

    # Extract full filename (first column)
    original_filename=$(echo "$line" | awk '{print $1}')

    # Extract prefix — detect both dot and underscore joins
    if [[ "$original_filename" =~ ^(OG[0-9]+_[0-9]+)\.(hic[0-9]+)[._] ]]; then
      og_id="${BASH_REMATCH[1]}"
      hic_part="${BASH_REMATCH[2]}"
      rest=$(echo "$original_filename" | sed "s/^${og_id}[._]${hic_part}[._]*//")

      # Assemble new name with "3.curated" inserted
      corrected_name="${og_id}.${hic_part}.3.curated.${rest}"
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
