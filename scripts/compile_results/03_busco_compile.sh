#!/bin/bash
output_file="BUSCO_compiled_results.tsv"
base_dir="/scratch/pawsey0964/lhuet/post-curation/OG*" 
echo -e "sample\tdataset\tcomplete\tsingle_copy\tmulti_copy\tfragmented\tmissing\tn_markers\tinternal_stop_codon_percent\tscaffold_n50_bus\tcontigs_n50_bus\tpercent_gaps\tnumber_of_scaffolds" > $output_file



# Find all .tsv files in the current directory and its subdirectories
tsv_files=$(find $base_dir -name "*.hic1-busco.batch_summary.txt")


# Append the data rows from each .tsv file to the output file
for file in $tsv_files; do
  # Skip the first line (header row) and append the rest to the output file
  tail -n +2 "$file" >> "$output_file"
done
