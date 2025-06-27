import pandas as pd

# Input and output
input_file = "percentage_stats_compiled.tsv"
output_file = "percentage_stats_split.tsv"

print(f"📥 Reading {input_file}...")

# Load original wide-format table
df = pd.read_csv(input_file, sep="\t", dtype=str)

# Parse identifiers
df["og_id"] = df["sample"].str.split('.').str[0].str.split('_').str[0]
df["seq_date"] = df["sample"].str.split('.').str[0].str.split('_').str[1].str.lstrip("v")
df["stage"] = df["sample"].str.extract(r"\.hic\d+\.(\d+)").astype(int)

# Construct hap1 and hap2 records
hap1 = pd.DataFrame({
    "og_id": df["og_id"],
    "seq_date": df["seq_date"],
    "stage": df["stage"],
    "haplotype": "hap1",
    "num_chromosomes": df["num_chromosomes_hap1"],
    "pct_assigned": df["pct_hap1_assigned"],
    "pct_no_super": df["pct_hap1_no_super"],
    "num_seq_no_super": df["num_seq_hap1_no_super"],
    "max_len_no_super": df["max_len_hap1_no_super"]
})

hap2 = pd.DataFrame({
    "og_id": df["og_id"],
    "seq_date": df["seq_date"],
    "stage": df["stage"],
    "haplotype": "hap2",
    "num_chromosomes": df["num_chromosomes_hap2"],
    "pct_assigned": df["pct_hap2_assigned"],
    "pct_no_super": df["pct_hap2_no_super"],
    "num_seq_no_super": df["num_seq_hap2_no_super"],
    "max_len_no_super": df["max_len_hap2_no_super"]
})

# Combine and clean
df_long = pd.concat([hap1, hap2], ignore_index=True)

# Save output
df_long.to_csv(output_file, sep="\t", index=False)

print(f"✅ Reformatted and saved: {output_file}")
print("🧾 Preview:")
print(df_long.head())
