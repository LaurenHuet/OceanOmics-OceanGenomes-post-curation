#!/bin/bash

# Set base directory
base_dir="/scratch/pawsey0964/lhuet/post-curation/OG*"

# Output file with SQL-compatible column headers
echo -e "filename\tnum_contigs\tcontig_n50\tcontig_n50_size_mb\tnum_scaffolds\tscaffold_n50\tscaffold_n50_size_mb\tlargest_scaffold\tlargest_scaffold_size_mb\ttotal_scaffold_length\ttotal_scaffold_length_size_mb\tgc_content_percent" > final_gfastats_report.txt

# Find input files
tsv_files=$(find $base_dir -name "*curated*.assembly_summary.txt*")

# Process each file
for file in $tsv_files; do
    awk -v filename="$(basename "$file")" 'BEGIN { OFS="\t" }
        {
            if ($1 == "#" && $2 == "scaffolds") { scaffolds = $3 }
            else if ($1 == "Total" && $2 == "scaffold" && $3 == "length") { scaffold_length = $4 }
            else if ($1 == "Scaffold" && $2 == "N50") { scaffold_N50 = $3 }
            else if ($1 == "Largest" && $2 == "scaffold") { largest_scaffold = $3 }
            else if ($1 == "#" && $2 == "contigs") { contigs = $3 }
            else if ($1 == "Contig" && $2 == "N50") { contig_N50 = $3 }
            else if ($1 == "GC" && $2 == "content") { gc_content = $4 }
        }
        END {
            contig_N50_Mb = contig_N50 / 1000000;
            scaffold_N50_Mb = scaffold_N50 / 1000000;
            scaffold_length_Mb = scaffold_length / 1000000;
            largest_scaffold_Mb = largest_scaffold / 1000000;

            print filename, contigs, contig_N50, contig_N50_Mb, scaffolds, scaffold_N50, scaffold_N50_Mb, largest_scaffold, largest_scaffold_Mb, scaffold_length, scaffold_length_Mb, gc_content
        }' "$file" >> final_gfastats_report.txt
done
