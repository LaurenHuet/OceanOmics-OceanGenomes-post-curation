import pandas as pd
import psycopg2

# singularity run $SING/psycopg2:0.1.sif python 06b_push_percentage_stats_to_sqldb.py


# PostgreSQL connection parameters
db_params = {
    'dbname': 'oceanomics',
    'user': 'postgres',
    'password': 'oceanomics',
    'host': '203.101.227.69',
    'port': 5432
}

# Input file
input_file = "percentage_stats_split.tsv"

# Read data
print(f"📥 Reading: {input_file}")
df = pd.read_csv(input_file, sep="\t")

print("🧾 Rows:", len(df))
print(df.head())

try:
    conn = psycopg2.connect(**db_params)
    cursor = conn.cursor()
    count = 0

    for _, row in df.iterrows():
        row_dict = row.to_dict()

        upsert_query = """
        INSERT INTO ref_genomes (
            og_id, seq_date, stage, haplotype,
            num_chromosomes, pct_assigned, pct_no_super,
            num_seq_no_super, max_len_no_super
        )
        VALUES (
            %(og_id)s, %(seq_date)s, %(stage)s, %(haplotype)s,
            %(num_chromosomes)s, %(pct_assigned)s, %(pct_no_super)s,
            %(num_seq_no_super)s, %(max_len_no_super)s
        )
        ON CONFLICT (og_id, seq_date, stage, haplotype) DO UPDATE SET
            num_chromosomes = EXCLUDED.num_chromosomes,
            pct_assigned = EXCLUDED.pct_assigned,
            pct_no_super = EXCLUDED.pct_no_super,
            num_seq_no_super = EXCLUDED.num_seq_no_super,
            max_len_no_super = EXCLUDED.max_len_no_super;
        """

        params = {
            "og_id": row_dict["og_id"],
            "seq_date": row_dict["seq_date"],
            "stage": int(row_dict["stage"]),
            "haplotype": row_dict["haplotype"],
            "num_chromosomes": int(row_dict["num_chromosomes"]) if pd.notna(row_dict["num_chromosomes"]) else None,
            "pct_assigned": float(row_dict["pct_assigned"]) if pd.notna(row_dict["pct_assigned"]) else None,
            "pct_no_super": float(row_dict["pct_no_super"]) if pd.notna(row_dict["pct_no_super"]) else None,
            "num_seq_no_super": int(row_dict["num_seq_no_super"]) if pd.notna(row_dict["num_seq_no_super"]) else None,
            "max_len_no_super": int(row_dict["max_len_no_super"]) if pd.notna(row_dict["max_len_no_super"]) else None,
        }

        cursor.execute(upsert_query, params)
        conn.commit()
        count += 1

    print(f"✅ Successfully pushed {count} rows to the database.")

except Exception as e:
    print(f"❌ Error during database push: {e}")
    conn.rollback()

finally:
    if 'cursor' in locals(): cursor.close()
    if 'conn' in locals(): conn.close()
