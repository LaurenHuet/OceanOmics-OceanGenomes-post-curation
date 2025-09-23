#!/bin/bash

output_file="BUSCO_compiled_results.tsv"
base_dir="/scratch/pawsey0964/lhuet/post_curation/post-curation/OG*"
echo -e "sample\tdataset\tcomplete\tsingle_copy\tmulti_copy\tfragmented\tmissing\tn_markers\tinternal_stop_codon_percent\tscaffold_n50_bus\tcontigs_n50_bus\tpercent_gaps\tnumber_of_scaffolds" > "$output_file"

# Find all .hic1-busco.batch_summary.txt files
tsv_files=$(find $base_dir -name "*.hic1-busco.batch_summary.txt")

# Process and clean each file
for file in $tsv_files; do
  tail -n +2 "$file" | while IFS=$'\t' read -r sample dataset complete single multi frag miss markers stop n50_scaf n50_contig gaps scafs; do

    trimmed_sample=$(echo "$sample" | xargs)

    if [[ "$trimmed_sample" =~ ^(OG[0-9]+_v[0-9]+)\.hic1_hap1\.chr_level\.fa$ ]]; then
        new_sample="${BASH_REMATCH[1]}.hic1.3.curated.hap1"
    elif [[ "$trimmed_sample" =~ ^(OG[0-9]+_v[0-9]+)\.hic1\.hap2\.chr_level_new\.fa$ ]]; then
        new_sample="${BASH_REMATCH[1]}.hic1.3.curated.hap2"
    else
        echo "⚠️ Could not match: $trimmed_sample" >&2
        new_sample="$trimmed_sample"
    fi

    echo -e "${new_sample}\t${dataset}\t${complete}\t${single}\t${multi}\t${frag}\t${miss}\t${markers}\t${stop}\t${n50_scaf}\t${n50_contig}\t${gaps}\t${scafs}" >> "$output_file"
  done
done