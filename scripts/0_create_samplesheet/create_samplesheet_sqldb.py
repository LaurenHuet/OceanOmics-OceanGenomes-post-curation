#!/usr/bin/env python3
import psycopg2
import os
import pandas as pd
from datetime import date


# run with singularity run $SING/psycopg2:0.1.sif python
# =====================================
# Database connection parameters
# =====================================
db_params = {
    'dbname': 'oceanomics_genomes',
    'user': 'postgres',
    'password': 'oceanomics',
    'host': '131.217.178.144',
    'port': 5432
}


# =====================================
# Base path used to build directories
# (edit here if your root changes)
# =====================================
BASE_ROOT = "/scratch/pawsey0964/lhuet/post_curation"

# =====================================
# OG IDs for the samplesheet (edit as needed)
# =====================================
og_ids = [
    'OG39',
    'OG859'
]

# =====================================
# SQL function definition
# - Builds rows for the target OG IDs
# - version/date logic same as previous sheet
# - genomesize from raw_qc via MAX(genome_size)
# - Paths constructed from BASE_ROOT
# =====================================
create_function_sql = f"""
CREATE OR REPLACE FUNCTION build_hicpost_samplesheet_rows(in_og_ids text[])
RETURNS TABLE (
  sample     text,
  hic_dir    text,
  assembly   text,
  meryldb    text,
  agp        text,
  version    text,
  date       text,
  genomesize numeric
)
LANGUAGE sql
AS $$
WITH p AS (
  SELECT unnest(in_og_ids) AS og_id
),
latest_seq AS (
  SELECT DISTINCT ON (seq.og_id)
         seq.og_id,
         seq.seq_date::date AS seq_date
  FROM sequencing seq
  JOIN p ON seq.og_id = p.og_id
  WHERE seq.technology = 'PacBio'
  ORDER BY seq.og_id, seq.seq_date DESC
),
gen_sz AS (
  -- If your column is named differently (e.g., genomesize), change genome_size below.
  SELECT rq.og_id, MAX(rq.genomesize) AS genome_size
  FROM raw_qc rq
  JOIN p ON rq.og_id = p.og_id
  GROUP BY rq.og_id
)
SELECT DISTINCT ON (p.og_id)
  p.og_id                                                   AS sample,
  '{BASE_ROOT}/' || p.og_id || '/hic'                       AS hic_dir,
  '{BASE_ROOT}/' || p.og_id || '/assembly'                  AS assembly,
  '{BASE_ROOT}/' || p.og_id || '/meryl'                   AS meryl,
  '{BASE_ROOT}/' || p.og_id || '/agp'                       AS agp,
  CASE WHEN rg.og_id IS NOT NULL THEN 'hic2' ELSE 'hic1' END AS version,
  CASE WHEN ls.seq_date IS NOT NULL THEN 'v' || to_char(ls.seq_date, 'YYMMDD') END AS date,
  gs.genome_size                                            AS genomesize
FROM p
LEFT JOIN ref_genomes rg ON rg.og_id = p.og_id
LEFT JOIN latest_seq  ls ON ls.og_id = p.og_id
LEFT JOIN gen_sz      gs ON gs.og_id = p.og_id
ORDER BY p.og_id;
$$;
"""

# =====================================
# Connect to the database
# =====================================
conn = psycopg2.connect(**db_params)
cur = conn.cursor()

# Create or replace the SQL function
cur.execute(create_function_sql)
conn.commit()

# =====================================
# Call the function with OG list
# =====================================
query = """
SELECT sample, hic_dir, assembly, meryldb, agp, version, date, genomesize
FROM build_hicpost_samplesheet_rows(%s);
"""
df = pd.read_sql_query(query, conn, params=(og_ids,))

# Tidy types:
# Keep genomesize numeric/nullable; do not coerce NaN -> strings
# Ensure date is string (already from SQL), paths are strings (already)

# Identify and print rows with missing values (these will be blank in CSV)
missing_rows = df[df.isnull().any(axis=1)]
if not missing_rows.empty:
    print("\nRows with missing values:\n")
    print(missing_rows)

# Close DB connection
cur.close()
conn.close()

# =====================================
# Save CSV to current working directory
# =====================================
output_path = os.path.join(os.getcwd(), "samplesheet.csv")
df.to_csv(output_path, index=False)

print(f"Samplesheet saved to: {output_path}")
