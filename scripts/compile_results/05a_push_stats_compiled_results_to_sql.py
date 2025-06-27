import psycopg2
import pandas as pd
import numpy as np

#singularity run $SING/psycopg2:0.1.sif python 05a_push_stats_compiled_results_to_sql.py

# PostgreSQL connection parameters
db_params = {
    'dbname': 'oceanomics',
    'user': 'postgres',
    'password': 'oceanomics',
    'host': '203.101.227.69',
    'port': 5432
}

# File paths
input_file = "stats_compiled.tsv"
output_file = "stats_compiled_split.tsv"

print(f"📥 Reading {input_file}...")

# STEP 1: Read and clean the raw file
df_raw = pd.read_csv(input_file, sep="\t", dtype=str)

# STEP 2: Split space-separated 'format' field into correct columns
split_cols = df_raw['format'].str.split(r'\s+', expand=True)
split_cols.columns = ['format', 'type', 'num_seqs', 'sum_len', 'min_len', 'avg_len', 'max_len']

# Combine with original 'file' column
df = pd.concat([df_raw['file'], split_cols], axis=1)

# STEP 3: Remove commas from numeric fields
for col in ['num_seqs', 'sum_len', 'min_len', 'avg_len', 'max_len']:
    df[col] = df[col].str.replace(",", "", regex=False)

# STEP 4: Parse identifiers
df["og_id"] = df["file"].str.split('.').str[0].str.split('_').str[0]
df["seq_date"] = df["file"].str.split('.').str[0].str.split('_').str[1].str.lstrip("v")
df["stage"] = df["file"].str.split('.').str[2].astype(int)
df["haplotype"] = df["file"].str.split('.').str[4].str.split('_').str[0]

# STEP 5: Save intermediate file
df.to_csv(output_file, sep="\t", index=False)
print(f"✅ Cleaned + split file saved to: {output_file}")
print("📋 Columns:", df.columns.tolist())

# STEP 6: Convert numeric columns for DB insertion
for col in ['num_seqs', 'sum_len', 'min_len', 'avg_len', 'max_len']:
    df[col] = pd.to_numeric(df[col], errors="coerce")


# STEP 8: Test push with rollback
try:
    conn = psycopg2.connect(**db_params)
    cursor = conn.cursor()
    conn.autocommit = False  # Enable rollback behavior

    row_count = 0

    for _, row in df.iterrows():
        row_dict = row.to_dict()

        upsert_query = """
        INSERT INTO ref_genomes (
            og_id, seq_date, stage, haplotype, format, "type",
            num_seqs, sum_len, min_len, avg_len, max_len
        )
        VALUES (
            %(og_id)s, %(seq_date)s, %(stage)s, %(haplotype)s, %(format)s, %(type)s,
            %(num_seqs)s, %(sum_len)s, %(min_len)s, %(avg_len)s, %(max_len)s
        )
        ON CONFLICT (og_id, seq_date, stage, haplotype) DO UPDATE SET
            format = EXCLUDED.format,
            "type" = EXCLUDED."type",
            num_seqs = EXCLUDED.num_seqs,
            sum_len = EXCLUDED.sum_len,
            min_len = EXCLUDED.min_len,
            avg_len = EXCLUDED.avg_len,
            max_len = EXCLUDED.max_len;
        """

        params = {
            "og_id": row_dict["og_id"],
            "seq_date": row_dict["seq_date"],
            "stage": row_dict["stage"],
            "haplotype": row_dict["haplotype"],
            "format": row_dict.get("format"),
            "type": row_dict.get("type"),
            "num_seqs": int(row_dict["num_seqs"]) if not pd.isna(row_dict["num_seqs"]) else None,
            "sum_len": int(row_dict["sum_len"]) if not pd.isna(row_dict["sum_len"]) else None,
            "min_len": int(row_dict["min_len"]) if not pd.isna(row_dict["min_len"]) else None,
            "avg_len": float(row_dict["avg_len"]) if not pd.isna(row_dict["avg_len"]) else None,
            "max_len": int(row_dict["max_len"]) if not pd.isna(row_dict["max_len"]) else None,
        }

        print(f"\n🔍 [TEST] Would insert row {row_count + 1}:")
        for key, val in params.items():
            print(f"  {key}: {val}")

        cursor.execute(upsert_query, params)
        row_count += 1

    # TEST MODE — do not save anything
    conn.commit()
    print(f"\n✅ COMMIT: Successfully inserted/updated {row_count} rows.")

except Exception as e:
    conn.rollback()
    print(f"❌ ERROR during test DB update: {e}")

finally:
    cursor.close()
    conn.close()
