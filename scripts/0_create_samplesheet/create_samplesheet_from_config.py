#!/usr/bin/env python3
"""
Create post-curation samplesheet rows by querying the OceanOmics PostgreSQL DB, using a single
bash-compatible pipeline config file (KEY=VALUE). Postgres credentials are read from an
INI file whose path is provided in the pipeline config as POSTGRES_CFG.

Outputs columns:
  sample,hic_dir,assembly,meryldb,agp,version,date,genomesize

Required config keys:
  POSTGRES_CFG=~/postgresql_details/oceanomics.cfg
  OG_IDS=...
  STAGING_BASE_DIR=/scratch/pawsey0964/{user}/post_curation

Optional:
  SAMPLESHEET_OUTPUT_DIR=/path/to/assets
  SAMPLESHEET_FILENAME_PREFIX=samplesheet
  SAMPLESHEET_LATEST_NAME=samplesheet.csv

Run:
  singularity run $SING/psycopg2:0.1.sif python create_postcuration_samplesheet_from_config.py ../postcuration_pipeline.conf
"""

from __future__ import annotations

import os
import re
import sys
import shutil
import getpass
import configparser
from pathlib import Path
from datetime import date
from typing import Dict, List

import pandas as pd
import psycopg2


def load_kv_config(path: str) -> Dict[str, str]:
    """Load a simple KEY=VALUE config file (bash-compatible)."""
    p = Path(path)
    if not p.exists():
        raise FileNotFoundError(f"❌ Config file does not exist: {path}")

    cfg: Dict[str, str] = {}
    for raw in p.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            raise ValueError(f"❌ Invalid config line (expected KEY=VALUE): {raw}")
        k, v = line.split("=", 1)
        k = k.strip()
        v = v.strip()
        # strip surrounding quotes for whole value
        if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
            v = v[1:-1]
        cfg[k] = v
    return cfg


def require(cfg: Dict[str, str], key: str) -> str:
    if key not in cfg or cfg[key].strip() == "":
        raise ValueError(f"❌ Missing required config key: {key}")
    return cfg[key].strip()


def expand_user_placeholders(s: str, user: str) -> str:
    return s.replace("{user}", user)


def parse_og_ids(value: str) -> List[str]:
    """
    Accepts:
      OG99,OG784
      "OG99,OG784"
      'OG99','OG784','OG758'
      OG99 OG784
    Returns unique OG IDs in order of appearance.
    """
    v = value.strip()
    if not v:
        return []

    # Extract explicit OG tokens if present (handles quoted lists cleanly)
    ogs = re.findall(r"\bOG\d+\b", v)
    if ogs:
        seen = set()
        out: List[str] = []
        for x in ogs:
            if x not in seen:
                seen.add(x)
                out.append(x)
        return out

    # fallback: split on commas/whitespace
    parts = [p.strip().strip("'").strip('"') for p in v.replace(",", " ").split()]
    parts = [p for p in parts if p]
    seen = set()
    out = []
    for x in parts:
        if x not in seen:
            seen.add(x)
            out.append(x)
    return out


def read_postgres_ini(postgres_cfg_path: str) -> Dict[str, str]:
    """
    Read Postgres connection details from an INI file with section [postgres].
    Required keys: dbname, user, password, host
    Optional: port
    """
    postgres_cfg_path = os.path.expanduser(postgres_cfg_path)
    if not os.path.exists(postgres_cfg_path):
        raise FileNotFoundError(f"❌ Postgres config not found: {postgres_cfg_path}")

    pg = configparser.ConfigParser()
    pg.read(postgres_cfg_path)

    if "postgres" not in pg:
        raise ValueError(f"❌ Missing [postgres] section in {postgres_cfg_path}")

    section = pg["postgres"]
    for k in ("dbname", "user", "password", "host"):
        if k not in section or section[k].strip() == "":
            raise ValueError(f"❌ Missing '{k}' in [postgres] section of {postgres_cfg_path}")

    return {
        "dbname": section["dbname"].strip(),
        "user": section["user"].strip(),
        "password": section["password"].strip(),
        "host": section["host"].strip(),
        "port": section.get("port", "5432").strip(),
    }


