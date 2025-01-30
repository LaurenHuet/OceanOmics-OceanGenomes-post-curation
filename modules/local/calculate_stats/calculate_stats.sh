#!/bin/bash --login

# Input file
input_file=$1
hap1=$2
hap2=$3

# Output file
output_file="percentage_stats_output.txt"

# Function to remove commas from numbers
remove_commas() {
    echo "${1//,/}"
}

# Function to calculate percentage
calculate_percentage() {
    local numerator=$1
    local denominator=$2
    local percentage=$(awk "BEGIN {printf \"%.2f\", ($numerator / $denominator) * 100}")
    echo $percentage
}

# Extract sum_len values for hap1
hap1_super_sum_len=$(awk '$1 ~ /hap1.super.fa/ {print $5}' $input_file)
hap1_chr_level_sum_len=$(awk '$1 ~ /hap1.chr_level.fa/ {print $5}' $input_file)
hap1_no_super_sum_len=$(awk '$1 ~ /hap1.no_super.fa/ {print $5}' $input_file)

# Calculate percentage for hap1
hap1_percentage=$(calculate_percentage $(remove_commas $hap1_super_sum_len) $(remove_commas $hap1_chr_level_sum_len))
hap1_no_super_percentage=$(calculate_percentage $(remove_commas $hap1_no_super_sum_len) $(remove_commas $hap1_chr_level_sum_len))

# Extract sum_len values for hap2
hap2_super_sum_len=$(awk '$1 ~ /hap2.super.fa/ {print $5}' $input_file)
hap2_chr_level_sum_len=$(awk '$1 ~ /hap2.chr_level_new.fa/ {print $5}' $input_file)
hap2_no_super_sum_len=$(awk '$1 ~ /hap2.no_super.fa/ {print $5}' $input_file)

# Calculate percentage for hap2
hap2_percentage=$(calculate_percentage $(remove_commas $hap2_super_sum_len) $(remove_commas $hap2_chr_level_sum_len))
hap2_no_super_percentage=$(calculate_percentage $(remove_commas $hap2_no_super_sum_len) $(remove_commas $hap2_chr_level_sum_len))

# Extract num_seqs and max_len values for hap1 and hap2 from the input file
hap1_num_seqs=$(awk '$1 ~ /hap1.no_super.fa/ {print $4}' $input_file)
hap1_max_len=$(awk '$1 ~ /hap1.no_super.fa/ {print $8}' $input_file)

hap2_num_seqs=$(awk '$1 ~ /hap2.no_super.fa/ {print $4}' $input_file)
hap2_max_len=$(awk '$1 ~ /hap2.no_super.fa/ {print $8}' $input_file)

# Record number of chromosomes (no unlocs)
hap1_nchr=$(grep '>SUPER_' $hap1 | grep -v 'unloc' | wc -l)
hap2_nchr=$(grep '>SUPER_' $hap2 | grep -v 'unloc' | wc -l)

# Write results to output file
echo "Number of chromosomes in hap1: $hap1_nchr" > $output_file
echo "Number of chromosomes in hap2: $hap2_nchr" >> $output_file
echo "Percentage of hap1 assembly assigned to chromosomes: $hap1_percentage%" >> $output_file
echo "Percentage of hap2 assembly assigned to chromosomes: $hap2_percentage%" >> $output_file
echo "Percentage of hap1.no_super.fa assembly assigned to chromosomes: $hap1_no_super_percentage%" >> $output_file
echo "Percentage of hap2.no_super.fa assembly assigned to chromosomes: $hap2_no_super_percentage%" >> $output_file
echo "Number of sequences in hap1.no_super.fa: $hap1_num_seqs" >> $output_file
echo "Maximum length of hap1.no_super.fa: $hap1_max_len" >> $output_file
echo "Number of sequences in hap2.no_super.fa: $hap2_num_seqs" >> $output_file
echo "Maximum length of hap2.no_super.fa: $hap2_max_len" >> $output_file
