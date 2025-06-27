import psycopg2
import pandas as pd
import numpy as np  # Required for handling infinity values

## run using singularity run $SING/psycopg2:0.1.sif python 02b_push_merqury_qv_results_to_sqldb.py

# PostgreSQL connection parameters
db_params = {
    'dbname': 'oceanomics',
    'user': 'postgres',
    'password': 'oceanomics',
    'host': '203.101.227.69',
    'port': 5432
}


# File containing merqury stats data

merqury_compiled_path = f"merqury.qv.curated.stats.tsv"  # if your file structure is different this might not work.

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
    merqury['haplotype'] =  merqury['sample'].str.split('.').str[4].str.split('_').str[0]


    # Save the updated DataFrame back to a tab-delimited file
    output_file = f"merqury_qv_compiled_results_split.tsv"
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
            og_id, seq_date, stage, haplotype, unique_k_mers_assembly, k_mers_total, qv, error
        )
        VALUES (
            %(og_id)s, %(seq_date)s, %(stage)s, %(haplotype)s, %(unique_k_mers_assembly)s, %(k_mers_total)s, %(qv)s, %(error)s
        )
        ON CONFLICT (og_id, seq_date, stage, haplotype) DO UPDATE SET
            unique_k_mers_assembly = EXCLUDED.unique_k_mers_assembly,
            k_mers_total = EXCLUDED.k_mers_total,
            qv = EXCLUDED.qv,
            error = EXCLUDED.error;
        """
        params = {
            "og_id": row_dict["og_id"],  # TEXT / VARCHAR
            "seq_date": row_dict["seq_date"],  # TEXT or DATE
            "stage": row_dict["stage"],  # TEXT or DATE
            "haplotype": row_dict["haplotype"],  # TEXT or DATE
            "unique_k_mers_assembly": None if pd.isna(row_dict["unique_k_mers_assembly"]) else int(row_dict["unique_k_mers_assembly"]),  # BIGINT
            "k_mers_total": None if pd.isna(row_dict["k_mers_total"]) else int(row_dict["k_mers_total"]),  # BIGINT
            "qv": float(row_dict["qv"]) if row_dict["qv"] not in [None, ""] else None,  # FLOAT
            "error": float(row_dict["error"]) if row_dict["error"] not in [None, ""] else None,  # FLOAT        
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