def build_function_sql(staging_base_dir: str) -> str:
    """
    Builds function:
      sample,hic_dir,assembly,meryldb,agp,version,date,genomesize

    IMPORTANT: version is always 'hic1' (no ref_genomes check).
    """
    base = staging_base_dir.rstrip("/")
    base_sql = base.replace("'", "''")  # SQL literal escape

    return f"""
CREATE OR REPLACE FUNCTION build_postcuration_samplesheet_rows(in_og_ids text[])
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
  WHERE seq.seq_type = 'PacBio'
  ORDER BY seq.og_id, seq.seq_date DESC
),
gen_sz AS (
  SELECT rq.og_id, MAX(rq.genomesize) AS genome_size
  FROM raw_qc rq
  JOIN p ON rq.og_id = p.og_id
  GROUP BY rq.og_id
)
SELECT DISTINCT ON (p.og_id)
  p.og_id                                 AS sample,
  '{base_sql}/' || p.og_id || '/hic'      AS hic_dir,
  '{base_sql}/' || p.og_id || '/assembly' AS assembly,
  '{base_sql}/' || p.og_id || '/meryl'    AS meryldb,
  '{base_sql}/' || p.og_id || '/agp'      AS agp,
  'hic1'                                  AS version,
  CASE
    WHEN ls.seq_date IS NOT NULL
    THEN 'v' || to_char(ls.seq_date, 'YYMMDD')
  END                                     AS date,
  gs.genome_size                          AS genomesize
FROM p
LEFT JOIN latest_seq ls ON ls.og_id = p.og_id
LEFT JOIN gen_sz gs     ON gs.og_id = p.og_id
ORDER BY p.og_id;
$$;
""".strip()


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: create_postcuration_samplesheet_from_config.py <pipeline_config.conf>", file=sys.stderr)
        sys.exit(1)

    conf_path = sys.argv[1]
    cfg = load_kv_config(conf_path)

    user = os.environ.get("USER") or getpass.getuser()
    user = user.replace("'", "").replace("/", "")

    og_ids = parse_og_ids(require(cfg, "OG_IDS"))
    if not og_ids:
        raise ValueError("❌ OG_IDS in config is empty / could not be parsed")

    staging_base_dir = expand_user_placeholders(require(cfg, "STAGING_BASE_DIR"), user)

    out_dir = expand_user_placeholders(cfg.get("SAMPLESHEET_OUTPUT_DIR", "").strip(), user)
    prefix = (cfg.get("SAMPLESHEET_FILENAME_PREFIX", "samplesheet").strip() or "samplesheet")
    latest_name = (cfg.get("SAMPLESHEET_LATEST_NAME", "samplesheet.csv").strip() or "samplesheet.csv")

    postgres_cfg = expand_user_placeholders(require(cfg, "POSTGRES_CFG"), user)
    pg = read_postgres_ini(postgres_cfg)

    func_sql = build_function_sql(staging_base_dir)

    conn = None
    cur = None
    try:
        conn = psycopg2.connect(
            dbname=pg["dbname"],
            user=pg["user"],
            password=pg["password"],
            host=pg["host"],
            port=int(pg["port"]),
        )
        cur = conn.cursor()

        # Drop first: cannot reliably change OUT columns with CREATE OR REPLACE
        cur.execute("DROP FUNCTION IF EXISTS build_postcuration_samplesheet_rows(text[]);")
        conn.commit()

        cur.execute(func_sql)
        conn.commit()

        cur.execute("SELECT * FROM build_postcuration_samplesheet_rows(%s);", (og_ids,))
        rows = cur.fetchall()
        cols = [d[0] for d in cur.description]
        df = pd.DataFrame(rows, columns=cols)

        # genomesize numeric nullable; keep as numeric
        if "genomesize" in df.columns:
            df["genomesize"] = pd.to_numeric(df["genomesize"], errors="coerce")

        missing_rows = df[df.isnull().any(axis=1)]
        if not missing_rows.empty:
            print("\nRows with missing values:\n", file=sys.stderr)
            print(missing_rows.to_string(index=False), file=sys.stderr)

        today = date.today().strftime("%Y%m%d")
        dated_filename = f"{prefix}_{today}.csv"

        out_path_dir = Path(out_dir) if out_dir else Path.cwd()
        out_path_dir.mkdir(parents=True, exist_ok=True)

        dated_path = out_path_dir / dated_filename
        df.to_csv(dated_path, index=False)
        print(f"✅ Samplesheet saved to: {dated_path}")

        # Stable latest copy (e.g. assets/samplesheet.csv)
        if latest_name:
            latest_path = out_path_dir / latest_name
            shutil.copyfile(dated_path, latest_path)
            print(f"✅ Latest copy saved to: {latest_path}")

    finally:
        if cur is not None:
            cur.close()
        if conn is not None:
            conn.close()


if __name__ == "__main__":
    main()
