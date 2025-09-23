import psycopg2
import pandas as pd
import numpy as np  # Required for handling infinity values

#run using singularity run $SING/psycopg2:0.1.sif python 02d_push_merqury_completeness_results_to_sqldb.py

# PostgreSQL connection parameters
db_params = {
    'dbname': 'oceanomics_genomes',
    'user': 'postgres',
    'password': 'oceanomics',
    'host': '131.217.178.144',
    'port': 5432
}

# File containing Merqury completeness data
merqury_compiled_path = f"merqury.completeness.stats.tsv"  # if your file structure is different this might not work.

# Import merqury data
print(f"Importing data from {merqury_compiled_path}")

# Load data
merqury = pd.read_csv(merqury_compiled_path, sep="\t")

# Split the 'sample' column up so we have og_id, seq_date, stage and haplotype
# Ensure 'sample' column exists
if 'sample' in merqury.columns:
    # Split 'sample' into 4 new columns
    merqury['og_id'] = merqury['sample'].str.split('.').str[0].str.split('_').str[0]
    merqury['seq_date'] = merqury['sample'].str.split('.').str[0].str.split('_').str[1].str.lstrip('v')
    merqury['stage'] = merqury['sample'].str.split('.').str[2].astype(int)
    merqury['haplotype'] = merqury['sample'].str.split('.').str[4].str.split('_').str[0]

    # Save the updated DataFrame back to a tab-delimited file
    output_file = f"merqury_completeness_compiled_results_split.tsv"
    merqury.to_csv(output_file, sep="\t", index=False)

    print("File successfully processed! New columns added.")
else:
    print("Error: 'sample' column not found in the input file.")

# Print summary of changes
print("\n🔍 Final dataset summary:")
print(merqury.describe())

try:
    # Connect to PostgreSQL
    conn = psycopg2.connect(**db_params)
    cursor = conn.cursor()

    row_count = 0  # Track number of processed rows

    for index, row in merqury.iterrows():
        row_dict = row.to_dict()

        # Extract primary key values
        og_id, seq_date, stage, haplotype = row["og_id"], row["seq_date"], row["stage"], row["haplotype"]

        # UPSERT: Insert if not exists, otherwise update
        upsert_query = """
        INSERT INTO ref_genomes (
            og_id, seq_date, stage, haplotype, solid_k_mers, total_k_mers, completeness
        )
        VALUES (
            %(og_id)s, %(seq_date)s, %(stage)s, %(haplotype)s, %(solid_k_mers)s, %(total_k_mers)s, %(completeness)s
        )
        ON CONFLICT (og_id, seq_date, stage, haplotype) DO UPDATE SET
            solid_k_mers = EXCLUDED.solid_k_mers,
            total_k_mers = EXCLUDED.total_k_mers,
            completeness = EXCLUDED.completeness;
        """
        params = {
            "og_id": row_dict["og_id"],  # TEXT / VARCHAR
            "seq_date": row_dict["seq_date"],  # TEXT or DATE
            "stage": row_dict["stage"],  # INTEGER
            "haplotype": row_dict["haplotype"],  # TEXT
            "solid_k_mers": None if pd.isna(row_dict["solid_k_mers"]) else int(row_dict["solid_k_mers"]),  # BIGINT
            "total_k_mers": None if pd.isna(row_dict["total_k_mers"]) else int(row_dict["total_k_mers"]),  # BIGINT
            "completeness": float(row_dict["completeness"]) if row_dict["completeness"] not in [None, ""] else None  # FLOAT
        }

        # Debugging Check
        print(f"Number of columns in query: {upsert_query.count('%s')}")
        print(f"Column names in DataFrame: {merqury.columns.tolist()}")
        print("row:", row_dict)
        print("params:", params)

        cursor.execute(upsert_query, params)
        row_count += 1

        conn.commit()
        print(f"✅ Successfully processed {row_count} rows!")

except Exception as e:
    conn.rollback()
    print(f"❌ Error: {e}")

finally:
    cursor.close()
    conn.close()
