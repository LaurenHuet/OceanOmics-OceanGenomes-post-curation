import pandas as pd

input_file = "stats_compiled.tsv"
output_file = "stats_compiled_split.tsv"

print(f"📥 Reading {input_file}...")

# Read as a raw file to preserve structure
df_raw = pd.read_csv(input_file, sep="\t", dtype=str)

# Split the malformed stats string into separate columns
split_cols = df_raw['format'].str.split(r'\s+', expand=True)
split_cols.columns = ['format', 'type', 'num_seqs', 'sum_len', 'min_len', 'avg_len', 'max_len']

# Combine with original 'file' column
df_clean = pd.concat([df_raw['file'], split_cols], axis=1)

# Remove commas from numeric fields
for col in ['num_seqs', 'sum_len', 'min_len', 'avg_len', 'max_len']:
    df_clean[col] = df_clean[col].str.replace(",", "", regex=False)

# Add parsed metadata from 'file'
df_clean["og_id"] = df_clean["file"].str.split('.').str[0].str.split('_').str[0]
df_clean["seq_date"] = df_clean["file"].str.split('.').str[0].str.split('_').str[1].str.lstrip("v")
df_clean["stage"] = df_clean["file"].str.split('.').str[2].astype(int)
df_clean["haplotype"] = df_clean["file"].str.split('.').str[4].str.split('_').str[0]

# Save to final output
df_clean.to_csv(output_file, sep="\t", index=False)

print(f"✅ Cleaned file saved to: {output_file}")
print("🧾 Columns:", df_clean.columns.tolist())
print(df_clean.head())
