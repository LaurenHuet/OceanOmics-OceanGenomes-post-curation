#!/usr/bin/env python3
import csv
import argparse
import re
from pathlib import Path
import shutil
from typing import List

def list_all_files(root: Path) -> List[Path]:
    return [p for p in root.rglob("*") if p.is_file()]

def main():
    ap = argparse.ArgumentParser(description="Place files according to a sample sheet.")
    ap.add_argument("--samplesheet", required=True, help="CSV with columns: sample,hic_dir,assembly,meryldb,agp,version,date,genomesize")
    ap.add_argument("--source", required=True, help="Root directory to search for input files")
    ap.add_argument("--copy", action="store_true", help="Copy instead of move")
    ap.add_argument("--dry-run", action="store_true", help="Show what would happen without changing files")
    args = ap.parse_args()

    source_root = Path(args.source).resolve()
    if not source_root.exists():
        raise SystemExit(f"Source path not found: {source_root}")

    all_files = list_all_files(source_root)

    # Precompile helpers
    def matches_prefix(p: Path, prefix: str) -> bool:
        # Allow anything that STARTS with sample (e.g., OG678G-1..., OG859O-1...)
        return p.name.startswith(prefix)

    def is_fastq(p: Path) -> bool:
        # Match .fastq.gz and .fastq.gz.<anything> (e.g., .partial)
        return ".fastq.gz" in p.name

    def is_json(p: Path) -> bool:
        return p.suffix == ".json"

    def has_token(p: Path, token: str) -> bool:
        return token in p.name

    with open(args.samplesheet, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            sample = row["sample"].strip()
            hic_dir = Path(row["hic_dir"].strip())
            assembly_dir = Path(row["assembly"].strip())
            meryldb_dir = Path(row["meryldb"].strip())
            agp_dir = Path(row["agp"].strip())
            version = row["version"].strip()          # e.g., hic1, hic2
            date = row["date"].strip()               # e.g., v240327 (already has the v)
            # Note: filenames begin with f"{sample}_{date}.{version}"
            series_prefix = f"{sample}_{date}.{version}"

            # Ensure directories exist
            for d in (hic_dir, assembly_dir, meryldb_dir, agp_dir):
                d.mkdir(parents=True, exist_ok=True)

            # Collect matches
            selected_hic = []
            selected_assembly = []
            selected_meryl = []
            selected_agp = []

            for p in all_files:
                name = p.name

                # HIC: fastqs (incl. .partial) + jsons that start with sample
                if matches_prefix(p, sample) and (is_fastq(p) or is_json(p)):
                    selected_hic.append(p)
                    continue

                # Series-specific files (prefix like OG678_v240327.hic2...)
                if name.startswith(series_prefix):
                    # assembly: combined scaffolds fasta
                    if ("hap1.hap2_combined_scaffolds.fa" in name) or (
                        name.endswith(".fa") and "combined_scaffolds" in name
                    ):
                        selected_assembly.append(p)
                        continue
                    # meryl/meryldb bundles
                    if ("meryl" in name) and name.endswith(".tar.gz"):
                        selected_meryl.append(p)
                        continue
                    # agp (sometimes ends with _1 etc.)
                    if ".agp" in name:
                        selected_agp.append(p)
                        continue

            # De-duplicate while preserving order
            def unique(seq): 
                seen = set()
                out = []
                for x in seq:
                    if x not in seen:
                        out.append(x); seen.add(x)
                return out

            selected_hic = unique(selected_hic)
            selected_assembly = unique(selected_assembly)
            selected_meryl = unique(selected_meryl)
            selected_agp = unique(selected_agp)

            # Report
            print(f"\n=== {sample} ===")
            print(f"HIC ({len(selected_hic)}):")
            for p in selected_hic: print(f"  - {p}")
            print(f"ASSEMBLY ({len(selected_assembly)}):")
            for p in selected_assembly: print(f"  - {p}")
            print(f"MERYLDB ({len(selected_meryl)}):")
            for p in selected_meryl: print(f"  - {p}")
            print(f"AGP ({len(selected_agp)}):")
            for p in selected_agp: print(f"  - {p}")

            # Move/copy
            def place(files: List[Path], dest: Path):
                for src in files:
                    target = dest / src.name
                    if args.dry_run:
                        print(f"[DRY] {'COPY' if args.copy else 'MOVE'} {src} -> {target}")
                    else:
                        if args.copy:
                            shutil.copy2(src, target)
                        else:
                            # Create parent (already done, but safe) then move
                            dest.mkdir(parents=True, exist_ok=True)
                            shutil.move(str(src), str(target))
            
            place(selected_hic, hic_dir)
            place(selected_assembly, assembly_dir)
            place(selected_meryl, meryldb_dir)
            place(selected_agp, agp_dir)

            print(f"Done: {sample} ({'copied' if args.copy else 'moved'})")

if __name__ == "__main__":
    main()
