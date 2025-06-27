#!/bin/bash

# Output TSV
output_file="percentage_stats_compiled.tsv"

# Base search directory
base_dir="/scratch/pawsey0964/lhuet/refgenomes/post-curation/OG*"

# Header line
echo -e "sample\tnum_chromosomes_hap1\tnum_chromosomes_hap2\tpct_hap1_assigned\tpct_hap2_assigned\tpct_hap1_no_super\tpct_hap2_no_super\tnum_seq_hap1_no_super\tmax_len_hap1_no_super\tnum_seq_hap2_no_super\tmax_len_hap2_no_super" > "$output_file"

# Find files and process each
find $base_dir -name "*percentage_stats_output.txt" | while read -r file; do
  # Extract sample prefix (everything up to .hic1)
  filename=$(basename "$file")
  sample_prefix="${filename%%.percentage_stats_output.txt}"
  sample_name="${sample_prefix}.3.curated"

  # Read values from file
  while read -r line; do
    key=$(echo "$line" | cut -d':' -f1 | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
    value=$(echo "$line" | cut -d':' -f2 | sed 's/%//;s/,//g' | xargs)
    
    # Assign values to appropriate variables
    case $key in
      number_of_chromosomes_in_hap1) num_chromosomes_hap1="$value" ;;
      number_of_chromosomes_in_hap2) num_chromosomes_hap2="$value" ;;
      percentage_of_hap1_assembly_assigned_to_chromosomes) pct_hap1_assigned="$value" ;;
      percentage_of_hap2_assembly_assigned_to_chromosomes) pct_hap2_assigned="$value" ;;
      percentage_of_hap1.no_super.fa_assembly_assigned_to_chromosomes) pct_hap1_no_super="$value" ;;
      percentage_of_hap2.no_super.fa_assembly_assigned_to_chromosomes) pct_hap2_no_super="$value" ;;
      number_of_sequences_in_hap1.no_super.fa) num_seq_hap1_no_super="$value" ;;
      maximum_length_of_hap1.no_super.fa) max_len_hap1_no_super="$value" ;;
      number_of_sequences_in_hap2.no_super.fa) num_seq_hap2_no_super="$value" ;;
      maximum_length_of_hap2.no_super.fa) max_len_hap2_no_super="$value" ;;
    esac
  done < "$file"

  # Output line
  echo -e "${sample_name}\t${num_chromosomes_hap1}\t${num_chromosomes_hap2}\t${pct_hap1_assigned}\t${pct_hap2_assigned}\t${pct_hap1_no_super}\t${pct_hap2_no_super}\t${num_seq_hap1_no_super}\t${max_len_hap1_no_super}\t${num_seq_hap2_no_super}\t${max_len_hap2_no_super}" >> "$output_file"
done
